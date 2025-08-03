#!/bin/bash

# Setup GitHub Personal Access Token for Security Hub Ticketing
# This is a simpler alternative to GitHub App authentication

set -e

echo "🔧 Setting up GitHub Personal Access Token Authentication"
echo "========================================================"

# Check if GitHub token is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide your GitHub Personal Access Token"
    echo "Usage: $0 <your-github-token>"
    echo ""
    echo "To create a GitHub Personal Access Token:"
    echo "1. Go to https://github.com/settings/tokens"
    echo "2. Click 'Generate new token (classic)'"
    echo "3. Give it a name like 'Security Hub Ticketing'"
    echo "4. Select scopes: 'repo' (for private repos) or 'public_repo' (for public repos)"
    echo "5. Copy the token and run: $0 <your-token>"
    exit 1
fi

GITHUB_TOKEN="$1"
REPO="Yayati-tech/Agent-Hubble"

echo "🔐 Testing GitHub token authentication..."

# Test the token
curl -s -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/user" > /tmp/github_test.json

if grep -q '"login"' /tmp/github_test.json; then
    echo "✅ GitHub token authentication successful!"
    USERNAME=$(cat /tmp/github_test.json | grep '"login"' | cut -d'"' -f4)
    echo "   Authenticated as: $USERNAME"
else
    echo "❌ GitHub token authentication failed!"
    echo "   Response: $(cat /tmp/github_test.json)"
    exit 1
fi

echo "🔍 Testing repository access..."

# Test repository access
curl -s -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "https://api.github.com/repos/$REPO" > /tmp/repo_test.json

if grep -q '"name"' /tmp/repo_test.json; then
    echo "✅ Repository access confirmed!"
    REPO_NAME=$(cat /tmp/repo_test.json | grep '"name"' | cut -d'"' -f4)
    echo "   Repository: $REPO_NAME"
else
    echo "❌ Repository access failed!"
    echo "   Response: $(cat /tmp/repo_test.json)"
    exit 1
fi

echo "🏷️ Creating GitHub labels..."

# Create labels for Security Hub findings
LABELS=(
    'security-hub,FF6B6B,Security Hub finding'
    'aws-security,FF8E53,AWS Security issue'
    'vulnerability,FF4757,Security vulnerability'
    'misconfiguration,FFA502,Configuration issue'
    'critical-severity,FF0000,Critical severity'
    'high-severity,FF6B35,High severity'
    'medium-severity,FFA500,Medium severity'
    'low-severity,FFD700,Low severity'
    'IAM,FF6B9B,IAM related'
    'S3,4ECDC4,S3 related'
    'EC2,45B7D1,EC2 related'
    'auto-remediation,2ECC71,Auto-remediation enabled'
    'remediation-success,27AE60,Remediation successful'
    'remediation-failed,E74C3C,Remediation failed'
)

for label in "${LABELS[@]}"; do
    IFS=',' read -r name color description <<< "$label"
    
    curl -s -X POST \
         -H "Authorization: token $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github.v3+json" \
         -H "Content-Type: application/json" \
         -d "{\"name\":\"$name\",\"color\":\"$color\",\"description\":\"$description\"}" \
         "https://api.github.com/repos/$REPO/labels" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Created label: $name"
    else
        echo "   ⚠️ Label '$name' may already exist"
    fi
done

echo "📝 Creating issue template..."

# Create issue template directory
mkdir -p .github/ISSUE_TEMPLATE

# Create Security Hub finding template
cat > .github/ISSUE_TEMPLATE/security-hub-finding.md << 'TEMPLATE_EOF'
---
name: Security Hub Finding
about: Create a ticket for a Security Hub finding
title: "[Security Hub] "
labels: ["security-hub", "aws-security"]
assignees: ""
---

## Security Hub Finding Details

**Finding ID:** `{{FINDING_ID}}`
**Severity:** `{{SEVERITY}}`
**Service:** `{{SERVICE}}`
**Status:** Open

### Description
{{DESCRIPTION}}

