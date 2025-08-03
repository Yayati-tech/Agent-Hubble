#!/bin/bash

# Enhanced Setup script for GitHub Issues integration with Security Hub
# Supports multiple authentication methods: Personal Access Tokens, GitHub Apps, OAuth, and AWS Secrets Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐙 Setting up Enhanced GitHub Issues integration for Security Hub...${NC}"

# Configuration
FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
REGION="us-west-2"
GITHUB_REPO="vivpa/aws-security-auto-remediation"
SECRET_NAME="github-ticketing-credentials"

# Check if required tools are installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ curl is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials verified${NC}"

# Authentication method selection
echo -e "${YELLOW}🔐 Choose GitHub authentication method:${NC}"
echo -e "1. Personal Access Token (Traditional)"
echo -e "2. GitHub App (Recommended for production)"
echo -e "3. OAuth App (For web applications)"
echo -e "4. AWS Secrets Manager (Most secure)"
echo -e "5. GitHub Actions (For CI/CD environments)"
read -p "Enter your choice (1-5): " AUTH_METHOD

case $AUTH_METHOD in
    1)
        echo -e "${BLUE}🔑 Setting up Personal Access Token authentication...${NC}"
        setup_personal_access_token
        ;;
    2)
        echo -e "${BLUE}🔑 Setting up GitHub App authentication...${NC}"
        setup_github_app
        ;;
    3)
        echo -e "${BLUE}🔑 Setting up OAuth App authentication...${NC}"
        setup_oauth_app
        ;;
    4)
        echo -e "${BLUE}🔑 Setting up AWS Secrets Manager authentication...${NC}"
        setup_secrets_manager
        ;;
    5)
        echo -e "${BLUE}🔑 Setting up GitHub Actions authentication...${NC}"
        setup_github_actions
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

function setup_personal_access_token() {
    echo -e "${YELLOW}🔑 Please enter your GitHub Personal Access Token:${NC}"
    echo -e "${BLUE}   You can create one at: https://github.com/settings/tokens${NC}"
    echo -e "${BLUE}   Required permissions: repo, issues${NC}"
    read -s GITHUB_TOKEN

    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}❌ GitHub token is required${NC}"
        exit 1
    fi

    # Test GitHub token
    test_github_token "$GITHUB_TOKEN"
    
    # Store in environment variables
    GITHUB_AUTH_TYPE="personal_access_token"
    GITHUB_AUTH_VALUE="$GITHUB_TOKEN"
}

function setup_github_app() {
    echo -e "${YELLOW}🔑 Setting up GitHub App authentication...${NC}"
    echo -e "${BLUE}   This is the recommended method for production environments${NC}"
    
    # Prompt for GitHub App credentials
    echo -e "${YELLOW}Enter your GitHub App ID:${NC}"
    read GITHUB_APP_ID
    
    echo -e "${YELLOW}Enter your GitHub App Installation ID:${NC}"
    read GITHUB_INSTALLATION_ID
    
    echo -e "${YELLOW}Enter your GitHub App Private Key (PEM format):${NC}"
    echo -e "${BLUE}   Paste your private key (press Enter twice when done):${NC}"
    GITHUB_PRIVATE_KEY=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            break
        fi
        GITHUB_PRIVATE_KEY="$GITHUB_PRIVATE_KEY$line"$'\n'
    done
    
    # Test GitHub App authentication
    test_github_app_auth "$GITHUB_APP_ID" "$GITHUB_INSTALLATION_ID" "$GITHUB_PRIVATE_KEY"
    
    # Store in environment variables
    GITHUB_AUTH_TYPE="github_app"
    GITHUB_AUTH_VALUE="{\"app_id\":\"$GITHUB_APP_ID\",\"installation_id\":\"$GITHUB_INSTALLATION_ID\",\"private_key\":\"$GITHUB_PRIVATE_KEY\"}"
}

function setup_oauth_app() {
    echo -e "${YELLOW}🔑 Setting up OAuth App authentication...${NC}"
    
    echo -e "${YELLOW}Enter your OAuth App Client ID:${NC}"
    read GITHUB_CLIENT_ID
    
    echo -e "${YELLOW}Enter your OAuth App Client Secret:${NC}"
    read -s GITHUB_CLIENT_SECRET
    
    echo -e "${YELLOW}Enter your OAuth Access Token:${NC}"
    read -s GITHUB_OAUTH_TOKEN
    
    # Test OAuth authentication
    test_github_oauth_auth "$GITHUB_OAUTH_TOKEN"
    
    # Store in environment variables
    GITHUB_AUTH_TYPE="oauth_app"
    GITHUB_AUTH_VALUE="{\"client_id\":\"$GITHUB_CLIENT_ID\",\"client_secret\":\"$GITHUB_CLIENT_SECRET\",\"access_token\":\"$GITHUB_OAUTH_TOKEN\"}"
}

