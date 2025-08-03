# 🚀 GitHub Actions Lambda Deployment Guide

## 📋 Overview

This guide sets up automated deployment of the Security Hub Lambda function with cryptography support using GitHub Actions. The workflow builds the cryptography layer in a Linux environment and deploys everything automatically.

## 🎯 Benefits

✅ **Solves Cryptography Issues** - Builds in Linux environment  
✅ **Automated Deployment** - No manual intervention needed  
✅ **Version Control** - Track all changes in Git  
✅ **Testing** - Automatic testing after deployment  
✅ **Monitoring** - Creates CloudWatch dashboards  
✅ **CI/CD** - Continuous integration and deployment  

## 🔧 Setup Steps

### Step 1: Create IAM User for GitHub Actions

1. **Go to AWS IAM Console**
   - Navigate to IAM > Users
   - Click "Create user"
   - Name: `github-actions-deployer`

2. **Attach Permissions**
   - Use the policy from `github-actions-iam-policy.json`
   - Or create a custom policy with the required permissions

3. **Create Access Keys**
   - Go to Security credentials tab
   - Create access key
   - Save the Access Key ID and Secret Access Key

### Step 2: Add GitHub Secrets

1. **Go to GitHub Repository**
   - Navigate to Settings > Secrets and variables > Actions

2. **Add Repository Secrets**
   ```
   AWS_ACCESS_KEY_ID = your-access-key-id
   AWS_SECRET_ACCESS_KEY = your-secret-access-key
   ```

### Step 3: Trigger Deployment

#### Option A: Automatic Deployment (Recommended)
- Push changes to `main` or `develop` branch
- Workflow triggers automatically

#### Option B: Manual Deployment
- Go to Actions tab
- Select "Deploy Security Hub Lambda with Cryptography Layer"
- Click "Run workflow"

## 📁 Workflow Files

### `.github/workflows/deploy-lambda.yml`
Main deployment workflow that:
- Builds cryptography layer in Linux environment
- Deploys Lambda function with the layer
- Tests the deployment
- Creates CloudWatch dashboard

### `.github/workflows/setup-github-secrets.yml`
Helper workflow that provides setup instructions

## 🔄 Workflow Process

1. **Checkout Code** - Gets the latest code
2. **Setup Python** - Configures Python 3.9 environment
3. **Configure AWS** - Sets up AWS credentials
4. **Build Lambda Layer** - Creates cryptography layer in Linux
5. **Publish Layer** - Uploads layer to AWS Lambda
6. **Build Deployment Package** - Creates Lambda deployment package
7. **Update Lambda Code** - Deploys new code
8. **Update Configuration** - Configures function with layer
9. **Test Function** - Validates deployment
10. **Create Dashboard** - Sets up CloudWatch monitoring
11. **Cleanup** - Removes temporary files

## 📊 What Gets Deployed

### Lambda Function
- **Name**: `enhanced-auto-remediation-lambda-arm64`
- **Runtime**: Python 3.9
- **Architecture**: ARM64
- **Memory**: 1024 MB
- **Timeout**: 900 seconds

### Lambda Layer
- **Name**: `cryptography-layer`
- **Contents**: cryptography, PyJWT
- **Architecture**: ARM64
- **Runtime**: Python 3.9

### Environment Variables
- GitHub App authentication
- SNS topic configuration
- DynamoDB table settings

## 🧪 Testing

The workflow automatically tests the deployment by:
1. Creating a test payload
2. Invoking the Lambda function
3. Checking the response
4. Validating success indicators

## 📈 Monitoring

### CloudWatch Dashboard
- **Name**: `GitHubActionsDashboard`
- **Metrics**: Duration, Errors, Invocations, Throttles
- **Region**: us-west-2

### Logs
- **Log Group**: `/aws/lambda/enhanced-auto-remediation-lambda-arm64`
- **Retention**: Default (indefinite)

## 🔍 Troubleshooting

### Common Issues

1. **AWS Credentials Error**
   - Verify secrets are correctly set
   - Check IAM permissions

2. **Layer Build Failure**
   - Check Python version compatibility
   - Verify cryptography version

3. **Lambda Update Failure**
   - Check function name exists
   - Verify region is correct

### Debug Steps

1. **Check Workflow Logs**
   - Go to Actions tab
   - Click on failed workflow
   - Review step logs

2. **Test Manually**
   ```bash
   aws lambda invoke --function-name enhanced-auto-remediation-lambda-arm64 --payload file://test-payload.json response.json
   ```

3. **Check CloudWatch Logs**
   ```bash
   aws logs get-log-events --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda-arm64" --log-stream-name "latest"
   ```

## 🚀 Next Steps

After successful deployment:

1. **Monitor GitHub Issues**
   - Check for new issues at: https://github.com/Yayati-tech/Agent-Hubble/issues

2. **Test with Real Findings**
   - Trigger Security Hub findings
   - Verify GitHub issues are created

3. **Monitor Performance**
   - Check CloudWatch dashboard
   - Review Lambda metrics

4. **Set up Alerts**
   - Configure CloudWatch alarms
   - Set up SNS notifications

## 📝 Files Created

- `.github/workflows/deploy-lambda.yml` - Main deployment workflow
- `.github/workflows/setup-github-secrets.yml` - Setup guide workflow
- `github-actions-iam-policy.json` - IAM policy template
- `GITHUB_ACTIONS_SETUP.md` - This setup guide

## 🎉 Success Indicators

✅ Workflow completes without errors  
✅ Lambda function test passes  
✅ CloudWatch dashboard created  
✅ GitHub issues are created for Security Hub findings  
✅ No cryptography compilation errors  

---

**🎯 Result**: Fully automated deployment with cryptography support and GitHub issues creation! 