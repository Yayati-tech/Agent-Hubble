# Security Hub Auto-Remediation Ticketing System

This repository now includes a comprehensive ticketing system that automatically creates tickets for Security Hub findings and updates them based on remediation results.

## 🎫 Features

### Multi-Platform Support
- **DynamoDB**: Built-in ticket storage (default)
- **GitHub Issues**: Create issues in GitHub repositories
- **Jira**: Create tickets in Jira projects
- **Fallback System**: Automatically falls back to DynamoDB if external systems fail

### Automatic Ticket Management
- Creates tickets for all Security Hub findings
- Updates ticket status based on remediation results
- Adds detailed comments with remediation outcomes
- Categorizes tickets by service type (IAM, S3, EC2, etc.)

### Smart Integration
- Works with existing auto-remediation system
- No disruption to current functionality
- Configurable through environment variables
- Comprehensive logging and monitoring

## 🚀 Quick Start

### 1. Deploy the Enhanced Lambda Function

```bash
# Deploy the ARM64 version (recommended for cost savings)
./deploy-arm64.sh
```

### 2. Set Up the Ticketing System

```bash
# Run the comprehensive ticketing setup
chmod +x setup-ticketing-system.sh
./setup-ticketing-system.sh
```

The setup script will guide you through:
- Choosing your ticketing system(s)
- Configuring GitHub Issues (optional)
- Configuring Jira (optional)
- Setting up DynamoDB table
- Updating Lambda environment variables

### 3. Test the System

```bash
# Test ticket creation with a sample finding
aws lambda invoke \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --payload '{
    "detail": {
      "findings": [{
        "Id": "test-finding-001",
        "Title": "Test Security Finding",
        "Description": "This is a test finding for ticketing system validation",
        "Severity": {"Label": "HIGH"},
        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
      }]
    }
  }' \
  response.json
```

## 📋 Configuration Options

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `TICKET_TABLE_NAME` | DynamoDB table for tickets | Yes |
| `GITHUB_TOKEN` | GitHub Personal Access Token | No |
| `GITHUB_REPO` | GitHub repository (owner/repo) | No |
| `JIRA_URL` | Jira instance URL | No |
| `JIRA_USERNAME` | Jira username | No |
| `JIRA_API_TOKEN` | Jira API token | No |
| `JIRA_PROJECT_KEY` | Jira project key | No |

### Ticket System Priority

The system tries to create tickets in this order:
1. **Jira** (if configured)
2. **GitHub Issues** (if configured)
3. **DynamoDB** (fallback)

## 🎯 Supported Services

The ticketing system automatically categorizes findings by service:

| Service | Detection | Ticket Category |
|---------|-----------|-----------------|
| IAM | `IAM` in ProductArn | IAM |
| S3 | `S3` in ProductArn | S3 |
| EC2 | `EC2` in ProductArn | EC2 |
| RDS | `RDS` in ProductArn | RDS |
| Lambda | `Lambda` in ProductArn | Lambda |
| KMS | `KMS` in ProductArn | KMS |
| GuardDuty | `GuardDuty` in ProductArn | GuardDuty |
| Inspector | `Inspector` in ProductArn | Inspector |
| SSM | `SSM` in ProductArn | SSM |
| Macie | `Macie` in ProductArn | Macie |
| WAF | `WAF` in ProductArn | WAF |
| ACM | `ACM` in ProductArn | ACM |
| SecretsManager | `SecretsManager` in ProductArn | SecretsManager |
| CloudFormation | `CloudFormation` in ProductArn | CloudFormation |
| APIGateway | `APIGateway` in ProductArn | APIGateway |
| ElastiCache | `ElastiCache` in ProductArn | ElastiCache |
| DynamoDB | `DynamoDB` in ProductArn | DynamoDB |
| EKS | `EKS` in ProductArn | EKS |
| ECR | `ECR` in ProductArn | ECR |
| ECS | `ECS` in ProductArn | ECS |
| Redshift | `Redshift` in ProductArn | Redshift |
| SageMaker | `SageMaker` in ProductArn | SageMaker |
| Glue | `Glue` in ProductArn | Glue |

## 📊 Ticket Information

Each ticket includes:

### Basic Information
- **Ticket ID**: Unique identifier (JIRA-XXX, GH-XXX, or TICKET-XXX)
- **Finding ID**: Original Security Hub finding ID
- **Title**: Security finding title
- **Description**: Detailed finding description
- **Severity**: HIGH, MEDIUM, LOW, CRITICAL
- **Service Type**: Categorized by AWS service

### Status Tracking
- **Created**: Ticket created for finding
- **SUCCESS**: Remediation completed successfully
- **FAILED**: Remediation failed

### Timestamps
- **Created At**: When the ticket was created
- **Updated At**: When the ticket was last updated

## 🔧 GitHub Integration

### Setup
1. Create a GitHub Personal Access Token with `repo` and `issues` permissions
2. Run the setup script and choose GitHub integration
3. Provide your repository in `owner/repo` format

