#!/bin/bash

# Security Hub Configuration Script
# This script configures Security Hub to trigger the enhanced auto-remediation Lambda function

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_success "AWS CLI is installed"
}

# Function to check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_success "AWS credentials are configured"
}

# Function to get AWS account ID
get_account_id() {
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "AWS Account ID: $ACCOUNT_ID"
}

# Function to get AWS region
get_region() {
    REGION=$(aws configure get region)
    if [ -z "$REGION" ]; then
        print_warning "AWS region not configured. Using us-east-1 as default."
        REGION="us-east-1"
    fi
    print_status "AWS Region: $REGION"
}

# Function to check if Lambda function exists
check_lambda_function() {
    local function_name="$1"
    if aws lambda get-function --function-name "$function_name" &> /dev/null; then
        print_success "Lambda function '$function_name' exists"
        return 0
    else
        print_error "Lambda function '$function_name' does not exist"
        return 1
    fi
}

# Function to check if SNS topic exists
check_sns_topic() {
    local topic_name="$1"
    if aws sns list-topics --query "Topics[?contains(TopicArn, '$topic_name')].TopicArn" --output text | grep -q .; then
        print_success "SNS topic '$topic_name' exists"
        return 0
    else
        print_warning "SNS topic '$topic_name' does not exist. Creating it..."
        aws sns create-topic --name "$topic_name"
        print_success "SNS topic '$topic_name' created"
    fi
}

# Function to create EventBridge rule
create_eventbridge_rule() {
    local rule_name="$1"
    local event_pattern="$2"
    
    print_status "Creating EventBridge rule: $rule_name"
    
    # Check if rule already exists
    if aws events describe-rule --name "$rule_name" &> /dev/null; then
        print_warning "EventBridge rule '$rule_name' already exists. Updating it..."
        aws events put-rule \
            --name "$rule_name" \
            --event-pattern "$event_pattern" \
            --description "Capture Security Hub findings for auto-remediation"
    else
        aws events put-rule \
            --name "$rule_name" \
            --event-pattern "$event_pattern" \
            --description "Capture Security Hub findings for auto-remediation"
    fi
    
    print_success "EventBridge rule '$rule_name' created/updated"
}

# Function to add Lambda target to EventBridge rule
add_lambda_target() {
    local rule_name="$1"
    local function_name="$2"
    local target_id="$3"
    
    print_status "Adding Lambda function as target to EventBridge rule"
    
    # Remove existing targets if any
    aws events remove-targets --rule "$rule_name" --ids "$target_id" 2>/dev/null || true
    
    # Add new target
    aws events put-targets \
        --rule "$rule_name" \
        --targets "Id=$target_id,Arn=arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$function_name"
    
    print_success "Lambda function added as target to EventBridge rule"
}

# Function to grant EventBridge permission to invoke Lambda
grant_lambda_permission() {
    local function_name="$1"
    local rule_name="$2"
    local statement_id="$3"
    
    print_status "Granting EventBridge permission to invoke Lambda function"
    
    # Remove existing permission if any
    aws lambda remove-permission --function-name "$function_name" --statement-id "$statement_id" 2>/dev/null || true
    
    # Add new permission
    aws lambda add-permission \
        --function-name "$function_name" \
        --statement-id "$statement_id" \
        --action "lambda:InvokeFunction" \
        --principal "events.amazonaws.com" \
        --source-arn "arn:aws:events:$REGION:$ACCOUNT_ID:rule/$rule_name"
    
    print_success "EventBridge permission granted to Lambda function"
}

# Function to create Security Hub custom action
create_security_hub_action() {
    local action_name="$1"
    local action_id="$2"
    
    print_status "Creating Security Hub custom action: $action_name"
    
    # Check if action already exists
    if aws securityhub describe-action-targets --action-target-arns "arn:aws:securityhub:$REGION:$ACCOUNT_ID:action/custom/$action_id" &> /dev/null; then
        print_warning "Security Hub custom action '$action_name' already exists"
    else
        aws securityhub create-action-target \
            --name "$action_name" \
            --description "Automatically remediate security findings" \
            --id "$action_id"
        print_success "Security Hub custom action '$action_name' created"
    fi
}

# Function to enable Security Hub standards
enable_security_hub_standards() {
    print_status "Enabling Security Hub standards"
    
    # Check if Security Hub is enabled
    if ! aws securityhub describe-hub &> /dev/null; then
        print_error "Security Hub is not enabled. Please enable it first in the AWS Console."
        exit 1
    fi
    
    # Enable AWS Foundational Security Best Practices
    aws securityhub batch-enable-standards \
        --standards-subscription-requests '[
            {
                "StandardsArn": "arn:aws:securityhub:'$REGION'::standards/aws-foundational-security-best-practices/v/1.0.0"
            }
        ]' 2>/dev/null || print_warning "Standards may already be enabled"
    
    print_success "Security Hub standards enabled"
}

