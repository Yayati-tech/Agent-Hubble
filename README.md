# AWS Security Auto-Remediation Lambda

Enhanced AWS Security Hub auto-remediation Lambda function with cross-account capabilities, comprehensive security remediations, and integrated ticket management system.

## 🚀 Features

- **Comprehensive Security Remediations**: Supports remediations for IAM, S3, EC2, RDS, Lambda, KMS, GuardDuty, Inspector, SSM, Macie, WAF, Shield, ACM, Secrets Manager, CloudFormation, API Gateway, ElastiCache, DynamoDB, EKS, ECR, ECS, Redshift, SageMaker, and Glue
- **Cross-Account Capabilities**: Can remediate security findings across multiple AWS accounts
- **Enhanced Error Handling**: Robust error handling and logging for production environments
- **CloudWatch Integration**: Sends metrics and logs to CloudWatch for monitoring
- **SNS Notifications**: Sends notifications for successful and failed remediations
- **ARM64 Support**: Compatible with ARM64 architecture for cost optimization
- **Multi-Service Remediations**: Coordinated remediations across multiple AWS services
- **Orchestrated Workflows**: Complex multi-step remediation processes
- **🎫 Integrated Ticket Management**: Automatic ticket creation for Security Hub findings
- **🔗 Multiple Ticket Systems**: Support for Jira, GitHub Issues, and custom DynamoDB tickets
- **📊 Ticket Dashboard**: Web-based dashboard for monitoring and managing tickets

## 🏗️ Architecture

This Lambda function integrates with AWS Security Hub to automatically remediate security findings based on their severity and type. It supports:

- **Multi-Service Remediations**: Coordinated remediations across multiple AWS services
- **Cross-Account Operations**: Remediation across different AWS accounts
- **Orchestrated Workflows**: Complex multi-step remediation processes
- **Ticket Integration**: Automatic ticket creation and management for all findings

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

## 🎫 Ticket Management System

### Supported Ticket Systems
- **Jira**: Full integration with Jira for issue tracking
- **GitHub Issues**: Automatic GitHub issue creation and updates
- **DynamoDB**: Custom ticket system using DynamoDB
- **Web Dashboard**: HTML dashboard for ticket monitoring

### Ticket Features
- **Automatic Creation**: Tickets created automatically for all Security Hub findings
- **Status Tracking**: Real-time status updates for remediation progress
- **Severity Mapping**: Automatic severity to priority mapping
- **Label Management**: Automatic labeling based on finding type
- **Comment Integration**: Automatic comments for status updates
- **Webhook Support**: Real-time updates via webhooks

### Ticket Dashboard
- **Real-time Monitoring**: Live view of all tickets and their status
- **Filtering**: Filter by status, severity, and search terms
- **Statistics**: Dashboard with ticket metrics and trends
- **Responsive Design**: Works on desktop and mobile devices

## 🚀 Deployment

### Prerequisites

- AWS CLI configured
- Appropriate IAM permissions for Security Hub, Lambda, and other AWS services
- SNS topic for notifications
- GitHub Personal Access Token (for GitHub integration)

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

### Ticket System Setup

#### Option 1: Basic Ticket System (DynamoDB)
```bash
chmod +x setup-ticket-system.sh
./setup-ticket-system.sh
```

#### Option 2: GitHub Issues Integration
```bash
chmod +x setup-github-tickets.sh
./setup-github-tickets.sh
```

#### Option 3: Jira Integration
Configure the following environment variables:
- `JIRA_URL`: Your Jira instance URL
- `JIRA_USERNAME`: Your Jira username
- `JIRA_API_TOKEN`: Your Jira API token
- `JIRA_PROJECT_KEY`: Your Jira project key

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

### Ticket System Environment Variables

#### For DynamoDB Tickets
- `TICKET_TABLE_NAME`: DynamoDB table name for tickets

#### For GitHub Issues
- `GITHUB_TOKEN`: GitHub Personal Access Token
- `GITHUB_REPO`: GitHub repository (format: "owner/repo")

#### For Jira Integration
- `JIRA_URL`: Jira instance URL
- `JIRA_USERNAME`: Jira username
- `JIRA_API_TOKEN`: Jira API token
- `JIRA_PROJECT_KEY`: Jira project key

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
- DynamoDB (ticket management)
- And many other AWS services

## 🔒 Security Considerations

