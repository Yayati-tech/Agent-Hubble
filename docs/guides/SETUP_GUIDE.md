# 🚀 Agent-Hubble Setup Guide

This guide provides step-by-step instructions for setting up the Agent-Hubble Security Hub auto-remediation system.

## 📋 Prerequisites

### Required Software
- **AWS CLI**: Version 2.x or later
- **Python**: 3.7+ for local testing
- **Git**: For repository management
- **Bash**: For running setup scripts

### Required AWS Services
- **Security Hub**: Enabled in your AWS account
- **Lambda**: For function execution
- **DynamoDB**: For ticket storage
- **SNS**: For notifications
- **CloudWatch**: For monitoring
- **IAM**: For permissions

### Required GitHub Setup
- **GitHub Account**: For issue integration
- **Repository**: For storing issues and labels
- **GitHub App**: For secure authentication

## 🔧 Step 1: Initial Setup

### 1.1 Clone the Repository
```bash
git clone <repository-url>
cd Agent-Hubble
```

### 1.2 Configure AWS Credentials
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-west-2)
- Default output format (json)

### 1.3 Verify AWS Access
```bash
aws sts get-caller-identity
```

## 🔧 Step 2: Security Hub Setup

### 2.1 Enable Security Hub
```bash
./scripts/security-hub/setup/setup-security-hub.sh
```

This script will:
- Enable Security Hub in your account
- Configure basic settings
- Set up necessary IAM roles

### 2.2 Verify Security Hub
```bash
aws securityhub describe-hub
```

## 🔧 Step 3: Lambda Function Deployment

### 3.1 Deploy Lambda Function
```bash
cd scripts/deployment/lambda
./deploy.sh
```

This script will:
- Create the Lambda function with ARM64 architecture
- Set up IAM roles and policies
- Configure environment variables
- Deploy the function code

### 3.2 Verify Lambda Deployment
```bash
aws lambda get-function --function-name enhanced-auto-remediation-lambda
```

## 🔧 Step 4: GitHub Integration

### 4.1 Current GitHub App Configuration

The system is already configured with a working GitHub App:

- **App ID**: `1719742`
- **Installation ID**: `78968584`
- **Repository**: `Yayati-tech/Agent-Hubble`
- **Status**: ✅ Active and working

### 4.2 Test GitHub Integration
```bash
# Test GitHub App access
cd scripts/github
python test-github-access.py

# Test Lambda function with GitHub
cd ../deployment/security-hub
echo '{"detail":{"findings":[{"Id":"test-finding","Severity":{"Label":"HIGH"},"Compliance":{"Status":"FAILED"},"ProductArn":"arn:aws:securityhub:us-west-2:002616177731:product/aws/securityhub"}]}}' > test-event.json

aws lambda invoke \
    --function-name enhanced-auto-remediation-lambda \
    --payload file://test-event.json \
    response.json \
    --cli-binary-format raw-in-base64-out

cat response.json
```

## 🔧 Step 5: Security Hub Integration

### 5.1 Configure Security Hub Trigger
```bash
cd scripts/deployment/security-hub
./configure-security-hub-trigger.sh
```

This script will:
- Create EventBridge rule for Security Hub findings
- Configure Lambda function as target
- Set up necessary permissions
- Enable Security Hub integration

### 5.2 Verify Security Hub Integration
```bash
# Check EventBridge rule
aws events describe-rule --name "SecurityHubFindingsRule"

# Check Lambda permissions
aws lambda get-policy --function-name enhanced-auto-remediation-lambda
```

## 🔧 Step 6: Testing and Verification

### 6.1 Test End-to-End Flow
```bash
# Create a test Security Hub finding
aws securityhub create-finding \
    --findings '[
        {
            "SchemaVersion": "2018-10-08",
            "Id": "test-finding-123",
            "ProductArn": "arn:aws:securityhub:us-west-2:002616177731:product/aws/securityhub",
            "GeneratorId": "test-generator",
            "AwsAccountId": "002616177731",
            "Types": ["Software and Configuration Checks"],
            "FirstObservedAt": "2025-08-04T00:00:00Z",
            "LastObservedAt": "2025-08-04T00:00:00Z",
            "CreatedAt": "2025-08-04T00:00:00Z",
            "UpdatedAt": "2025-08-04T00:00:00Z",
            "Severity": {
                "Product": 8,
                "Label": "HIGH",
                "Normalized": 8
            },
            "Title": "Test Security Finding",
            "Description": "This is a test finding for auto-remediation",
            "Remediation": {
                "Recommendation": {
                    "Text": "This is a test finding",
                    "Url": "https://docs.aws.amazon.com/securityhub/"
                }
            },
            "ProductFields": {},
            "Resources": [
                {
                    "Type": "AwsAccount",
                    "Id": "arn:aws:iam::002616177731:root",
                    "Partition": "aws",
                    "Region": "us-west-2"
                }
            ],
            "Compliance": {
                "Status": "FAILED"
            },
            "WorkflowState": "NEW",
            "Workflow": {
                "Status": "NEW"
            },
            "RecordState": "ACTIVE"
        }
    ]'
```

### 6.2 Monitor Results
```bash
# Check CloudWatch logs
aws logs describe-log-streams \
    --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda" \
    --order-by LastEventTime \
    --descending \
    --max-items 1

# View latest logs
aws logs get-log-events \
    --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda" \
    --log-stream-name "STREAM_NAME_FROM_ABOVE"
```

## ✅ Verification Checklist

### Lambda Function
- ✅ Function deployed with ARM64 architecture
- ✅ Environment variables configured
- ✅ IAM roles and policies set up
- ✅ Function responds to test invocations

### GitHub Integration
- ✅ GitHub App authentication working
- ✅ Repository access confirmed
- ✅ Issue creation successful
- ✅ Issue updates working

### Security Hub Integration
- ✅ EventBridge rule created
- ✅ Lambda function configured as target
- ✅ Permissions properly set
- ✅ Test findings processed

### Monitoring
- ✅ CloudWatch logs accessible
- ✅ SNS notifications working
- ✅ DynamoDB tickets created as fallback

## 🚀 Next Steps

1. **Monitor**: Watch CloudWatch logs for any issues
2. **Scale**: Configure for additional repositories if needed
3. **Secure**: Consider moving to AWS Secrets Manager for enterprise use
4. **Customize**: Modify remediation logic for your specific needs

## 🆘 Troubleshooting

### Common Issues

1. **Lambda deployment fails**
   - Check AWS credentials and permissions
   - Verify Python dependencies are installed
   - Check IAM role permissions

2. **GitHub integration fails**
   - Verify GitHub App is installed in repository
   - Check App ID and Installation ID
   - Ensure private key is properly formatted

3. **Security Hub integration fails**
   - Verify EventBridge rule exists
   - Check Lambda function permissions
   - Ensure Security Hub is enabled

### Debug Commands

```bash
# Test Lambda function
aws lambda invoke \
    --function-name enhanced-auto-remediation-lambda \
    --payload '{"test": "event"}' \
    response.json

# Test GitHub App access
cd scripts/github
python test-github-access.py

# Check Security Hub status
aws securityhub describe-hub
```

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review CloudWatch logs for detailed error messages
- Create an issue in the repository for persistent problems 