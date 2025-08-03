# Cross-Account Security Hub Auto-Remediation Guide

## 🏢 Organization-Wide Security Remediation

This guide explains how to configure your enhanced auto-remediation Lambda function to remediate Security Hub findings across all accounts in your AWS organization.

## ✅ What's Now Possible

With the enhanced setup, your Lambda function can:

- **🔍 Detect cross-account findings** from Security Hub aggregation
- **🔐 Assume roles** in member accounts automatically
- **🛠️ Remediate issues** across all organization accounts
- **📊 Track remediation** status organization-wide
- **🔔 Send notifications** for cross-account remediations
- **📈 Monitor metrics** across all accounts

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Organization                        │
├─────────────────────────────────────────────────────────────┤
│  Management Account (Lambda Function)                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ EventBridge Rule                                  │   │
│  │ └─ Security Hub Findings → Lambda Function        │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                               │
│                           ▼                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Enhanced Lambda Function                           │   │
│  │ ┌─────────────────────────────────────────────────┐ │   │
│  │ │ 1. Extract Account ID from Finding            │ │   │
│  │ │ 2. Assume Role in Target Account              │ │   │
│  │ │ 3. Create Cross-Account Clients               │ │   │
│  │ │ 4. Execute Remediation                        │ │   │
│  │ │ 5. Update Finding Status                      │ │   │
│  │ └─────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                               │
│                           ▼                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Member Account 1                                   │   │
│  │ ┌─────────────────────────────────────────────────┐ │   │
│  │ │ SecurityHubAutoRemediationRole                │ │   │
│  │ │ (Cross-Account Access)                        │ │   │
│  │ └─────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                               │
│                           ▼                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Member Account 2                                   │   │
│  │ ┌─────────────────────────────────────────────────┐ │   │
│  │ │ SecurityHubAutoRemediationRole                │ │   │
│  │ │ (Cross-Account Access)                        │ │   │
│  │ └─────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                               │
│                           ▼                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Member Account N                                   │   │
│  │ ┌─────────────────────────────────────────────────┐ │   │
│  │ │ SecurityHubAutoRemediationRole                │ │   │
│  │ │ (Cross-Account Access)                        │ │   │
│  │ └─────────────────────────────────────────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Setup (Organization-Wide)

### Prerequisites

1. **AWS Organizations enabled** with management account access
2. **Lambda function deployed** in management account
3. **Security Hub enabled** in management account
4. **Appropriate IAM permissions** for cross-account operations

### Step 1: Deploy Lambda Function

First, deploy your enhanced Lambda function in the management account:

```bash
# Deploy in management account
chmod +x deploy-arm64.sh
./deploy-arm64.sh
```

### Step 2: Configure Cross-Account Setup

Run the cross-account configuration script from the management account:

```bash
chmod +x cross-account-setup.sh
./cross-account-setup.sh
```

This script will automatically:

✅ **List all organization accounts**
✅ **Create cross-account IAM roles** in each member account
✅ **Enable Security Hub** in all member accounts
✅ **Configure Security Hub aggregation** for organization-wide findings
✅ **Create organization-wide EventBridge rule**
✅ **Set up cross-account SNS topics**
✅ **Test cross-account access**
✅ **Create test findings** across all accounts

### Step 3: Verify Organization Setup

Monitor the setup and verify cross-account functionality:

```bash
# Monitor Lambda logs for cross-account activity
aws logs tail /aws/lambda/enhanced-auto-remediation-lambda --follow

# Check organization-wide findings
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"}]}'

# List all accounts in organization
aws organizations list-accounts --query 'Accounts[?Status==`ACTIVE`].[Id,Name]' --output table
```

## 🔧 Manual Configuration (Alternative)

If you prefer to configure manually, follow these steps:

### 1. Create Cross-Account IAM Roles

For each member account, create a role that the management account can assume:

```bash
# In each member account, create the role
aws iam create-role \
  --role-name "SecurityHubAutoRemediationRole" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::MANAGEMENT_ACCOUNT_ID:root"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "sts:ExternalId": "SecurityHubAutoRemediation"
          }
        }
      }
    ]
  }'

# Attach necessary policies
aws iam attach-role-policy \
  --role-name "SecurityHubAutoRemediationRole" \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
```

