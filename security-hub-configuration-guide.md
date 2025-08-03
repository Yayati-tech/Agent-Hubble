# Security Hub Configuration Guide

## Step 1: Configure Security Hub to Trigger Lambda Function

This guide will help you configure AWS Security Hub to automatically trigger your enhanced auto-remediation Lambda function when security findings are generated.

### Prerequisites

1. **Lambda Function Deployed**: Ensure your Lambda function is deployed and accessible
2. **IAM Permissions**: Verify the Lambda execution role has necessary permissions
3. **SNS Topic**: Confirm the SNS topic exists for notifications
4. **Security Hub Enabled**: Security Hub must be enabled in your AWS account

### Configuration Steps

#### 1. Create EventBridge Rule

First, create an EventBridge rule to capture Security Hub findings:

```bash
# Create EventBridge rule for Security Hub findings
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
  }' \
  --description "Capture Security Hub findings for auto-remediation"
```

#### 2. Add Lambda Function as Target

Add your Lambda function as a target for the EventBridge rule:

```bash
# Add Lambda function as target
aws events put-targets \
  --rule "SecurityHubFindingsRule" \
  --targets "Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT:function:enhanced-auto-remediation-lambda"
```

#### 3. Grant EventBridge Permission to Invoke Lambda

Allow EventBridge to invoke your Lambda function:

```bash
# Add permission for EventBridge to invoke Lambda
aws lambda add-permission \
  --function-name "enhanced-auto-remediation-lambda" \
  --statement-id "EventBridgeInvoke" \
  --action "lambda:InvokeFunction" \
  --principal "events.amazonaws.com" \
  --source-arn "arn:aws:events:REGION:ACCOUNT:rule/SecurityHubFindingsRule"
```

#### 4. Configure Security Hub Integration (Optional)

If you want to integrate with Security Hub's custom actions:

```bash
# Create custom action in Security Hub
aws securityhub create-action-target \
  --name "AutoRemediation" \
  --description "Automatically remediate security findings" \
  --id "AutoRemediationAction"
```

#### 5. Enable Security Hub Controls

Enable the Security Hub controls you want to monitor:

```bash
# Enable Security Hub controls
aws securityhub batch-enable-standards \
  --standards-subscription-requests '[
    {
      "StandardsArn": "arn:aws:securityhub:REGION::standards/aws-foundational-security-best-practices/v/1.0.0"
    }
  ]'
```

### Advanced Configuration

#### Custom Event Pattern

For more specific filtering, you can customize the event pattern:

```json
{
  "source": ["aws.securityhub"],
  "detail-type": ["Security Hub Findings - Imported"],
  "detail": {
    "findings": {
      "Severity": {
        "Label": ["HIGH", "CRITICAL"]
      },
      "ProductArn": {
        "anything-but": ["arn:aws:securityhub:REGION::product/aws/guardduty"]
      }
    }
  }
}
```

#### Multiple Severity Levels

To capture different severity levels with different actions:

```bash
# Create rule for CRITICAL findings
aws events put-rule \
  --name "SecurityHubCriticalFindings" \
  --event-pattern '{
    "source": ["aws.securityhub"],
    "detail-type": ["Security Hub Findings - Imported"],
    "detail": {
      "findings": {
        "Severity": {
          "Label": ["CRITICAL"]
        }
      }
    }
  }'

# Create rule for HIGH findings
aws events put-rule \
  --name "SecurityHubHighFindings" \
  --event-pattern '{
    "source": ["aws.securityhub"],
    "detail-type": ["Security Hub Findings - Imported"],
    "detail": {
      "findings": {
        "Severity": {
          "Label": ["HIGH"]
        }
      }
    }
  }'
```

### Verification Steps

#### 1. Test the Configuration

Create a test finding to verify the setup:

```bash
# Create a test Security Hub finding
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
      "Description": "This is a test finding for validation",
      "Remediation": {
        "Recommendation": {
          "Text": "Test remediation recommendation"
        }
      }
    }
  ]'
```

#### 2. Monitor CloudWatch Logs

Check the Lambda function logs:

```bash
# Get recent Lambda logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/enhanced-auto-remediation-lambda"

# Get log events
aws logs filter-log-events \
  --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda" \
  --start-time $(date -d '1 hour ago' +%s)000
```

#### 3. Check SNS Notifications

Verify notifications are being sent:

```bash
# List SNS topics
aws sns list-topics

# Check SNS subscriptions
aws sns list-subscriptions
```

### Troubleshooting

#### Common Issues

1. **Lambda Function Not Invoked**
   - Check EventBridge rule configuration
   - Verify Lambda permissions
   - Check CloudWatch logs for errors

2. **Permission Denied**
   - Ensure Lambda execution role has necessary permissions
   - Check Security Hub permissions
   - Verify SNS topic permissions

3. **No Findings Processed**
   - Verify Security Hub is enabled
   - Check event pattern matches
   - Ensure findings meet severity criteria

#### Debug Commands

```bash
# Check EventBridge rules
aws events list-rules --name-prefix "SecurityHub"

# Check Lambda function status
aws lambda get-function --function-name "enhanced-auto-remediation-lambda"

# Check Security Hub status
aws securityhub describe-hub

# List Security Hub findings
aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"}]}'
```

### Environment-Specific Configuration

#### For ARM64 Deployment

If using ARM64 deployment, ensure the Lambda function is configured correctly:

```bash
# Update Lambda function configuration for ARM64
aws lambda update-function-configuration \
  --function-name "enhanced-auto-remediation-lambda" \
  --architectures "arm64" \
  --timeout 900 \
  --memory-size 1024
```

#### For Cross-Account Setup

For cross-account remediation:

```bash
# Add cross-account permissions
aws lambda add-permission \
  --function-name "enhanced-auto-remediation-lambda" \
  --statement-id "CrossAccountRemediation" \
  --action "lambda:InvokeFunction" \
  --principal "arn:aws:iam::ACCOUNT_ID:root"
```

### Security Considerations

1. **Least Privilege**: Ensure Lambda role has minimal required permissions
2. **Encryption**: Use KMS encryption for sensitive data
3. **Monitoring**: Set up CloudWatch alarms for failed remediations
4. **Auditing**: Enable CloudTrail for API call logging
5. **Backup**: Regular backups of configuration and code

### Next Steps

After completing this configuration:

1. **Test with Real Findings**: Monitor actual Security Hub findings
2. **Set Up Monitoring**: Configure CloudWatch alarms and dashboards
3. **Review Remediations**: Verify remediation actions are appropriate
4. **Document Procedures**: Create runbooks for manual intervention
5. **Regular Reviews**: Schedule periodic reviews of remediation effectiveness

### Support

For additional support:
- Check CloudWatch logs for detailed error messages
- Review Security Hub documentation
- Consult AWS Lambda best practices
- Monitor SNS notifications for system alerts 