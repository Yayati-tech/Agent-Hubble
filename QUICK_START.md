# Quick Start Guide: Security Hub Auto-Remediation

This guide will help you quickly set up the Security Hub auto-remediation system with your enhanced Lambda function.

## 🚀 Quick Setup (5 minutes)

### Step 1: Deploy the Lambda Function

First, deploy your Lambda function using one of the provided deployment scripts:

```bash
# For ARM64 deployment (recommended for cost optimization)
chmod +x deploy-arm64.sh
./deploy-arm64.sh

# OR for standard deployment
chmod +x deploy.sh
./deploy.sh
```

### Step 2: Configure Security Hub Integration

Run the Security Hub configuration script:

```bash
chmod +x setup-security-hub.sh
./setup-security-hub.sh
```

This script will automatically:
- ✅ Create EventBridge rule for Security Hub findings
- ✅ Add Lambda function as target
- ✅ Grant necessary permissions
- ✅ Create SNS topic for notifications
- ✅ Enable Security Hub standards
- ✅ Create a test finding to verify setup

### Step 3: Verify the Setup

Monitor the logs to ensure everything is working:

```bash
# Monitor Lambda function logs
aws logs tail /aws/lambda/enhanced-auto-remediation-lambda --follow

# Check SNS notifications
aws sns list-subscriptions

# List Security Hub findings
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"}]}'
```

## 📋 Prerequisites

Before running the setup, ensure you have:

1. **AWS CLI installed and configured**
   ```bash
   aws --version
   aws configure
   ```

2. **Security Hub enabled** in your AWS account
   - Go to AWS Console → Security Hub
   - Click "Enable Security Hub"

3. **Appropriate IAM permissions** for:
   - Lambda
   - EventBridge
   - Security Hub
   - SNS
   - CloudWatch

## 🔧 Manual Configuration (Alternative)

If you prefer to configure manually, follow these steps:

### 1. Create EventBridge Rule

```bash
aws events put-rule \
  --name "SecurityHubFindingsRule" \
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
```

### 2. Add Lambda Target

```bash
aws events put-targets \
  --rule "SecurityHubFindingsRule" \
  --targets "Id=1,Arn=arn:aws:lambda:REGION:ACCOUNT:function:enhanced-auto-remediation-lambda"
```

### 3. Grant Lambda Permission

```bash
aws lambda add-permission \
  --function-name "enhanced-auto-remediation-lambda" \
  --statement-id "EventBridgeInvoke" \
  --action "lambda:InvokeFunction" \
  --principal "events.amazonaws.com" \
  --source-arn "arn:aws:events:REGION:ACCOUNT:rule/SecurityHubFindingsRule"
```

## 🧪 Testing

### Create a Test Finding

```bash
aws securityhub batch-import-findings \
  --findings '[
    {
      "Id": "test-finding-123",
      "ProductArn": "arn:aws:securityhub:REGION::product/aws/securityhub",
      "GeneratorId": "test-generator",
      "AwsAccountId": "YOUR_ACCOUNT_ID",
      "Types": ["Software and Configuration Checks/AWS Security Best Practices"],
      "CreatedAt": "2024-01-01T00:00:00Z",
      "UpdatedAt": "2024-01-01T00:00:00Z",
      "Severity": {
        "Label": "HIGH"
      },
      "Title": "Test Security Finding",
      "Description": "This is a test finding for validation"
    }
  ]'
```

### Monitor Execution

```bash
# Check Lambda logs
aws logs filter-log-events \
  --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda" \
  --start-time $(date -d '1 hour ago' +%s)000

# Check SNS notifications
aws sns list-topics
```

## 🔍 Troubleshooting

### Common Issues

1. **Lambda function not invoked**
   - Check EventBridge rule configuration
   - Verify Lambda permissions
   - Check CloudWatch logs

2. **Permission denied errors**
   - Ensure Lambda execution role has necessary permissions
   - Check Security Hub permissions
   - Verify SNS topic permissions

3. **No findings processed**
   - Verify Security Hub is enabled
   - Check event pattern matches
   - Ensure findings meet severity criteria

### Debug Commands

```bash
# Check EventBridge rules
aws events list-rules --name-prefix "SecurityHub"

# Check Lambda function status
aws lambda get-function --function-name "enhanced-auto-remediation-lambda"

# Check Security Hub status
aws securityhub describe-hub

# Check SNS topics
aws sns list-topics
```

## 📊 Monitoring

### CloudWatch Metrics

Monitor these CloudWatch metrics:
- `RemediationSuccess`: Successful remediations
- `RemediationFailure`: Failed remediations
- `TotalRemediations`: Total processed
- `TicketCreation`: Tickets created

### CloudWatch Alarms

Set up alarms for:
- Failed remediations
- Lambda function errors
- High error rates

## 🎯 Next Steps

After successful setup:

1. **Review remediations**: Ensure automatic actions are appropriate
2. **Set up monitoring**: Configure CloudWatch alarms and dashboards
3. **Test with real findings**: Monitor actual Security Hub findings
4. **Customize rules**: Adjust event patterns for your needs
5. **Document procedures**: Create runbooks for manual intervention

## 📞 Support

For additional help:
- Check CloudWatch logs for detailed error messages
- Review the comprehensive configuration guide
- Consult AWS Security Hub documentation
- Monitor SNS notifications for system alerts

---

**Note**: This setup provides automatic remediation for HIGH and CRITICAL Security Hub findings. Adjust the event pattern in the EventBridge rule if you need different severity levels or specific finding types. 