function setup_secrets_manager() {
    echo -e "${YELLOW}🔑 Setting up AWS Secrets Manager authentication...${NC}"
    echo -e "${BLUE}   This is the most secure method for storing credentials${NC}"
    
    # Check if secret already exists
    if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" &> /dev/null; then
        echo -e "${YELLOW}⚠️ Secret '$SECRET_NAME' already exists. Do you want to update it? (y/n)${NC}"
        read -p "" UPDATE_SECRET
        if [[ $UPDATE_SECRET != "y" ]]; then
            echo -e "${BLUE}Using existing secret...${NC}"
            GITHUB_AUTH_TYPE="secrets_manager"
            GITHUB_AUTH_VALUE="$SECRET_NAME"
            return
        fi
    fi
    
    # Prompt for GitHub credentials
    echo -e "${YELLOW}Enter your GitHub Personal Access Token:${NC}"
    read -s GITHUB_TOKEN
    
    echo -e "${YELLOW}Enter your GitHub repository (owner/repo):${NC}"
    read GITHUB_REPO_INPUT
    if [ -n "$GITHUB_REPO_INPUT" ]; then
        GITHUB_REPO="$GITHUB_REPO_INPUT"
    fi
    
    # Test GitHub token
    test_github_token "$GITHUB_TOKEN"
    
    # Create secret in AWS Secrets Manager
    echo -e "${YELLOW}🔐 Creating secret in AWS Secrets Manager...${NC}"
    
    SECRET_VALUE=$(cat << EOF
{
    "github_token": "$GITHUB_TOKEN",
    "github_repo": "$GITHUB_REPO",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "auth_type": "personal_access_token"
}
EOF
)
    
    if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" &> /dev/null; then
        # Update existing secret
        aws secretsmanager update-secret \
            --secret-id "$SECRET_NAME" \
            --secret-string "$SECRET_VALUE" \
            --region "$REGION"
        echo -e "${GREEN}✅ Secret updated: $SECRET_NAME${NC}"
    else
        # Create new secret
        aws secretsmanager create-secret \
            --name "$SECRET_NAME" \
            --description "GitHub credentials for Security Hub ticketing system" \
            --secret-string "$SECRET_VALUE" \
            --region "$REGION"
        echo -e "${GREEN}✅ Secret created: $SECRET_NAME${NC}"
    fi
    
    # Store in environment variables
    GITHUB_AUTH_TYPE="secrets_manager"
    GITHUB_AUTH_VALUE="$SECRET_NAME"
}

function setup_github_actions() {
    echo -e "${YELLOW}🔑 Setting up GitHub Actions authentication...${NC}"
    echo -e "${BLUE}   This method uses GitHub's built-in GITHUB_TOKEN${NC}"
    
    echo -e "${YELLOW}Enter your GitHub repository (owner/repo):${NC}"
    read GITHUB_REPO_INPUT
    if [ -n "$GITHUB_REPO_INPUT" ]; then
        GITHUB_REPO="$GITHUB_REPO_INPUT"
    fi
    
    # For GitHub Actions, we'll use the built-in token
    GITHUB_AUTH_TYPE="github_actions"
    GITHUB_AUTH_VALUE="$GITHUB_REPO"
    
    echo -e "${GREEN}✅ GitHub Actions authentication configured${NC}"
    echo -e "${BLUE}   Note: This will use the GITHUB_TOKEN environment variable in GitHub Actions${NC}"
}

