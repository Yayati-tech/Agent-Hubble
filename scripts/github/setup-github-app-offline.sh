#!/bin/bash

# GitHub App Setup Script for Security Hub Ticketing (Offline Version)
# This script guides you through setting up GitHub App authentication without AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 GitHub App Setup for Security Hub Ticketing (Offline)${NC}"
echo -e "${BLUE}========================================================${NC}"

# Check if required tools are installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites verified${NC}"

echo -e "${YELLOW}📋 GitHub App Setup Instructions:${NC}"
echo -e "${BLUE}1. Go to: https://github.com/settings/apps${NC}"
echo -e "${BLUE}2. Click 'New GitHub App'${NC}"
echo -e "${BLUE}3. Configure with:${NC}"
echo -e "${BLUE}   - App name: Security Hub Ticketing${NC}"
echo -e "${BLUE}   - Homepage URL: https://your-domain.com${NC}"
echo -e "${BLUE}   - Repository permissions: Contents (Read & write), Issues (Read & write), Metadata (Read-only)${NC}"
echo -e "${BLUE}4. Click 'Create GitHub App'${NC}"
echo -e "${BLUE}5. Install the app in your repository${NC}"
echo -e "${BLUE}6. Note the App ID, Installation ID, and download the Private Key${NC}"
echo ""

# Prompt for GitHub App credentials
echo -e "${YELLOW}🔑 Enter your GitHub App credentials:${NC}"

read -p "GitHub App ID: " GITHUB_APP_ID
read -p "GitHub App Installation ID: " GITHUB_INSTALLATION_ID
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

echo -e "${GREEN}✅ GitHub App credentials captured${NC}"

# Test GitHub App authentication
echo -e "${YELLOW}🔍 Testing GitHub App authentication...${NC}"

# Create temporary Python script to test JWT generation
cat > test_github_app_auth.py << 'EOF'
#!/usr/bin/env python3
import json
import time
import jwt
import requests
import os

