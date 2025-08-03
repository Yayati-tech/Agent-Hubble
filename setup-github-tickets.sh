#!/bin/bash

# Setup script for GitHub Issues integration with Security Hub
# This script configures GitHub integration for ticket creation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐙 Setting up GitHub Issues integration for Security Hub...${NC}"

# Configuration
FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
REGION="us-west-2"
GITHUB_REPO="vivpa/aws-security-auto-remediation"

# Check if required tools are installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials verified${NC}"

# Prompt for GitHub token
echo -e "${YELLOW}🔑 Please enter your GitHub Personal Access Token:${NC}"
echo -e "${BLUE}   You can create one at: https://github.com/settings/tokens${NC}"
echo -e "${BLUE}   Required permissions: repo, issues${NC}"
read -s GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ GitHub token is required${NC}"
    exit 1
fi

# Test GitHub token
echo -e "${YELLOW}🔍 Testing GitHub token...${NC}"

GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/user | grep -o '"login":"[^"]*"' | cut -d'"' -f4)

if [ -z "$GITHUB_USER" ]; then
    echo -e "${RED}❌ Invalid GitHub token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ GitHub token verified for user: $GITHUB_USER${NC}"

# Test repository access
echo -e "${YELLOW}🔍 Testing repository access...${NC}"

REPO_ACCESS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/$GITHUB_REPO | grep -o '"full_name":"[^"]*"' | cut -d'"' -f4)

if [ -z "$REPO_ACCESS" ]; then
    echo -e "${RED}❌ Cannot access repository: $GITHUB_REPO${NC}"
    echo -e "${YELLOW}   Make sure the token has access to this repository${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Repository access verified: $REPO_ACCESS${NC}"

# Create GitHub labels for Security Hub issues
echo -e "${YELLOW}🏷️ Creating GitHub labels for Security Hub issues...${NC}"

# Define labels
declare -A labels=(
    ["security-hub"]="Security Hub finding"
    ["auto-remediation"]="Auto-remediation enabled"
    ["IAM"]="IAM related issue"
    ["S3"]="S3 related issue"
    ["EC2"]="EC2 related issue"
    ["RDS"]="RDS related issue"
    ["Lambda"]="Lambda related issue"
    ["KMS"]="KMS related issue"
    ["GuardDuty"]="GuardDuty related issue"
    ["Inspector"]="Inspector related issue"
    ["SSM"]="SSM related issue"
    ["Macie"]="Macie related issue"
    ["WAF"]="WAF related issue"
    ["ACM"]="ACM related issue"
    ["SecretsManager"]="Secrets Manager related issue"
    ["CloudFormation"]="CloudFormation related issue"
    ["APIGateway"]="API Gateway related issue"
    ["ElastiCache"]="ElastiCache related issue"
    ["DynamoDB"]="DynamoDB related issue"
    ["EKS"]="EKS related issue"
    ["ECR"]="ECR related issue"
    ["ECS"]="ECS related issue"
    ["Redshift"]="Redshift related issue"
    ["SageMaker"]="SageMaker related issue"
    ["Glue"]="Glue related issue"
    ["high-severity"]="High severity finding"
    ["medium-severity"]="Medium severity finding"
    ["low-severity"]="Low severity finding"
    ["critical-severity"]="Critical severity finding"
)

# Create labels
for label in "${!labels[@]}"; do
    description="${labels[$label]}"
    
    # Determine color based on label type
    if [[ $label == *"severity"* ]]; then
        case $label in
            "critical-severity") color="d73a4a" ;;
            "high-severity") color="d93f0b" ;;
            "medium-severity") color="fbca04" ;;
            "low-severity") color="0e8a16" ;;
        esac
    elif [[ $label == "security-hub" ]]; then
        color="1d76db"
    elif [[ $label == "auto-remediation" ]]; then
        color="0e8a16"
    else
        color="0052cc"
    fi
    
    # Create label
    curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/$GITHUB_REPO/labels \
        -d "{\"name\":\"$label\",\"description\":\"$description\",\"color\":\"$color\"}" > /dev/null
    
    echo -e "${GREEN}✅ Created label: $label${NC}"
done

echo -e "${GREEN}✅ All GitHub labels created successfully${NC}"

