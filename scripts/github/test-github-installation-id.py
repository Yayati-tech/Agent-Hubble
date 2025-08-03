#!/usr/bin/env python3
"""
Test GitHub App Installation ID
This script helps find the correct installation ID for a GitHub App
"""

import json
import time
import jwt
import requests
import sys

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
        
        jwt_token = jwt.encode(payload, private_key, algorithm='RS256')
        
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
    print("🔧 GitHub App Installation ID Finder")
    print("====================================")
    
    # GitHub App credentials
    app_id = "1719009"
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
    repo_name = "Yayati-tech/Agent-Hubble"
    
    # Find the correct installation ID
    installation_id = find_installation_id(app_id, private_key, repo_name)
    
    if installation_id:
        # Test the installation token
        success = test_installation_token(app_id, installation_id, private_key)
        
        if success:
            print(f"\n✅ SUCCESS! Correct Installation ID: {installation_id}")
            print(f"   Update your Lambda environment variable GITHUB_AUTH_VALUE with:")
            print(f"   {{\"app_id\":\"{app_id}\",\"installation_id\":\"{installation_id}\",\"private_key\":\"...\"}}")
        else:
            print(f"\n❌ Installation ID {installation_id} is not working")
    else:
        print("\n❌ No valid installation ID found")

if __name__ == "__main__":
    main() 