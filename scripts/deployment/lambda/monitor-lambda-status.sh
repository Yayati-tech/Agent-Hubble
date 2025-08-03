#!/bin/bash

# Monitor Lambda Function Status
# This script helps monitor the Lambda function status during deployment

set -e

FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
REGION="us-west-2"
ACCOUNT_ID="002616177731"

echo "🔍 Monitoring Lambda Function Status"
echo "=================================="
echo ""
echo "Function: $FUNCTION_NAME"
echo "Region: $REGION"
echo "Account: $ACCOUNT_ID"
echo ""

# Function to check if AWS CLI is available
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed or not in PATH"
        echo "   Please install AWS CLI or configure your credentials"
        return 1
    fi
    return 0
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS credentials are not configured"
        echo "   Please run 'aws configure' or set up your credentials"
        return 1
    fi
    return 0
}

# Function to get Lambda function status
get_lambda_status() {
    echo "🔍 Checking Lambda function status..."
    
    # Try to get function details
    FUNCTION_INFO=$(aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Lambda function exists and is accessible"
        
        # Extract function state
        STATE=$(echo "$FUNCTION_INFO" | grep -o '"State": "[^"]*"' | cut -d'"' -f4)
        if [ -n "$STATE" ]; then
            echo "📊 Function State: $STATE"
        fi
        
        # Extract last update status
        LAST_UPDATE=$(echo "$FUNCTION_INFO" | grep -o '"LastUpdateStatus": "[^"]*"' | cut -d'"' -f4)
        if [ -n "$LAST_UPDATE" ]; then
            echo "🔄 Last Update Status: $LAST_UPDATE"
        fi
        
        # Extract runtime
        RUNTIME=$(echo "$FUNCTION_INFO" | grep -o '"Runtime": "[^"]*"' | cut -d'"' -f4)
        if [ -n "$RUNTIME" ]; then
            echo "⚙️  Runtime: $RUNTIME"
        fi
        
        # Check if function is active
        if [ "$STATE" = "Active" ] && [ "$LAST_UPDATE" = "Successful" ]; then
            echo "✅ Function is ready for updates"
            return 0
        elif [ "$LAST_UPDATE" = "InProgress" ]; then
            echo "⏳ Function update is in progress"
            return 1
        else
            echo "⚠️  Function may be in an intermediate state"
            return 1
        fi
    else
        echo "❌ Error accessing Lambda function:"
        echo "$FUNCTION_INFO"
        return 1
    fi
}

# Function to check Lambda layers
check_lambda_layers() {
    echo ""
    echo "🔍 Checking Lambda layers..."
    
    # List layers
    LAYERS=$(aws lambda list-layers --region "$REGION" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✅ Successfully listed Lambda layers"
        
        # Check for cryptography layer
        if echo "$LAYERS" | grep -q "cryptography-layer"; then
            echo "✅ cryptography-layer exists"
            
            # Get layer versions
            LAYER_VERSIONS=$(aws lambda list-layer-versions --layer-name "cryptography-layer" --region "$REGION" 2>/dev/null)
            if [ $? -eq 0 ]; then
                VERSION_COUNT=$(echo "$LAYER_VERSIONS" | grep -c '"Version"')
                echo "📊 cryptography-layer has $VERSION_COUNT version(s)"
            else
                echo "⚠️  Could not get layer versions"
            fi
        else
            echo "❌ cryptography-layer not found"
        fi
    else
        echo "❌ Could not list Lambda layers"
    fi
}

# Function to check CloudWatch logs
check_cloudwatch_logs() {
    echo ""
    echo "🔍 Checking CloudWatch logs..."
    
    LOG_GROUP="/aws/lambda/$FUNCTION_NAME"
    
    # Check if log group exists
    LOG_GROUPS=$(aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$REGION" 2>/dev/null)
    if [ $? -eq 0 ] && echo "$LOG_GROUPS" | grep -q "$LOG_GROUP"; then
        echo "✅ CloudWatch log group exists: $LOG_GROUP"
        
        # Get recent log streams
        RECENT_STREAMS=$(aws logs describe-log-streams --log-group-name "$LOG_GROUP" --order-by LastEventTime --descending --max-items 3 --region "$REGION" 2>/dev/null)
        if [ $? -eq 0 ]; then
            STREAM_COUNT=$(echo "$RECENT_STREAMS" | grep -c '"logStreamName"')
            echo "📊 Found $STREAM_COUNT recent log streams"
        fi
    else
        echo "⚠️  CloudWatch log group may not exist yet"
    fi
}

# Function to provide manual check instructions
manual_check_instructions() {
    echo ""
    echo "🔗 Manual Check Instructions"
    echo "=========================="
    echo ""
    echo "1. **AWS Lambda Console**:"
    echo "   https://console.aws.amazon.com/lambda/home?region=us-west-2#/functions/$FUNCTION_NAME"
    echo ""
    echo "2. **Check for these indicators**:"
    echo "   ✅ Function shows as 'Active'"
    echo "   ✅ No error messages in the console"
    echo "   ✅ Configuration tab shows updated settings"
    echo ""
    echo "3. **GitHub Actions**:"
    echo "   https://github.com/Yayati-tech/Agent-Hubble/actions"
    echo ""
    echo "4. **CloudWatch Logs**:"
    echo "   https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#logsV2:log-groups/log-group/$LOG_GROUP"
    echo ""
}

# Function to provide next steps
next_steps() {
    echo ""
    echo "🎯 Next Steps"
    echo "============="
    echo ""
    
    if get_lambda_status; then
        echo "✅ Lambda function is ready!"
        echo "🔄 You can now re-run the GitHub Actions workflow"
        echo ""
        echo "1. Go to GitHub Actions: https://github.com/Yayati-tech/Agent-Hubble/actions"
        echo "2. Find the failed workflow run"
        echo "3. Click 'Re-run jobs' or 'Re-run all jobs'"
        echo "4. Monitor the deployment progress"
    else
        echo "⏳ Lambda function is still updating"
        echo "🔄 Wait a few more minutes and check again"
        echo ""
        echo "Expected wait time: 5-10 more minutes"
        echo "Check again in 2-3 minutes"
    fi
}

# Main monitoring function
main() {
    echo "Starting Lambda function monitoring..."
    echo ""
    
    # Check prerequisites
    if ! check_aws_cli; then
        manual_check_instructions
        return 1
    fi
    
    if ! check_aws_credentials; then
        echo "⚠️  Using manual check instructions instead"
        manual_check_instructions
        return 1
    fi
    
    # Check Lambda function status
    get_lambda_status
    LAMBDA_READY=$?
    
    # Check Lambda layers
    check_lambda_layers
    
    # Check CloudWatch logs
    check_cloudwatch_logs
    
    # Provide manual instructions
    manual_check_instructions
    
    # Provide next steps
    next_steps
    
    echo ""
    echo "🔄 To monitor continuously, run this script again in 2-3 minutes"
    echo ""
}

# Run main function
main "$@" 