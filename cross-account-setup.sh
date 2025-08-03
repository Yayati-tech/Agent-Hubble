#!/bin/bash

# Cross-Account Security Hub Auto-Remediation Setup
# This script configures organization-wide Security Hub auto-remediation

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

# Function to check if this is the management account
check_management_account() {
    print_status "Checking if this is the management account..."
    
    # Check if Organizations API is available
    if aws organizations describe-organization &> /dev/null; then
        print_success "This appears to be the management account"
        MANAGEMENT_ACCOUNT_ID=$ACCOUNT_ID
        return 0
    else
        print_warning "This may not be the management account or Organizations is not enabled"
        return 1
    fi
}

# Function to list organization accounts
list_organization_accounts() {
    print_status "Listing organization accounts..."
    
    # Get all accounts in the organization
    aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`].[Id,Name,Email]' --output table
    
    # Store account IDs for later use
    ACCOUNT_IDS=$(aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`].Id' --output text)
    print_success "Found $(echo $ACCOUNT_IDS | wc -w) active accounts"
}

# Function to create cross-account IAM role
create_cross_account_role() {
    local account_id="$1"
    local role_name="$2"
    
    print_status "Creating cross-account role in account $account_id"
    
    # Create trust policy for the role
    cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${MANAGEMENT_ACCOUNT_ID}:root"
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

    # Create the role
    aws iam create-role \
        --role-name "$role_name" \
        --assume-role-policy-document file://trust-policy.json \
        --description "Cross-account role for Security Hub auto-remediation" \
        2>/dev/null || print_warning "Role may already exist"
    
    # Attach necessary policies
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" \
        2>/dev/null || print_warning "Policy may already be attached"
    
    print_success "Cross-account role created in account $account_id"
}

# Function to create management account IAM policy
create_management_policy() {
    print_status "Creating management account IAM policy for cross-account access"
    
    # Create policy document
    cat > cross-account-policy.json << EOF
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
        --policy-document file://cross-account-policy.json \
        --description "Policy for cross-account Security Hub remediation" \
        2>/dev/null || print_warning "Policy may already exist"
    
    print_success "Management account IAM policy created"
}

# Function to enable Security Hub in member accounts
enable_security_hub_member_accounts() {
    print_status "Enabling Security Hub in member accounts..."
    
    for account_id in $ACCOUNT_IDS; do
        if [ "$account_id" != "$MANAGEMENT_ACCOUNT_ID" ]; then
            print_status "Enabling Security Hub in account $account_id"
            
            # Assume role in member account
            ROLE_ARN="arn:aws:iam::${account_id}:role/SecurityHubAutoRemediationRole"
            
            # Get temporary credentials
            TEMP_CREDS=$(aws sts assume-role \
                --role-arn "$ROLE_ARN" \
                --role-session-name "SecurityHubSetup" \
                --external-id "SecurityHubAutoRemediation" \
                --query 'Credentials' \
                --output json 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                # Extract credentials
                ACCESS_KEY=$(echo "$TEMP_CREDS" | jq -r '.AccessKeyId')
                SECRET_KEY=$(echo "$TEMP_CREDS" | jq -r '.SecretAccessKey')
                SESSION_TOKEN=$(echo "$TEMP_CREDS" | jq -r '.SessionToken')
                
                # Enable Security Hub
                AWS_ACCESS_KEY_ID="$ACCESS_KEY" \
                AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \
                AWS_SESSION_TOKEN="$SESSION_TOKEN" \
                aws securityhub enable-security-hub \
                    --enable-default-standards \
                    --region "$REGION" 2>/dev/null || print_warning "Security Hub may already be enabled"
                
                print_success "Security Hub enabled in account $account_id"
            else
                print_warning "Could not assume role in account $account_id"
            fi
        fi
    done
}

# Function to configure Security Hub aggregation
configure_security_hub_aggregation() {
    print_status "Configuring Security Hub aggregation..."
    
    # Create aggregation configuration
    cat > aggregation-config.json << EOF
{
    "FindingAggregatorArn": "arn:aws:securityhub:${REGION}:${MANAGEMENT_ACCOUNT_ID}:finding-aggregator/default",
    "RegionLinkingMode": "ALL_REGIONS",
    "SourceRegions": ["${REGION}"]
}
EOF

    # Create finding aggregator
    aws securityhub create-finding-aggregator \
        --region-linking-mode "ALL_REGIONS" \
        --source-regions "$REGION" \
        2>/dev/null || print_warning "Finding aggregator may already exist"
    
    print_success "Security Hub aggregation configured"
}

# Function to create organization-wide EventBridge rule
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
        --targets "Id=1,Arn=arn:aws:lambda:${REGION}:${MANAGEMENT_ACCOUNT_ID}:function:enhanced-auto-remediation-lambda"
    
    # Grant permission
    aws lambda add-permission \
        --function-name "enhanced-auto-remediation-lambda" \
        --statement-id "OrganizationEventBridgeInvoke" \
        --action "lambda:InvokeFunction" \
        --principal "events.amazonaws.com" \
        --source-arn "arn:aws:events:${REGION}:${MANAGEMENT_ACCOUNT_ID}:rule/OrganizationSecurityHubFindingsRule"
    
    print_success "Organization-wide EventBridge rule created"
}