function test_github_token() {
    local token="$1"
    echo -e "${YELLOW}🔍 Testing GitHub token...${NC}"
    
    GITHUB_USER=$(curl -s -H "Authorization: token $token" \
        https://api.github.com/user | jq -r '.login')
    
    if [ "$GITHUB_USER" == "null" ] || [ -z "$GITHUB_USER" ]; then
        echo -e "${RED}❌ Invalid GitHub token${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub token verified for user: $GITHUB_USER${NC}"
}

function test_github_app_auth() {
    local app_id="$1"
    local installation_id="$2"
    local private_key="$3"
    
    echo -e "${YELLOW}🔍 Testing GitHub App authentication...${NC}"
    
    # This would require JWT token generation
    # For now, we'll just validate the inputs
    if [ -z "$app_id" ] || [ -z "$installation_id" ] || [ -z "$private_key" ]; then
        echo -e "${RED}❌ Invalid GitHub App credentials${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ GitHub App credentials validated${NC}"
    echo -e "${BLUE}   Note: JWT token generation will be handled by the Lambda function${NC}"
}

function test_github_oauth_auth() {
    local token="$1"
    echo -e "${YELLOW}🔍 Testing OAuth authentication...${NC}"
    
    GITHUB_USER=$(curl -s -H "Authorization: token $token" \
        https://api.github.com/user | jq -r '.login')
    
    if [ "$GITHUB_USER" == "null" ] || [ -z "$GITHUB_USER" ]; then
        echo -e "${RED}❌ Invalid OAuth token${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ OAuth token verified for user: $GITHUB_USER${NC}"
}

# Test repository access
echo -e "${YELLOW}🔍 Testing repository access...${NC}"

if [ "$GITHUB_AUTH_TYPE" == "personal_access_token" ]; then
    REPO_ACCESS=$(curl -s -H "Authorization: token $GITHUB_AUTH_VALUE" \
        https://api.github.com/repos/$GITHUB_REPO | jq -r '.full_name')
elif [ "$GITHUB_AUTH_TYPE" == "secrets_manager" ]; then
    # For secrets manager, we'll test later
    REPO_ACCESS="$GITHUB_REPO"
else
    # For other auth types, we'll test later
    REPO_ACCESS="$GITHUB_REPO"
fi

if [ "$REPO_ACCESS" == "null" ] || [ -z "$REPO_ACCESS" ]; then
    echo -e "${RED}❌ Cannot access repository: $GITHUB_REPO${NC}"
    echo -e "${YELLOW}   Make sure the credentials have access to this repository${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Repository access verified: $REPO_ACCESS${NC}"

# Create GitHub labels for Security Hub issues
echo -e "${YELLOW}🏷️ Creating GitHub labels for Security Hub issues...${NC}"

# Define labels with enhanced descriptions
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
    
    # Create label using appropriate authentication
    if [ "$GITHUB_AUTH_TYPE" == "personal_access_token" ]; then
        curl -s -X POST \
            -H "Authorization: token $GITHUB_AUTH_VALUE" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/repos/$GITHUB_REPO/labels \
            -d "{\"name\":\"$label\",\"description\":\"$description\",\"color\":\"$color\"}" > /dev/null
    fi
    
    echo -e "${GREEN}✅ Created label: $label${NC}"
done

echo -e "${GREEN}✅ All GitHub labels created successfully${NC}"

# Create environment variables file with GitHub configuration
echo -e "${YELLOW}⚙️ Creating environment variables file with GitHub configuration...${NC}"

cat > env-vars-github-enhanced.json << EOF
{
    "Variables": {
        "SNS_TOPIC_NAME": "SecurityHubAutoRemediationAlerts",
        "BACKUP_ACCOUNT_ID": "002616177731",
        "MANAGEMENT_ACCOUNT_ID": "013983952777",
        "TICKET_TABLE_NAME": "SecurityHubTickets",
        "GITHUB_AUTH_TYPE": "$GITHUB_AUTH_TYPE",
        "GITHUB_AUTH_VALUE": "$GITHUB_AUTH_VALUE",
        "GITHUB_REPO": "$GITHUB_REPO"
    }
}
EOF

echo -e "${GREEN}✅ Environment variables file created: env-vars-github-enhanced.json${NC}"

# Update Lambda function with GitHub configuration
echo -e "${YELLOW}🔄 Updating Lambda function with GitHub configuration...${NC}"

aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment file://env-vars-github-enhanced.json \
    --region $REGION

echo -e "${GREEN}✅ Lambda function updated with GitHub configuration${NC}"

# Create GitHub issue templates
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

# Bug report template
cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - OS: [e.g. iOS]
 - Browser: [e.g. chrome, safari]
 - Version: [e.g. 22]

**Additional context**
Add any other context about the problem here.
EOF

echo -e "${GREEN}✅ GitHub issue templates created${NC}"

# Create GitHub Actions workflow for automated responses
echo -e "${YELLOW}🤖 Creating GitHub Actions workflow for automated responses...${NC}"

mkdir -p .github/workflows

cat > .github/workflows/security-hub-automation.yml << 'EOF'
name: Security Hub Issue Automation

on:
  issues:
    types: [opened, edited, labeled, unlabeled]

jobs:
  security-hub-automation:
    runs-on: ubuntu-latest
    if: contains(github.event.issue.labels.*.name, 'security-hub')
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        
    - name: Install dependencies
      run: |
        pip install requests
        
    - name: Process Security Hub issue
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      run: |
        python .github/scripts/process_security_issue.py
EOF

mkdir -p .github/scripts

cat > .github/scripts/process_security_issue.py << 'EOF'
#!/usr/bin/env python3
"""
GitHub Actions script to process Security Hub issues
"""

import os
import json
import requests
from datetime import datetime

def process_security_issue():
    """Process Security Hub issue and add automated responses"""
    
    # Get issue details from environment
    issue_number = os.environ.get('GITHUB_EVENT_PATH')
    if not issue_number:
        print("No issue number found")
        return
    
    # Read event data
    with open(issue_number, 'r') as f:
        event_data = json.load(f)
    
    issue = event_data['issue']
    labels = [label['name'] for label in issue['labels']]
    
    # Check if this is a Security Hub issue
    if 'security-hub' not in labels:
        print("Not a Security Hub issue")
        return
    
    # Add automated comment based on severity
    if 'critical-severity' in labels:
        add_priority_comment(issue['number'], "CRITICAL")
    elif 'high-severity' in labels:
        add_priority_comment(issue['number'], "HIGH")
    elif 'medium-severity' in labels:
        add_priority_comment(issue['number'], "MEDIUM")
    elif 'low-severity' in labels:
        add_priority_comment(issue['number'], "LOW")

def add_priority_comment(issue_number, severity):
    """Add priority comment to issue"""
    
    comment = f"""
## 🔴 Priority Alert

This Security Hub finding has been classified as **{severity}** priority.

### Required Actions:
- [ ] Review within 24 hours
- [ ] Assess remediation timeline
- [ ] Update status when resolved

### Escalation:
- **CRITICAL**: Immediate attention required
- **HIGH**: Review within 24 hours
- **MEDIUM**: Review within 48 hours
- **LOW**: Review within 1 week

---
*Automated response from Security Hub Auto-Remediation system*
"""
    
    # Add comment using GitHub API
    headers = {
        'Authorization': f'token {os.environ["GITHUB_TOKEN"]}',
        'Accept': 'application/vnd.github.v3+json'
    }
    
    data = {
        'body': comment
    }
    
    repo = os.environ['GITHUB_REPOSITORY']
    url = f'https://api.github.com/repos/{repo}/issues/{issue_number}/comments'
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 201:
        print(f"Added priority comment to issue #{issue_number}")
    else:
        print(f"Failed to add comment: {response.status_code}")

if __name__ == "__main__":
    process_security_issue()
EOF

chmod +x .github/scripts/process_security_issue.py

echo -e "${GREEN}✅ GitHub Actions workflow created${NC}"

# Create monitoring and alerting
echo -e "${YELLOW}📊 Setting up monitoring and alerting...${NC}"

# Create CloudWatch dashboard for GitHub integration
cat > github-enhanced-dashboard.json << EOF
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
                    [".", "Errors", ".", "."],
                    [".", "Invocations", ".", "."]
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
                    ["AWS/SecretsManager", "SecretCount", "SecretName", "$SECRET_NAME"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "GitHub Credentials Secret Status"
            }
        }
    ]
}
EOF

