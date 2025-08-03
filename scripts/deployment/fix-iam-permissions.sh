#!/bin/bash

# Fix IAM Permissions for GitHub Actions
# This script helps fix the IAM permissions issue for the github-actions-deployer user

set -e

echo "🔧 Fixing IAM Permissions for GitHub Actions"
echo "============================================"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: This script must be run from a git repository"
    exit 1
fi

echo "📋 Issue: IAM user lacks lambda:PublishLayerVersion permission"
echo ""

echo "🔐 Step 1: Update IAM Policy"
echo "============================="
echo ""
echo "1. Go to AWS IAM Console: https://console.aws.amazon.com/iam/"
echo "2. Click 'Policies' in the left sidebar"
echo "3. Search for the policy attached to 'github-actions-deployer' user"
echo "4. Click on the policy name"
echo "5. Click 'Edit policy'"
echo "6. Click 'JSON' tab"
echo "7. Replace the policy content with:"
echo ""

# Display the updated policy
if [ -f "github-actions-iam-policy.json" ]; then
    echo "=== Updated IAM Policy ==="
    cat github-actions-iam-policy.json
    echo "=========================="
else
    echo "⚠️  IAM policy file not found"
fi

echo ""
echo "🔑 Step 2: Alternative - Create New Policy"
echo "=========================================="
echo ""
echo "If you can't edit the existing policy, create a new one:"
echo ""
echo "1. Go to IAM Console → Policies → Create policy"
echo "2. Use JSON tab and paste the policy above"
echo "3. Name: 'GitHubActionsLambdaDeployment'"
echo "4. Description: 'Policy for GitHub Actions Lambda deployment'"
echo "5. Click 'Create policy'"
echo ""

echo "👤 Step 3: Attach Policy to User"
echo "================================"
echo ""
echo "1. Go to IAM Console → Users"
echo "2. Click on 'github-actions-deployer'"
echo "3. Click 'Add permissions'"
echo "4. Select 'Attach policies directly'"
echo "5. Search for and select your policy"
echo "6. Click 'Next: Review' → 'Add permissions'"
echo ""

echo "🧪 Step 4: Test the Fix"
echo "======================"
echo ""
echo "After updating the policy:"
echo "1. Go to GitHub Actions: https://github.com/Yayati-tech/Agent-Hubble/actions"
echo "2. Find the failed workflow run"
echo "3. Click 'Re-run jobs' or 'Re-run all jobs'"
echo "4. Monitor the workflow execution"
echo ""

echo "🔍 Step 5: Verify Permissions"
echo "============================"
echo ""
echo "To verify the user has proper permissions, you can test:"
echo ""
echo "aws lambda list-layers --region us-west-2"
echo "aws lambda list-layer-versions --layer-name cryptography-layer --region us-west-2"
echo ""

echo "🚨 Troubleshooting Tips:"
echo "======================="
echo ""
echo "If the issue persists:"
echo "1. Check that the policy is properly attached to the user"
echo "2. Verify the AWS credentials in GitHub secrets are correct"
echo "3. Ensure you're using the right AWS account (002616177731)"
echo "4. Check if there are any service control policies (SCPs) blocking the action"
echo ""

echo "📊 Expected Results:"
echo "==================="
echo ""
echo "✅ Lambda layer 'cryptography-layer' can be published"
echo "✅ Lambda function can be updated"
echo "✅ CloudWatch dashboard can be created"
echo "✅ GitHub Actions workflow completes successfully"
echo ""

echo "🎯 Next Steps:"
echo "=============="
echo ""
echo "1. Update the IAM policy as shown above"
echo "2. Re-run the GitHub Actions workflow"
echo "3. Monitor the deployment progress"
echo "4. Verify Lambda function and layer are updated"
echo "" 