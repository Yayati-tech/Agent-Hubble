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
./scripts/security-hub/setup-security-hub.sh
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
./scripts/deployment/lambda/deploy-arm64.sh
```

This script will:
- Create the Lambda function
- Set up IAM roles and policies
- Configure environment variables
- Deploy the function code

### 3.2 Verify Lambda Deployment
```bash
./scripts/deployment/monitor-lambda-status.sh
```

## 🔧 Step 4: GitHub Integration

### 4.1 Set Up GitHub App
```bash
./scripts/github/setup/setup-github-app.sh
```

This script will:
- Create a GitHub App
- Configure permissions
- Generate authentication credentials
- Set up repository integration

### 4.2 Verify GitHub Permissions
```bash
./scripts/github/verification/verify-github-app-permissions.py
```

### 4.3 Test GitHub Integration
```bash
./scripts/testing/test-github-integration.py
```

## 🔧 Step 5: Testing

### 5.1 Test Lambda Function
```bash
./scripts/testing/test-lambda-comprehensive.py
```

### 5.2 Test Ticketing System
```bash
./scripts/testing/test-ticketing-system.py
```

### 5.3 Test Integration
```bash
./scripts/testing/test-integration-simple.py
```

## 🔧 Step 6: Monitoring Setup

### 6.1 Set Up CloudWatch Dashboard
```bash
./scripts/deployment/setup-monitoring.sh
```

### 6.2 Configure SNS Notifications
```bash
./scripts/security-hub/setup-notifications.sh
```

## 🔧 Step 7: Cross-Account Setup (Optional)

If you need to remediate findings across multiple AWS accounts:

### 7.1 Set Up Cross-Account Roles
```bash
./scripts/deployment/cross-account-setup.sh
```

### 7.2 Configure Trust Policies
```bash
./scripts/deployment/setup-trust-policies.sh
```

## 🔧 Step 8: Verification

### 8.1 Run Complete Test Suite
```bash
# Test Lambda function logic
python scripts/testing/test-lambda-comprehensive.py

# Test GitHub integration
python scripts/github/verification/verify-github-app-permissions.py

# Test ticketing system
python scripts/testing/test-ticketing-system.py

# Test integration
python scripts/testing/test-integration-simple.py
```

### 8.2 Check System Status
```bash
./scripts/security-hub/monitoring/quick-status-check.sh
```

## 📊 Configuration Files

### Environment Variables
The system uses several environment variables. Key ones include:

```bash
# AWS Configuration
BACKUP_ACCOUNT_ID=002616177731
MANAGEMENT_ACCOUNT_ID=013983952777
SNS_TOPIC_NAME=SecurityHubAutoRemediationAlerts

# GitHub Configuration
GITHUB_AUTH_TYPE=github_app
GITHUB_REPO=Yayati-tech/Agent-Hubble

# DynamoDB Configuration
TICKET_TABLE_NAME=SecurityHubTickets
```

### IAM Policies
The system requires several IAM policies:
- Lambda execution role
- Security Hub access
- DynamoDB access
- SNS publish permissions
- Cross-account remediation permissions

## 🚨 Troubleshooting

### Common Issues

#### 1. AWS Credentials Expired
```bash
aws configure
```

#### 2. GitHub App Permissions
```bash
./scripts/github/verification/verify-github-app-permissions.py
```

#### 3. Lambda Function Issues
```bash
./scripts/deployment/monitor-lambda-status.sh
```

#### 4. Cryptography Layer Issues
```bash
./scripts/deployment/fix-cryptography-layer.sh
```

### Debugging Steps

1. **Check CloudWatch Logs**
   ```bash
   aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/enhanced-auto-remediation"
   ```

2. **Verify GitHub Issues**
   - Check repository: https://github.com/Yayati-tech/Agent-Hubble/issues
   - Verify labels: https://github.com/Yayati-tech/Agent-Hubble/labels

3. **Check DynamoDB Tables**
   ```bash
   aws dynamodb describe-table --table-name SecurityHubTickets
   ```

4. **Monitor SNS Notifications**
   ```bash
   aws sns list-topics
   ```

## 📈 Performance Optimization

### Lambda Function
- **Memory**: 512 MB (recommended)
- **Timeout**: 5 minutes
- **Concurrency**: 10 (adjust based on load)

### DynamoDB
- **Read Capacity**: 5 units
- **Write Capacity**: 5 units
- **Auto Scaling**: Enabled

### CloudWatch
- **Log Retention**: 14 days
- **Metrics**: 1-minute granularity
- **Alarms**: Set up for errors and throttles

## 🔐 Security Considerations

### IAM Best Practices
- Use least privilege access
- Rotate access keys regularly
- Enable CloudTrail logging
- Use cross-account roles for remediation

### GitHub Security
- Use GitHub App authentication (not Personal Access Tokens)
- Limit repository access to specific repositories
- Enable branch protection rules
- Use issue templates for structured data

### Data Protection
- Encrypt data in transit and at rest
- Use AWS KMS for key management
- Implement proper logging and monitoring
- Regular security audits

## 📚 Additional Resources

### Documentation
- [README.md](../README.md) - Main project documentation
- [GitHub Integration Guide](GITHUB_AUTHENTICATION_GUIDE.md) - Detailed GitHub setup
- [Security Hub Configuration](security-hub-configuration-guide.md) - Security Hub setup
- [Cross-Account Setup](CROSS_ACCOUNT_GUIDE.md) - Multi-account configuration

### Testing
- [Testing Guide](../testing/TESTING_GUIDE.md) - Comprehensive testing procedures
- [Integration Test Results](../status/INTEGRATION_TEST_RESULTS.md) - Test results and metrics

### Monitoring
- [GitHub Integration Status](../status/GITHUB_INTEGRATION_STATUS.md) - Integration status
- [Project Status](../status/PROJECT_STATUS.md) - Overall project status

## 🎯 Next Steps

After successful setup:

1. **Monitor the System**
   - Check CloudWatch dashboard
   - Review GitHub issues
   - Monitor SNS notifications

2. **Customize Workflows**
   - Modify issue templates
   - Adjust remediation logic
   - Configure custom labels

3. **Scale the System**
   - Add more AWS services
   - Implement custom remediations
   - Expand to additional accounts

4. **Maintain the System**
   - Regular security updates
   - Performance monitoring
   - Backup and recovery procedures

---

**Status**: ✅ **PRODUCTION READY**  
**Last Updated**: August 3, 2025  
**Version**: 1.0.0 