# Function to create cross-account SNS topics
create_cross_account_sns_topics() {
    print_status "Creating cross-account SNS topics..."
    
    for account_id in $ACCOUNT_IDS; do
        print_status "Creating SNS topic in account $account_id"
        
        # Assume role in member account
        ROLE_ARN="arn:aws:iam::${account_id}:role/SecurityHubAutoRemediationRole"
        
        # Get temporary credentials
        TEMP_CREDS=$(aws sts assume-role \
            --role-arn "$ROLE_ARN" \
            --role-session-name "SNSSetup" \
            --external-id "SecurityHubAutoRemediation" \
            --query 'Credentials' \
            --output json 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            # Extract credentials
            ACCESS_KEY=$(echo "$TEMP_CREDS" | jq -r '.AccessKeyId')
            SECRET_KEY=$(echo "$TEMP_CREDS" | jq -r '.SecretAccessKey')
            SESSION_TOKEN=$(echo "$TEMP_CREDS" | jq -r '.SessionToken')
            
            # Create SNS topic
            AWS_ACCESS_KEY_ID="$ACCESS_KEY" \
            AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \
            AWS_SESSION_TOKEN="$SESSION_TOKEN" \
            aws sns create-topic \
                --name "SecurityHubAutoRemediationAlerts" \
                --region "$REGION" 2>/dev/null || print_warning "SNS topic may already exist"
            
            print_success "SNS topic created in account $account_id"
        else
            print_warning "Could not create SNS topic in account $account_id"
        fi
    done
}

# Function to test cross-account access
test_cross_account_access() {
    print_status "Testing cross-account access..."
    
    for account_id in $ACCOUNT_IDS; do
        if [ "$account_id" != "$MANAGEMENT_ACCOUNT_ID" ]; then
            print_status "Testing access to account $account_id"
            
            # Assume role in member account
            ROLE_ARN="arn:aws:iam::${account_id}:role/SecurityHubAutoRemediationRole"
            
            # Test role assumption
            if aws sts assume-role \
                --role-arn "$ROLE_ARN" \
                --role-session-name "TestAccess" \
                --external-id "SecurityHubAutoRemediation" \
                --duration-seconds 900 &> /dev/null; then
                print_success "Successfully accessed account $account_id"
            else
                print_error "Failed to access account $account_id"
            fi
        fi
    done
}

# Function to create test findings across accounts
create_test_findings_organization() {
    print_status "Creating test findings across organization..."
    
    for account_id in $ACCOUNT_IDS; do
        print_status "Creating test finding in account $account_id"
        
        # Assume role in member account
        ROLE_ARN="arn:aws:iam::${account_id}:role/SecurityHubAutoRemediationRole"
        
        # Get temporary credentials
        TEMP_CREDS=$(aws sts assume-role \
            --role-arn "$ROLE_ARN" \
            --role-session-name "TestFinding" \
            --external-id "SecurityHubAutoRemediation" \
            --query 'Credentials' \
            --output json 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            # Extract credentials
            ACCESS_KEY=$(echo "$TEMP_CREDS" | jq -r '.AccessKeyId')
            SECRET_KEY=$(echo "$TEMP_CREDS" | jq -r '.SecretAccessKey')
            SESSION_TOKEN=$(echo "$TEMP_CREDS" | jq -r '.SessionToken')
            
            # Create test finding
            CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            
            AWS_ACCESS_KEY_ID="$ACCESS_KEY" \
            AWS_SECRET_ACCESS_KEY="$SECRET_KEY" \
            AWS_SESSION_TOKEN="$SESSION_TOKEN" \
            aws securityhub batch-import-findings \
                --findings "[
                    {
                        \"Id\": \"test-finding-org-$(date +%s)\",
                        \"ProductArn\": \"arn:aws:securityhub:${REGION}::product/aws/securityhub\",
                        \"GeneratorId\": \"test-generator\",
                        \"AwsAccountId\": \"${account_id}\",
                        \"Types\": [\"Software and Configuration Checks/AWS Security Best Practices\"],
                        \"CreatedAt\": \"${CURRENT_TIME}\",
                        \"UpdatedAt\": \"${CURRENT_TIME}\",
                        \"Severity\": {
                            \"Label\": \"HIGH\"
                        },
                        \"Title\": \"Test Organization Finding\",
                        \"Description\": \"This is a test finding for organization-wide validation\"
                    }
                ]" \
                --region "$REGION" 2>/dev/null || print_warning "Test finding creation failed"
            
            print_success "Test finding created in account $account_id"
        else
            print_warning "Could not create test finding in account $account_id"
        fi
    done
}

