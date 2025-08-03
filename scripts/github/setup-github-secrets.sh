#!/bin/bash

# Setup GitHub Secrets for Lambda Deployment
# This script helps you set up the required GitHub secrets for the Lambda deployment workflow

set -e

echo "🔧 GitHub Secrets Setup Guide"
echo "============================"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: This script must be run from a git repository"
    echo "   Please run this script from your Agent-Hubble repository directory"
    exit 1
fi

# Get repository info
REPO_URL=$(git config --get remote.origin.url)
if [[ $REPO_URL == *"github.com"* ]]; then
    REPO_NAME=$(echo $REPO_URL | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\)\.git.*/\1/')
    echo "✅ Found GitHub repository: $REPO_NAME"
else
    echo "❌ Error: This doesn't appear to be a GitHub repository"
    echo "   Repository URL: $REPO_URL"
    exit 1
fi

echo ""
echo "📋 Required GitHub Secrets:"
echo "==========================="
echo ""
echo "1. AWS_ACCESS_KEY_ID"
echo "2. AWS_SECRET_ACCESS_KEY"
echo ""

echo "🔐 Step 1: Create AWS IAM User"
echo "==============================="
echo ""
echo "1. Go to AWS IAM Console: https://console.aws.amazon.com/iam/"
echo "2. Click 'Users' → 'Create user'"
echo "3. User name: github-actions-deployer"
echo "4. Select 'Programmatic access'"
echo "5. Click 'Next: Permissions'"
echo ""

echo "📝 Step 2: Attach IAM Policy"
echo "============================="
echo ""
echo "1. Click 'Attach policies directly'"
echo "2. Click 'Create policy'"
echo "3. Use JSON tab and paste this policy:"
echo ""

# Display the IAM policy
if [ -f "github-actions-iam-policy.json" ]; then
    echo "=== IAM Policy ==="
    cat github-actions-iam-policy.json
    echo "=================="
else
    echo "⚠️  IAM policy file not found. Please create the policy manually:"
    echo "   - lambda:UpdateFunctionCode"
    echo "   - lambda:UpdateFunctionConfiguration"
    echo "   - lambda:PublishLayerVersion"
    echo "   - cloudwatch:PutDashboard"
    echo "   - iam:PassRole"
fi

echo ""
echo "🔑 Step 3: Create Access Keys"
echo "============================="
echo ""
echo "1. After creating the user, go to 'Security credentials' tab"
echo "2. Click 'Create access key'"
echo "3. Select 'Command Line Interface (CLI)'"
echo "4. Check 'I understand the above recommendation'"
echo "5. Click 'Next' → 'Create access key'"
echo "6. Save the Access Key ID and Secret Access Key"
echo ""

echo "🔐 Step 4: Add GitHub Secrets"
echo "============================="
echo ""
echo "1. Go to your GitHub repository:"
echo "   https://github.com/$REPO_NAME"
echo ""
echo "2. Click 'Settings' tab"
echo "3. Click 'Secrets and variables' → 'Actions'"
echo "4. Click 'New repository secret'"
echo ""

echo "📝 Add these secrets:"
echo "===================="
echo ""
echo "Secret Name: AWS_ACCESS_KEY_ID"
echo "Secret Value: [Your Access Key ID from Step 3]"
echo ""
echo "Secret Name: AWS_SECRET_ACCESS_KEY"
echo "Secret Value: [Your Secret Access Key from Step 3]"
echo ""

echo "🧪 Step 5: Test the Setup"
echo "========================="
echo ""
echo "After adding the secrets:"
echo "1. Go to 'Actions' tab in your repository"
echo "2. Select 'Deploy Security Hub Lambda with Cryptography Layer'"
echo "3. Click 'Run workflow'"
echo "4. Select branch: main"
echo "5. Click 'Run workflow'"
echo ""

echo "📊 Step 6: Monitor Deployment"
echo "============================="
echo ""
echo "1. Watch the workflow run in the Actions tab"
echo "2. Check for any errors in the logs"
echo "3. Verify Lambda function is updated"
echo "4. Test with Security Hub findings"
echo ""

echo "🔗 Useful Links:"
echo "================"
echo ""
echo "📋 GitHub Repository: https://github.com/$REPO_NAME"
echo "🔧 GitHub Actions: https://github.com/$REPO_NAME/actions"
echo "🔐 GitHub Secrets: https://github.com/$REPO_NAME/settings/secrets/actions"
echo "☁️ AWS Lambda: https://console.aws.amazon.com/lambda/home?region=us-west-2#/functions/enhanced-auto-remediation-lambda-arm64"
echo "📊 CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=GitHubActionsDashboard"
echo ""

echo "🎯 Expected Results:"
echo "==================="
echo ""
echo "✅ Lambda function updated with cryptography layer"
echo "✅ GitHub issues created for Security Hub findings"
echo "✅ DynamoDB tickets created as fallback"
echo "✅ CloudWatch dashboard created"
echo "✅ No more cryptography compilation errors"
echo ""

echo "🚨 Troubleshooting:"
echo "=================="
echo ""
echo "If the workflow fails:"
echo "1. Check AWS credentials are correct"
echo "2. Verify IAM permissions are attached"
echo "3. Check the workflow logs for specific errors"
echo "4. Ensure the Lambda function exists"
echo ""

echo "🎉 Setup Complete!"
echo "================="
echo ""
echo "Next steps:"
echo "1. Add the GitHub secrets as shown above"
echo "2. Run the workflow manually or push changes"
echo "3. Monitor the deployment progress"
echo "4. Test with real Security Hub findings"
echo "" 