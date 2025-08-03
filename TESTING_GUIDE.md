# Security Hub Ticketing System Testing Guide

This guide provides comprehensive testing instructions for the Security Hub Auto-Remediation Ticketing System.

## 🎯 Overview

The ticketing system supports three platforms:
1. **DynamoDB** (default fallback)
2. **GitHub Issues**
3. **Jira**

## 🚀 Quick Start Testing

### 1. Basic Logic Testing (No AWS Required)

Test the core ticketing logic without external dependencies:

```bash
# Set required environment variable
export TICKET_TABLE_NAME="SecurityHubTickets"

# Run basic tests
python3 test-ticketing-basic.py
```

This will test:
- Environment variable configuration
- Finding parsing and categorization
- Ticket data structure creation
- Lambda payload format validation
- Severity to priority mapping
- Ticket ID generation patterns
- Error handling scenarios

### 2. Comprehensive Testing (AWS Required)

Test all integrations with AWS credentials:

```bash
# Run comprehensive tests
python3 test-ticketing-system.py
```

This will test:
- AWS credentials and connectivity
- DynamoDB table setup and access
- GitHub integration (if configured)
- Jira integration (if configured)
- Lambda function deployment and configuration
- Ticket creation and updates
- Lambda function invocation

## 📋 Prerequisites

### For Basic Testing
- Python 3.7+
- Required environment variables:
  - `TICKET_TABLE_NAME` (default: "SecurityHubTickets")

### For Comprehensive Testing
- AWS CLI configured with valid credentials
- Python 3.7+ with boto3 and requests
- Optional: GitHub Personal Access Token
- Optional: Jira API credentials

## 🔧 Setup Instructions

### 1. Install Dependencies

```bash
# Install required Python packages
pip install boto3 requests

# Or install from requirements.txt
pip install -r requirements.txt
```

### 2. Configure Environment Variables

```bash
# Required
export TICKET_TABLE_NAME="SecurityHubTickets"

# Optional - GitHub Integration
export GITHUB_TOKEN="your_github_token"
export GITHUB_REPO="owner/repo"

# Optional - Jira Integration
export JIRA_URL="https://your-domain.atlassian.net"
export JIRA_USERNAME="your_email"
export JIRA_API_TOKEN="your_api_token"
export JIRA_PROJECT_KEY="PROJECT"
```

### 3. Deploy Lambda Function (if not already deployed)

```bash
# Deploy the enhanced Lambda function
chmod +x deploy-arm64.sh
./deploy-arm64.sh
```

### 4. Set Up Ticketing System

```bash
# Run the comprehensive setup
chmod +x setup-ticketing-system.sh
./setup-ticketing-system.sh
```

## 🧪 Test Scenarios

### Scenario 1: DynamoDB Only Testing

**Objective**: Test the basic DynamoDB fallback system

**Setup**:
```bash
export TICKET_TABLE_NAME="SecurityHubTickets"
```

**Test Commands**:
```bash
# Run basic tests
python3 test-ticketing-basic.py

# Run comprehensive tests (requires AWS credentials)
python3 test-ticketing-system.py
```

**Expected Results**:
- ✅ All basic tests pass
- ✅ DynamoDB table accessible
- ✅ Ticket creation and updates work
- ⚠️ GitHub and Jira tests skipped (not configured)

### Scenario 2: GitHub Integration Testing

**Objective**: Test GitHub Issues integration

**Setup**:
```bash
export TICKET_TABLE_NAME="SecurityHubTickets"
export GITHUB_TOKEN="your_github_token"
export GITHUB_REPO="your-username/your-repo"
```

**Test Commands**:
```bash
python3 test-ticketing-system.py
```

**Expected Results**:
- ✅ GitHub token valid
- ✅ Repository accessible
- ✅ Issue creation works
- ✅ Labels are created automatically

### Scenario 3: Jira Integration Testing

**Objective**: Test Jira integration

**Setup**:
```bash
export TICKET_TABLE_NAME="SecurityHubTickets"
export JIRA_URL="https://your-domain.atlassian.net"
export JIRA_USERNAME="your_email"
export JIRA_API_TOKEN="your_api_token"
export JIRA_PROJECT_KEY="PROJECT"
```

**Test Commands**:
```bash
python3 test-ticketing-system.py
```

**Expected Results**:
- ✅ Jira credentials valid
- ✅ Project accessible
- ✅ Ticket creation works
- ✅ Priority mapping works

### Scenario 4: Lambda Function Testing

**Objective**: Test the deployed Lambda function

**Prerequisites**:
- Lambda function deployed
- AWS credentials configured
- Environment variables set

**Test Commands**:
```bash
# Test Lambda function directly
aws lambda invoke \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --payload file://test-payload.json \
  response.json

# Check response
cat response.json
```

**Expected Results**:
- ✅ Lambda function found
- ✅ Environment variables configured
- ✅ Function invocation successful
- ✅ Tickets created in configured system

## 📊 Test Payloads

### Basic Test Payload

```json
{
  "detail": {
    "findings": [
      {
        "Id": "test-finding-001",
        "Title": "Test Security Finding",
        "Description": "This is a test finding for ticketing system validation",
        "Severity": {"Label": "HIGH"},
        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
      }
    ]
  }
}
```

### Multiple Service Test Payload

