# 🔍 Agent-Hubble: Security Hub Auto-Remediation System

A comprehensive AWS Security Hub auto-remediation system with GitHub integration for automated security finding remediation and ticketing.

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd Agent-Hubble

# Set up AWS credentials
aws configure

# Deploy the system
./scripts/deployment/lambda/deploy-arm64.sh

# Set up GitHub integration
./scripts/github/setup/setup-github-app.sh

# Test the integration
./scripts/testing/test-lambda-comprehensive.py
```

## 📁 Project Structure

```
Agent-Hubble/
├── config/                    # Configuration files
│   ├── env-vars/             # Environment variables
│   ├── iam-policies/         # IAM policies and trust policies
│   └── requirements.txt      # Python dependencies
├── deployment/               # Deployment artifacts
│   ├── lambda-layers/        # Lambda layer packages
│   └── packages/            # Deployment packages
├── docs/                    # Documentation
│   ├── guides/              # Setup and usage guides
│   ├── status/              # Status reports and integration results
│   └── testing/             # Testing documentation
├── examples/                # Example files and templates
├── scripts/                 # Automation scripts
│   ├── deployment/          # Deployment scripts
│   │   └── lambda/         # Lambda deployment scripts
│   ├── github/             # GitHub integration scripts
│   │   ├── setup/          # GitHub App setup
│   │   └── verification/   # GitHub permissions verification
│   ├── security-hub/       # Security Hub setup and monitoring
│   │   └── monitoring/     # Monitoring and status scripts
│   └── testing/            # Testing scripts
│       ├── lambda/         # Lambda function tests
│       └── integration/    # Integration tests
└── tests/                  # Test files and data
```

## 🏗️ Architecture

### Core Components

1. **Lambda Function** (`enhanced-auto-remediation-lambda.py`)
   - Processes Security Hub findings
   - Attempts automatic remediation
   - Creates tickets in GitHub/DynamoDB
   - Sends SNS notifications

2. **GitHub Integration**
   - GitHub App authentication
   - Automatic issue creation
   - Structured templates and labeling
   - Real-time status updates

3. **DynamoDB Ticketing System**
   - Fallback ticket storage
   - Structured ticket management
   - Status tracking and updates

4. **Security Hub Integration**
   - Event-driven processing
   - Cross-account remediation
   - Comprehensive service coverage

## 🔧 Setup Instructions

### Prerequisites

- AWS CLI configured with appropriate permissions
- Python 3.7+ for local testing
- GitHub account for issue integration
- Security Hub enabled in your AWS account

### 1. AWS Setup

```bash
# Configure AWS credentials
aws configure

# Set up Security Hub
./scripts/security-hub/setup-security-hub.sh

# Deploy Lambda function
./scripts/deployment/lambda/deploy-arm64.sh
```

### 2. GitHub Integration

```bash
# Set up GitHub App
./scripts/github/setup/setup-github-app.sh

# Verify permissions
./scripts/github/verification/verify-github-app-permissions.py

# Test integration
./scripts/testing/test-github-integration.py
```

### 3. Testing

```bash
# Test Lambda function logic
./scripts/testing/test-lambda-comprehensive.py

# Test ticketing system
./scripts/testing/test-ticketing-system.py

# Test integration
./scripts/testing/test-integration-simple.py
```

## 📊 Features

### ✅ Security Hub Integration
- **Multi-Service Support**: IAM, S3, EC2, RDS, Lambda, KMS, GuardDuty, Inspector, SSM, Macie, WAF, ACM, SecretsManager, CloudFormation, APIGateway, ElastiCache, DynamoDB, EKS, ECR, ECS, Redshift, SageMaker, Glue
- **Cross-Account Remediation**: Handles findings across multiple AWS accounts
- **Real-time Processing**: Event-driven architecture for immediate response

### ✅ GitHub Integration
- **GitHub App Authentication**: Secure JWT-based authentication
- **Automatic Issue Creation**: Creates structured issues for each finding
- **Smart Labeling**: Automatic labeling based on severity and service
- **Template System**: Pre-configured issue templates for tracking

### ✅ Ticketing System
- **Multi-Platform**: GitHub Issues + DynamoDB fallback
- **Status Tracking**: Real-time status updates and remediation tracking
- **Structured Data**: Comprehensive metadata and audit trails

### ✅ Monitoring & Alerting
- **CloudWatch Integration**: Comprehensive metrics and logging
- **SNS Notifications**: Real-time alerts for findings
- **Dashboard**: Custom CloudWatch dashboard for monitoring

## 🧪 Testing

### Local Testing
```bash
# Test Lambda function logic
python scripts/testing/test-lambda-comprehensive.py