def test_github_app_auth():
    try:
        # Get credentials from environment
        app_id = os.environ.get('GITHUB_APP_ID')
        installation_id = os.environ.get('GITHUB_INSTALLATION_ID')
        private_key = os.environ.get('GITHUB_PRIVATE_KEY')
        
        if not all([app_id, installation_id, private_key]):
            print("❌ Missing required environment variables")
            return False
        
        # Generate JWT token
        now = int(time.time())
        payload = {
            'iat': now,
            'exp': now + (10 * 60),  # 10 minutes
            'iss': app_id
        }
        
        jwt_token = jwt.encode(payload, private_key, algorithm='RS256')
        
        # Get installation access token
        headers = {
            'Authorization': f'Bearer {jwt_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'
        response = requests.post(url, headers=headers)
        
        if response.status_code == 201:
            token_data = response.json()
            access_token = token_data['token']
            
            # Test API access
            headers = {
                'Authorization': f'token {access_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            user_response = requests.get('https://api.github.com/user', headers=headers)
            if user_response.status_code == 200:
                user_data = user_response.json()
                print(f"✅ GitHub App authentication successful")
                print(f"   App ID: {app_id}")
                print(f"   Installation ID: {installation_id}")
                print(f"   Authenticated as: {user_data.get('login', 'Unknown')}")
                return True
            else:
                print(f"❌ API access failed: {user_response.status_code}")
                return False
        else:
            print(f"❌ Failed to get installation token: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ GitHub App authentication failed: {str(e)}")
        return False

if __name__ == "__main__":
    test_github_app_auth()
EOF

# Set environment variables for testing
export GITHUB_APP_ID="$GITHUB_APP_ID"
export GITHUB_INSTALLATION_ID="$GITHUB_INSTALLATION_ID"
export GITHUB_PRIVATE_KEY="$GITHUB_PRIVATE_KEY"

# Test authentication
python3 test_github_app_auth.py

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ GitHub App authentication verified${NC}"
else
    echo -e "${RED}❌ GitHub App authentication failed${NC}"
    echo -e "${YELLOW}   Please check your credentials and try again${NC}"
    rm -f test_github_app_auth.py
    exit 1
fi

# Clean up test file
rm -f test_github_app_auth.py

# Create environment variables file
echo -e "${YELLOW}⚙️ Creating environment variables file...${NC}"

cat > env-vars-github-app.json << EOF
{
    "Variables": {
        "SNS_TOPIC_NAME": "SecurityHubAutoRemediationAlerts",
        "BACKUP_ACCOUNT_ID": "002616177731",
        "MANAGEMENT_ACCOUNT_ID": "013983952777",
        "TICKET_TABLE_NAME": "SecurityHubTickets",
        "GITHUB_AUTH_TYPE": "github_app",
        "GITHUB_AUTH_VALUE": "{\"app_id\":\"$GITHUB_APP_ID\",\"installation_id\":\"$GITHUB_INSTALLATION_ID\",\"private_key\":\"$GITHUB_PRIVATE_KEY\"}",
        "GITHUB_REPO": "$GITHUB_REPO"
    }
}
EOF

echo -e "${GREEN}✅ Environment variables file created: env-vars-github-app.json${NC}"

# Create GitHub labels
echo -e "${YELLOW}🏷️ Creating GitHub labels...${NC}"

# Generate access token for API calls
cat > create_access_token.py << 'EOF'
#!/usr/bin/env python3
import json
import time
import jwt
import requests
import os

def create_access_token():
    app_id = os.environ.get('GITHUB_APP_ID')
    installation_id = os.environ.get('GITHUB_INSTALLATION_ID')
    private_key = os.environ.get('GITHUB_PRIVATE_KEY')
    
    # Generate JWT token
    now = int(time.time())
    payload = {
        'iat': now,
        'exp': now + (10 * 60),
        'iss': app_id
    }
    
    jwt_token = jwt.encode(payload, private_key, algorithm='RS256')
    
    # Get installation access token
    headers = {
        'Authorization': f'Bearer {jwt_token}',
        'Accept': 'application/vnd.github.v3+json'
    }
    
    url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'
    response = requests.post(url, headers=headers)
    
    if response.status_code == 201:
        token_data = response.json()
        return token_data['token']
    else:
        raise Exception(f"Failed to get installation token: {response.status_code}")

if __name__ == "__main__":
    try:
        token = create_access_token()
        print(token)
    except Exception as e:
        print(f"Error: {str(e)}")
        exit(1)
EOF

# Get access token
ACCESS_TOKEN=$(python3 create_access_token.py)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Access token generated successfully${NC}"
    
    # Create labels
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
        ["remediation-success"]="Remediation completed successfully"
        ["remediation-failed"]="Remediation failed"
        ["aws-security"]="AWS Security finding"
        ["compliance"]="Compliance related issue"
        ["vulnerability"]="Security vulnerability"
        ["misconfiguration"]="Security misconfiguration"
    )
    
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
        elif [[ $label == *"remediation"* ]]; then
            case $label in
                "remediation-success") color="0e8a16" ;;
                "remediation-failed") color="d73a4a" ;;
            esac
        elif [[ $label == "security-hub" ]]; then
            color="1d76db"
        elif [[ $label == "auto-remediation" ]]; then
            color="0e8a16"
        elif [[ $label == "aws-security" ]]; then
            color="d73a4a"
        elif [[ $label == "compliance" ]]; then
            color="fbca04"
        elif [[ $label == "vulnerability" ]]; then
            color="d73a4a"
        elif [[ $label == "misconfiguration" ]]; then
            color="d93f0b"
        else
            color="0052cc"
        fi
        
        # Create label
        curl -s -X POST \
            -H "Authorization: token $ACCESS_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/repos/$GITHUB_REPO/labels \
            -d "{\"name\":\"$label\",\"description\":\"$description\",\"color\":\"$color\"}" > /dev/null
        
        echo -e "${GREEN}✅ Created label: $label${NC}"
    done
    
    echo -e "${GREEN}✅ All GitHub labels created successfully${NC}"
else
    echo -e "${RED}❌ Failed to generate access token${NC}"
fi

# Clean up temporary files
rm -f create_access_token.py

# Create issue templates
echo -e "${YELLOW}📝 Creating GitHub issue templates...${NC}"

mkdir -p .github/ISSUE_TEMPLATE

# Security Hub finding template
cat > .github/ISSUE_TEMPLATE/security-hub-finding.md << 'EOF'
---
name: Security Hub Finding
about: Auto-generated issue for Security Hub finding
title: "[Security Hub] "
labels: ["security-hub", "auto-remediation"]
assignees: []
---

## Security Hub Finding Details

**Finding ID:** `{{ finding_id }}`
**Severity:** `{{ severity }}`
**Service:** `{{ service }}`
**Status:** `{{ status }}`

### Description
{{ description }}

### Remediation Status
- [ ] **Created** - Finding received
- [ ] **In Progress** - Remediation started
- [ ] **Success** - Remediation completed
- [ ] **Failed** - Remediation failed

### Additional Information
- **Account:** `{{ account_id }}`
- **Region:** `{{ region }}`
- **Created:** `{{ created_at }}`
- **Updated:** `{{ updated_at }}`

### Remediation Details
{{ remediation_details }}

---
*This issue was automatically created by the Security Hub Auto-Remediation system.*
EOF

echo -e "${GREEN}✅ GitHub issue templates created${NC}"

# Create AWS update script
echo -e "${YELLOW}📝 Creating AWS update script...${NC}"

cat > update-lambda-github-app.sh << EOF
#!/bin/bash

# Update Lambda function with GitHub App configuration
# Run this script after configuring AWS credentials

set -e

FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
REGION="us-west-2"

echo "🔄 Updating Lambda function with GitHub App configuration..."

aws lambda update-function-configuration \\
    --function-name \$FUNCTION_NAME \\
    --environment file://env-vars-github-app.json \\
    --region \$REGION

echo "✅ Lambda function updated successfully!"

# Create CloudWatch dashboard
echo "📊 Creating CloudWatch dashboard..."

cat > github-app-dashboard.json << 'DASHBOARD_EOF'
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
                    ["AWS/Lambda", "Duration", "FunctionName", "\$FUNCTION_NAME"],
                    [".", "Errors", ".", "."],
                    [".", "Invocations", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "\$REGION",
                "title": "GitHub App Integration Lambda Performance"
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
                    ["AWS/Lambda", "Throttles", "FunctionName", "\$FUNCTION_NAME"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "\$REGION",
                "title": "Lambda Throttles"
            }
        }
    ]
}
DASHBOARD_EOF