### Features
- Automatic issue creation for findings
- Pre-configured labels for categorization
- Status updates with comments
- Markdown-formatted descriptions

### Labels Created
- `security-hub`: All Security Hub findings
- `auto-remediation`: Auto-remediation enabled
- Service-specific labels: `IAM`, `S3`, `EC2`, etc.

## 🔧 Jira Integration

### Setup
1. Create a Jira API token
2. Run the setup script and choose Jira integration
3. Provide your Jira URL, username, API token, and project key

### Features
- Automatic ticket creation for findings
- Priority mapping based on severity
- Status transitions (configurable)
- Rich text descriptions

### Priority Mapping
- **CRITICAL** → Highest
- **HIGH** → High
- **MEDIUM** → Medium
- **LOW** → Low

## 📊 DynamoDB Integration

### Default Fallback
- No external dependencies
- Automatic table creation
- Full ticket history
- Query and scan capabilities

### Table Schema
```json
{
  "ticket_id": "TICKET-20231201123456",
  "finding_id": "arn:aws:securityhub:us-west-2:123456789012:subscription/aws-foundational-security-best-practices/v/1.0.0/IAM.1/finding/12345678-1234-1234-1234-123456789012",
  "title": "Security finding title",
  "description": "Detailed finding description",
  "severity": "HIGH",
  "remediation_type": "IAM",
  "status": "SUCCESS",
  "created_at": "2023-12-01T12:34:56.789Z",
  "updated_at": "2023-12-01T12:35:00.123Z"
}
```

## 📈 Monitoring and Logging

### CloudWatch Logs
```bash
# Monitor Lambda execution
aws logs tail /aws/lambda/enhanced-auto-remediation-lambda-arm64 --follow
```

### DynamoDB Queries
```bash
# List all tickets
aws dynamodb scan --table-name SecurityHubTickets

# Query tickets by status
aws dynamodb query \
  --table-name SecurityHubTickets \
  --key-condition-expression "ticket_id = :id" \
  --expression-attribute-values '{":id":{"S":"TICKET-20231201123456"}}'
```

### GitHub Issues
- Check your GitHub repository for created issues
- Issues are labeled and categorized automatically
- Comments are added for status updates

### Jira Tickets
- Check your Jira project for created tickets
- Tickets include priority and severity mapping
- Status transitions are logged

## 🛠️ Customization

### Custom Ticket Templates

You can customize ticket descriptions by modifying the `_format_jira_description()` and `_format_github_description()` methods in the `TicketManager` class.

### Additional Labels/Tags

Add custom labels or tags by modifying the label arrays in the setup script or the ticket creation methods.

### Status Workflows

Customize Jira status transitions by implementing the `_get_jira_status_transition()` method with your specific workflow IDs.

## 🔒 Security Considerations

### GitHub Token
- Use Personal Access Tokens with minimal required permissions
- Store tokens securely (consider AWS Secrets Manager)
- Rotate tokens regularly

### Jira Credentials
- Use API tokens instead of passwords
- Store credentials securely
- Implement proper access controls

### DynamoDB
- Use IAM roles with least privilege
- Enable encryption at rest
- Monitor access patterns

## 🚨 Troubleshooting

### Common Issues

1. **GitHub Token Invalid**
   - Verify token has correct permissions
   - Check token hasn't expired
   - Ensure repository access

2. **Jira Connection Failed**
   - Verify URL format
   - Check credentials
   - Ensure project key exists

3. **DynamoDB Permissions**
   - Verify Lambda role has DynamoDB permissions
   - Check table exists in correct region

4. **Environment Variables**
   - Verify all required variables are set
   - Check Lambda function configuration

### Debug Commands

```bash
# Check Lambda environment variables
aws lambda get-function-configuration \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --query 'Environment.Variables'

# Test DynamoDB access
aws dynamodb describe-table --table-name SecurityHubTickets

# Check CloudWatch logs for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/enhanced-auto-remediation-lambda-arm64 \
  --filter-pattern "ERROR"
```

## 📚 API Reference

### TicketManager Class

#### Methods
- `create_ticket(finding, remediation_type)`: Create a ticket for a finding
- `update_ticket(ticket_id, status, message, error)`: Update ticket status
- `create_jira_ticket(ticket_data)`: Create Jira ticket
- `create_github_issue(ticket_data)`: Create GitHub issue
- `create_dynamodb_ticket(ticket_data)`: Create DynamoDB ticket

#### Ticket Data Structure
```python
{
    'finding_id': 'finding-arn',
    'severity': 'HIGH',
    'title': 'Finding title',
    'description': 'Finding description',
    'remediation_type': 'IAM',
    'status': 'CREATED',
    'created_at': '2023-12-01T12:34:56.789Z',
    'updated_at': '2023-12-01T12:34:56.789Z'
}
```

## 🤝 Contributing

To contribute to the ticketing system:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Update documentation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section
- Review CloudWatch logs for detailed error information 