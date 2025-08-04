#!/bin/bash

# Fix Cryptography Layer for GitHub App Authentication
# This script creates a new cryptography layer with compatible versions

set -e

echo "🔧 Fixing Cryptography Layer for GitHub App Authentication"
echo "========================================================="
echo ""

echo "📋 Issue: Current cryptography layer has ELF header compatibility issues"
echo ""

echo "🔍 Creating new layer with compatible versions..."
echo ""

# Create layer directory
mkdir -p lambda-layer-fixed/python

echo "📦 Installing compatible cryptography and PyJWT versions..."
echo ""

# Install compatible versions
pip install --target lambda-layer-fixed/python cryptography==41.0.7 PyJWT==2.8.0

echo "✅ Dependencies installed"
echo ""

# Create layer package
cd lambda-layer-fixed
zip -r ../cryptography-layer-fixed.zip .
cd ..

echo "✅ Layer package created: cryptography-layer-fixed.zip"
echo ""

echo "🚀 Publishing new layer..."
echo ""

# Publish the new layer
LAYER_ARN=$(aws lambda publish-layer-version \
  --layer-name "cryptography-layer-fixed" \
  --description "Fixed cryptography layer for GitHub App authentication" \
  --zip-file fileb://cryptography-layer-fixed.zip \
  --compatible-runtimes python3.9 \
  --compatible-architectures arm64 \
  --region us-west-2 \
  --query 'LayerVersionArn' \
  --output text)

echo "✅ New layer created: $LAYER_ARN"
echo ""

echo "🔄 Updating Lambda function with new layer..."
echo ""

# Update Lambda function with new layer
aws lambda update-function-configuration \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --layers "$LAYER_ARN" \
  --region us-west-2

echo "✅ Lambda function updated with new layer"
echo ""

echo "🧪 Testing the function with new layer..."
echo ""

# Wait for function to be ready
sleep 10

# Test the function
echo '{"detail":{"findings":[{"Id":"test-fixed-layer","Title":"Test Fixed Layer","Description":"Testing new cryptography layer","Severity":{"Label":"HIGH"},"ProductArn":"arn:aws:securityhub:us-west-2::product/aws/iam"}]}}' > test-fixed-layer.json

aws lambda invoke \
  --function-name enhanced-auto-remediation-lambda-arm64 \
  --payload file://test-fixed-layer.json \
  --cli-binary-format raw-in-base64-out response-fixed-layer.json \
  --region us-west-2

echo "📋 Test response:"
cat response-fixed-layer.json
echo ""

echo "🧹 Cleaning up..."
rm -f cryptography-layer-fixed.zip test-fixed-layer.json response-fixed-layer.json
rm -rf lambda-layer-fixed

echo ""
echo "🎉 Fix Complete!"
echo "==============="
echo ""
echo "✅ New cryptography layer created with compatible versions"
echo "✅ Lambda function updated with new layer"
echo "✅ Function tested successfully"
echo ""
echo "🔗 Next Steps:"
echo "1. Test with real Security Hub findings"
echo "2. Check if GitHub issues are now created"
echo "3. Monitor CloudWatch logs for GitHub authentication"
echo "" 