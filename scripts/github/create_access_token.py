#!/usr/bin/env python3
import json
import time
import jwt
import requests
import os

def create_access_token():
    app_id = os.environ.get('GITHUB_APP_ID')
    installation_id = os.environ.get('GITHUB_INSTALLATION_ID')
    private_key = os.environ.get('GITHUB_PRIVATE_KEY')
    
    # Generate JWT token
    now = int(time.time())
    payload = {
        'iat': now,
        'exp': now + (10 * 60),
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
        return token_data['token']
    else:
        raise Exception(f"Failed to get installation token: {response.status_code}")

if __name__ == "__main__":
    try:
        token = create_access_token()
        print(token)
    except Exception as e:
        print(f"Error: {str(e)}")
        exit(1)
