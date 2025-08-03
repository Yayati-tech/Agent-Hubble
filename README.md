# AWS Security Auto-Remediation Lambda

Enhanced AWS Security Hub auto-remediation Lambda function with cross-account capabilities and comprehensive security remediations.

## 🚀 Features

- **Comprehensive Security Remediations**: Supports remediations for IAM, S3, EC2, RDS, Lambda, KMS, GuardDuty, Inspector, SSM, Macie, WAF, Shield, ACM, Secrets Manager, CloudFormation, API Gateway, ElastiCache, DynamoDB, EKS, ECR, ECS, Redshift, SageMaker, and Glue
- **Cross-Account Capabilities**: Can remediate security findings across multiple AWS accounts
- **Enhanced Error Handling**: Robust error handling and logging for production environments
- **CloudWatch Integration**: Sends metrics and logs to CloudWatch for monitoring
- **SNS Notifications**: Sends notifications for successful and failed remediations
- **ARM64 Support**: Compatible with ARM64 architecture for cost optimization
- **Multi-Service Remediations**: Coordinated remediations across multiple AWS services
- **Orchestrated Workflows**: Complex multi-step remediation processes

## 🏗️ Architecture

This Lambda function integrates with AWS Security Hub to automatically remediate security findings based on their severity and type. It supports:

- **Multi-Service Remediations**: Coordinated remediations across multiple AWS services
- **Cross-Account Operations**: Remediation across different AWS accounts
- **Orchestrated Workflows**: Complex multi-step remediation processes

## 📋 Supported Remediations

### IAM Remediations
- Root user access key usage
- Root user console access
- IAM access key issues
- Unused IAM users, roles, and policies
- IAM password policy
- MFA not enabled for IAM users

### S3 Remediations
- S3 bucket encryption
- S3 bucket versioning
- S3 bucket logging
- S3 bucket public access
- S3 bucket lifecycle policies

### EC2 Remediations
- Unused EBS volumes and snapshots
- Unused EC2 instances
- Unused security groups and network interfaces
- Security group issues
- VPC flow logs
- Default VPC usage

### CloudTrail & Config Remediations
- CloudTrail not enabled/integrated/encrypted
- AWS Config not enabled/recording

### Database Remediations
- RDS encryption, backup retention, deletion protection, performance insights
- DynamoDB encryption and backup
- ElastiCache encryption and security groups
- Redshift encryption and logging

### Container & Serverless Remediations
- Lambda function encryption, logging, timeout, VPC configuration
- EKS cluster logging and security groups
- ECR repository encryption and image scanning
- ECS service logging and task security

### Security Services Remediations
- GuardDuty enabled, archiving, threat detection
- Inspector enabled, vulnerability findings, assessment runs
- Macie enabled, data classification, sensitive data findings
- WAF enabled, rules configured, Shield Advanced

### Other Service Remediations
- KMS key rotation and deletion protection
- Certificate expiration and validation
- Secret rotation and encryption
- Stack drift detection and deletion protection
- API Gateway logging and encryption
- SageMaker notebook encryption and model security
- Glue job encryption and catalog encryption

## 🚀 Deployment

### Prerequisites

- AWS CLI configured
- Appropriate IAM permissions for Security Hub, Lambda, and other AWS services
- SNS topic for notifications

### Quick Deployment

1. **Clone this repository**
   ```bash
   git clone https://github.com/vivpa/aws-security-auto-remediation.git
   cd aws-security-auto-remediation
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Deploy using the provided deployment scripts**:
   - `deploy-simple.sh` - Basic deployment
   - `deploy.sh` - Full deployment with CloudFormation
   - `deploy-arm64.sh` - ARM64 optimized deployment

### Deployment Options

#### Option 1: Simple Deployment
```bash
chmod +x deploy-simple.sh
./deploy-simple.sh
```

#### Option 2: Full Deployment
```bash
chmod +x deploy.sh
./deploy.sh
```

#### Option 3: ARM64 Deployment (Recommended for cost optimization)
```bash
chmod +x deploy-arm64.sh
./deploy-arm64.sh
```

#### Option 4: CloudFormation Deployment
```bash
aws cloudformation create-stack \
  --stack-name security-auto-remediation \
  --template-body file://cloudformation-template.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## ⚙️ Configuration

