#!/usr/bin/env python3
"""
Test GitHub App Installation ID (Fixed Version)
This script helps find the correct installation ID for a GitHub App
"""

import json
import time
import requests
import sys
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import jwt

def create_jwt(payload, private_key, algorithm='RS256'):
    """Create a JWT token using PyJWT with cryptography"""
    try:
        # Load the private key
        private_key_bytes = private_key.encode('utf-8')
        signing_key = serialization.load_pem_private_key(
            private_key_bytes,
            password=None,
            backend=default_backend()
        )
        
        return jwt.encode(payload, signing_key, algorithm=algorithm)
    except Exception as e:
        print(f"Error creating JWT: {str(e)}")
        return None

def find_installation_id(app_id, private_key, repo_name):
    """Find the correct installation ID for a GitHub App"""
    print(f"🔍 Finding installation ID for app {app_id} and repo {repo_name}")
    
    try:
        # Generate JWT token
        now = int(time.time())
        payload = {
            'iat': now,
            'exp': now + (10 * 60),  # 10 minutes
            'iss': app_id
        }
        
        jwt_token = create_jwt(payload, private_key, 'RS256')
        if not jwt_token:
            return None
        
        # Get installations for the app
        headers = {
            'Authorization': f'Bearer {jwt_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        url = 'https://api.github.com/app/installations'
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            installations = response.json()
            print(f"✅ Found {len(installations)} installations")
            
            for installation in installations:
                installation_id = installation['id']
                account = installation['account']
                print(f"   Installation ID: {installation_id}")
                print(f"   Account: {account['login']} ({account['type']})")
                
                # Check if this installation has access to the target repository
                try:
                    # Get repositories for this installation
                    repo_url = f'https://api.github.com/app/installations/{installation_id}/repositories'
                    repo_response = requests.get(repo_url, headers=headers)
                    
                    if repo_response.status_code == 200:
                        repositories = repo_response.json()['repositories']
                        print(f"   Repositories ({len(repositories)}):")
                        
                        for repo in repositories:
                            full_name = repo['full_name']
                            print(f"     - {full_name}")
                            
                            if full_name == repo_name:
                                print(f"   ✅ Found matching repository: {full_name}")
                                print(f"   ✅ Correct Installation ID: {installation_id}")
                                return installation_id
                    
                except Exception as e:
                    print(f"   ❌ Error checking repositories: {str(e)}")
                
                print()
            
            print("❌ No installation found with access to the target repository")
            return None
            
        else:
            print(f"❌ Failed to get installations: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error finding installation ID: {str(e)}")
        return None

def test_installation_token(app_id, installation_id, private_key):
    """Test getting an installation access token"""
    print(f"\n🔐 Testing installation token for ID: {installation_id}")
    
    try:
        # Generate JWT token
        now = int(time.time())
        payload = {
            'iat': now,
            'exp': now + (10 * 60),  # 10 minutes
            'iss': app_id
        }
        
        jwt_token = create_jwt(payload, private_key, 'RS256')
        if not jwt_token:
            return False
        
        # Get installation access token
        headers = {
            'Authorization': f'Bearer {jwt_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        url = f'https://api.github.com/app/installations/{installation_id}/access_tokens'
        response = requests.post(url, headers=headers)
        
        if response.status_code == 201:
            token_data = response.json()
            print(f"✅ Installation token obtained successfully")
            print(f"   Token expires: {token_data.get('expires_at', 'Unknown')}")
            return True
        else:
            print(f"❌ Failed to get installation token: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing installation token: {str(e)}")
        return False

def main():
    """Main function"""
    print("🔧 GitHub App Installation ID Finder (Fixed)")
    print("=" * 50)
    
    # Get GitHub App credentials from Lambda environment
    import os
    import boto3
    
    try:
        lambda_client = boto3.client('lambda')
        response = lambda_client.get_function_configuration(
            FunctionName='enhanced-auto-remediation-lambda'
        )
        
        env_vars = response['Environment']['Variables']
        github_auth_value = env_vars.get('GITHUB_AUTH_VALUE')
        github_repo = env_vars.get('GITHUB_REPO')
        
        if not github_auth_value or not github_repo:
            print("❌ GitHub credentials not found in Lambda environment")
            return
        
        auth_data = json.loads(github_auth_value)
        app_id = auth_data.get('app_id')
        installation_id = auth_data.get('installation_id')
        private_key = auth_data.get('private_key')
        
        if not all([app_id, installation_id, private_key]):
            print("❌ Incomplete GitHub credentials")
            return
        
        print(f"📋 Current Configuration:")
        print(f"   App ID: {app_id}")
        print(f"   Installation ID: {installation_id}")
        print(f"   Repository: {github_repo}")
        print()
        
        # Find correct installation ID
        correct_installation_id = find_installation_id(app_id, private_key, github_repo)
        
        if correct_installation_id:
            print(f"\n✅ Found correct installation ID: {correct_installation_id}")
            
            # Test the installation token
            if test_installation_token(app_id, correct_installation_id, private_key):
                print(f"\n🎉 GitHub integration is working!")
                print(f"   Correct Installation ID: {correct_installation_id}")
                
                # Update Lambda environment if different
                if correct_installation_id != installation_id:
                    print(f"\n🔄 Updating Lambda environment with correct installation ID...")
                    auth_data['installation_id'] = correct_installation_id
                    new_auth_value = json.dumps(auth_data)
                    
                    lambda_client.update_function_configuration(
                        FunctionName='enhanced-auto-remediation-lambda',
                        Environment={
                            'Variables': {
                                **env_vars,
                                'GITHUB_AUTH_VALUE': new_auth_value
                            }
                        }
                    )
                    print(f"✅ Updated Lambda environment with correct installation ID")
            else:
                print(f"\n❌ Installation token test failed")
        else:
            print(f"\n❌ No valid installation ID found")
            print(f"   Current installation ID: {installation_id}")
            print(f"   This might be incorrect or the GitHub App is not properly installed")
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    main() 