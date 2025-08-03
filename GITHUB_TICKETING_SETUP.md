# GitHub Ticketing Setup Guide

This guide provides step-by-step instructions for setting up GitHub ticketing integration with the Security Hub Auto-Remediation system using different authentication methods.

## 🎯 Overview

The enhanced GitHub ticketing system supports multiple authentication methods:

1. **Personal Access Token** - Quick setup for development
2. **GitHub App** - Recommended for production
3. **OAuth App** - For web applications
4. **AWS Secrets Manager** - Most secure for enterprise
5. **GitHub Actions** - For CI/CD environments

## 🚀 Quick Start

### Option 1: Personal Access Token (Easiest)

```bash
# 1. Create GitHub Personal Access Token
# Go to: https://github.com/settings/tokens
# Create token with 'repo' and 'issues' permissions

# 2. Set environment variables
export GITHUB_TOKEN="your_token_here"
export GITHUB_REPO="your-username/your-repo"

# 3. Run enhanced setup
./setup-github-tickets-enhanced.sh
# Choose option 1 (Personal Access Token)
```

### Option 2: GitHub App (Recommended for Production)

```bash
# 1. Create GitHub App
# Go to: https://github.com/settings/apps
# Configure with:
# - App name: Security Hub Ticketing
# - Homepage URL: https://your-domain.com
# - Permissions: Repository (Contents, Issues, Metadata)

# 2. Install App in your repository
# Go to your repository → Settings → Integrations → GitHub Apps

# 3. Get App credentials (App ID, Installation ID, Private Key)

# 4. Run enhanced setup
./setup-github-tickets-enhanced.sh
# Choose option 2 (GitHub App)
```

### Option 3: AWS Secrets Manager (Most Secure)

```bash
# 1. Create secret in AWS Secrets Manager
aws secretsmanager create-secret \
    --name "github-ticketing-credentials" \
    --description "GitHub credentials for Security Hub ticketing" \
    --secret-string '{"github_token":"your_token","github_repo":"owner/repo"}'

# 2. Run enhanced setup
./setup-github-tickets-enhanced.sh
# Choose option 4 (AWS Secrets Manager)
```

## 📋 Detailed Setup Instructions

### 1. Personal Access Token Setup

#### Step 1: Create GitHub Token
1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Security Hub Ticketing")
4. Select scopes:
   - `repo` (Full control of private repositories)
   - `issues` (Full control of issues)