### 2. Enable Security Hub in Member Accounts

```bash
# Enable Security Hub in each member account
aws securityhub enable-security-hub --enable-default-standards
```

### 3. Configure Security Hub Aggregation

```bash
# Create finding aggregator in management account
aws securityhub create-finding-aggregator \
  --region-linking-mode "ALL_REGIONS" \
  --source-regions "us-east-1"
```

### 4. Create Organization-Wide EventBridge Rule

```bash
# Create event pattern for organization-wide findings
aws events put-rule \
  --name "OrganizationSecurityHubFindingsRule" \
  --event-pattern '{
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

# Add Lambda function as target
aws events put-targets \
  --rule "OrganizationSecurityHubFindingsRule" \
  --targets "Id=1,Arn=arn:aws:lambda:REGION:MANAGEMENT_ACCOUNT:function:enhanced-auto-remediation-lambda"
```

## 🔍 How Cross-Account Remediation Works

### 1. Finding Detection

When a Security Hub finding is created in any member account:

1. **Security Hub aggregation** collects findings from all accounts
2. **EventBridge rule** triggers the Lambda function
3. **Lambda function** receives the finding event

### 2. Account ID Extraction

The Lambda function extracts the target account ID from the finding:

```python
def extract_account_id_from_finding(finding):
    # Try multiple sources for account ID
    account_id = finding.get('AwsAccountId')
    if account_id:
        return account_id
    
    # Extract from ProductArn
    product_arn = finding.get('ProductArn', '')
    if 'arn:aws:securityhub:' in product_arn:
        parts = product_arn.split(':')
        if len(parts) >= 5:
            return parts[4]
    
    # Extract from Resources
    resources = finding.get('Resources', [])
    for resource in resources:
        resource_arn = resource.get('Id', '')
        if 'arn:aws:' in resource_arn:
            parts = resource_arn.split(':')
            if len(parts) >= 5:
                return parts[4]
    
    return None
```

### 3. Role Assumption

The Lambda function assumes a role in the target account:

```python
def assume_cross_account_role(account_id):
    sts_client = boto3.client('sts')
    
    assumed_role = sts_client.assume_role(
        RoleArn=f"arn:aws:iam::{account_id}:role/SecurityHubAutoRemediationRole",
        RoleSessionName="SecurityHubRemediation",
        ExternalId="SecurityHubAutoRemediation"
    )
    
    session = boto3.Session(
        aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
        aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
        aws_session_token=assumed_role['Credentials']['SessionToken']
    )
    
    return session
```

### 4. Cross-Account Remediation

The function creates AWS clients for the target account and executes remediation:

```python
def remediate_cross_account_issues(finding, multiple_clients):
    target_account_id = extract_account_id_from_finding(finding)
    session = assume_cross_account_role(target_account_id)
    cross_account_clients = create_cross_account_clients(target_account_id, session)
    
    # Execute remediation using cross-account clients
    remediated = remediate_specific_issue(finding, cross_account_clients)
    
    # Update finding status in target account
    cross_account_clients['securityhub'].update_findings(...)
    
    return remediated
```

## 📊 Monitoring Cross-Account Remediation

### CloudWatch Metrics

Monitor these metrics across all accounts:

```bash
# Get cross-account remediation metrics
aws cloudwatch get-metric-statistics \
  --namespace "SecurityHub/AutoRemediation" \
  --metric-name "RemediatedFindings" \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --period 300 \
  --statistics Sum
```

### CloudWatch Logs

Monitor Lambda function logs for cross-account activity:

```bash
# Monitor cross-account remediation logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda" \
  --filter-pattern "Cross-account finding detected" \
  --start-time $(date -d '1 hour ago' +%s)000
```

### SNS Notifications

Cross-account remediations send notifications to all accounts:

```bash
# Check SNS notifications across accounts
aws sns list-topics --query 'Topics[?contains(TopicName, `SecurityHubAutoRemediationAlerts`)]'
```

## 🔒 Security Considerations

### IAM Permissions

The cross-account roles need appropriate permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "securityhub:*",
                "iam:*",
                "s3:*",
                "ec2:*",
                "rds:*",
                "lambda:*",
                "kms:*",
                "cloudwatch:*",
                "sns:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### External ID Protection

