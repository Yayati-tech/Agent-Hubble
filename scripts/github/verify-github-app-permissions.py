#!/usr/bin/env python3
"""
Verify GitHub App Permissions
This script checks the GitHub App permissions and tests access to the repository
"""

import json
import time
import jwt
import requests
import sys

def verify_github_app_permissions():
    """Verify GitHub App permissions and access"""
    print("🔍 Verifying GitHub App Permissions")
    print("====================================")
    
    # GitHub App credentials
    app_id = "1719742"
    installation_id = "78968584"
    private_key = """-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAy2bsfBlI7YeAos+UxcDAMhzU6HCkap3UhvC4T7I3rmCI0E/Y
Slr8CSWr7U+hqp8ZtBJeq/aqmylExui2o/lY69i3T1ypydxCxbNjBWNfAAT+wXwQ
dxQK6lA7gIvA3bvdu09G3OYXBy7Ze5sMabo/iqAeLoU5pX6U7cbIbMO97Nf8q/8N
s+vetgqBBwHyVOizAWjhEwO3GkVR9BpABVxTQFS2GlAet7ec0SFGwVV+C/hQF7Xm
zsqnQbSi4mp2GQ9REg3AzBMnEY+idTUF41SrTB0RC3XxMkkm5K+k0nbh30sRgVMq
m3ZWG2ns7993MEltTLMemO+vDlDsOFEwY/j+kwIDAQABAoIBAQCjKeEye6YAxN3v
vMz/BWwnxvETtKhvzkQaKyfu5mu8OjwFvscmfm4HeGy+ZU6ubApWZRYEpE6fQS+m
0C8SwocOSj5iL1cUUthNd2VLgTdH8LnbxAYBP9axt8LDj1gbhwSLqUCTGxAF9xMH
EI2Ykos+TMtpTf28QBp/0yIb/blxLzMeP2H7c69zqxxYoa3A4yZdfI0cS7hB+Ck1
7nlNeCmIHXf6OhyuR9+YTV+b1drUD2bWaOCcZxV71MOPQvkvrEJSJFFVWMszeqDK
9YM62h2hkmescf8dvfKGNIxR0BuPG+IPeEk36p8U+KQHOyEWdc0+pBsU5fA1o7so
D8rQbbFBAoGBAPENq8CVBaiaEy1Z1a0nz7MKYzoZY8QKlLHTxyuCCtloqIzZEBUQ
ZLLkg4ZvZP9KsoRho+dfyLraobKITK4U3+uMobGTCGjIoiiWTwOVR1fS/ED2emNA
A8GAjq0v+lwdZd3YxNjhmzdAHifht7TqLB70tIKTW4DVAoQ44630HDm5AoGBANgD
mVzYXHLOVWfgXvDD6WsrRHnNJwHvLdWaUSzNZ9dz3zF05VB0U+Dns/nkLGqHBbzh
LTag0Hqd/brxbdB+8sBu2oqgrJ9pLKRdM9Aqp2UkKiz6dwIsVHiEkHKHmsjh8H5N
LEhqHRP9Z0SUJh8FRweJ8v390lRiJuucqOJTifCrAoGBALNaUqJ1vsIV8ZLatouh
hX5XikDeR0bEAKLXSefrWBsvLcmub7LcgbBBKkNKesEgWPb6lzM+J2Iv7gOiOjuE
OJ9QAbbYCXe9YDoGrD+kQHLt/tZvDdzu8lx1RLNDcWo8TWDlOoGMSyquwEE4RrGL
UsytkeldrsWKt9adZXo2mRGxAoGATs45VALm70dRJx1W5ZVDgcJ+L8VlVrJQUV4E
AUlKefKe2WchBZH6y9Eb+q2AeriZokev+/79L86Vs27Ctk6p9wQ6HFrzvxBapfgO
oAH/oclozZHues97XaBXJkFMeb7bwugaoKx9wT4wP3eg1K5TNG/iQ0EnS3unYUt8
3VzGtRMCgYBDCOMsXUAZfIOQkj0cdBFCzeZrOWuQTAKaB8TFu9KknG6QsDQAB/l5
FBMvyGoH4V+OGodlcVzn8v0bwcS1p6LErSrBoRjXkaFKYGY5+vOYdHJVXJW7Hc1n
r4HphjPxCvpv7LmHvddva3+4z5Du64I1sxsbvk971sAGBqEj2I+v7Q==
-----END RSA PRIVATE KEY-----"""
    repo_name = "Yayati-tech/Agent-Hubble"
    
    try:
        print(f"🔐 Testing GitHub App Authentication...")
        
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
            
            # Test repository access
            print(f"\n🔍 Testing Repository Access...")
            repo_headers = {
                'Authorization': f'token {access_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            # Check repository details
            repo_url = f'https://api.github.com/repos/{repo_name}'
            repo_response = requests.get(repo_url, headers=repo_headers)
            
            if repo_response.status_code == 200:
                repo_data = repo_response.json()
                print(f"✅ Repository access confirmed")
                print(f"   Repository: {repo_data['full_name']}")
                print(f"   Private: {repo_data['private']}")
                print(f"   Has Issues: {repo_data['has_issues']}")
                print(f"   Issues Enabled: {repo_data['has_issues']}")
                
                # Check if issues are enabled
                if repo_data['has_issues']:
                    print(f"✅ Issues are enabled in the repository")
                else:
                    print(f"❌ Issues are disabled in the repository")
                    print(f"   Go to: https://github.com/{repo_name}/settings")
                    print(f"   Enable 'Issues' in the Features section")
                
                # Test issue creation
                print(f"\n🧪 Testing Issue Creation...")
                test_issue_data = {
                    'title': 'Test Issue - Security Hub Integration',
                    'body': 'This is a test issue to verify GitHub App permissions for Security Hub integration.',
                    'labels': ['test', 'security-hub']
                }
                
                issue_url = f'https://api.github.com/repos/{repo_name}/issues'
                issue_response = requests.post(issue_url, headers=repo_headers, json=test_issue_data)
                
                if issue_response.status_code == 201:
                    issue_data = issue_response.json()
                    print(f"✅ Issue creation successful!")
                    print(f"   Issue URL: {issue_data['html_url']}")
                    print(f"   Issue Number: {issue_data['number']}")
                    
                    # Clean up - delete the test issue
                    print(f"\n🧹 Cleaning up test issue...")
                    delete_response = requests.patch(
                        f'https://api.github.com/repos/{repo_name}/issues/{issue_data["number"]}',
                        headers=repo_headers,
                        json={'state': 'closed'}
                    )
                    if delete_response.status_code == 200:
                        print(f"✅ Test issue closed successfully")
                    else:
                        print(f"⚠️ Could not close test issue: {delete_response.status_code}")
                    
                else:
                    print(f"❌ Issue creation failed: {issue_response.status_code}")
                    print(f"   Response: {issue_response.text}")
                    
                    if issue_response.status_code == 410:
                        print(f"   This means issues are disabled for the repository")
                    elif issue_response.status_code == 403:
                        print(f"   This means the GitHub App doesn't have issue creation permissions")
                
            else:
                print(f"❌ Repository access failed: {repo_response.status_code}")
                print(f"   Response: {repo_response.text}")
                
        else:
            print(f"❌ Failed to get installation token: {response.status_code}")
            print(f"   Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error verifying GitHub App permissions: {str(e)}")

def check_installation_permissions():
    """Check the installation permissions"""
    print(f"\n📋 Installation Permissions Check")
    print(f"================================")
    
    app_id = "1719742"
    installation_id = "78968584"
    private_key = """-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAy2bsfBlI7YeAos+UxcDAMhzU6HCkap3UhvC4T7I3rmCI0E/Y
Slr8CSWr7U+hqp8ZtBJeq/aqmylExui2o/lY69i3T1ypydxCxbNjBWNfAAT+wXwQ
dxQK6lA7gIvA3bvdu09G3OYXBy7Ze5sMabo/iqAeLoU5pX6U7cbIbMO97Nf8q/8N
s+vetgqBBwHyVOizAWjhEwO3GkVR9BpABVxTQFS2GlAet7ec0SFGwVV+C/hQF7Xm
zsqnQbSi4mp2GQ9REg3AzBMnEY+idTUF41SrTB0RC3XxMkkm5K+k0nbh30sRgVMq
m3ZWG2ns7993MEltTLMemO+vDlDsOFEwY/j+kwIDAQABAoIBAQCjKeEye6YAxN3v
vMz/BWwnxvETtKhvzkQaKyfu5mu8OjwFvscmfm4HeGy+ZU6ubApWZRYEpE6fQS+m
0C8SwocOSj5iL1cUUthNd2VLgTdH8LnbxAYBP9axt8LDj1gbhwSLqUCTGxAF9xMH
EI2Ykos+TMtpTf28QBp/0yIb/blxLzMeP2H7c69zqxxYoa3A4yZdfI0cS7hB+Ck1
7nlNeCmIHXf6OhyuR9+YTV+b1drUD2bWaOCcZxV71MOPQvkvrEJSJFFVWMszeqDK
9YM62h2hkmescf8dvfKGNIxR0BuPG+IPeEk36p8U+KQHOyEWdc0+pBsU5fA1o7so
D8rQbbFBAoGBAPENq8CVBaiaEy1Z1a0nz7MKYzoZY8QKlLHTxyuCCtloqIzZEBUQ
ZLLkg4ZvZP9KsoRho+dfyLraobKITK4U3+uMobGTCGjIoiiWTwOVR1fS/ED2emNA
A8GAjq0v+lwdZd3YxNjhmzdAHifht7TqLB70tIKTW4DVAoQ44630HDm5AoGBANgD
mVzYXHLOVWfgXvDD6WsrRHnNJwHvLdWaUSzNZ9dz3zF05VB0U+Dns/nkLGqHBbzh
LTag0Hqd/brxbdB+8sBu2oqgrJ9pLKRdM9Aqp2UkKiz6dwIsVHiEkHKHmsjh8H5N
LEhqHRP9Z0SUJh8FRweJ8v390lRiJuucqOJTifCrAoGBALNaUqJ1vsIV8ZLatouh
hX5XikDeR0bEAKLXSefrWBsvLcmub7LcgbBBKkNKesEgWPb6lzM+J2Iv7gOiOjuE
OJ9QAbbYCXe9YDoGrD+kQHLt/tZvDdzu8lx1RLNDcWo8TWDlOoGMSyquwEE4RrGL
UsytkeldrsWKt9adZXo2mRGxAoGATs45VALm70dRJx1W5ZVDgcJ+L8VlVrJQUV4E
AUlKefKe2WchBZH6y9Eb+q2AeriZokev+/79L86Vs27Ctk6p9wQ6HFrzvxBapfgO
oAH/oclozZHues97XaBXJkFMeb7bwugaoKx9wT4wP3eg1K5TNG/iQ0EnS3unYUt8
3VzGtRMCgYBDCOMsXUAZfIOQkj0cdBFCzeZrOWuQTAKaB8TFu9KknG6QsDQAB/l5
FBMvyGoH4V+OGodlcVzn8v0bwcS1p6LErSrBoRjXkaFKYGY5+vOYdHJVXJW7Hc1n
r4HphjPxCvpv7LmHvddva3+4z5Du64I1sxsbvk971sAGBqEj2I+v7Q==
-----END RSA PRIVATE KEY-----"""
    
    try:
        # Generate JWT token
        now = int(time.time())
        payload = {
            'iat': now,
            'exp': now + (10 * 60),  # 10 minutes
            'iss': app_id
        }
        
        jwt_token = jwt.encode(payload, private_key, algorithm='RS256')
        
        # Get installation details
        headers = {
            'Authorization': f'Bearer {jwt_token}',
            'Accept': 'application/vnd.github.v3+json'
        }
        
        url = f'https://api.github.com/app/installations/{installation_id}'
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            installation_data = response.json()
            print(f"✅ Installation details retrieved")
            print(f"   Installation ID: {installation_data['id']}")
            print(f"   Account: {installation_data['account']['login']}")
            print(f"   Repository Selection: {installation_data.get('repository_selection', 'N/A')}")
            
            # Check permissions
            permissions = installation_data.get('permissions', {})
            print(f"\n📋 Current Permissions:")
            for permission, access in permissions.items():
                print(f"   {permission}: {access}")
            
            # Check if issues permission is present
            if 'issues' in permissions:
                print(f"\n✅ Issues permission: {permissions['issues']}")
                if permissions['issues'] == 'write':
                    print(f"   ✅ GitHub App has write access to issues")
                else:
                    print(f"   ⚠️ GitHub App has {permissions['issues']} access to issues")
            else:
                print(f"\n❌ No issues permission found")
                print(f"   Go to: https://github.com/settings/apps/security-hub-ticketing")
                print(f"   Add 'Issues: Read & write' permission")
            
        else:
            print(f"❌ Failed to get installation details: {response.status_code}")
            print(f"   Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error checking installation permissions: {str(e)}")

def main():
    """Main function"""
    print("🔧 GitHub App Permissions Verification")
    print("=====================================")
    
    # Check installation permissions
    check_installation_permissions()
    
    # Verify GitHub App permissions
    verify_github_app_permissions()
    
    print(f"\n🎯 Summary:")
    print(f"   - Check if issues are enabled in the repository")
    print(f"   - Verify GitHub App has 'Issues: Read & write' permission")
    print(f"   - Test issue creation manually if needed")

if __name__ == "__main__":
    main() 