### Environment Variables

Set the following environment variables:

- `BACKUP_ACCOUNT_ID`: Backup account ID for cross-account operations
- `MANAGEMENT_ACCOUNT_ID`: Management account ID
- `SNS_TOPIC_NAME`: SNS topic name for notifications
- `AWS_REGION`: AWS region for deployment
- `LOG_LEVEL`: Logging level (INFO, DEBUG, ERROR)
- `TIMEOUT`: Lambda function timeout in seconds
- `MEMORY_SIZE`: Lambda function memory size in MB

### IAM Permissions

The Lambda function requires permissions for:
- Security Hub (read, update findings)
- IAM (user, role, policy management)
- S3 (bucket configuration)
- EC2 (instance, volume, security group management)
- RDS (instance configuration)
- Lambda (function configuration)
- KMS (key management)
- CloudWatch (metrics and logs)
- SNS (notifications)
- And many other AWS services

## 🔒 Security Considerations

- The Lambda function requires appropriate IAM permissions
- Cross-account operations require proper role assumptions
- All remediations are logged and monitored
- Failed remediations are reported via SNS
- Environment variables should be encrypted
- Consider using AWS Secrets Manager for sensitive configuration

## 📊 Monitoring

### CloudWatch Metrics
- `RemediationSuccess`: Number of successful remediations
- `RemediationFailure`: Number of failed remediations
- `TotalRemediations`: Total number of remediations processed

### CloudWatch Logs
- Detailed logging for troubleshooting
- Error tracking and debugging
- Performance monitoring

### SNS Notifications
- Success notifications for remediated findings
- Failure notifications for failed remediations
- Error notifications for system issues

### Security Hub Integration
- Automatic finding status updates
- Remediation tracking
- Compliance reporting

## 🧪 Testing

### Test with Sample Findings

1. **Create a test Security Hub finding**
2. **Trigger the Lambda function**
3. **Monitor CloudWatch logs**
4. **Verify SNS notifications**
5. **Check Security Hub finding status**

### Local Testing

```bash
# Test the Lambda function locally
python -c "
import json
from enhanced_auto_remediation_lambda import lambda_handler

# Sample Security Hub event
event = {
    'detail': {
        'findings': [
            {
                'Id': 'test-finding-123',
                'Severity': {'Label': 'HIGH'},
                'ProductArn': 'arn:aws:securityhub:us-west-2::product/aws/securityhub'
            }
        ]
    }
}

result = lambda_handler(event, None)
print(json.dumps(result, indent=2))
"
```

## 🔧 Troubleshooting

### Common Issues

1. **IAM Permissions**: Ensure the Lambda role has all required permissions
2. **SNS Topic**: Verify the SNS topic exists and is accessible
3. **Environment Variables**: Check that all required environment variables are set
4. **Timeout Issues**: Increase the Lambda timeout for complex remediations
5. **Memory Issues**: Increase the Lambda memory for resource-intensive operations

### Debugging

1. **Check CloudWatch Logs**: Look for error messages and stack traces
2. **Verify SNS Notifications**: Ensure notifications are being sent
3. **Test Individual Functions**: Test specific remediation functions
4. **Monitor Metrics**: Check CloudWatch metrics for performance issues

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AWS Security Hub team for the comprehensive security findings
- AWS Lambda team for the serverless computing platform
- AWS CloudWatch team for monitoring and logging capabilities
- AWS SNS team for notification services

## 📞 Support

For support and questions:
- Create an issue in this repository
- Check the CloudWatch logs for detailed error messages
- Review the Security Hub documentation
- Consult AWS Lambda best practices

## 🔄 Version History

- **v1.0.0**: Initial release with basic remediation capabilities
- **v1.1.0**: Added cross-account support and enhanced error handling
- **v1.2.0**: Added ARM64 support and comprehensive service coverage
- **v1.3.0**: Added orchestrated workflows and multi-service remediations

---

**Note**: This Lambda function is designed for production use but should be thoroughly tested in your environment before deployment. Always review and customize the IAM permissions based on your specific security requirements.