#!/bin/bash

# Update Lambda Function with New GitHub App Credentials
# This script contains the exact AWS CLI command to update the Lambda function

set -e

echo "🔧 Updating Lambda Function with New GitHub App Credentials"
echo "=========================================================="

# Check if AWS credentials are available
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please set your AWS credentials first."
    echo ""
    echo "You can set them using:"
    echo "export AWS_ACCESS_KEY_ID=your_access_key"
    echo "export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo "export AWS_SESSION_TOKEN=your_session_token"
    echo ""
    echo "Or run the AWS CLI command manually:"
    echo ""
    echo "aws lambda update-function-configuration \\"
    echo "  --function-name enhanced-auto-remediation-lambda-arm64 \\"
    echo "  --environment Variables='{"
    echo "    SNS_TOPIC_NAME=SecurityHubAutoRemediationAlerts,"
    echo "    BACKUP_ACCOUNT_ID=002616177731,"
    echo "    MANAGEMENT_ACCOUNT_ID=013983952777,"
    echo "    TICKET_TABLE_NAME=SecurityHubTickets,"
    echo "    GITHUB_AUTH_TYPE=github_app,"
    echo "    GITHUB_AUTH_VALUE=\"{\\\"app_id\\\":\\\"1719742\\\",\\\"installation_id\\\":\\\"78968584\\\",\\\"private_key\\\":\\\"-----BEGIN RSA PRIVATE KEY-----\\\\nMIIEpAIBAAKCAQEAy2bsfBlI7YeAos+UxcDAMhzU6HCkap3UhvC4T7I3rmCI0E/Y\\\\nSlr8CSWr7U+hqp8ZtBJeq/aqmylExui2o/lY69i3T1ypydxCxbNjBWNfAAT+wXwQ\\\\ndxQK6lA7gIvA3bvdu09G3OYXBy7Ze5sMabo/iqAeLoU5pX6U7cbIbMO97Nf8q/8N\\\\ns+vetgqBBwHyVOizAWjhEwO3GkVR9BpABVxTQFS2GlAet7ec0SFGwVV+C/hQF7Xm\\\\nzsqnQbSi4mp2GQ9REg3AzBMnEY+idTUF41SrTB0RC3XxMkkm5K+k0nbh30sRgVMq\\\\nm3ZWG2ns7993MEltTLMemO+vDlDsOFEwY/j+kwIDAQABAoIBAQCjKeEye6YAxN3v\\\\nvMz/BWwnxvETtKhvzkQaKyfu5mu8OjwFvscmfm4HeGy+ZU6ubApWZRYEpE6fQS+m\\\\n0C8SwocOSj5iL1cUUthNd2VLgTdH8LnbxAYBP9axt8LDj1gbhwSLqUCTGxAF9xMH\\\\nEI2Ykos+TMtpTf28QBp/0yIb/blxLzMeP2H7c69zqxxYoa3A4yZdfI0cS7hB+Ck1\\\\n7nlNeCmIHXf6OhyuR9+YTV+b1drUD2bWaOCcZxV71MOPQvkvrEJSJFFVWMszeqDK\\\\n9YM62h2hkmescf8dvfKGNIxR0BuPG+IPeEk36p8U+KQHOyEWdc0+pBsU5fA1o7so\\\\nD8rQbbFBAoGBAPENq8CVBaiaEy1Z1a0nz7MKYzoZY8QKlLHTxyuCCtloqIzZEBUQ\\\\nZLLkg4ZvZP9KsoRho+dfyLraobKITK4U3+uMobGTCGjIoiiWTwOVR1fS/ED2emNA\\\\nA8GAjq0v+lwdZd3YxNjhmzdAHifht7TqLB70tIKTW4DVAoQ44630HDm5AoGBANgD\\\\nmVzYXHLOVWfgXvDD6WsrRHnNJwHvLdWaUSzNZ9dz3zF05VB0U+Dns/nkLGqHBbzh\\\\nLTag0Hqd/brxbdB+8sBu2oqgrJ9pLKRdM9Aqp2UkKiz6dwIsVHiEkHKHmsjh8H5N\\\\nLEhqHRP9Z0SUJh8FRweJ8v390lRiJuucqOJTifCrAoGBALNaUqJ1vsIV8ZLatouh\\\\nhX5XikDeR0bEAKLXSefrWBsvLcmub7LcgbBBKkNKesEgWPb6lzM+J2Iv7gOiOjuE\\\\nOJ9QAbbYCXe9YDoGrD+kQHLt/tZvDdzu8lx1RLNDcWo8TWDlOoGMSyquwEE4RrGL\\\\nUsytkeldrsWKt9adZXo2mRGxAoGATs45VALm70dRJx1W5ZVDgcJ+L8VlVrJQUV4E\\\\nAUlKefKe2WchBZH6y9Eb+q2AeriZokev+/79L86Vs27Ctk6p9wQ6HFrzvxBapfgO\\\\noAH/oclozZHues97XaBXJkFMeb7bwugaoKx9wT4wP3eg1K5TNG/iQ0EnS3unYUt8\\\\n3VzGtRMCgYBDCOMsXUAZfIOQkj0cdBFCzeZrOWuQTAKaB8TFu9KknG6QsDQAB/l5\\\\nFBMvyGoH4V+OGodlcVzn8v0bwcS1p6LErSrBoRjXkaFKYGY5+vOYdHJVXJW7Hc1n\\\\nr4HphjPxCvpv7LmHvddva3+4z5Du64I1sxsbvk971sAGBqEj2I+v7Q==\\\\n-----END RSA PRIVATE KEY-----\\\\n\\\"},"
    echo "    GITHUB_REPO=Yayati-tech/Agent-Hubble"
    echo "  }' \\"
    echo "  --region us-west-2"
    exit 1
