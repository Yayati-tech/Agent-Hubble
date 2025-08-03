#!/bin/bash

# Update GitHub App Credentials
# This script helps update the Lambda function with new GitHub App details

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Update GitHub App Credentials${NC}"
echo -e "${BLUE}================================${NC}"

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials verified${NC}"

# Collect new GitHub App credentials
echo -e "${YELLOW}📋 Enter your new GitHub App credentials:${NC}"

read -p "GitHub App ID: " GITHUB_APP_ID
read -p "GitHub App Installation ID (numeric): " GITHUB_INSTALLATION_ID
read -p "GitHub repository (owner/repo): " GITHUB_REPO

echo -e "${YELLOW}📄 Enter your GitHub App Private Key (PEM format):${NC}"
echo -e "${BLUE}   Paste your private key (press Enter twice when done):${NC}"
GITHUB_PRIVATE_KEY=""
while IFS= read -r line; do
    if [ -z "$line" ]; then
        break
    fi
    GITHUB_PRIVATE_KEY="$GITHUB_PRIVATE_KEY$line"$'\n'
done

# Validate inputs
if [ -z "$GITHUB_APP_ID" ] || [ -z "$GITHUB_INSTALLATION_ID" ] || [ -z "$GITHUB_REPO" ] || [ -z "$GITHUB_PRIVATE_KEY" ]; then
    echo -e "${RED}❌ All fields are required${NC}"
    exit 1
fi

# Validate installation ID is numeric
if ! [[ "$GITHUB_INSTALLATION_ID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Installation ID must be numeric${NC}"
    exit 1
fi

echo -e "${GREEN}✅ GitHub App credentials captured${NC}"

# Create the auth value JSON
GITHUB_AUTH_VALUE=$(cat <<EOF
{"app_id":"$GITHUB_APP_ID","installation_id":"$GITHUB_INSTALLATION_ID","private_key":"$(echo "$GITHUB_PRIVATE_KEY" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' '\\n')"}
EOF
)

# Create environment variables file
cat > env-vars-github-app-new.json << EOF
{
    "Variables": {
        "SNS_TOPIC_NAME": "SecurityHubAutoRemediationAlerts",
        "BACKUP_ACCOUNT_ID": "002616177731",
        "MANAGEMENT_ACCOUNT_ID": "013983952777",
        "TICKET_TABLE_NAME": "SecurityHubTickets",
        "GITHUB_AUTH_TYPE": "github_app",
        "GITHUB_AUTH_VALUE": "$GITHUB_AUTH_VALUE",
        "GITHUB_REPO": "$GITHUB_REPO"
    }
}
EOF

echo -e "${YELLOW}🔧 Updating Lambda function configuration...${NC}"

# Update Lambda function configuration
aws lambda update-function-configuration \
    --function-name enhanced-auto-remediation-lambda-arm64 \
    --environment Variables="{
        SNS_TOPIC_NAME=SecurityHubAutoRemediationAlerts,
        BACKUP_ACCOUNT_ID=002616177731,
        MANAGEMENT_ACCOUNT_ID=013983952777,
        TICKET_TABLE_NAME=SecurityHubTickets,
        GITHUB_AUTH_TYPE=github_app,
        GITHUB_AUTH_VALUE='$GITHUB_AUTH_VALUE',
        GITHUB_REPO=$GITHUB_REPO
    }" \
    --region us-west-2

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Lambda function configuration updated successfully${NC}"
else
    echo -e "${RED}❌ Failed to update Lambda function configuration${NC}"
    exit 1
fi

echo -e "${YELLOW}⏳ Waiting for update to complete...${NC}"
sleep 10

# Test the updated configuration
echo -e "${YELLOW}🧪 Testing the updated configuration...${NC}"

# Create test payload
cat > test-github-app-update.json << EOF
{
    "detail": {
        "findings": [
            {
                "Id": "test-github-app-update",
                "Title": "Test GitHub App Update",
                "Description": "Testing the updated GitHub App configuration",
                "Severity": {
                    "Label": "HIGH"
                },
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
            }
        ]
    }
}
EOF

# Test the function
aws lambda invoke \
    --function-name enhanced-auto-remediation-lambda-arm64 \
    --payload file://test-github-app-update.json \
    --cli-binary-format raw-in-base64-out \
    response-github-app-update.json \
    --region us-west-2

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Lambda function test successful${NC}"
    
    # Check the response
    if [ -f response-github-app-update.json ]; then
        echo -e "${YELLOW}📄 Response:${NC}"
        cat response-github-app-update.json
        echo ""
    fi
else
    echo -e "${RED}❌ Lambda function test failed${NC}"
fi

# Clean up test files
rm -f test-github-app-update.json response-github-app-update.json

echo -e "${GREEN}🎉 GitHub App credentials updated successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "${BLUE}   App ID: $GITHUB_APP_ID${NC}"
echo -e "${BLUE}   Installation ID: $GITHUB_INSTALLATION_ID${NC}"
echo -e "${BLUE}   Repository: $GITHUB_REPO${NC}"
echo -e "${BLUE}   Function: enhanced-auto-remediation-lambda-arm64${NC}"
echo ""
echo -e "${YELLOW}🔗 Useful links:${NC}"
echo -e "${BLUE}   Repository: https://github.com/$GITHUB_REPO${NC}"
echo -e "${BLUE}   Issues: https://github.com/$GITHUB_REPO/issues${NC}"
echo -e "${BLUE}   CloudWatch Logs: /aws/lambda/enhanced-auto-remediation-lambda-arm64${NC}" 