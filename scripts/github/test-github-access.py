#!/usr/bin/env python3
"""
Test GitHub App Access to Repository
"""

import json
import time
import requests
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

def test_repository_access():
    """Test if the GitHub App can access the repository"""
    
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
    
    print("🔧 Testing GitHub App Repository Access")
    print("=" * 50)
    print(f"App ID: {app_id}")
    print(f"Installation ID: {installation_id}")
    print(f"Repository: {repo_name}")
    print()
    
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
            print("❌ Failed to create JWT token")
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
            access_token = token_data['token']
            print(f"✅ Installation token obtained successfully")
            print(f"   Token expires: {token_data.get('expires_at', 'Unknown')}")
            
            # Test repository access
            repo_headers = {
                'Authorization': f'Bearer {access_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            repo_url = f'https://api.github.com/repos/{repo_name}'
            repo_response = requests.get(repo_url, headers=repo_headers)
            
            if repo_response.status_code == 200:
                repo_data = repo_response.json()
                print(f"✅ Repository access confirmed!")
                print(f"   Repository: {repo_data['full_name']}")
                print(f"   Description: {repo_data.get('description', 'No description')}")
                print(f"   Private: {repo_data['private']}")
                print(f"   Issues enabled: {repo_data['has_issues']}")
                return True
            else:
                print(f"❌ Repository access failed: {repo_response.status_code}")
                print(f"   Response: {repo_response.text}")
                return False
                
        else:
            print(f"❌ Failed to get installation token: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing repository access: {str(e)}")
        return False

if __name__ == "__main__":
    test_repository_access() 