fi

echo "✅ AWS credentials verified"

# Update the Lambda function
echo "🔧 Updating Lambda function configuration..."

aws lambda update-function-configuration \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --environment Variables='{
    SNS_TOPIC_NAME=SecurityHubAutoRemediationAlerts,
    BACKUP_ACCOUNT_ID=002616177731,
    MANAGEMENT_ACCOUNT_ID=013983952777,
    TICKET_TABLE_NAME=SecurityHubTickets,
    GITHUB_AUTH_TYPE=github_app,
    GITHUB_AUTH_VALUE="{\"app_id\":\"1719742\",\"installation_id\":\"78968584\",\"private_key\":\"-----BEGIN RSA PRIVATE KEY-----\\nMIIEpAIBAAKCAQEAy2bsfBlI7YeAos+UxcDAMhzU6HCkap3UhvC4T7I3rmCI0E/Y\\nSlr8CSWr7U+hqp8ZtBJeq/aqmylExui2o/lY69i3T1ypydxCxbNjBWNfAAT+wXwQ\\ndxQK6lA7gIvA3bvdu09G3OYXBy7Ze5sMabo/iqAeLoU5pX6U7cbIbMO97Nf8q/8N\\ns+vetgqBBwHyVOizAWjhEwO3GkVR9BpABVxTQFS2GlAet7ec0SFGwVV+C/hQF7Xm\\nzsqnQbSi4mp2GQ9REg3AzBMnEY+idTUF41SrTB0RC3XxMkkm5K+k0nbh30sRgVMq\\nm3ZWG2ns7993MEltTLMemO+vDlDsOFEwY/j+kwIDAQABAoIBAQCjKeEye6YAxN3v\\nvMz/BWwnxvETtKhvzkQaKyfu5mu8OjwFvscmfm4HeGy+ZU6ubApWZRYEpE6fQS+m\\n0C8SwocOSj5iL1cUUthNd2VLgTdH8LnbxAYBP9axt8LDj1gbhwSLqUCTGxAF9xMH\\nEI2Ykos+TMtpTf28QBp/0yIb/blxLzMeP2H7c69zqxxYoa3A4yZdfI0cS7hB+Ck1\\n7nlNeCmIHXf6OhyuR9+YTV+b1drUD2bWaOCcZxV71MOPQvkvrEJSJFFVWMszeqDK\\n9YM62h2hkmescf8dvfKGNIxR0BuPG+IPeEk36p8U+KQHOyEWdc0+pBsU5fA1o7so\\nD8rQbbFBAoGBAPENq8CVBaiaEy1Z1a0nz7MKYzoZY8QKlLHTxyuCCtloqIzZEBUQ\\nZLLkg4ZvZP9KsoRho+dfyLraobKITK4U3+uMobGTCGjIoiiWTwOVR1fS/ED2emNA\\nA8GAjq0v+lwdZd3YxNjhmzdAHifht7TqLB70tIKTW4DVAoQ44630HDm5AoGBANgD\\nmVzYXHLOVWfgXvDD6WsrRHnNJwHvLdWaUSzNZ9dz3zF05VB0U+Dns/nkLGqHBbzh\\nLTag0Hqd/brxbdB+8sBu2oqgrJ9pLKRdM9Aqp2UkKiz6dwIsVHiEkHKHmsjh8H5N\\nLEhqHRP9Z0SUJh8FRweJ8v390lRiJuucqOJTifCrAoGBALNaUqJ1vsIV8ZLatouh\\nhX5XikDeR0bEAKLXSefrWBsvLcmub7LcgbBBKkNKesEgWPb6lzM+J2Iv7gOiOjuE\\nOJ9QAbbYCXe9YDoGrD+kQHLt/tZvDdzu8lx1RLNDcWo8TWDlOoGMSyquwEE4RrGL\\nUsytkeldrsWKt9adZXo2mRGxAoGATs45VALm70dRJx1W5ZVDgcJ+L8VlVrJQUV4E\\nAUlKefKe2WchBZH6y9Eb+q2AeriZokev+/79L86Vs27Ctk6p9wQ6HFrzvxBapfgO\\noAH/oclozZHues97XaBXJkFMeb7bwugaoKx9wT4wP3eg1K5TNG/iQ0EnS3unYUt8\\n3VzGtRMCgYBDCOMsXUAZfIOQkj0cdBFCzeZrOWuQTAKaB8TFu9KknG6QsDQAB/l5\\nFBMvyGoH4V+OGodlcVzn8v0bwcS1p6LErSrBoRjXkaFKYGY5+vOYdHJVXJW7Hc1n\\nr4HphjPxCvpv7LmHvddva3+4z5Du64I1sxsbvk971sAGBqEj2I+v7Q==\\n-----END RSA PRIVATE KEY-----\\n\"}",
    GITHUB_REPO=Yayati-tech/Agent-Hubble
  }' \
  --region us-west-2

