# GitHub Authentication Methods for Security Hub Ticketing

This guide explains the different authentication methods available for GitHub integration with the Security Hub ticketing system.

## 🔐 Available Authentication Methods

### 1. Personal Access Token (Traditional)
**Best for**: Development, testing, and simple integrations
**Security Level**: Medium
**Setup Complexity**: Low

#### How it works:
- Uses a GitHub Personal Access Token with `repo` and `issues` permissions
- Token is stored in environment variables
- Simple and straightforward authentication

#### Setup:
```bash
# Create token at: https://github.com/settings/tokens
export GITHUB_TOKEN="your_personal_access_token"
export GITHUB_REPO="owner/repo"
```

#### Pros:
- ✅ Simple to set up
- ✅ Works immediately
- ✅ Good for development

#### Cons:
- ❌ Token stored in environment variables
- ❌ Manual token rotation required
- ❌ Limited to user permissions

---

### 2. GitHub App (Recommended for Production)
**Best for**: Production environments, enterprise use
**Security Level**: High
**Setup Complexity**: Medium

#### How it works:
- Uses GitHub App with JWT token generation
- Installation-based permissions
- Automatic token rotation
- Fine-grained permissions

#### Setup:
1. Create a GitHub App at: https://github.com/settings/apps
2. Install the app in your repository
3. Configure with App ID, Installation ID, and Private Key

#### Configuration:
```bash
export GITHUB_AUTH_TYPE="github_app"
export GITHUB_AUTH_VALUE='{"app_id":"12345","installation_id":"67890","private_key":"-----BEGIN RSA PRIVATE KEY-----\n..."}'
export GITHUB_REPO="owner/repo"
```

#### Pros:
- ✅ Most secure method
- ✅ Fine-grained permissions
- ✅ Automatic token rotation
- ✅ Installation-based access
- ✅ Enterprise-ready

#### Cons:
- ❌ More complex setup
- ❌ Requires GitHub App creation
- ❌ JWT token generation overhead

---

### 3. OAuth App (For Web Applications)
**Best for**: Web applications, user-specific integrations
**Security Level**: Medium
**Setup Complexity**: Medium

#### How it works:
- Uses OAuth 2.0 flow for authentication
- Requires client ID, client secret, and access token
- User-specific permissions

#### Setup:
1. Create OAuth App at: https://github.com/settings/developers
2. Configure redirect URIs
3. Obtain access token through OAuth flow

#### Configuration:
```bash
export GITHUB_AUTH_TYPE="oauth_app"
export GITHUB_AUTH_VALUE='{"client_id":"abc123","client_secret":"def456","access_token":"ghi789"}'
export GITHUB_REPO="owner/repo"
```

#### Pros:
- ✅ Standard OAuth 2.0 flow
- ✅ User-specific permissions
- ✅ Good for web applications

#### Cons:
- ❌ Requires OAuth flow setup
- ❌ Tokens expire and need refresh
- ❌ More complex than PAT

---

### 4. AWS Secrets Manager (Most Secure)
**Best for**: Production environments, enterprise security
**Security Level**: Very High
**Setup Complexity**: Medium

#### How it works:
- Stores GitHub credentials in AWS Secrets Manager
- Lambda function retrieves credentials at runtime
- Automatic encryption and rotation
- IAM-based access control

#### Setup:
```bash
# Create secret in AWS Secrets Manager
aws secretsmanager create-secret \
    --name "github-ticketing-credentials" \
    --description "GitHub credentials for Security Hub ticketing" \
    --secret-string '{"github_token":"your_token","github_repo":"owner/repo"}'

# Configure Lambda environment
export GITHUB_AUTH_TYPE="secrets_manager"
export GITHUB_AUTH_VALUE="github-ticketing-credentials"
```

#### Pros:
- ✅ Most secure credential storage
- ✅ Automatic encryption
- ✅ IAM-based access control
- ✅ Automatic rotation support
- ✅ Audit trail

#### Cons:
- ❌ Requires AWS Secrets Manager
- ❌ Additional AWS costs
- ❌ More complex setup

---

### 5. GitHub Actions (For CI/CD Environments)
**Best for**: CI/CD pipelines, automated workflows
**Security Level**: High
**Setup Complexity**: Low

#### How it works:
- Uses GitHub's built-in `GITHUB_TOKEN`
- Automatically available in GitHub Actions
- Repository-specific permissions

#### Setup:
```yaml
# In .github/workflows/security-hub.yml
name: Security Hub Processing
on:
  repository_dispatch:
    types: [security-hub-finding]

jobs:
  process-finding:
    runs-on: ubuntu-latest
    steps:
      - name: Process Security Hub Finding
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITHUB_AUTH_TYPE: github_actions
          GITHUB_REPO: ${{ github.repository }}
        run: |
          python process_finding.py
```