Use external IDs to prevent confused deputy attacks:

```python
assumed_role = sts_client.assume_role(
    RoleArn=f"arn:aws:iam::{account_id}:role/SecurityHubAutoRemediationRole",
    RoleSessionName="SecurityHubRemediation",
    ExternalId="SecurityHubAutoRemediation"  # Prevents unauthorized access
)
```

### Least Privilege

Consider using more restrictive policies based on your needs:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "securityhub:UpdateFindings",
                "iam:DeleteAccessKey",
                "s3:PutBucketEncryption"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestTag/Remediation": "SecurityHub"
                }
            }
        }
    ]
}
```

## 🧪 Testing Cross-Account Remediation

### Create Test Findings

Create test findings in member accounts:

```bash
# Create test finding in member account
aws securityhub batch-import-findings \
  --findings '[
    {
      "Id": "test-cross-account-123",
      "ProductArn": "arn:aws:securityhub:REGION::product/aws/securityhub",
      "GeneratorId": "test-generator",
      "AwsAccountId": "MEMBER_ACCOUNT_ID",
      "Types": ["Software and Configuration Checks/AWS Security Best Practices"],
      "CreatedAt": "2024-01-01T00:00:00Z",
      "UpdatedAt": "2024-01-01T00:00:00Z",
      "Severity": {
        "Label": "HIGH"
      },
      "Title": "Test Cross-Account Finding",
      "Description": "This is a test finding for cross-account validation"
    }
  ]'
```

### Monitor Remediation

Monitor the remediation process:

```bash
# Check Lambda logs for cross-account activity
aws logs tail /aws/lambda/enhanced-auto-remediation-lambda --follow

# Check finding status in member account
aws securityhub get-findings \
  --filters '{"Id":[{"Value":"test-cross-account-123","Comparison":"EQUALS"}]}'
```

## 🔍 Troubleshooting

### Common Issues

1. **Role assumption fails**
   - Check if cross-account role exists in member account
   - Verify trust policy allows management account
   - Ensure external ID matches

2. **Permission denied in member account**
   - Verify role has necessary permissions
   - Check if service is available in member account
   - Ensure account is active

3. **Finding not detected**
   - Verify Security Hub aggregation is configured
   - Check EventBridge rule pattern
   - Ensure finding meets severity criteria

### Debug Commands

```bash
# Test role assumption
aws sts assume-role \
  --role-arn "arn:aws:iam::MEMBER_ACCOUNT_ID:role/SecurityHubAutoRemediationRole" \
  --role-session-name "TestAccess" \
  --external-id "SecurityHubAutoRemediation"

# Check Security Hub aggregation
aws securityhub list-finding-aggregators

# Verify EventBridge rule
aws events describe-rule --name "OrganizationSecurityHubFindingsRule"

# Check cross-account permissions
aws iam get-role --role-name "SecurityHubAutoRemediationRole"
```

## 📈 Benefits of Cross-Account Remediation

### Centralized Management
- **Single Lambda function** manages all accounts
- **Consistent remediation** across organization
- **Unified monitoring** and alerting

### Cost Optimization
- **Reduced Lambda functions** (one vs. many)
- **Centralized logging** and metrics
- **Efficient resource utilization**

### Security Enhancement
- **Organization-wide visibility** of security issues
- **Automated remediation** across all accounts
- **Comprehensive audit trail**

### Operational Efficiency
- **Reduced manual intervention** across accounts
- **Standardized remediation** procedures
- **Faster response** to security findings

## 🎯 Next Steps

After setting up cross-account remediation:

1. **Monitor effectiveness** across all accounts
2. **Customize remediation rules** for specific needs
3. **Set up alerts** for failed cross-account remediations
4. **Review and optimize** IAM permissions
5. **Document procedures** for manual intervention
6. **Regular testing** of cross-account functionality

## 📞 Support

For additional help with cross-account setup:

- Check CloudWatch logs for detailed error messages
- Review IAM permissions in member accounts
- Verify Security Hub aggregation configuration
- Test role assumption manually
- Monitor SNS notifications for cross-account activity

---

**Note**: Cross-account remediation requires careful planning and testing. Always test in a non-production environment first and ensure all security requirements are met before deploying to production. 