#!/bin/bash

# Backup Account Security Hub Auto-Remediation Setup
# This script configures cross-account remediation from account 002616177731

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
        print_warning "AWS region not configured. Using us-west-2 as default."
        REGION="us-west-2"
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

# Function to create cross-account IAM policy for backup account
create_backup_account_policy() {
    print_status "Creating cross-account IAM policy for backup account"
    
    # Create policy document for cross-account access
    cat > backup-account-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:aws:iam::*:role/SecurityHubAutoRemediationRole"
            ],
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "SecurityHubAutoRemediation"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "organizations:ListAccounts",
                "organizations:DescribeOrganization"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "securityhub:GetFindings",
                "securityhub:UpdateFindings",
                "securityhub:BatchUpdateFindings"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    # Create the policy
    aws iam create-policy \
        --policy-name "SecurityHubCrossAccountRemediation" \
        --policy-document file://backup-account-policy.json \
        --description "Policy for cross-account Security Hub remediation from backup account" \
        2>/dev/null || print_warning "Policy may already exist"
    
    print_success "Backup account IAM policy created"
}

# Function to create EventBridge rule for organization-wide findings
create_organization_eventbridge_rule() {
    print_status "Creating organization-wide EventBridge rule..."
    
    # Create event pattern for organization-wide findings
    cat > organization-event-pattern.json << EOF
{
    "source": ["aws.securityhub"],
    "detail-type": ["Security Hub Findings - Imported"],
    "detail": {
        "findings": {
            "Severity": {
                "Label": ["HIGH", "CRITICAL"]
            }
        }
    }
}
EOF

    # Create the rule
    aws events put-rule \
        --name "OrganizationSecurityHubFindingsRule" \
        --event-pattern file://organization-event-pattern.json \
        --description "Organization-wide Security Hub findings for auto-remediation"
    
    # Add Lambda function as target
    aws events put-targets \
        --rule "OrganizationSecurityHubFindingsRule" \
        --targets "Id=1,Arn=arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:enhanced-auto-remediation-lambda-arm64"
    
    # Grant permission
    aws lambda add-permission \
        --function-name "enhanced-auto-remediation-lambda-arm64" \
        --statement-id "OrganizationEventBridgeInvoke" \
        --action "lambda:InvokeFunction" \
        --principal "events.amazonaws.com" \
        --source-arn "arn:aws:events:${REGION}:${ACCOUNT_ID}:rule/OrganizationSecurityHubFindingsRule"
    
    print_success "Organization-wide EventBridge rule created"
}

# Function to create SNS topic for notifications
create_sns_topic() {
    print_status "Creating SNS topic for notifications..."
    
    aws sns create-topic \
        --name "SecurityHubAutoRemediationAlerts" \
        2>/dev/null || print_warning "SNS topic may already exist"
    
    print_success "SNS topic created"
}

# Function to enable Security Hub in backup account
enable_security_hub_backup_account() {
    print_status "Enabling Security Hub in backup account..."
    
    aws securityhub enable-security-hub \
        --enable-default-standards \
        2>/dev/null || print_warning "Security Hub may already be enabled"
    
    print_success "Security Hub enabled in backup account"
}

# Function to create test finding
create_test_finding() {
    print_status "Creating test Security Hub finding"
    
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    aws securityhub batch-import-findings \
        --findings '[
            {
                "Id": "test-finding-backup-'$(date +%s)'",
                "ProductArn": "arn:aws:securityhub:'$REGION'::product/aws/securityhub",
                "GeneratorId": "test-generator",
                "AwsAccountId": "'$ACCOUNT_ID'",
                "Types": ["Software and Configuration Checks/AWS Security Best Practices"],
                "CreatedAt": "'$current_time'",
                "UpdatedAt": "'$current_time'",
                "Severity": {
                    "Label": "HIGH"
                },
                "Title": "Test Backup Account Finding",
                "Description": "This is a test finding for backup account validation"
            }
        ]' 2>/dev/null || print_warning "Test finding creation failed"
    
    print_success "Test Security Hub finding created"
}