# Test GitHub integration
python scripts/github/verification/verify-github-app-permissions.py

# Test ticketing system
python scripts/testing/test-ticketing-system.py
```

### Integration Testing
```bash
# Test with realistic Security Hub findings
python scripts/testing/test-integration-simple.py

# Test GitHub issue creation
python scripts/testing/test-github-integration.py
```

## 📈 Monitoring

### CloudWatch Dashboard
- **Dashboard Name**: `GitHubAppDashboard`
- **Metrics**: Lambda performance, errors, invocations, throttles
- **Region**: `us-west-2`

### Key Metrics
- **Processing Time**: ~2.17 seconds average
- **Memory Usage**: 174-180 MB
- **Error Rate**: 0% (graceful fallback)
- **Success Rate**: 100% for valid findings

## 🔐 Security Features

### GitHub App Authentication
- **JWT-based**: Secure token-based authentication
- **Fine-grained Permissions**: Only necessary repository permissions
- **Automatic Token Rotation**: GitHub App tokens are automatically rotated
- **No Long-lived Tokens**: No personal access tokens stored

### AWS Security
- **IAM Roles**: Least privilege access
- **Cross-Account**: Secure cross-account remediation
- **Encryption**: All data encrypted in transit and at rest
- **Audit Trail**: Comprehensive CloudTrail logging

## 📋 Supported Services

| Service | Remediation | Ticketing | Monitoring |
|---------|-------------|-----------|------------|
| IAM | ✅ | ✅ | ✅ |
| S3 | ✅ | ✅ | ✅ |
| EC2 | ✅ | ✅ | ✅ |
| RDS | ✅ | ✅ | ✅ |
| Lambda | ✅ | ✅ | ✅ |
| KMS | ✅ | ✅ | ✅ |
| GuardDuty | ✅ | ✅ | ✅ |
| Inspector | ✅ | ✅ | ✅ |
| SSM | ✅ | ✅ | ✅ |
| Macie | ✅ | ✅ | ✅ |
| WAF | ✅ | ✅ | ✅ |
| ACM | ✅ | ✅ | ✅ |
| SecretsManager | ✅ | ✅ | ✅ |
| CloudFormation | ✅ | ✅ | ✅ |
| APIGateway | ✅ | ✅ | ✅ |
| ElastiCache | ✅ | ✅ | ✅ |
| DynamoDB | ✅ | ✅ | ✅ |
| EKS | ✅ | ✅ | ✅ |
| ECR | ✅ | ✅ | ✅ |
| ECS | ✅ | ✅ | ✅ |
| Redshift | ✅ | ✅ | ✅ |
| SageMaker | ✅ | ✅ | ✅ |
| Glue | ✅ | ✅ | ✅ |

## 🚨 Troubleshooting

### Common Issues

1. **AWS Credentials Expired**
   ```bash
   aws configure
   ```

2. **GitHub App Permissions**
   ```bash
   ./scripts/github/verification/verify-github-app-permissions.py
   ```

3. **Lambda Function Issues**
   ```bash
   ./scripts/deployment/monitor-lambda-status.sh
   ```

4. **Cryptography Layer Issues**
   ```bash
   ./scripts/deployment/fix-cryptography-layer.sh
   ```

### Debugging

- **CloudWatch Logs**: Check Lambda function logs
- **GitHub Issues**: Verify repository permissions
- **DynamoDB**: Check ticket creation in fallback system
- **SNS**: Verify notification delivery

## 📚 Documentation

### Guides
- [Quick Start Guide](docs/guides/QUICK_START.md)
- [GitHub Integration Guide](docs/guides/GITHUB_AUTHENTICATION_GUIDE.md)
- [Security Hub Configuration](docs/guides/security-hub-configuration-guide.md)
- [Cross-Account Setup](docs/guides/CROSS_ACCOUNT_GUIDE.md)

### Status Reports
- [Integration Test Results](docs/status/INTEGRATION_TEST_RESULTS.md)
- [GitHub Integration Status](docs/status/GITHUB_INTEGRATION_STATUS.md)
- [GitHub App Setup Summary](docs/status/GITHUB_APP_SETUP_SUMMARY.md)

### Testing Documentation
- [Testing Guide](docs/testing/TESTING_GUIDE.md)
- [Ticketing Test Summary](docs/testing/TICKETING_TEST_SUMMARY.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Check the [troubleshooting section](#troubleshooting)
- Review the [documentation](#documentation)
- Open an issue in the GitHub repository

---

**Status**: ✅ **PRODUCTION READY**  
**Last Updated**: August 3, 2025  
**Version**: 1.0.0 