5. Click "Generate token"
6. Copy the token (you won't see it again!)

#### Step 2: Configure Environment
```bash
export GITHUB_TOKEN="ghp_your_token_here"
export GITHUB_REPO="your-username/your-repo"
```

#### Step 3: Run Setup
```bash
./setup-github-tickets-enhanced.sh
# Choose option 1 when prompted
```

### 2. GitHub App Setup

#### Step 1: Create GitHub App
1. Go to [GitHub Settings > Apps](https://github.com/settings/apps)
2. Click "New GitHub App"
3. Configure the app:
   - **App name**: Security Hub Ticketing
   - **Homepage URL**: https://your-domain.com
   - **Webhook**: (optional)
   - **Repository permissions**:
     - Contents: Read & write
     - Issues: Read & write
     - Metadata: Read-only
4. Click "Create GitHub App"

#### Step 2: Install the App
1. Go to your repository
2. Navigate to Settings → Integrations → GitHub Apps
3. Find your app and click "Configure"
4. Select the repository and click "Install"

#### Step 3: Get Credentials
1. Note the **App ID** from the app settings
2. Note the **Installation ID** from the installation page
3. Download the **Private Key** (PEM file)

#### Step 4: Configure Setup
```bash
# Set environment variables
export GITHUB_APP_ID="your_app_id"
export GITHUB_INSTALLATION_ID="your_installation_id"
export GITHUB_PRIVATE_KEY="$(cat your_private_key.pem)"
export GITHUB_REPO="your-username/your-repo"

# Run setup
./setup-github-tickets-enhanced.sh
# Choose option 2 when prompted
```

### 3. AWS Secrets Manager Setup

#### Step 1: Create Secret
```bash
# Create the secret
aws secretsmanager create-secret \
    --name "github-ticketing-credentials" \
    --description "GitHub credentials for Security Hub ticketing" \
    --secret-string '{
        "github_token": "your_github_token",
        "github_repo": "owner/repo",
        "created_at": "2023-12-01T00:00:00Z",
        "auth_type": "personal_access_token"
    }'
```

#### Step 2: Configure Lambda Permissions
```bash
# Get your Lambda function role
LAMBDA_ROLE=$(aws lambda get-function \
    --function-name enhanced-auto-remediation-lambda-arm64 \
    --query 'Configuration.Role' --output text)

# Create policy for Secrets Manager access
cat > secrets-manager-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "arn:aws:secretsmanager:us-west-2:*:secret:github-ticketing-credentials*"
        }
    ]
}
EOF

# Attach policy to Lambda role
aws iam put-role-policy \
    --role-name $(echo $LAMBDA_ROLE | cut -d'/' -f2) \
    --policy-name SecretsManagerAccess \
    --policy-document file://secrets-manager-policy.json
```

#### Step 3: Run Setup
```bash
./setup-github-tickets-enhanced.sh
# Choose option 4 when prompted
```

### 4. OAuth App Setup

#### Step 1: Create OAuth App
1. Go to [GitHub Settings > Developer settings > OAuth Apps](https://github.com/settings/developers)
2. Click "New OAuth App"
3. Configure:
   - **Application name**: Security Hub Ticketing
   - **Homepage URL**: https://your-domain.com
   - **Authorization callback URL**: https://your-domain.com/callback
4. Click "Register application"

#### Step 2: Get Access Token
1. Note the **Client ID** and **Client Secret**
2. Follow the OAuth flow to get an access token
3. Store the credentials securely

#### Step 3: Configure Setup
```bash
export GITHUB_CLIENT_ID="your_client_id"
export GITHUB_CLIENT_SECRET="your_client_secret"
export GITHUB_OAUTH_TOKEN="your_access_token"
export GITHUB_REPO="your-username/your-repo"

./setup-github-tickets-enhanced.sh
# Choose option 3 when prompted
```

### 5. GitHub Actions Setup

#### Step 1: Create Workflow
Create `.github/workflows/security-hub.yml`:

```yaml
name: Security Hub Processing
on:
  repository_dispatch:
    types: [security-hub-finding]

jobs:
  process-finding:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
          
      - name: Process Security Hub Finding
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITHUB_AUTH_TYPE: github_actions
          GITHUB_REPO: ${{ github.repository }}
        run: |
          python process_finding.py
```

#### Step 2: Configure Environment
```bash
export GITHUB_AUTH_TYPE="github_actions"
export GITHUB_REPO="your-username/your-repo"

./setup-github-tickets-enhanced.sh
# Choose option 5 when prompted
```

## 🧪 Testing Your Setup

### Test Authentication
```bash
# Test the enhanced authentication module
python3 enhanced-github-auth.py
```

### Test Issue Creation
```bash
# Test with sample finding
aws lambda invoke \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --payload '{
    "detail": {
      "findings": [{
        "Id": "test-github-finding-001",
        "Title": "Test GitHub Integration",
        "Description": "Testing GitHub issue creation",
        "Severity": {"Label": "HIGH"},
        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
      }]
    }
  }' \
  response.json

cat response.json
```

### Manual GitHub API Test
```bash
# Test Personal Access Token
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/user

# Test repository access
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO
```

## 🔧 Configuration Options

### Environment Variables

All methods use these environment variables:

```bash
# Required for all methods
export GITHUB_REPO="owner/repo"

# Authentication method and credentials
export GITHUB_AUTH_TYPE="method_name"
export GITHUB_AUTH_VALUE="credentials_or_config"
```

### Authentication Method Values

| Method | GITHUB_AUTH_TYPE | GITHUB_AUTH_VALUE |
|--------|------------------|-------------------|
| Personal Access Token | `personal_access_token` | `your_token` |
| GitHub App | `github_app` | `{"app_id":"123","installation_id":"456","private_key":"..."}` |
| OAuth App | `oauth_app` | `{"client_id":"abc","client_secret":"def","access_token":"ghi"}` |
| AWS Secrets Manager | `secrets_manager` | `secret_name` |
| GitHub Actions | `github_actions` | `owner/repo` |

## 🎨 Customization

### Issue Templates
The setup creates issue templates in `.github/ISSUE_TEMPLATE/`:

- `security-hub-finding.md` - Template for Security Hub findings
- `bug_report.md` - Standard bug report template

### Labels
The setup creates comprehensive labels:

- **Service labels**: IAM, S3, EC2, RDS, etc.
- **Severity labels**: critical-severity, high-severity, etc.
- **Status labels**: remediation-success, remediation-failed
- **Category labels**: aws-security, compliance, vulnerability

### GitHub Actions Workflow
The setup creates `.github/workflows/security-hub-automation.yml` for automated issue processing.

## 🔒 Security Considerations

### For Development
- Use Personal Access Token with minimal permissions
- Store tokens in environment variables (not in code)
- Rotate tokens regularly

### For Production
- Use GitHub App for fine-grained permissions
- Store credentials in AWS Secrets Manager
- Implement proper IAM roles and policies
- Enable audit logging

### For Enterprise
- Use AWS Secrets Manager for credential storage
- Implement proper access controls
- Set up monitoring and alerting
- Regular security reviews

## 🐛 Troubleshooting

### Common Issues

#### 1. "Invalid token" error
```bash
# Check token permissions
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/user

# Check repository access
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/OWNER/REPO
```

#### 2. "Repository not found" error
- Verify repository name format: `owner/repo`
- Check repository exists and is accessible
- Ensure token has repository access

#### 3. "Rate limit exceeded" error
- GitHub Apps have higher rate limits
- Consider using GitHub App instead of PAT
- Implement rate limiting in your code

#### 4. "JWT token generation failed" error
- Verify private key format (PEM)
- Check App ID is correct
- Ensure private key matches App ID

### Debug Commands

```bash
# Test GitHub API access
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/user

# Check rate limits
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/rate_limit

# Test repository access
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/OWNER/REPO

# Check Lambda environment variables
aws lambda get-function-configuration \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --query 'Environment.Variables'
```

## 📊 Monitoring

### CloudWatch Dashboard
The setup creates a CloudWatch dashboard: `GitHubEnhancedDashboard`

### SNS Alerts
The setup creates an SNS topic: `GitHubIntegrationAlerts`

### GitHub Actions Logs
Check the Actions tab in your GitHub repository for workflow execution logs.

## 🎯 Next Steps

After successful setup:

1. **Test the integration** with sample findings
2. **Customize issue templates** for your workflow
3. **Set up monitoring** and alerting
4. **Train your team** on the new ticketing system
5. **Document any customizations** for future reference

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review the GitHub API documentation
- Create an issue in the repository
- Consult the AWS Secrets Manager documentation 