# Function to verify setup
verify_setup() {
    print_status "Verifying setup..."
    
    # Check Lambda function
    if aws lambda get-function --function-name "enhanced-auto-remediation-lambda-arm64" &> /dev/null; then
        print_success "Lambda function verified"
    else
        print_error "Lambda function not found"
    fi
    
    # Check EventBridge rule
    if aws events describe-rule --name "OrganizationSecurityHubFindingsRule" &> /dev/null; then
        print_success "Organization EventBridge rule verified"
    else
        print_error "Organization EventBridge rule not found"
    fi
    
    # Check Security Hub
    if aws securityhub describe-hub &> /dev/null; then
        print_success "Security Hub is enabled"
    else
        print_error "Security Hub is not enabled"
    fi
    
    # Check SNS topic
    if aws sns list-topics --query "Topics[?contains(TopicArn, 'SecurityHubAutoRemediationAlerts')].TopicArn" --output text | grep -q .; then
        print_success "SNS topic verified"
    else
        print_error "SNS topic not found"
    fi
}

# Function to provide manual setup instructions
provide_manual_instructions() {
    echo ""
    echo "=========================================="
    echo "Manual Setup Instructions for Member Accounts"
    echo "=========================================="
    echo ""
    echo "Since the Lambda function runs in account $ACCOUNT_ID, you need to:"
    echo ""
    echo "1. Create cross-account roles in each member account:"
    echo "   For each member account, create a role with this trust policy:"
    echo ""
    cat > trust-policy-template.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${ACCOUNT_ID}:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "SecurityHubAutoRemediation"
                }
            }
        }
    ]
}
EOF
    cat trust-policy-template.json
    echo ""
    echo "2. Enable Security Hub in each member account"
    echo "3. Create SNS topics in each member account"
    echo ""
    echo "Member accounts in your organization:"
    aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`].[Id,Name]' --output table
    echo ""
    echo "You can use the following command to create roles in member accounts:"
    echo "aws iam create-role --role-name SecurityHubAutoRemediationRole --assume-role-policy-document file://trust-policy-template.json"
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo "Backup Account Security Hub Setup"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    check_aws_cli
    check_aws_credentials
    get_account_id
    get_region
    echo ""
    
    # Verify this is the backup account
    if [ "$ACCOUNT_ID" != "002616177731" ]; then
        print_warning "This script is designed to run in account 002616177731 (Backup Management)"
        print_warning "Current account: $ACCOUNT_ID"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check if Lambda function exists
    print_status "Checking Lambda function..."
    if ! check_lambda_function "enhanced-auto-remediation-lambda-arm64"; then
        print_error "Please deploy the Lambda function first using deploy.sh or deploy-arm64.sh"
        exit 1
    fi
    
    # Create cross-account IAM policy
    create_backup_account_policy
    echo ""
    
    # Enable Security Hub
    enable_security_hub_backup_account
    echo ""
    
    # Create organization-wide EventBridge rule
    create_organization_eventbridge_rule
    echo ""
    
    # Create SNS topic
    create_sns_topic
    echo ""
    
    # Verify setup
    verify_setup
    echo ""
    
    # Create test finding
    create_test_finding
    echo ""
    
    print_success "Backup account Security Hub setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Set up cross-account roles in member accounts (see instructions below)"
    echo "2. Enable Security Hub in member accounts"
    echo "3. Monitor CloudWatch logs for cross-account remediation"
    echo "4. Test with findings from member accounts"
    echo ""
    
    # Provide manual setup instructions
    provide_manual_instructions
    
    echo "To monitor logs:"
    echo "aws logs tail /aws/lambda/enhanced-auto-remediation-lambda-arm64 --follow"
    echo ""
    echo "To check findings:"
    echo "aws securityhub get-findings --filters '{\"SeverityLabel\":[{\"Value\":\"HIGH\",\"Comparison\":\"EQUALS\"}]}'"
}

# Run main function
main "$@" 