aws cloudwatch put-dashboard \\
    --dashboard-name "GitHubAppDashboard" \\
    --dashboard-body file://github-app-dashboard.json \\
    --region \$REGION

echo "✅ CloudWatch dashboard created: GitHubAppDashboard"

# Clean up
rm -f github-app-dashboard.json

echo "🎉 AWS resources updated successfully!"
EOF

chmod +x update-lambda-github-app.sh

echo -e "${GREEN}✅ AWS update script created: update-lambda-github-app.sh${NC}"

echo -e "${GREEN}🎉 GitHub App setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "  1. Configure AWS credentials: aws configure"
echo -e "  2. Run the AWS update script: ./update-lambda-github-app.sh"
echo -e "  3. Test GitHub issue creation with sample findings"
echo -e "  4. Monitor GitHub integration metrics in CloudWatch"
echo -e "  5. Configure issue templates for your workflow"
echo ""
echo -e "${YELLOW}🔗 Useful links:${NC}"
echo -e "  - Repository: https://github.com/$GITHUB_REPO"
echo -e "  - Issues: https://github.com/$GITHUB_REPO/issues"
echo -e "  - Labels: https://github.com/$GITHUB_REPO/labels"
echo -e "  - Actions: https://github.com/$GITHUB_REPO/actions"
echo ""
echo -e "${YELLOW}🔐 Authentication Method: GitHub App${NC}"
echo -e "${BLUE}   App ID: $GITHUB_APP_ID${NC}"
echo -e "${BLUE}   Installation ID: $GITHUB_INSTALLATION_ID${NC}"
echo -e "${BLUE}   Repository: $GITHUB_REPO${NC}"
echo ""
echo -e "${YELLOW}📁 Generated files:${NC}"
echo -e "  - env-vars-github-app.json (Lambda environment variables)"
echo -e "  - update-lambda-github-app.sh (AWS update script)"
echo -e "  - .github/ISSUE_TEMPLATE/security-hub-finding.md (Issue template)" 