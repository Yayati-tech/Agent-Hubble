#!/bin/bash

# Update Lambda function with GitHub App configuration
# Run this script after configuring AWS credentials

set -e

FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
REGION="us-west-2"

echo "🔄 Updating Lambda function with GitHub App configuration..."

aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --environment file://env-vars-github-app-corrected.json \
    --region $REGION

echo "✅ Lambda function updated successfully!"

# Create CloudWatch dashboard
echo "📊 Creating CloudWatch dashboard..."

cat > github-app-dashboard.json << 'DASHBOARD_EOF'
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Lambda", "Duration", "FunctionName", "$FUNCTION_NAME"],
                    [".", "Errors", ".", "."],
                    [".", "Invocations", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "GitHub App Integration Lambda Performance"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Lambda", "Throttles", "FunctionName", "$FUNCTION_NAME"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$REGION",
                "title": "Lambda Throttles"
            }
        }
    ]
}
DASHBOARD_EOF

aws cloudwatch put-dashboard \
    --dashboard-name "GitHubAppDashboard" \
    --dashboard-body file://github-app-dashboard.json \
    --region $REGION

echo "✅ CloudWatch dashboard created: GitHubAppDashboard"

# Clean up
rm -f github-app-dashboard.json

echo "🎉 AWS resources updated successfully!" 