# Create environment variables file with GitHub configuration
echo -e "${YELLOW}⚙️ Creating environment variables file with GitHub configuration...${NC}"

cat > env-vars-github-tickets.json << EOF
{
    "Variables": {
        "SNS_TOPIC_NAME": "SecurityHubAutoRemediationAlerts",
        "BACKUP_ACCOUNT_ID": "002616177731",
        "MANAGEMENT_ACCOUNT_ID": "013983952777",
        "TICKET_TABLE_NAME": "SecurityHubTickets",
        "GITHUB_TOKEN": "$GITHUB_TOKEN",
        "GITHUB_REPO": "$GITHUB_REPO"
    }
}
EOF

echo -e "${GREEN}✅ Environment variables file created: env-vars-github-tickets.json${NC}"

# Update Lambda function with GitHub configuration
echo -e "${YELLOW}🔄 Updating Lambda function with GitHub configuration...${NC}"

aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment file://env-vars-github-tickets.json \
    --region $REGION

echo -e "${GREEN}✅ Lambda function updated with GitHub configuration${NC}"

# Create GitHub webhook for issue updates (optional)
echo -e "${YELLOW}🔗 Setting up GitHub webhook for issue updates...${NC}"

# Create API Gateway for webhook
API_NAME="SecurityHubWebhook"
API_DESCRIPTION="API Gateway for GitHub webhook integration"

# Create API Gateway
API_ID=$(aws apigateway create-rest-api \
    --name $API_NAME \
    --description "$API_DESCRIPTION" \
    --region $REGION \
    --query 'id' --output text)

echo -e "${GREEN}✅ API Gateway created: $API_ID${NC}"

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $REGION \
    --query 'items[?path==`/`].id' --output text)

# Create webhook resource
WEBHOOK_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_ID \
    --path-part "webhook" \
    --region $REGION \
    --query 'id' --output text)

# Create POST method
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $WEBHOOK_ID \
    --http-method POST \
    --authorization-type NONE \
    --region $REGION

# Create Lambda integration
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $WEBHOOK_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:$(aws sts get-caller-identity --query Account --output text):function:$FUNCTION_NAME/invocations" \
    --region $REGION

# Deploy API
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region $REGION \
    --query 'id' --output text)

WEBHOOK_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/prod/webhook"

echo -e "${GREEN}✅ API Gateway webhook created: $WEBHOOK_URL${NC}"

# Create CloudWatch dashboard for GitHub integration metrics
echo -e "${YELLOW}📊 Creating CloudWatch dashboard for GitHub integration metrics...${NC}"

cat > github-integration-dashboard.json << EOF
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
                    ["AWS/Lambda", "Duration", "FunctionName", "$FUNCTION_NAME"],
                    [".", "Errors", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "GitHub Integration Lambda Performance"
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
                    ["AWS/ApiGateway", "Count", "ApiName", "$API_NAME"],
                    [".", "4XXError", ".", "."],
                    [".", "5XXError", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "GitHub Webhook API Performance"
            }
        }
    ]
}
EOF

aws cloudwatch put-dashboard \
    --dashboard-name "GitHubIntegrationDashboard" \
    --dashboard-body file://github-integration-dashboard.json \
    --region $REGION

echo -e "${GREEN}✅ CloudWatch dashboard created: GitHubIntegrationDashboard${NC}"

# Clean up temporary files
rm -f github-integration-dashboard.json

echo -e "${GREEN}🎉 GitHub integration setup completed successfully!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "  1. Test GitHub issue creation with sample findings"
echo -e "  2. Monitor GitHub integration metrics in CloudWatch"
echo -e "  3. Set up GitHub webhook for issue updates (optional)"
echo -e "  4. Configure issue templates for Security Hub findings"
echo -e "  5. Set up GitHub Actions for automated responses"
echo -e ""
echo -e "${YELLOW}🔗 Useful links:${NC}"
echo -e "  - Repository: https://github.com/$GITHUB_REPO"
echo -e "  - Issues: https://github.com/$GITHUB_REPO/issues"
echo -e "  - Labels: https://github.com/$GITHUB_REPO/labels"
echo -e "  - Webhook URL: $WEBHOOK_URL"