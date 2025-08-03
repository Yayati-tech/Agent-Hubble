#!/usr/bin/env python3
"""
Test GitHub Integration for Security Hub Ticketing System
This script tests the GitHub App authentication and issue creation functionality.
"""

import json
import time
import jwt
import requests
import os
import sys

def test_github_app_auth():
    """Test GitHub App authentication"""
    print("🔐 Testing GitHub App Authentication...")
    
    try:
        # Get credentials from environment (these should be set in Lambda)
        app_id = "1719009"
        installation_id = "Iv23lipU7TXAKNYvi57H"
        private_key = """-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAvJhgqF24DMSPpwHY41O/5yiD8ktOfF22MPZ5jj1kMvIF/WJB
DoD6UCSBgXK/pEdiqZ2CU0LodBfyuaRsHv2bNw+O8HGx4Dt9Id8+6haQ3lVxh7qR
YrpMbfbw0+f7F/f6R2A+MN16yypBhBCQiKbCT2NxJPw+bM6rZv1+nNx5h/KfhHol
gd6jd7IhzuDNRwHozvYovwX/kaWF7doYiD9tw+xvRlzIEf/ZWOywY5f11zcHX9tS
CXIO374LMN7M/8obgJ51gI3PYRllo7di70n5PUdrA3o2Pq+pJ3qnN8mnUepleW2G
NnwH7+0xS3dYqTJoaSXgbzTHdAgI4jKCY3C9kQIDAQABAoIBAARpWBF4J778thOF
AorGwb1pgDShuFNGaeWZTlyaaQacDLHRo43wTGqlf/YENiFknhUznwHNldxpVv8q
rnDHI+NU1NYhArUpDxNEwpb9MiRRQVeYcKArlXAZD6cVTRVRcqRKxwmjlKS990xc
itT3eaIbxGDGGbu31eCR221V5u3cH7nEU7D8ZXcmPQKNNI6SruXVdR1AfdE/xEvs
oox35WRT7gfDcoIkiev443dXCYzRoaJ4euJoJnj+PGLUyJuj3eelejCSeGr/SvD8
quPy3apmyzqDRXuxFpi+ApzgXsKcXDUr4tFQSJ2Qn7KwIUaq31G+08/ILzZIJfjq
txohtAECgYEA7ULsbJ/L8Z7N2Mc/vy5IehtbV1LWDjSOv8c3NIZJuVwdY87Qkyy+
SOXnEzZZ/lebnjUZVDbGZB0DYtckDLFQy9jUxDiElMEm0BNx4iRy+uPkvHKmulhU
NcApi0BJ/sRcvF0Qz9hdsXx9nJcnR63hw4k1KPcGlJP12W5//9m+olECgYEAy31+
yIc221ZaUpVevaSfzc0YZ8PB4gsqOJezrYz9k6M0WYD8jCJeG/hQWoIoRq1VMrXX
+arA5S8n+X9xCLXuHXjMjwojctLDAGRq7hHaOxcDOUkaSiRiFRS4leP2njPbrTJj
uleWwFmDEzubDVd4Y/p3uIlhoi5/WzF0DSrgV0ECgYBbhEfrskuZXHbsGhb1qGWe
a/T0nuggPJefU7lwkifXzrcra3e6fTS8q6lRGNLnr2VARh0KBcLKlQJcWr32A2M1
7eJL+bzyH/rXodh4sTSEn+j344V6NV3uCbw8kUS5d4aJxaAZe8zQDEPrZcZp+KEv
qjoOHhK0tsnK37uRtay5sQKBgQCmfDdlcxMTovPlCyZnPDAunbVw9/1BpmbVxHAR
9v9kciubaue0801RzvhXBJRVNu00vwhD0UtedxVakMT3HnoBjNq30NCt2fgG8yF1
RA/rNmnBzah/roK8wqY+pDMavkzlyAtF4vGIz/NooeS6pqzuB3c5+NRzb11tS+mp
+EFxwQKBgDHhKiivMK7UOxUjuiMrK4UHsPtNOZ+eA4UfXcRv1EkkiL36u5EjceYY
3iZeVs3tV7nK4gLFMmOblu4BSy8B5WI6+hX6XqDWsPxjagyTrHAisv4PcKx/2N/u
ARHyR3oO/7blXR/GCDzphzGrDPQGWk+JNUw8SyodkX0w2iu30Y+6
-----END RSA PRIVATE KEY-----"""
        
        # Generate JWT token
        now = int(time.time())
        payload = {
            'iat': now,
            'exp': now + (10 * 60),  # 10 minutes
            'iss': app_id
        }
        
        jwt_token = jwt.encode(payload, private_key, algorithm='RS256')
        
        # Get installation access token
        headers = {
            'Authorization': f'Bearer {jwt_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'
        response = requests.post(url, headers=headers)
        
        if response.status_code == 201:
            token_data = response.json()
            access_token = token_data['token']
            print(f"✅ GitHub App authentication successful")
            print(f"   App ID: {app_id}")
            print(f"   Installation ID: {installation_id}")
            print(f"   Token expires: {token_data.get('expires_at', 'Unknown')}")
            return access_token
        else:
            print(f"❌ Failed to get installation token: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ GitHub App authentication failed: {str(e)}")
        return None

def test_github_api_access(access_token):
    """Test GitHub API access"""
    print("\n🔍 Testing GitHub API Access...")
    
    try:
        headers = {
            'Authorization': f'token {access_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        # Test user endpoint
        user_response = requests.get('https://api.github.com/user', headers=headers)
        if user_response.status_code == 200:
            user_data = user_response.json()
            print(f"✅ API access successful")
            print(f"   Authenticated as: {user_data.get('login', 'Unknown')}")
            return True
        else:
            print(f"❌ API access failed: {user_response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ API access test failed: {str(e)}")
        return False

def test_repository_access(access_token, repo="Yayati-tech/Agent-Hubble"):
    """Test repository access"""
    print(f"\n📁 Testing Repository Access: {repo}")
    
    try:
        headers = {
            'Authorization': f'token {access_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        # Test repository access
        repo_response = requests.get(f'https://api.github.com/repos/{repo}', headers=headers)
        if repo_response.status_code == 200:
            repo_data = repo_response.json()
            print(f"✅ Repository access successful")
            print(f"   Repository: {repo_data.get('full_name', repo)}")
            print(f"   Description: {repo_data.get('description', 'No description')}")
            return True
        else:
            print(f"❌ Repository access failed: {repo_response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Repository access test failed: {str(e)}")
        return False

def test_issue_creation(access_token, repo="Yayati-tech/Agent-Hubble"):
    """Test issue creation"""
    print(f"\n📝 Testing Issue Creation in {repo}")
    
    try:
        headers = {
            'Authorization': f'token {access_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        # Create a test issue
        issue_data = {
            "title": "[TEST] Security Hub Integration Test",
            "body": """## Security Hub Integration Test

This is a test issue to verify GitHub App integration with the Security Hub ticketing system.

### Test Details
- **Test ID**: `integration-test-001`
- **Timestamp**: `{}`
- **Authentication**: GitHub App (JWT)
- **Repository**: `{}`

### Expected Behavior
- Issue should be created with proper labels
- GitHub App authentication should work
- Integration should be ready for production

---
*This is an automated test issue created by the Security Hub ticketing system.*""".format(
                time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
                repo
            ),
            "labels": ["security-hub", "auto-remediation", "test", "high-severity"]
        }
        
        issue_response = requests.post(
            f'https://api.github.com/repos/{repo}/issues',
            headers=headers,
            json=issue_data
        )
        
        if issue_response.status_code == 201:
            issue_data = issue_response.json()
            print(f"✅ Issue creation successful")
            print(f"   Issue URL: {issue_data.get('html_url', 'Unknown')}")
            print(f"   Issue Number: {issue_data.get('number', 'Unknown')}")
            print(f"   Labels: {[label['name'] for label in issue_data.get('labels', [])]}")
            return issue_data.get('html_url')
        else:
            print(f"❌ Issue creation failed: {issue_response.status_code}")
            print(f"   Response: {issue_response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Issue creation test failed: {str(e)}")
        return None

def test_labels_access(access_token, repo="Yayati-tech/Agent-Hubble"):
    """Test labels access"""
    print(f"\n🏷️ Testing Labels Access in {repo}")
    
    try:
        headers = {
            'Authorization': f'token {access_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        # Get labels
        labels_response = requests.get(f'https://api.github.com/repos/{repo}/labels', headers=headers)
        
        if labels_response.status_code == 200:
            labels = labels_response.json()
            print(f"✅ Labels access successful")
            print(f"   Total labels: {len(labels)}")
            
            # Show some key labels
            key_labels = ['security-hub', 'auto-remediation', 'high-severity', 'IAM', 'S3']
            found_labels = [label['name'] for label in labels if label['name'] in key_labels]
            print(f"   Key labels found: {found_labels}")
            return True
        else:
            print(f"❌ Labels access failed: {labels_response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Labels access test failed: {str(e)}")
        return False

def main():
    """Main test function"""
    print("🚀 GitHub Integration Test for Security Hub Ticketing System")
    print("=" * 60)
    
    # Test 1: GitHub App Authentication
    access_token = test_github_app_auth()
    if not access_token:
        print("❌ Authentication failed. Exiting.")
        sys.exit(1)
    
    # Test 2: API Access
    if not test_github_api_access(access_token):
        print("❌ API access failed. Exiting.")
        sys.exit(1)
    
    # Test 3: Repository Access
    if not test_repository_access(access_token):
        print("❌ Repository access failed. Exiting.")
        sys.exit(1)
    
    # Test 4: Labels Access
    if not test_labels_access(access_token):
        print("❌ Labels access failed. Exiting.")
        sys.exit(1)
    
    # Test 5: Issue Creation
    issue_url = test_issue_creation(access_token)
    if not issue_url:
        print("❌ Issue creation failed. Exiting.")
        sys.exit(1)
    
    # Summary
    print("\n" + "=" * 60)
    print("🎉 ALL TESTS PASSED!")
    print("=" * 60)
    print("✅ GitHub App authentication working")
    print("✅ API access successful")
    print("✅ Repository access confirmed")
    print("✅ Labels access working")
    print("✅ Issue creation successful")
    print(f"📝 Test issue created: {issue_url}")
    print("\n🔗 Useful Links:")
    print(f"   - Repository: https://github.com/Yayati-tech/Agent-Hubble")
    print(f"   - Issues: https://github.com/Yayati-tech/Agent-Hubble/issues")
    print(f"   - Labels: https://github.com/Yayati-tech/Agent-Hubble/labels")
    print("\n🎯 Integration Status: READY FOR PRODUCTION")

if __name__ == "__main__":
    main() 