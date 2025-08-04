# GitHub Authentication Guide for Security Hub Ticketing

This guide explains how to set up GitHub authentication for the Security Hub auto-remediation Lambda function.

## 🔐 Current GitHub App Configuration

The system is currently configured with a working GitHub App:

- **App ID**: `1719742`
- **Installation ID**: `78968584`
- **Repository**: `Yayati-tech/Agent-Hubble`
- **Status**: ✅ Active and working

## 🚀 Quick Setup Guide

### For Production (GitHub App - Recommended)

The GitHub App is already configured and working. If you need to set up a new one:

#### 1. Create GitHub App
1. Go to: https://github.com/settings/apps
2. Click "New GitHub App"
3. Configure with:
   - **App name**: Security Hub Ticketing
   - **Homepage URL**: https://your-domain.com
   - **Repository permissions**:
     - Contents: Read & write
     - Issues: Read & write
     - Metadata: Read-only

#### 2. Install App in Repository
1. Go to your repository → Settings → Integrations → GitHub Apps
2. Find "Security Hub Ticketing" and click "Install"
3. Choose "All repositories" or select specific repositories
4. Click "Install"

#### 3. Get App Credentials
1. Go to: https://github.com/settings/apps/1719742
2. Note the **App ID** and **Installation ID**
3. Download the **Private Key** (PEM format)

#### 4. Configure Lambda Environment
```bash
# Update Lambda environment variables
aws lambda update-function-configuration \
    --function-name enhanced-auto-remediation-lambda \
    --environment '{
        "Variables": {
            "GITHUB_AUTH_TYPE": "github_app",
            "GITHUB_REPO": "Yayati-tech/Agent-Hubble",
            "GITHUB_AUTH_VALUE": "{\"app_id\":\"YOUR_APP_ID\",\"installation_id\":\"YOUR_INSTALLATION_ID\",\"private_key\":\"-----BEGIN RSA PRIVATE KEY-----\\n...\\n-----END RSA PRIVATE KEY-----\\n\"}"
        }
    }'
```

## 🔧 Testing GitHub Integration

### Test GitHub App Access
```bash
# Run the test script
cd scripts/github
python test-github-access.py
```

### Test Lambda Function
```bash
# Create test event
echo '{"detail":{"findings":[{"Id":"test-finding","Severity":{"Label":"HIGH"},"Compliance":{"Status":"FAILED"},"ProductArn":"arn:aws:securityhub:us-west-2:002616177731:product/aws/securityhub"}]}}' > test-event.json

# Invoke Lambda
aws lambda invoke \
    --function-name enhanced-auto-remediation-lambda \
    --payload file://test-event.json \
    response.json \
    --cli-binary-format raw-in-base64-out

# Check response
cat response.json
```

### Check CloudWatch Logs
```bash
# Get latest log stream
aws logs describe-log-streams \
    --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda" \
    --order-by LastEventTime \
    --descending \
    --max-items 1

# View logs
aws logs get-log-events \
    --log-group-name "/aws/lambda/enhanced-auto-remediation-lambda" \
    --log-stream-name "STREAM_NAME_FROM_ABOVE"
```

## ✅ Verification Steps

### 1. GitHub App Authentication
- ✅ App ID and Installation ID are valid
- ✅ Private key is properly formatted
- ✅ App has access to target repository

### 2. Issue Creation
- ✅ GitHub issues are created with proper labels
- ✅ Labels use underscores (not hyphens): `auto_remediation`
- ✅ Issues include finding details and remediation information

### 3. Issue Updates
- ✅ Issues are updated with status information
- ✅ Comments are added with remediation results
- ✅ Labels are updated based on remediation status

## 🔒 Security Best Practices

### 1. GitHub App Security
- ✅ Use GitHub Apps instead of Personal Access Tokens
- ✅ Fine-grained permissions (only what's needed)
- ✅ Automatic token rotation
- ✅ Installation-based access control

### 2. Credential Management
- ✅ Store credentials in Lambda environment variables
- ✅ Use AWS Secrets Manager for enterprise deployments
- ✅ Never commit credentials to code
- ✅ Rotate private keys regularly

### 3. Monitoring
- ✅ Monitor CloudWatch logs for authentication errors
- ✅ Set up CloudWatch alarms for failed authentications
- ✅ Review GitHub App permissions regularly

## 🆘 Troubleshooting

### Common Issues

#### 1. "Integration not found" (404 error)
- **Cause**: GitHub App doesn't exist or wrong App ID
- **Solution**: Create new GitHub App or verify App ID

#### 2. "Repository access failed"
- **Cause**: GitHub App not installed in repository
- **Solution**: Install GitHub App in target repository

#### 3. "Label validation failed"
- **Cause**: Label names contain invalid characters
- **Solution**: Use underscores instead of hyphens in labels

#### 4. "JWT token generation failed"
- **Cause**: Invalid private key format
- **Solution**: Ensure private key is in PEM format with proper newlines

### Debug Commands

```bash
# Test GitHub App installation
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://api.github.com/app/installations

# Test repository access
curl -H "Authorization: Bearer YOUR_INSTALLATION_TOKEN" \
  https://api.github.com/repos/Yayati-tech/Agent-Hubble

# Check rate limits
curl -H "Authorization: Bearer YOUR_INSTALLATION_TOKEN" \
  https://api.github.com/rate_limit
```

## 📊 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| GitHub App | ✅ Active | App ID: 1719742 |
| Installation | ✅ Active | Installation ID: 78968584 |
| Repository Access | ✅ Working | Yayati-tech/Agent-Hubble |
| Issue Creation | ✅ Working | Creates issues with proper labels |
| Issue Updates | ✅ Working | Updates with status and comments |
| Fallback System | ✅ Working | DynamoDB tickets as backup |

## 🎯 Next Steps

1. **Monitor**: Watch CloudWatch logs for any authentication issues
2. **Test**: Run test events to verify GitHub issue creation
3. **Scale**: Configure for additional repositories if needed
4. **Secure**: Consider moving to AWS Secrets Manager for enterprise use

---

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review CloudWatch logs for detailed error messages
- Test GitHub App access using the provided scripts
- Create an issue in the repository for persistent problems 