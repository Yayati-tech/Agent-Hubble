#!/bin/bash

# Setup script for Security Hub Ticket Integration
# This script configures environment variables and creates necessary AWS resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎫 Setting up Security Hub Ticket Integration...${NC}"

# Configuration
FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
REGION="us-west-2"
TICKET_TABLE_NAME="SecurityHubTickets"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials verified${NC}"

# Create DynamoDB table for custom ticket system
echo -e "${YELLOW}📊 Creating DynamoDB table for ticket system...${NC}"

aws dynamodb create-table \
    --table-name $TICKET_TABLE_NAME \
    --attribute-definitions AttributeName=ticket_id,AttributeType=S \
    --key-schema AttributeName=ticket_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION

echo -e "${GREEN}✅ DynamoDB table created: $TICKET_TABLE_NAME${NC}"

# Create environment variables file
echo -e "${YELLOW}⚙️ Creating environment variables file...${NC}"

cat > env-vars-with-tickets.json << EOF
{
    "Variables": {
        "SNS_TOPIC_NAME": "SecurityHubAutoRemediationAlerts",
        "BACKUP_ACCOUNT_ID": "002616177731",
        "MANAGEMENT_ACCOUNT_ID": "013983952777",
        "TICKET_TABLE_NAME": "$TICKET_TABLE_NAME"
    }
}
EOF

echo -e "${GREEN}✅ Environment variables file created: env-vars-with-tickets.json${NC}"

# Update Lambda function with new environment variables
echo -e "${YELLOW}🔄 Updating Lambda function with ticket system environment variables...${NC}"

aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment file://env-vars-with-tickets.json \
    --region $REGION

echo -e "${GREEN}✅ Lambda function updated with ticket system configuration${NC}"

# Add DynamoDB permissions to Lambda role
echo -e "${YELLOW}🔐 Adding DynamoDB permissions to Lambda role...${NC}"

ROLE_NAME="SecurityHubAutoRemediationRole"

# Create DynamoDB policy
cat > dynamodb-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": "arn:aws:dynamodb:$REGION:$(aws sts get-caller-identity --query Account --output text):table/$TICKET_TABLE_NAME"
        }
    ]
}
EOF

# Attach policy to role
aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name DynamoDBTicketPolicy \
    --policy-document file://dynamodb-policy.json

echo -e "${GREEN}✅ DynamoDB permissions added to Lambda role${NC}"

# Create S3 bucket for ticket dashboard (optional)
echo -e "${YELLOW}🌐 Creating S3 bucket for ticket dashboard...${NC}"

DASHBOARD_BUCKET="security-hub-ticket-dashboard-$(aws sts get-caller-identity --query Account --output text)"

aws s3 mb s3://$DASHBOARD_BUCKET --region $REGION

# Configure bucket for static website hosting
aws s3 website s3://$DASHBOARD_BUCKET --index-document index.html --error-document error.html

# Upload ticket dashboard
aws s3 cp ticket-dashboard.html s3://$DASHBOARD_BUCKET/index.html

echo -e "${GREEN}✅ S3 bucket created and dashboard uploaded: $DASHBOARD_BUCKET${NC}"

# Create CloudWatch dashboard for ticket metrics
echo -e "${YELLOW}📊 Creating CloudWatch dashboard for ticket metrics...${NC}"

cat > ticket-dashboard-metrics.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "$TICKET_TABLE_NAME"],
                    [".", "ConsumedWriteCapacityUnits", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "Ticket System DynamoDB Metrics"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Lambda", "Duration", "FunctionName", "$FUNCTION_NAME"],
                    [".", "Errors", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "Lambda Function Performance"
            }
        }
    ]
}
EOF

aws cloudwatch put-dashboard \
    --dashboard-name "SecurityHubTicketDashboard" \
    --dashboard-body file://ticket-dashboard-metrics.json \
    --region $REGION

echo -e "${GREEN}✅ CloudWatch dashboard created: SecurityHubTicketDashboard${NC}"

# Clean up temporary files
rm -f dynamodb-policy.json ticket-dashboard-metrics.json

echo -e "${GREEN}🎉 Ticket system setup completed successfully!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "  1. Configure Jira/GitHub integration (optional)"
echo -e "  2. Test ticket creation with sample findings"
echo -e "  3. Access ticket dashboard at: http://$DASHBOARD_BUCKET.s3-website-$REGION.amazonaws.com"
echo -e "  4. Monitor ticket metrics in CloudWatch dashboard"
echo -e "  5. Set up SNS notifications for ticket events"