### Resources Affected
{{RESOURCES}}

### Remediation Steps
- [ ] Review the finding details
- [ ] Assess the security impact
- [ ] Implement remediation if required
- [ ] Verify remediation effectiveness
- [ ] Update finding status

### Additional Information
- **Account:** {{ACCOUNT_ID}}
- **Region:** {{REGION}}
- **Product ARN:** {{PRODUCT_ARN}}
- **Created:** {{CREATED_AT}}

---
*This issue was automatically created by the Security Hub Auto-Remediation System*
TEMPLATE_EOF

echo "✅ Created issue template: .github/ISSUE_TEMPLATE/security-hub-finding.md"

echo "🔧 Creating environment variables file..."

# Create environment variables file
cat > env-vars-github-pat.json << EOF
{
    "Variables": {
        "SNS_TOPIC_NAME": "SecurityHubAutoRemediationAlerts",
        "BACKUP_ACCOUNT_ID": "002616177731",
        "MANAGEMENT_ACCOUNT_ID": "013983952777",
        "TICKET_TABLE_NAME": "SecurityHubTickets",
        "GITHUB_AUTH_TYPE": "personal_access_token",
        "GITHUB_TOKEN": "$GITHUB_TOKEN",
        "GITHUB_REPO": "$REPO"
    }
}
EOF

echo "✅ Created environment variables file: env-vars-github-pat.json"

echo "🔄 Creating Lambda update script..."

# Create Lambda update script
cat > update-lambda-github-pat.sh << 'SCRIPT_EOF'
#!/bin/bash

# Update Lambda function with GitHub PAT configuration
# Run this script after configuring AWS credentials

set -e

FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
REGION="us-west-2"

echo "🔄 Updating Lambda function with GitHub PAT configuration..."

aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment file://env-vars-github-pat.json \
    --region $REGION

echo "✅ Lambda function updated successfully!"

# Create CloudWatch dashboard
echo "📊 Creating CloudWatch dashboard..."

cat > github-pat-dashboard.json << 'DASHBOARD_EOF'
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
                "title": "GitHub PAT Integration Lambda Performance"
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
                    ["AWS/Lambda", "Throttles", "FunctionName", "$FUNCTION_NAME"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "Lambda Throttles"
            }
        }
    ]
}
DASHBOARD_EOF

aws cloudwatch put-dashboard \
    --dashboard-name "GitHubPATDashboard" \
    --dashboard-body file://github-pat-dashboard.json \
    --region $REGION

echo "✅ CloudWatch dashboard created: GitHubPATDashboard"

# Clean up
rm -f github-pat-dashboard.json

echo "🎉 AWS resources updated successfully!"
SCRIPT_EOF

chmod +x update-lambda-github-pat.sh

echo "✅ Created Lambda update script: update-lambda-github-pat.sh"

echo ""
echo "🎉 GitHub Personal Access Token Setup Complete!"
echo "=============================================="
echo ""
echo "📋 Summary:"
echo "   ✅ GitHub token authentication tested"
echo "   ✅ Repository access confirmed"
echo "   ✅ GitHub labels created"
echo "   ✅ Issue template created"
echo "   ✅ Environment variables file created"
echo "   ✅ Lambda update script created"
echo ""
echo "🚀 Next Steps:"
echo "   1. Run: ./update-lambda-github-pat.sh"
echo "   2. Test the integration with: aws lambda invoke --function-name enhanced-auto-remediation-lambda-arm64 --payload file://test-payload.json --cli-binary-format raw-in-base64-out response.json"
echo "   3. Check GitHub issues at: https://github.com/$REPO/issues"
echo ""
echo "🔗 Useful Links:"
echo "   - Repository: https://github.com/$REPO"
echo "   - Issues: https://github.com/$REPO/issues"
echo "   - Labels: https://github.com/$REPO/labels"
echo ""

# Clean up temporary files
rm -f /tmp/github_test.json /tmp/repo_test.json

echo "✨ Setup complete! Ready to create GitHub issues for Security Hub findings." 