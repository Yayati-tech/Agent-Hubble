# 🔐 GitHub Secrets Setup - Visual Guide

## 📋 Overview

This guide walks you through setting up GitHub secrets for the Lambda deployment workflow. You'll need to create an AWS IAM user and add the credentials to GitHub.

## 🎯 What You'll Need

- AWS Account access
- GitHub repository access
- About 10-15 minutes

## 🔧 Step-by-Step Setup

### Step 1: Create AWS IAM User

1. **Go to AWS IAM Console**
   - Open: https://console.aws.amazon.com/iam/
   - Click "Users" in the left sidebar
   - Click "Create user"

2. **Configure User**
   - **User name**: `github-actions-deployer`
   - **Access type**: Select "Programmatic access"
   - Click "Next: Permissions"

3. **Attach Permissions**
   - Select "Attach policies directly"
   - Click "Create policy"
   - Click "JSON" tab
   - Paste the policy from `github-actions-iam-policy.json`
   - Click "Next: Tags" → "Next: Review" → "Create policy"
   - Go back to user creation
   - Search for your new policy and attach it
   - Click "Next: Tags" → "Next: Review" → "Create user"

### Step 2: Create Access Keys

1. **After creating the user**
   - Click on the user name: `github-actions-deployer`
   - Go to "Security credentials" tab
   - Click "Create access key"

2. **Configure Access Key**
   - Select "Command Line Interface (CLI)"
   - Check "I understand the above recommendation"
   - Click "Next"

3. **Save Credentials**
   - **Access Key ID**: Copy this (starts with `AKIA...`)
   - **Secret Access Key**: Copy this (longer string)
   - ⚠️ **Important**: Save these securely - you won't see the secret again!

### Step 3: Add GitHub Secrets

1. **Go to GitHub Repository**
   - Navigate to your repository: https://github.com/Yayati-tech/Agent-Hubble
   - Click "Settings" tab

2. **Access Secrets**
   - In the left sidebar, click "Secrets and variables"
   - Click "Actions"

3. **Add First Secret**
   - Click "New repository secret"
   - **Name**: `AWS_ACCESS_KEY_ID`
   - **Value**: Paste your Access Key ID from Step 2
   - Click "Add secret"

4. **Add Second Secret**
   - Click "New repository secret" again
   - **Name**: `AWS_SECRET_ACCESS_KEY`
   - **Value**: Paste your Secret Access Key from Step 2
   - Click "Add secret"

### Step 4: Verify Secrets

1. **Check Secrets List**
   - You should see both secrets listed:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
   - The values will be hidden with dots (●●●●●●●●)

## 🧪 Test the Setup

### Option A: Manual Workflow Run

1. **Go to Actions Tab**
   - Click "Actions" tab in your repository
   - Find "Deploy Security Hub Lambda with Cryptography Layer"
   - Click "Run workflow"

2. **Configure Run**
   - **Branch**: Select "main"
   - **Environment**: production
   - Click "Run workflow"

3. **Monitor Progress**
   - Watch the workflow run
   - Check each step for success/failure
   - Look for any error messages

### Option B: Automatic Trigger

1. **Push Changes**
   - Make any change to the repository
   - Push to `main` branch
   - Workflow will trigger automatically

## 📊 Expected Results

### ✅ Successful Deployment

If everything works correctly, you should see:

1. **Workflow Steps**
   - ✅ Checkout code
   - ✅ Set up Python
   - ✅ Configure AWS credentials
   - ✅ Build Lambda Layer with Cryptography
   - ✅ Publish Lambda Layer
   - ✅ Build Lambda Deployment Package
   - ✅ Update Lambda Function Code
   - ✅ Update Lambda Function Configuration
   - ✅ Test Lambda Function
   - ✅ Create CloudWatch Dashboard

2. **AWS Resources**
   - Lambda layer created: `cryptography-layer`
   - Lambda function updated: `enhanced-auto-remediation-lambda-arm64`
   - CloudWatch dashboard created: `GitHubActionsDashboard`

3. **GitHub Issues**
   - New issues created for Security Hub findings
   - Proper labels applied
   - Structured templates used

## 🔍 Troubleshooting

### Common Issues

#### 1. AWS Credentials Error
```
Error: The security token included in the request is invalid
```
**Solution**: Check that your AWS credentials are correct and have proper permissions.

#### 2. Lambda Function Not Found
```
Error: Function not found: enhanced-auto-remediation-lambda-arm64
```
**Solution**: Ensure the Lambda function exists in the correct region (us-west-2).

#### 3. IAM Permissions Error
```
Error: User: arn:aws:iam::... is not authorized to perform: lambda:UpdateFunctionCode
```
**Solution**: Verify the IAM policy is attached to the user.

#### 4. Cryptography Build Error
```
Error: Failed building wheel for cryptography
```
**Solution**: This should be resolved by the Linux environment in GitHub Actions.

### Debug Steps

1. **Check Workflow Logs**
   - Go to Actions tab
   - Click on the failed workflow
   - Expand the failed step
   - Look for specific error messages

2. **Verify AWS Credentials**
   ```bash
   aws sts get-caller-identity
   ```

3. **Test Lambda Access**
   ```bash
   aws lambda get-function --function-name enhanced-auto-remediation-lambda-arm64
   ```

## 🔗 Useful Links

- **GitHub Repository**: https://github.com/Yayati-tech/Agent-Hubble
- **GitHub Actions**: https://github.com/Yayati-tech/Agent-Hubble/actions
- **GitHub Secrets**: https://github.com/Yayati-tech/Agent-Hubble/settings/secrets/actions
- **AWS Lambda**: https://console.aws.amazon.com/lambda/home?region=us-west-2#/functions/enhanced-auto-remediation-lambda-arm64
- **CloudWatch**: https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=GitHubActionsDashboard

## 🎉 Success Checklist

- [ ] AWS IAM user created with proper permissions
- [ ] Access keys generated and saved
- [ ] GitHub secrets added (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- [ ] Workflow runs successfully
- [ ] Lambda function updated with cryptography layer
- [ ] GitHub issues created for Security Hub findings
- [ ] CloudWatch dashboard created
- [ ] No cryptography compilation errors

---

**🎯 Result**: Fully automated deployment with cryptography support and GitHub issues creation! 