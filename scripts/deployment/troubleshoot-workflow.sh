#!/bin/bash

# Troubleshoot GitHub Actions Workflow Failure
# This script helps identify and fix workflow issues

set -e

echo "🔍 Troubleshooting GitHub Actions Workflow Failure"
echo "================================================"
echo ""

echo "📋 Common Issues and Solutions:"
echo "=============================="
echo ""

echo "1. **Environment Variables File Issue**"
echo "====================================="
echo ""
echo "The workflow uses 'env-vars-github-app-corrected.json' for Lambda configuration."
echo "Check if this file exists and has valid JSON format."
echo ""

if [ -f "env-vars-github-app-corrected.json" ]; then
    echo "✅ env-vars-github-app-corrected.json exists"
    
    # Validate JSON format
    if python3 -m json.tool env-vars-github-app-corrected.json > /dev/null 2>&1; then
        echo "✅ JSON format is valid"
    else
        echo "❌ JSON format is invalid"
        echo "   Please check the file format"
    fi
else
    echo "❌ env-vars-github-app-corrected.json is missing"
    echo "   This file is required for Lambda configuration"
fi

echo ""
echo "2. **Lambda Function Status Check**"
echo "================================="
echo ""
echo "Let's verify the Lambda function is ready for updates:"
echo ""

# Check if we have AWS credentials
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials are available"
    
    # Check Lambda function status
    FUNCTION_STATUS=$(aws lambda get-function --function-name enhanced-auto-remediation-lambda-arm64 --region us-west-2 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Lambda function is accessible"
        
        # Extract state and update status
        STATE=$(echo "$FUNCTION_STATUS" | grep -o '"State": "[^"]*"' | cut -d'"' -f4)
        LAST_UPDATE=$(echo "$FUNCTION_STATUS" | grep -o '"LastUpdateStatus": "[^"]*"' | cut -d'"' -f4)
        
        echo "📊 Function State: $STATE"
        echo "📊 Last Update Status: $LAST_UPDATE"
        
        if [ "$STATE" = "Active" ] && [ "$LAST_UPDATE" = "Successful" ]; then
            echo "✅ Lambda function is ready for updates"
        else
            echo "⚠️  Lambda function may not be ready for updates"
            echo "   State: $STATE, Last Update: $LAST_UPDATE"
        fi
    else
        echo "❌ Error accessing Lambda function:"
        echo "$FUNCTION_STATUS"
    fi
else
    echo "⚠️  AWS credentials not available for testing"
fi

echo ""
echo "3. **GitHub Secrets Check**"
echo "=========================="
echo ""
echo "Verify these secrets are set in GitHub:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo "Go to: https://github.com/Yayati-tech/Agent-Hubble/settings/secrets/actions"
echo ""

echo "4. **Workflow File Check**"
echo "========================="
echo ""

if [ -f ".github/workflows/deploy-lambda.yml" ]; then
    echo "✅ Workflow file exists"
    
    # Check for common issues in workflow file
    if grep -q "env-vars-github-app-corrected.json" .github/workflows/deploy-lambda.yml; then
        echo "✅ Environment variables file reference found"
    else
        echo "❌ Environment variables file reference missing"
    fi
    
    if grep -q "LAYER_ARN" .github/workflows/deploy-lambda.yml; then
        echo "✅ Layer ARN variable reference found"
    else
        echo "❌ Layer ARN variable reference missing"
    fi
else
    echo "❌ Workflow file missing"
fi

echo ""
echo "5. **Common Failure Points**"
echo "==========================="
echo ""
echo "🔍 Check these specific steps in the workflow:"
echo ""
echo "a) **Build Lambda Layer with Cryptography**"
echo "   - Issue: cryptography compilation on Linux"
echo "   - Solution: Should work in GitHub Actions Ubuntu environment"
echo ""
echo "b) **Publish Lambda Layer**"
echo "   - Issue: IAM permissions for lambda:PublishLayerVersion"
echo "   - Solution: ✅ Already fixed"
echo ""
echo "c) **Update Lambda Function Code**"
echo "   - Issue: ResourceConflictException"
echo "   - Solution: ✅ Already resolved"
echo ""
echo "d) **Update Lambda Function Configuration**"
echo "   - Issue: Invalid environment variables format"
echo "   - Solution: Check env-vars-github-app-corrected.json"
echo ""
echo "e) **Test Lambda Function**"
echo "   - Issue: Function timeout or error"
echo "   - Solution: Check Lambda logs"
echo ""

echo "6. **Debugging Steps**"
echo "====================="
echo ""
echo "1. **Check GitHub Actions Logs**:"
echo "   - Go to: https://github.com/Yayati-tech/Agent-Hubble/actions"
echo "   - Click on the failed workflow run"
echo "   - Look for specific error messages"
echo ""
echo "2. **Check Lambda Logs**:"
echo "   - Go to: https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fenhanced-auto-remediation-lambda-arm64"
echo "   - Look for recent error logs"
echo ""
echo "3. **Test Lambda Function Manually**:"
echo "   - Use AWS CLI to test the function"
echo "   - Check for runtime errors"
echo ""

echo "7. **Quick Fixes**"
echo "================="
echo ""
echo "If the workflow is failing on a specific step:"
echo ""
echo "a) **Environment Variables Issue**:"
echo "   - Check JSON format in env-vars-github-app-corrected.json"
echo "   - Ensure all required variables are present"
echo ""
echo "b) **Lambda Function Not Ready**:"
echo "   - Wait for function to be in 'Active' state"
echo "   - Ensure LastUpdateStatus is 'Successful'"
echo ""
echo "c) **Test Step Failure**:"
echo "   - Check Lambda function logs for errors"
echo "   - Verify function has proper permissions"
echo ""

echo "8. **Re-run Strategy**"
echo "====================="
echo ""
echo "1. **Fix any identified issues above**"
echo "2. **Go to GitHub Actions**: https://github.com/Yayati-tech/Agent-Hubble/actions"
echo "3. **Find the failed workflow run**"
echo "4. **Click 'Re-run jobs'** or **'Re-run all jobs'**"
echo "5. **Monitor the execution step by step**"
echo ""

echo "🎯 Next Steps:"
echo "=============="
echo ""
echo "1. Check the specific error message in GitHub Actions logs"
echo "2. Apply the appropriate fix based on the error"
echo "3. Re-run the workflow"
echo "4. Monitor the execution progress"
echo ""

echo "🔗 Useful Links:"
echo "================"
echo ""
echo "📋 GitHub Actions: https://github.com/Yayati-tech/Agent-Hubble/actions"
echo "🔐 GitHub Secrets: https://github.com/Yayati-tech/Agent-Hubble/settings/secrets/actions"
echo "☁️ AWS Lambda: https://console.aws.amazon.com/lambda/home?region=us-west-2#/functions/enhanced-auto-remediation-lambda-arm64"
echo "📊 CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fenhanced-auto-remediation-lambda-arm64"
echo "" 