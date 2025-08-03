#!/usr/bin/env python3
"""
Enhanced GitHub Authentication Module
Supports multiple authentication methods for GitHub API access
"""

import json
import os
import time
import jwt
import requests
import boto3
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

class GitHubAuthManager:
    """Manages different GitHub authentication methods"""
    
    def __init__(self):
        self.auth_type = os.environ.get('GITHUB_AUTH_TYPE', 'personal_access_token')
        self.auth_value = os.environ.get('GITHUB_AUTH_VALUE', '')
        self.github_repo = os.environ.get('GITHUB_REPO', '')
        self.secrets_manager = boto3.client('secretsmanager')
        
    def get_auth_headers(self):
        """Get authentication headers based on the configured method"""
        if self.auth_type == 'personal_access_token':
            return self._get_pat_headers()
        elif self.auth_type == 'github_app':
            return self._get_github_app_headers()
        elif self.auth_type == 'oauth_app':
            return self._get_oauth_headers()
        elif self.auth_type == 'secrets_manager':
            return self._get_secrets_manager_headers()
        elif self.auth_type == 'github_actions':
            return self._get_github_actions_headers()
        else:
            raise ValueError(f"Unsupported authentication type: {self.auth_type}")
    
    def _get_pat_headers(self):
        """Get headers for Personal Access Token authentication"""
        return {
            'Authorization': f'token {self.auth_value}',
            'Accept': 'application/vnd.github.v3+json'
        }
    
    def _get_github_app_headers(self):
        """Get headers for GitHub App authentication"""
        try:
            # Parse GitHub App credentials
            app_creds = json.loads(self.auth_value)
            app_id = app_creds['app_id']
            installation_id = app_creds['installation_id']
            private_key = app_creds['private_key']
            
            # Generate JWT token
            jwt_token = self._generate_jwt_token(app_id, private_key)
            
            # Get installation access token
            access_token = self._get_installation_token(jwt_token, installation_id)
            
            return {
                'Authorization': f'token {access_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
        except Exception as e:
            raise Exception(f"GitHub App authentication failed: {str(e)}")
    
    def _get_oauth_headers(self):
        """Get headers for OAuth App authentication"""
        try:
            oauth_creds = json.loads(self.auth_value)
            access_token = oauth_creds['access_token']
            
            return {
                'Authorization': f'token {access_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
        except Exception as e:
            raise Exception(f"OAuth authentication failed: {str(e)}")
    
    def _get_secrets_manager_headers(self):
        """Get headers using credentials from AWS Secrets Manager"""
        try:
            # Get secret from AWS Secrets Manager
            secret_response = self.secrets_manager.get_secret_value(
                SecretId=self.auth_value
            )
            secret_data = json.loads(secret_response['SecretString'])
            
            github_token = secret_data['github_token']
            
            return {
                'Authorization': f'token {github_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
        except ClientError as e:
            raise Exception(f"Failed to retrieve secret from AWS Secrets Manager: {str(e)}")
        except Exception as e:
            raise Exception(f"Secrets Manager authentication failed: {str(e)}")
    
    def _get_github_actions_headers(self):
        """Get headers for GitHub Actions authentication"""
        # In GitHub Actions, GITHUB_TOKEN is automatically available
        github_token = os.environ.get('GITHUB_TOKEN')
        if not github_token:
            raise Exception("GITHUB_TOKEN not available in GitHub Actions environment")
        
        return {
            'Authorization': f'token {github_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
    
    def _generate_jwt_token(self, app_id, private_key):
        """Generate JWT token for GitHub App authentication"""
        try:
            # Create JWT payload
            now = int(time.time())
            payload = {
                'iat': now,
                'exp': now + (10 * 60),  # 10 minutes
                'iss': app_id
            }
            
            # Generate JWT token
            token = jwt.encode(payload, private_key, algorithm='RS256')
            return token
        except Exception as e:
            raise Exception(f"Failed to generate JWT token: {str(e)}")
    
    def _get_installation_token(self, jwt_token, installation_id):
        """Get installation access token using JWT token"""
        try:
            headers = {
                'Authorization': f'Bearer {jwt_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'
            response = requests.post(url, headers=headers)
            
            if response.status_code == 201:
                token_data = response.json()
                return token_data['token']
            else:
                raise Exception(f"Failed to get installation token: {response.status_code}")
        except Exception as e:
            raise Exception(f"Failed to get installation token: {str(e)}")
    
    def test_authentication(self):
        """Test the configured authentication method"""
        try:
            headers = self.get_auth_headers()
            
            # Test API access
            response = requests.get('https://api.github.com/user', headers=headers)
            
            if response.status_code == 200:
                user_data = response.json()
                return {
                    'success': True,
                    'user': user_data['login'],
                    'method': self.auth_type
                }
            else:
                return {
                    'success': False,
                    'error': f"API request failed: {response.status_code}",
                    'method': self.auth_type
                }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'method': self.auth_type
            }

class GitHubIssueManager:
    """Manages GitHub issue creation and updates with enhanced authentication"""
    
    def __init__(self):
        self.auth_manager = GitHubAuthManager()
        self.github_repo = os.environ.get('GITHUB_REPO', '')
        
    def create_issue(self, ticket_data):
        """Create a GitHub issue for a Security Hub finding"""
        try:
            headers = self.auth_manager.get_auth_headers()
            
            # Prepare issue data
            issue_data = self._prepare_issue_data(ticket_data)
            
            # Create issue
            url = f'https://api.github.com/repos/{self.github_repo}/issues'
            response = requests.post(url, headers=headers, json=issue_data)
            
            if response.status_code == 201:
                issue_info = response.json()
                return f"GH-{issue_info['number']}"
            else:
                raise Exception(f"Failed to create issue: {response.status_code} - {response.text}")
        except Exception as e:
            raise Exception(f"GitHub issue creation failed: {str(e)}")
    
    def update_issue(self, issue_id, status, message=None, error=None):
        """Update a GitHub issue with status and comments"""
        try:
            headers = self.auth_manager.get_auth_headers()
            
            # Extract issue number from ticket ID
            issue_number = issue_id.replace('GH-', '')
            
            # Add comment
            comment_data = self._prepare_comment_data(status, message, error)
            
            url = f'https://api.github.com/repos/{self.github_repo}/issues/{issue_number}/comments'
            response = requests.post(url, headers=headers, json=comment_data)
            
            if response.status_code == 201:
                return True
            else:
                raise Exception(f"Failed to update issue: {response.status_code}")
        except Exception as e:
            raise Exception(f"GitHub issue update failed: {str(e)}")
    
    def _prepare_issue_data(self, ticket_data):
        """Prepare issue data for GitHub API"""
        # Determine labels based on severity and service
        labels = ['security-hub', 'auto-remediation']
        
        # Add severity label
        severity = ticket_data.get('severity', 'UNKNOWN').lower()
        if severity in ['critical', 'high', 'medium', 'low']:
            labels.append(f'{severity}-severity')
        
        # Add service label
        service = ticket_data.get('remediation_type', '')
        if service and service != 'auto-remediation':
            labels.append(service)
        
        # Prepare issue body
        body = self._format_issue_body(ticket_data)
        
        return {
            'title': f"Security Hub Finding: {ticket_data.get('title', 'Security Finding')}",
            'body': body,
            'labels': labels
        }
    
    def _prepare_comment_data(self, status, message=None, error=None):
        """Prepare comment data for GitHub API"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
        
        comment = f"## Status Update - {timestamp}\n\n"
        comment += f"**Status:** {status}\n\n"
        
        if message:
            comment += f"**Message:** {message}\n\n"
        
        if error:
            comment += f"**Error:** {error}\n\n"
        
        comment += "---\n*Updated by Security Hub Auto-Remediation system*"
        
        return {'body': comment}
    
    def _format_issue_body(self, ticket_data):
        """Format issue body with finding details"""
        body = f"""## Security Hub Finding Details

**Finding ID:** `{ticket_data.get('finding_id', 'N/A')}`
**Severity:** `{ticket_data.get('severity', 'UNKNOWN')}`
**Service:** `{ticket_data.get('remediation_type', 'N/A')}`
**Status:** `{ticket_data.get('status', 'CREATED')}`

### Description
{ticket_data.get('description', 'No description available')}

### Remediation Status
- [ ] **Created** - Finding received
- [ ] **In Progress** - Remediation started
- [ ] **Success** - Remediation completed
- [ ] **Failed** - Remediation failed

### Additional Information
- **Created:** `{ticket_data.get('created_at', 'N/A')}`
- **Updated:** `{ticket_data.get('updated_at', 'N/A')}`

### Remediation Details
This issue was automatically created by the Security Hub Auto-Remediation system.

---
*This issue was automatically created by the Security Hub Auto-Remediation system.*"""
        
        return body

# Example usage and testing
def test_github_auth():
    """Test GitHub authentication methods"""
    auth_manager = GitHubAuthManager()
    
    print("Testing GitHub authentication...")
    result = auth_manager.test_authentication()
    
    if result['success']:
        print(f"✅ Authentication successful for user: {result['user']}")
        print(f"   Method: {result['method']}")
        return True
    else:
        print(f"❌ Authentication failed: {result['error']}")
        print(f"   Method: {result['method']}")
        return False

def test_issue_creation():
    """Test GitHub issue creation"""
    issue_manager = GitHubIssueManager()
    
    # Test ticket data
    test_ticket = {
        'finding_id': 'test-finding-001',
        'title': 'Test Security Finding',
        'description': 'This is a test finding for GitHub integration',
        'severity': 'HIGH',
        'remediation_type': 'IAM',
        'status': 'CREATED',
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat()
    }
    
    try:
        issue_id = issue_manager.create_issue(test_ticket)
        print(f"✅ Issue created successfully: {issue_id}")
        
        # Test issue update
        success = issue_manager.update_issue(issue_id, "SUCCESS", "Test remediation completed")
        if success:
            print(f"✅ Issue updated successfully: {issue_id}")
        
        return True
    except Exception as e:
        print(f"❌ Issue creation failed: {str(e)}")
        return False

if __name__ == "__main__":
    print("Testing Enhanced GitHub Authentication...")
    
    # Test authentication
    auth_success = test_github_auth()
    
    if auth_success:
        # Test issue creation
        test_issue_creation()
    else:
        print("Authentication failed, skipping issue creation test") 