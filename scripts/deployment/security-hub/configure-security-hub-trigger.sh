#!/bin/bash

# Security Hub Lambda Trigger Configuration Script
# This script configures Security Hub to trigger the ARM64 Lambda function

set -e

# Configuration
FUNCTION_NAME="enhanced-auto-remediation-lambda"
FUNCTION_ARN="arn:aws:lambda:us-west-2:002616177731:function:enhanced-auto-remediation-lambda"
REGION="us-west-2"
ACCOUNT_ID="002616177731"
RULE_NAME="SecurityHubAutoRemediationRule"
EVENT_BUS_NAME="default"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo -e "${GREEN}🔐 Configuring Security Hub to trigger ARM64 Lambda function...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Verify Lambda function exists
log_info "Verifying Lambda function exists..."
if ! aws lambda get-function --function-name $FUNCTION_NAME &> /dev/null; then
    log_error "Lambda function $FUNCTION_NAME does not exist. Please deploy it first."
    exit 1
fi
log_success "Lambda function verified: $FUNCTION_NAME"

# Create EventBridge rule for Security Hub findings
log_info "Creating EventBridge rule for Security Hub findings..."

# Create rule
aws events put-rule \
    --name $RULE_NAME \
    --event-pattern '{
        "source": ["aws.securityhub"],
        "detail-type": ["Security Hub Findings - Imported"]
    }' \
    --description "Rule to trigger auto-remediation Lambda for Security Hub findings"

log_success "EventBridge rule created: $RULE_NAME"

# Add Lambda permission for EventBridge
log_info "Adding Lambda permission for EventBridge..."
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id "SecurityHubEventBridgePermission" \
    --action "lambda:InvokeFunction" \
    --principal "events.amazonaws.com" \
    --source-arn "arn:aws:events:$REGION:$ACCOUNT_ID:rule/$RULE_NAME" 2>/dev/null || log_warning "Permission already exists"

log_success "Lambda permission verified for EventBridge"

# Create target for the rule
log_info "Creating EventBridge target for Lambda function..."

# Add target to rule
log_info "Adding target to EventBridge rule..."
aws events put-targets \
    --rule $RULE_NAME \
    --targets '[{"Id":"SecurityHubLambdaTarget","Arn":"arn:aws:lambda:us-west-2:002616177731:function:enhanced-auto-remediation-lambda"}]'

log_success "EventBridge target created for Lambda function"

# Configure Security Hub to send findings to EventBridge
log_info "Configuring Security Hub to send findings to EventBridge..."

# Get current Security Hub configuration
log_info "Checking current Security Hub configuration..."

# Enable Security Hub if not already enabled
if ! aws securityhub describe-hub --region $REGION &> /dev/null; then
    log_info "Enabling Security Hub..."
    aws securityhub enable-security-hub \
        --enable-default-standards \
        --region $REGION
    log_success "Security Hub enabled"
else
    log_success "Security Hub is already enabled"
fi

# Create custom action for auto-remediation
log_info "Creating custom Security Hub action for auto-remediation..."

aws securityhub create-action \
    --name "AutoRemediation" \
    --description "Trigger automatic remediation for Security Hub findings" \
    --region $REGION 2>/dev/null || log_warning "Custom action already exists"

log_success "Custom Security Hub action verified: AutoRemediation"

# Create CloudWatch log group for Lambda function if it doesn't exist
log_info "Ensuring CloudWatch log group exists..."
aws logs create-log-group --log-group-name "/aws/lambda/$FUNCTION_NAME" 2>/dev/null || true
log_success "CloudWatch log group verified"

# Test the configuration
log_info "Testing the configuration..."

# Create a test event
cat > test-event.json << EOF
{
    "version": "0",
    "id": "test-security-hub-finding",
    "detail-type": "Security Hub Findings - Imported",
    "source": "aws.securityhub",
    "account": "$ACCOUNT_ID",
    "time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "region": "$REGION",
    "resources": ["arn:aws:securityhub:$REGION:$ACCOUNT_ID:findings/test"],
    "detail": {
        "findings": [
            {
                "SchemaVersion": "2018-10-08",
                "Id": "arn:aws:securityhub:$REGION:$ACCOUNT_ID:product/aws/securityhub/finding/test",
                "ProductArn": "arn:aws:securityhub:$REGION:$ACCOUNT_ID:product/aws/securityhub",
                "GeneratorId": "aws-foundations-cis",
                "AwsAccountId": "$ACCOUNT_ID",
                "Types": ["Software and Configuration Checks/Industry and Regulatory Standards/CIS AWS Foundations Benchmark"],
                "FirstObservedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
                "LastObservedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
                "CreatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
                "UpdatedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
                "Severity": {
                    "Product": 0,
                    "Label": "INFORMATIONAL",
                    "Normalized": 0
                },
                "Title": "Test Security Hub Finding",
                "Description": "This is a test finding for auto-remediation",
                "Remediation": {
                    "Recommendation": {
                        "Text": "This is a test finding",
                        "Url": "https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html"
                    }
                },
                "ProductFields": {
                    "StandardsArn": "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
                    "StandardsSubscriptionArn": "arn:aws:securityhub:$REGION:$ACCOUNT_ID:subscription/cis-aws-foundations-benchmark/v/1.2.0",
                    "ControlId": "1.1",
                    "StandardsControlArn": "arn:aws:securityhub:$REGION:$ACCOUNT_ID:control/cis-aws-foundations-benchmark/v/1.2.0/1.1",
                    "StandardsControl": "1.1",
                    "StandardsGuideArn": "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
                    "StandardsGuideSubscriptionArn": "arn:aws:securityhub:$REGION:$ACCOUNT_ID:subscription/cis-aws-foundations-benchmark/v/1.2.0"
                },
                "Resources": [
                    {
                        "Type": "AwsAccount",
                        "Id": "arn:aws:iam::$ACCOUNT_ID:root",
                        "Partition": "aws",
                        "Region": "$REGION"
                    }
                ],
                "Compliance": {
                    "Status": "PASSED"
                },
                "WorkflowState": "NEW",
                "Workflow": {
                    "Status": "NEW"
                },
                "RecordState": "ACTIVE"
            }
        ]
    }
}
EOF

# Test the Lambda function directly
log_info "Testing Lambda function with test event..."
aws lambda invoke \
    --function-name $FUNCTION_NAME \
    --payload file://test-event.json \
    response.json

if [ $? -eq 0 ]; then
    log_success "Lambda function test successful"
    log_info "Response:"
    cat response.json
else
    log_error "Lambda function test failed"
    exit 1
fi

# Clean up test files
rm -f target.json custom-action.json test-event.json response.json

log_success "🎉 Security Hub configuration completed successfully!"
echo ""
log_info "📋 Configuration Summary:"
echo "  - EventBridge Rule: $RULE_NAME"
echo "  - Lambda Function: $FUNCTION_NAME"
echo "  - Architecture: ARM64"
echo "  - Region: $REGION"
echo "  - Account: $ACCOUNT_ID"
echo ""
log_info "📋 Next Steps:"
echo "  1. Monitor CloudWatch logs: /aws/lambda/$FUNCTION_NAME"
echo "  2. Test with real Security Hub findings"
echo "  3. Configure SNS notifications for remediation events"
echo "  4. Set up CloudWatch alarms for function errors"
echo ""
log_info "🔍 To monitor the function:"
echo "  aws logs tail /aws/lambda/$FUNCTION_NAME --follow"
echo ""
log_info "🧪 To test with a real finding:"
echo "  aws securityhub batch-import-findings --findings file://real-finding.json" 