if [ $? -eq 0 ]; then
    echo "✅ Lambda function configuration updated successfully"
    
    echo ""
    echo "⏳ Waiting for update to complete..."
    sleep 10
    
    echo ""
    echo "🧪 Testing the updated configuration..."
    
    # Test the function
    aws lambda invoke \
      --function-name enhanced-auto-remediation-lambda-arm64 \
      --payload file://test-crypto-fix.json \
      --cli-binary-format raw-in-base64-out \
      response-github-app-test.json \
      --region us-west-2
    
    if [ $? -eq 0 ]; then
        echo "✅ Lambda function test successful"
        
        # Check the response
        if [ -f response-github-app-test.json ]; then
            echo "📄 Response:"
            cat response-github-app-test.json
            echo ""
        fi
    else
        echo "❌ Lambda function test failed"
    fi
    
    # Clean up test file
    rm -f response-github-app-test.json
    
else
    echo "❌ Failed to update Lambda function configuration"
    exit 1
fi

echo ""
echo "🎉 GitHub App configuration updated successfully!"
echo ""
echo "📋 Summary:"
echo "   App ID: 1719742"
echo "   Installation ID: 78968584"
echo "   Repository: Yayati-tech/Agent-Hubble"
echo "   Function: enhanced-auto-remediation-lambda-arm64"
echo ""
echo "🔗 Useful links:"
echo "   Repository: https://github.com/Yayati-tech/Agent-Hubble"
echo "   Issues: https://github.com/Yayati-tech/Agent-Hubble/issues"
echo "   CloudWatch Logs: /aws/lambda/enhanced-auto-remediation-lambda-arm64" 