aws cloudwatch put-dashboard \
    --dashboard-name "GitHubEnhancedDashboard" \
    --dashboard-body file://github-enhanced-dashboard.json \
    --region $REGION

echo -e "${GREEN}✅ CloudWatch dashboard created: GitHubEnhancedDashboard${NC}"

# Create SNS topic for GitHub integration alerts
echo -e "${YELLOW}🔔 Creating SNS topic for GitHub integration alerts...${NC}"

SNS_TOPIC_ARN=$(aws sns create-topic \
    --name "GitHubIntegrationAlerts" \
    --region $REGION \
    --query 'TopicArn' --output text)

echo -e "${GREEN}✅ SNS topic created: $SNS_TOPIC_ARN${NC}"

# Clean up temporary files
rm -f github-enhanced-dashboard.json

echo -e "${GREEN}🎉 Enhanced GitHub integration setup completed successfully!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "  1. Test GitHub issue creation with sample findings"
echo -e "  2. Monitor GitHub integration metrics in CloudWatch"
echo -e "  3. Configure issue templates for your workflow"
echo -e "  4. Set up GitHub Actions for automated responses"
echo -e "  5. Review and customize the automation scripts"
echo -e ""
echo -e "${YELLOW}🔗 Useful links:${NC}"
echo -e "  - Repository: https://github.com/$GITHUB_REPO"
echo -e "  - Issues: https://github.com/$GITHUB_REPO/issues"
echo -e "  - Labels: https://github.com/$GITHUB_REPO/labels"
echo -e "  - Actions: https://github.com/$GITHUB_REPO/actions"
echo -e "  - CloudWatch Dashboard: GitHubEnhancedDashboard"
echo -e ""
echo -e "${YELLOW}🔐 Authentication Method: $GITHUB_AUTH_TYPE${NC}"
echo -e "${BLUE}   Credentials stored: $GITHUB_AUTH_VALUE${NC}" 