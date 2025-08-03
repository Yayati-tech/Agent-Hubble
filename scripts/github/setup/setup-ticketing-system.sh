#!/bin/bash

# Comprehensive Setup script for Security Hub Ticket Integration
# This script configures environment variables and creates necessary AWS resources for ticketing

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
    --region $REGION 2>/dev/null || echo -e "${YELLOW}⚠️ DynamoDB table may already exist${NC}"

echo -e "${GREEN}✅ DynamoDB table created/verified: $TICKET_TABLE_NAME${NC}"

# Prompt for ticketing system choice
echo -e "${YELLOW}🎯 Choose your ticketing system:${NC}"
echo -e "1. DynamoDB (default - no external dependencies)"
echo -e "2. GitHub Issues"
echo -e "3. Jira"
echo -e "4. All systems (DynamoDB + GitHub + Jira)"
read -p "Enter your choice (1-4): " TICKET_CHOICE

# Initialize environment variables
ENV_VARS="{
    \"Variables\": {
        \"SNS_TOPIC_NAME\": \"SecurityHubAutoRemediationAlerts\",
        \"BACKUP_ACCOUNT_ID\": \"002616177731\",
        \"MANAGEMENT_ACCOUNT_ID\": \"013983952777\",
        \"TICKET_TABLE_NAME\": \"$TICKET_TABLE_NAME\"
    }
}"

# Configure GitHub integration
if [[ "$TICKET_CHOICE" == "2" || "$TICKET_CHOICE" == "4" ]]; then
    echo -e "${YELLOW}🐙 Configuring GitHub Issues integration...${NC}"
    
    read -p "Enter GitHub repository (format: owner/repo): " GITHUB_REPO
    read -s -p "Enter GitHub Personal Access Token: " GITHUB_TOKEN
    echo
    
    if [[ -n "$GITHUB_REPO" && -n "$GITHUB_TOKEN" ]]; then
        # Test GitHub token
        GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            https://api.github.com/user | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
        
        if [[ -n "$GITHUB_USER" ]]; then
            echo -e "${GREEN}✅ GitHub token verified for user: $GITHUB_USER${NC}"
            
            # Add GitHub variables to environment
            ENV_VARS=$(echo $ENV_VARS | jq '.Variables.GITHUB_TOKEN = "'$GITHUB_TOKEN'" | .Variables.GITHUB_REPO = "'$GITHUB_REPO'"')
            
            # Create GitHub labels
            echo -e "${YELLOW}🏷️ Creating GitHub labels...${NC}"
            declare -a labels=("security-hub" "auto-remediation" "IAM" "S3" "EC2" "RDS" "Lambda" "KMS" "GuardDuty" "Inspector" "SSM" "Macie" "WAF" "ACM" "SecretsManager" "CloudFormation" "APIGateway" "ElastiCache" "DynamoDB" "EKS" "ECR" "ECS" "Redshift" "SageMaker" "Glue")
            
            for label in "${labels[@]}"; do
                curl -s -X POST \
                    -H "Authorization: token $GITHUB_TOKEN" \
                    -H "Accept: application/vnd.github.v3+json" \
                    https://api.github.com/repos/$GITHUB_REPO/labels \
                    -d "{\"name\":\"$label\",\"color\":\"0366d6\",\"description\":\"Security Hub finding\"}" 2>/dev/null || echo -e "${YELLOW}⚠️ Label $label may already exist${NC}"
            done
            
            echo -e "${GREEN}✅ GitHub integration configured${NC}"
        else
            echo -e "${RED}❌ Invalid GitHub token${NC}"
        fi
    fi
fi

# Configure Jira integration
if [[ "$TICKET_CHOICE" == "3" || "$TICKET_CHOICE" == "4" ]]; then
    echo -e "${YELLOW}🔧 Configuring Jira integration...${NC}"
    
    read -p "Enter Jira URL (e.g., https://your-domain.atlassian.net): " JIRA_URL
    read -p "Enter Jira username: " JIRA_USERNAME
    read -s -p "Enter Jira API token: " JIRA_API_TOKEN
    echo
    read -p "Enter Jira project key: " JIRA_PROJECT_KEY
    
    if [[ -n "$JIRA_URL" && -n "$JIRA_USERNAME" && -n "$JIRA_API_TOKEN" && -n "$JIRA_PROJECT_KEY" ]]; then
        # Test Jira connection
        AUTH_STRING=$(echo -n "$JIRA_USERNAME:$JIRA_API_TOKEN" | base64)
        JIRA_TEST=$(curl -s -H "Authorization: Basic $AUTH_STRING" \
            "$JIRA_URL/rest/api/2/myself")
        
        if [[ $JIRA_TEST == *"\"name\""* ]]; then
            echo -e "${GREEN}✅ Jira connection verified${NC}"
            
            # Add Jira variables to environment
            ENV_VARS=$(echo $ENV_VARS | jq '.Variables.JIRA_URL = "'$JIRA_URL'" | .Variables.JIRA_USERNAME = "'$JIRA_USERNAME'" | .Variables.JIRA_API_TOKEN = "'$JIRA_API_TOKEN'" | .Variables.JIRA_PROJECT_KEY = "'$JIRA_PROJECT_KEY'"')
            
            echo -e "${GREEN}✅ Jira integration configured${NC}"
        else
            echo -e "${RED}❌ Invalid Jira credentials${NC}"
        fi
    fi
fi

# Create environment variables file
echo -e "${YELLOW}⚙️ Creating environment variables file...${NC}"

echo $ENV_VARS > env-vars-with-tickets.json

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
    --policy-document file://dynamodb-policy.json 2>/dev/null || echo -e "${YELLOW}⚠️ DynamoDB policy may already exist${NC}"

echo -e "${GREEN}✅ DynamoDB permissions added to Lambda role${NC}"

# Clean up temporary files
rm -f dynamodb-policy.json

echo -e "${GREEN}🎉 Ticket system setup completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Ticket System Configuration:${NC}"
echo -e "  - DynamoDB Table: $TICKET_TABLE_NAME"
if [[ "$TICKET_CHOICE" == "2" || "$TICKET_CHOICE" == "4" ]]; then
    echo -e "  - GitHub Repository: $GITHUB_REPO"
fi
if [[ "$TICKET_CHOICE" == "3" || "$TICKET_CHOICE" == "4" ]]; then
    echo -e "  - Jira Project: $JIRA_PROJECT_KEY"
fi
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "  1. Test the ticketing system with a Security Hub finding"
echo -e "  2. Monitor CloudWatch logs for ticket creation"
echo -e "  3. Check your ticketing system for created tickets"
echo -e "  4. Customize ticket templates as needed"
echo ""
echo -e "${YELLOW}📋 Monitoring commands:${NC}"
echo -e "  # Monitor Lambda logs"
echo -e "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo -e ""
echo -e "  # Check DynamoDB tickets"
echo -e "  aws dynamodb scan --table-name $TICKET_TABLE_NAME"
echo -e ""
echo -e "  # Test ticket creation"
echo -e "  aws lambda invoke --function-name $FUNCTION_NAME --payload '{\"detail\":{\"findings\":[{\"Id\":\"test-finding\",\"Title\":\"Test Finding\",\"Description\":\"Test description\",\"Severity\":{\"Label\":\"HIGH\"}}]}}' response.json" 