# Function to create test finding
create_test_finding() {
    print_status "Creating test Security Hub finding"
    
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    aws securityhub batch-import-findings \
        --findings '[
            {
                "Id": "test-finding-'$(date +%s)'",
                "ProductArn": "arn:aws:securityhub:'$REGION'::product/aws/securityhub",
                "GeneratorId": "test-generator",
                "AwsAccountId": "'$ACCOUNT_ID'",
                "Types": ["Software and Configuration Checks/AWS Security Best Practices"],
                "CreatedAt": "'$current_time'",
                "UpdatedAt": "'$current_time'",
                "Severity": {
                    "Label": "HIGH"
                },
                "Title": "Test Security Finding",
                "Description": "This is a test finding for validation of the auto-remediation setup",
                "Remediation": {
                    "Recommendation": {
                        "Text": "Test remediation recommendation"
                    }
                }
            }
        ]' 2>/dev/null || print_warning "Test finding creation failed (may already exist)"
    
    print_success "Test Security Hub finding created"
}

# Function to verify configuration
verify_configuration() {
    print_status "Verifying configuration..."
    
    # Check EventBridge rule
    if aws events describe-rule --name "SecurityHubFindingsRule" &> /dev/null; then
        print_success "EventBridge rule exists"
    else
        print_error "EventBridge rule not found"
    fi
    
    # Check Lambda function
    if aws lambda get-function --function-name "enhanced-auto-remediation-lambda" &> /dev/null; then
        print_success "Lambda function exists"
    else
        print_error "Lambda function not found"
    fi
    
    # Check SNS topic
    if aws sns list-topics --query "Topics[?contains(TopicArn, 'SecurityHubAutoRemediationAlerts')].TopicArn" --output text | grep -q .; then
        print_success "SNS topic exists"
    else
        print_error "SNS topic not found"
    fi
    
    # Check Security Hub
    if aws securityhub describe-hub &> /dev/null; then
        print_success "Security Hub is enabled"
    else
        print_error "Security Hub is not enabled"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "Security Hub Auto-Remediation Setup"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    check_aws_cli
    check_aws_credentials
    get_account_id
    get_region
    echo ""
    
    # Configuration variables
    LAMBDA_FUNCTION_NAME="enhanced-auto-remediation-lambda"
    SNS_TOPIC_NAME="SecurityHubAutoRemediationAlerts"
    EVENTBRIDGE_RULE_NAME="SecurityHubFindingsRule"
    TARGET_ID="1"
    STATEMENT_ID="EventBridgeInvoke"
    ACTION_NAME="AutoRemediation"
    ACTION_ID="AutoRemediationAction"
    
    # Event pattern for Security Hub findings
    EVENT_PATTERN='{
        "source": ["aws.securityhub"],
        "detail-type": ["Security Hub Findings - Imported"],
        "detail": {
            "findings": {
                "Severity": {
                    "Label": ["HIGH", "CRITICAL"]
                }
            }
        }
    }'
    
    # Check if Lambda function exists
    print_status "Checking Lambda function..."
    if ! check_lambda_function "$LAMBDA_FUNCTION_NAME"; then
        print_error "Please deploy the Lambda function first using deploy.sh or deploy-arm64.sh"
        exit 1
    fi
    
    # Check SNS topic
    print_status "Checking SNS topic..."
    check_sns_topic "$SNS_TOPIC_NAME"
    echo ""
    
    # Create EventBridge rule
    print_status "Setting up EventBridge rule..."
    create_eventbridge_rule "$EVENTBRIDGE_RULE_NAME" "$EVENT_PATTERN"
    echo ""
    
    # Add Lambda target
    print_status "Adding Lambda function as target..."
    add_lambda_target "$EVENTBRIDGE_RULE_NAME" "$LAMBDA_FUNCTION_NAME" "$TARGET_ID"
    echo ""
    
    # Grant Lambda permission
    print_status "Granting EventBridge permission to invoke Lambda..."
    grant_lambda_permission "$LAMBDA_FUNCTION_NAME" "$EVENTBRIDGE_RULE_NAME" "$STATEMENT_ID"
    echo ""
    
    # Create Security Hub custom action (optional)
    print_status "Setting up Security Hub custom action..."
    create_security_hub_action "$ACTION_NAME" "$ACTION_ID"
    echo ""
    
    # Enable Security Hub standards
    print_status "Enabling Security Hub standards..."
    enable_security_hub_standards
    echo ""
    
    # Verify configuration
    print_status "Verifying configuration..."
    verify_configuration
    echo ""
    
    # Create test finding
    print_status "Creating test finding..."
    create_test_finding
    echo ""
    
    print_success "Security Hub configuration completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Monitor CloudWatch logs for Lambda function execution"
    echo "2. Check SNS notifications for remediation status"
    echo "3. Verify Security Hub findings are being processed"
    echo "4. Set up CloudWatch alarms for monitoring"
    echo ""
    echo "To monitor logs:"
    echo "aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow"
    echo ""
    echo "To check SNS notifications:"
    echo "aws sns list-subscriptions"
    echo ""
    echo "To list Security Hub findings:"
    echo "aws securityhub get-findings --filters '{\"SeverityLabel\":[{\"Value\":\"HIGH\",\"Comparison\":\"EQUALS\"}]}'"
}

# Run main function
main "$@" 