#### Pros:
- ✅ Built-in security
- ✅ No credential management
- ✅ Repository-specific permissions
- ✅ Perfect for CI/CD

#### Cons:
- ❌ Only works in GitHub Actions
- ❌ Limited to repository scope
- ❌ Requires workflow setup

---

## 🔧 Implementation Details

### Environment Variables

All methods use these environment variables:

```bash
# Required for all methods
export GITHUB_REPO="owner/repo"

# Authentication method and credentials
export GITHUB_AUTH_TYPE="method_name"
export GITHUB_AUTH_VALUE="credentials_or_config"
```

### Authentication Priority

The system tries authentication methods in this order:

1. **GitHub App** (if configured)
2. **OAuth App** (if configured)
3. **Personal Access Token** (if configured)
4. **AWS Secrets Manager** (if configured)
5. **GitHub Actions** (if in Actions environment)
6. **DynamoDB Fallback** (always available)

### Error Handling

Each authentication method includes comprehensive error handling:

```python
try:
    headers = auth_manager.get_auth_headers()
    # Use headers for API calls
except Exception as e:
    logger.error(f"Authentication failed: {str(e)}")
    # Fall back to DynamoDB
```

---

## 🚀 Quick Setup Guide

### For Development (Personal Access Token)

```bash
# 1. Create Personal Access Token
# Go to: https://github.com/settings/tokens
# Create token with 'repo' and 'issues' permissions

# 2. Set environment variables
export GITHUB_TOKEN="your_token_here"
export GITHUB_REPO="your-username/your-repo"

# 3. Run enhanced setup
chmod +x setup-github-tickets-enhanced.sh
./setup-github-tickets-enhanced.sh
# Choose option 1 (Personal Access Token)
```

### For Production (GitHub App)

```bash
# 1. Create GitHub App
# Go to: https://github.com/settings/apps
# Configure with:
# - App name: Security Hub Ticketing
# - Homepage URL: https://your-domain.com
# - Webhook: (optional)
# - Permissions: Repository (Contents, Issues, Metadata)

# 2. Install App in your repository
# Go to your repository → Settings → Integrations → GitHub Apps

# 3. Get App credentials
# App ID, Installation ID, and Private Key

# 4. Run enhanced setup
./setup-github-tickets-enhanced.sh
# Choose option 2 (GitHub App)
```

### For Enterprise (AWS Secrets Manager)

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

---

## 🔒 Security Best Practices

### 1. Use GitHub Apps for Production
- Provides fine-grained permissions
- Automatic token rotation
- Installation-based access control

### 2. Store Credentials Securely
- Use AWS Secrets Manager for production
- Never commit credentials to code
- Rotate tokens regularly

### 3. Implement Least Privilege
- Only grant necessary permissions
- Use repository-specific tokens
- Review permissions regularly

### 4. Monitor and Audit
- Enable GitHub audit logs
- Monitor Lambda function logs
- Set up CloudWatch alarms

### 5. Regular Maintenance
- Rotate tokens quarterly
- Review and update permissions
- Monitor for security issues

---

## 🧪 Testing Authentication Methods

### Test Script

```bash
# Test the enhanced authentication
python3 enhanced-github-auth.py
```

### Manual Testing

```bash
# Test Personal Access Token
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/user

# Test GitHub App (requires JWT generation)
python3 -c "
import jwt
import time
payload = {'iat': int(time.time()), 'exp': int(time.time()) + 600, 'iss': 'YOUR_APP_ID'}
token = jwt.encode(payload, 'YOUR_PRIVATE_KEY', algorithm='RS256')
print(token)
"
```

---

## 📊 Comparison Matrix

| Method | Security | Setup | Maintenance | Production Ready |
|--------|----------|-------|-------------|------------------|
| Personal Access Token | Medium | Easy | High | No |
| GitHub App | High | Medium | Low | Yes |
| OAuth App | Medium | Medium | Medium | Yes |
| AWS Secrets Manager | Very High | Medium | Low | Yes |
| GitHub Actions | High | Easy | Low | Yes (CI/CD only) |

---

## 🎯 Recommendations

### For Development
- Use **Personal Access Token** for quick setup and testing

### For Production
- Use **GitHub App** for most secure and maintainable solution
- Use **AWS Secrets Manager** for enterprise environments

### For CI/CD
- Use **GitHub Actions** for automated workflows

### For Enterprise
- Use **AWS Secrets Manager** + **GitHub App** for maximum security

---

## 🆘 Troubleshooting

### Common Issues

#### 1. "Invalid token" error
- Check token permissions (repo, issues)
- Verify token hasn't expired
- Ensure token has access to repository

#### 2. "Repository not found" error
- Verify repository name format (owner/repo)
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

# Test repository access
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/repos/OWNER/REPO

# Check rate limits
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/rate_limit
```

---

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review GitHub API documentation
- Create an issue in the repository
- Consult AWS Secrets Manager documentation 