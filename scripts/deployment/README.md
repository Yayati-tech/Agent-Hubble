# 🚀 Deployment Scripts Documentation

## Overview
This directory contains all deployment scripts for the Agent-Hubble Security Hub Auto-Remediation system.

## 📁 Directory Structure

```
deployment/
├── README.md                           # This file
├── lambda/                             # Lambda function deployments (ARM64 only)
│   ├── deploy.sh                       # ARM64 Lambda deployment script
│   ├── deploy-false-positive-analysis.sh # False positive analysis Lambda
│   ├── update-lambda-cryptography.sh   # Cryptography update script
│   └── enhanced-auto-remediation-lambda.py # Main Lambda function
├── github/                             # GitHub Actions workflows
├── security-hub/                       # Security Hub configuration
└── layers/                             # Lambda layers
    ├── create-cryptography-layer.sh    # Cryptography layer creation
    └── fix-cryptography-layer.sh       # Layer troubleshooting
```

## 🔧 Lambda Deployment Scripts

### ARM64 Deployment (`deploy.sh`)
- **Purpose**: Deploy the main auto-remediation Lambda function with ARM64 architecture
- **Features**: 
  - Creates IAM roles and policies
  - Sets up SNS topics
  - Installs dependencies with cryptography>=42.0.2
  - Configures environment variables
  - Supports both creation and updates
  - Optimized for ARM64 performance and cost efficiency

### False Positive Analysis (`deploy-false-positive-analysis.sh`)
- **Purpose**: Deploy ML-based false positive analysis Lambda
- **Features**:
  - Machine learning dependencies
  - SageMaker integration
  - DynamoDB for data storage

## 🛠️ Layer Management

### Cryptography Layer
- **Script**: `create-cryptography-layer.sh`
- **Purpose**: Create Lambda layer with cryptography>=42.0.2
- **Dependencies**: cryptography, PyJWT
- **Architecture**: Multi-architecture support

## 🔐 Security Features

### IAM Roles and Policies
- **Role**: `SecurityHubAutoRemediationRole`
- **Permissions**: Security Hub, IAM, S3, EC2, RDS, Lambda, KMS, CloudWatch
- **Cross-account**: Support for multi-account remediation

### Environment Variables
```bash
BACKUP_ACCOUNT_ID="002616177731"
MANAGEMENT_ACCOUNT_ID="013983952777"
SNS_TOPIC_NAME="SecurityHubAutoRemediationAlerts"
```

## 🚀 Quick Start

### Prerequisites
1. AWS CLI installed and configured
2. Python 3.9+
3. Required AWS permissions

### Deploy ARM64 Lambda
```bash
cd scripts/deployment/lambda
./deploy.sh
```

### Update Cryptography
```bash
cd scripts/deployment/lambda
./update-lambda-cryptography.sh
```

## 🔧 Troubleshooting

### Common Issues
1. **AWS Credentials**: Ensure credentials are configured and not expired
2. **IAM Permissions**: Verify sufficient permissions for Lambda, IAM, Security Hub
3. **Dependencies**: Check Python dependencies are compatible
4. **Environment Variables**: Verify JSON format for Lambda environment variables

### Debug Commands
```bash
# Check AWS credentials
aws sts get-caller-identity

# Test Lambda function
aws lambda invoke --function-name enhanced-auto-remediation-lambda response.json

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/enhanced-auto-remediation-lambda
```

## 📋 Maintenance

### Regular Tasks
- [ ] Update cryptography dependencies quarterly
- [ ] Review IAM permissions monthly
- [ ] Test cross-account functionality
- [ ] Monitor CloudWatch metrics
- [ ] Update Python runtime versions

### Security Checklist
- [ ] Rotate AWS credentials regularly
- [ ] Review IAM policies for least privilege
- [ ] Update dependencies for security patches
- [ ] Monitor Security Hub findings
- [ ] Test remediation workflows

## 🔄 Version History

### v2.0.0 (Current)
- ✅ Updated to cryptography>=42.0.2
- ✅ Enhanced JWT handling
- ✅ Improved GitHub App authentication
- ✅ Better error handling and logging
- ✅ ARM64 support

### v1.0.0
- ✅ Initial deployment scripts
- ✅ Basic Security Hub integration
- ✅ SNS notifications
- ✅ Cross-account remediation 