- The Lambda function requires appropriate IAM permissions
- Cross-account operations require proper role assumptions
- All remediations are logged and monitored
- Failed remediations are reported via SNS
- Environment variables should be encrypted
- Consider using AWS Secrets Manager for sensitive configuration
- GitHub tokens and Jira credentials should be stored securely

## 📊 Monitoring

### CloudWatch Metrics
- `RemediationSuccess`: Number of successful remediations
- `RemediationFailure`: Number of failed remediations
- `TotalRemediations`: Total number of remediations processed
- `TicketCreation`: Number of tickets created
- `TicketUpdates`: Number of ticket updates

### CloudWatch Logs
- Detailed logging for troubleshooting
- Error tracking and debugging
- Performance monitoring
- Ticket system logs

### SNS Notifications
- Success notifications for remediated findings
- Failure notifications for failed remediations
- Error notifications for system issues
- Ticket creation and update notifications

### Security Hub Integration
- Automatic finding status updates
- Remediation tracking
- Compliance reporting

### Ticket Dashboard
- Real-time ticket monitoring
- Status tracking and filtering
- Performance metrics
- Integration status

## 🧪 Testing

### Test with Sample Findings

1. **Create a test Security Hub finding**
2. **Trigger the Lambda function**
3. **Monitor CloudWatch logs**
4. **Verify SNS notifications**
5. **Check Security Hub finding status**
6. **Verify ticket creation**

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
                'ProductArn': 'arn:aws:securityhub:us-west-2::product/aws/securityhub',
                'Title': 'Test Security Finding',
                'Description': 'This is a test finding for validation'
            }
        ]
    }
}

result = lambda_handler(event, None)
print(json.dumps(result, indent=2))
"
```

### Test Ticket Integration

```bash
# Test ticket creation
python -c "
from ticket_integration_examples import TicketManager
import json

# Sample finding
finding = {
    'Id': 'test-finding-123',
    'Severity': {'Label': 'HIGH'},
    'Title': 'Test Security Finding',
    'Description': 'This is a test finding for ticket validation'
}

# Create ticket manager
ticket_manager = TicketManager()

# Create ticket
ticket_id = ticket_manager.create_ticket(finding, 'IAM')
print(f'Created ticket: {ticket_id}')

# Update ticket
ticket_manager.update_ticket(ticket_id, 'RESOLVED', 'Test resolution')
print(f'Updated ticket: {ticket_id}')
"
```

## 🔧 Troubleshooting

### Common Issues

1. **IAM Permissions**: Ensure the Lambda role has all required permissions
2. **SNS Topic**: Verify the SNS topic exists and is accessible
3. **Environment Variables**: Check that all required environment variables are set
4. **Timeout Issues**: Increase the Lambda timeout for complex remediations
5. **Memory Issues**: Increase the Lambda memory for resource-intensive operations
6. **Ticket System**: Verify ticket system configuration and credentials
7. **GitHub Integration**: Check GitHub token permissions and repository access
8. **Jira Integration**: Verify Jira credentials and project access

### Debugging

1. **Check CloudWatch Logs**: Look for error messages and stack traces
2. **Verify SNS Notifications**: Ensure notifications are being sent
3. **Test Individual Functions**: Test specific remediation functions
4. **Monitor Metrics**: Check CloudWatch metrics for performance issues
5. **Check Ticket Dashboard**: Verify ticket creation and updates
6. **Test Ticket Integrations**: Verify GitHub/Jira connectivity

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
- GitHub team for issue tracking integration
- Atlassian team for Jira integration

## 📞 Support

For support and questions:
- Create an issue in this repository
- Check the CloudWatch logs for detailed error messages
- Review the Security Hub documentation
- Consult AWS Lambda best practices
- Check ticket system documentation

## 🔄 Version History

- **v1.0.0**: Initial release with basic remediation capabilities
- **v1.1.0**: Added cross-account support and enhanced error handling
- **v1.2.0**: Added ARM64 support and comprehensive service coverage
- **v1.3.0**: Added orchestrated workflows and multi-service remediations
- **v1.4.0**: Added integrated ticket management system
- **v1.5.0**: Added GitHub Issues and Jira integration

---

**Note**: This Lambda function is designed for production use but should be thoroughly tested in your environment before deployment. Always review and customize the IAM permissions based on your specific security requirements.