```json
{
  "detail": {
    "findings": [
      {
        "Id": "test-iam-finding-001",
        "Title": "IAM User without MFA",
        "Description": "Test finding for IAM user without multi-factor authentication",
        "Severity": {"Label": "HIGH"},
        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
      },
      {
        "Id": "test-s3-finding-002",
        "Title": "S3 Bucket Public Access",
        "Description": "Test finding for S3 bucket with public access enabled",
        "Severity": {"Label": "CRITICAL"},
        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/s3"
      },
      {
        "Id": "test-ec2-finding-003",
        "Title": "Unused EC2 Instance",
        "Description": "Test finding for unused EC2 instance",
        "Severity": {"Label": "MEDIUM"},
        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/ec2"
      }
    ]
  }
}
```

## 🔍 Manual Testing Steps

### 1. Test DynamoDB Integration

```bash
# Check if table exists
aws dynamodb describe-table --table-name SecurityHubTickets

# List all tickets
aws dynamodb scan --table-name SecurityHubTickets

# Query specific ticket
aws dynamodb query \
  --table-name SecurityHubTickets \
  --key-condition-expression "ticket_id = :id" \
  --expression-attribute-values '{":id":{"S":"TICKET-20231201123456"}}'
```

### 2. Test GitHub Integration

```bash
# Check if issues are created
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPO/issues

# Check if labels exist
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_REPO/labels
```

### 3. Test Jira Integration

```bash
# Check if tickets are created
curl -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/2/search?jql=project=$JIRA_PROJECT_KEY"
```

### 4. Test Lambda Function

```bash
# Invoke Lambda with test payload
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

# Check response
cat response.json
```

## 🐛 Troubleshooting

### Common Issues

#### 1. AWS Credentials Expired
```bash
# Reconfigure AWS credentials
aws configure
```

#### 2. DynamoDB Table Not Found
```bash
# Create the table
aws dynamodb create-table \
  --table-name SecurityHubTickets \
  --attribute-definitions AttributeName=ticket_id,AttributeType=S \
  --key-schema AttributeName=ticket_id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

#### 3. GitHub Token Invalid
```bash
# Test GitHub token
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

#### 4. Jira Credentials Invalid
```bash
# Test Jira credentials
curl -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/2/myself"
```

#### 5. Lambda Function Not Found
```bash
# Deploy Lambda function
./deploy-arm64.sh
```

### Debug Commands

```bash
# Check Lambda environment variables
aws lambda get-function-configuration \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --query 'Environment.Variables'

# Check CloudWatch logs
aws logs tail /aws/lambda/enhanced-auto-remediation-lambda-arm64 --follow

# Check DynamoDB table
aws dynamodb describe-table --table-name SecurityHubTickets
```

## 📈 Performance Testing

### Load Testing

```bash
# Test with multiple findings
for i in {1..10}; do
  aws lambda invoke \
    --function-name enhanced-auto-remediation-lambda-arm64 \
    --payload "{\"detail\":{\"findings\":[{\"Id\":\"test-$i\",\"Title\":\"Test $i\",\"Severity\":{\"Label\":\"HIGH\"},\"ProductArn\":\"arn:aws:securityhub:us-west-2::product/aws/iam\"}]}}" \
    response-$i.json
done
```

### Monitoring

```bash
# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=enhanced-auto-remediation-lambda-arm64 \
  --start-time $(date -d '1 hour ago' --iso-8601) \
  --end-time $(date --iso-8601) \
  --period 300 \
  --statistics Average
```

## ✅ Success Criteria

A successful test run should show:

### Basic Tests
- ✅ All environment variables configured
- ✅ Finding parsing works correctly
- ✅ Ticket data structure valid
- ✅ Lambda payload format correct
- ✅ Severity mapping works
- ✅ Ticket ID generation works
- ✅ Error handling graceful

### Comprehensive Tests
- ✅ AWS credentials valid
- ✅ DynamoDB table accessible
- ✅ GitHub integration working (if configured)
- ✅ Jira integration working (if configured)
- ✅ Lambda function deployed and configured
- ✅ Ticket creation successful
- ✅ Lambda invocation successful

## 📝 Test Report Template

After running tests, document your results:

```markdown
# Ticketing System Test Report

**Date**: [Date]
**Tester**: [Name]
**Environment**: [AWS Region, Account ID]

## Test Results

### Basic Tests
- [ ] Environment Variables
- [ ] Finding Parsing
- [ ] Ticket Data Structure
- [ ] Lambda Payload Format
- [ ] Severity Mapping
- [ ] Ticket ID Generation
- [ ] Error Handling

### Comprehensive Tests
- [ ] AWS Credentials
- [ ] DynamoDB Setup
- [ ] GitHub Integration
- [ ] Jira Integration
- [ ] Lambda Function
- [ ] Ticket Creation
- [ ] Lambda Invocation

## Issues Found
[List any issues encountered]

## Recommendations
[List any recommendations for improvement]
```

## 🎯 Next Steps

After successful testing:

1. **Deploy to Production**: Use the setup scripts to deploy to production
2. **Monitor**: Set up CloudWatch alarms and monitoring
3. **Document**: Update documentation with any customizations
4. **Train**: Train team members on the ticketing system
5. **Maintain**: Regular testing and updates

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review CloudWatch logs for detailed error information
- Create an issue in the GitHub repository
- Consult the main README.md for additional information 