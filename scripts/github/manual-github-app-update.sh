#!/bin/bash

# Manual GitHub App Credentials Update
# This script helps you update the Lambda function with new GitHub App details

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Manual GitHub App Credentials Update${NC}"
echo -e "${BLUE}=======================================${NC}"

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

echo -e "${GREEN}✅ Environment variables file created: env-vars-github-app-new.json${NC}"

echo -e "${YELLOW}🔧 AWS CLI Command to Update Lambda:${NC}"
echo ""
echo -e "${BLUE}Run this command with your AWS credentials:${NC}"
echo ""
echo -e "${GREEN}aws lambda update-function-configuration \\${NC}"
echo -e "${GREEN}  --function-name enhanced-auto-remediation-lambda-arm64 \\${NC}"
echo -e "${GREEN}  --environment Variables='{${NC}"
echo -e "${GREEN}    SNS_TOPIC_NAME=SecurityHubAutoRemediationAlerts,${NC}"
echo -e "${GREEN}    BACKUP_ACCOUNT_ID=002616177731,${NC}"
echo -e "${GREEN}    MANAGEMENT_ACCOUNT_ID=013983952777,${NC}"
echo -e "${GREEN}    TICKET_TABLE_NAME=SecurityHubTickets,${NC}"
echo -e "${GREEN}    GITHUB_AUTH_TYPE=github_app,${NC}"
echo -e "${GREEN}    GITHUB_AUTH_VALUE=\"$GITHUB_AUTH_VALUE\",${NC}"
echo -e "${GREEN}    GITHUB_REPO=$GITHUB_REPO${NC}"
echo -e "${GREEN}  }' \\${NC}"
echo -e "${GREEN}  --region us-west-2${NC}"
echo ""

echo -e "${YELLOW}🧪 Test Command:${NC}"
echo ""
echo -e "${BLUE}After updating, test with:${NC}"
echo ""
echo -e "${GREEN}aws lambda invoke \\${NC}"
echo -e "${GREEN}  --function-name enhanced-auto-remediation-lambda-arm64 \\${NC}"
echo -e "${GREEN}  --payload file://test-crypto-fix.json \\${NC}"
echo -e "${GREEN}  response-test.json \\${NC}"
echo -e "${GREEN}  --region us-west-2${NC}"
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
echo ""
echo -e "${GREEN}✅ Manual update script completed!${NC}" 