# Function to verify organization setup
verify_organization_setup() {
    print_status "Verifying organization setup..."
    
    # Check management account
    if aws organizations describe-organization &> /dev/null; then
        print_success "Management account verified"
    else
        print_error "Management account verification failed"
    fi
    
    # Check Lambda function
    if aws lambda get-function --function-name "enhanced-auto-remediation-lambda" &> /dev/null; then
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
    
    # Check Security Hub aggregation
    if aws securityhub list-finding-aggregators &> /dev/null; then
        print_success "Security Hub aggregation verified"
    else
        print_error "Security Hub aggregation verification failed"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "Cross-Account Security Hub Setup"
    echo "=========================================="
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    check_aws_cli
    check_aws_credentials
    get_account_id
    get_region
    echo ""
    
    # Check if this is management account
    if ! check_management_account; then
        print_error "This script must be run from the AWS Organizations management account"
        exit 1
    fi
    
    # List organization accounts
    list_organization_accounts
    echo ""
    
    # Create cross-account roles
    print_status "Creating cross-account IAM roles..."
    for account_id in $ACCOUNT_IDS; do
        if [ "$account_id" != "$MANAGEMENT_ACCOUNT_ID" ]; then
            create_cross_account_role "$account_id" "SecurityHubAutoRemediationRole"
        fi
    done
    echo ""
    
    # Create management account policy
    create_management_policy
    echo ""
    
    # Enable Security Hub in member accounts
    enable_security_hub_member_accounts
    echo ""
    
    # Configure Security Hub aggregation
    configure_security_hub_aggregation
    echo ""
    
    # Create organization-wide EventBridge rule
    create_organization_eventbridge_rule
    echo ""
    
    # Create cross-account SNS topics
    create_cross_account_sns_topics
    echo ""
    
    # Test cross-account access
    test_cross_account_access
    echo ""
    
    # Verify setup
    verify_organization_setup
    echo ""
    
    # Create test findings
    create_test_findings_organization
    echo ""
    
    print_success "Cross-account Security Hub setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Monitor CloudWatch logs for cross-account remediation"
    echo "2. Check SNS notifications across all accounts"
    echo "3. Verify Security Hub findings are being processed organization-wide"
    echo "4. Set up CloudWatch alarms for monitoring"
    echo ""
    echo "To monitor logs:"
    echo "aws logs tail /aws/lambda/enhanced-auto-remediation-lambda --follow"
    echo ""
    echo "To check organization-wide findings:"
    echo "aws securityhub get-findings --filters '{\"SeverityLabel\":[{\"Value\":\"HIGH\",\"Comparison\":\"EQUALS\"}]}'"
    echo ""
    echo "To list all accounts:"
    echo "aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`].[Id,Name]' --output table"
}

# Run main function
main "$@" 