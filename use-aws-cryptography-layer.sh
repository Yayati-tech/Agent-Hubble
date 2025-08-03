#!/bin/bash

# Use AWS Pre-built Cryptography Layer
# This uses AWS's official cryptography layer

set -e

echo "☁️ Using AWS Pre-built Cryptography Layer"
echo "=========================================="

REGION="us-west-2"
FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"

# AWS provides a cryptography layer, but we'll create our own
echo "🔧 Creating custom cryptography layer..."

# Create layer directory
mkdir -p crypto-layer/python

echo "📦 Installing cryptography for Lambda..."

# Use pip to install cryptography for the correct platform
pip3 install --target crypto-layer/python cryptography==3.4.8 --platform manylinux1_x86_64 --only-binary=all --no-deps

# Also install PyJWT
pip3 install --target crypto-layer/python PyJWT==2.8.0 --platform manylinux1_x86_64 --only-binary=all --no-deps

echo "🗜️ Creating layer package..."
cd crypto-layer
zip -r ../crypto-layer.zip .
cd ..

echo "🚀 Publishing Lambda Layer..."

# Create the layer
LAYER_ARN=$(aws lambda publish-layer-version \
    --layer-name "cryptography-layer" \
    --description "Cryptography and PyJWT for GitHub App authentication" \
    --zip-file fileb://crypto-layer.zip \
    --compatible-runtimes python3.9 \
    --compatible-architectures arm64 \
    --region $REGION \
    --query 'LayerVersionArn' \
    --output text)

echo "✅ Layer created: $LAYER_ARN"

echo "🔄 Updating Lambda function with cryptography layer..."

# Update Lambda function to use the layer
aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --layers $LAYER_ARN \
    --region $REGION

echo "✅ Lambda function updated with cryptography layer!"

echo "🧹 Cleaning up..."
rm -rf crypto-layer crypto-layer.zip

echo ""
echo "🎉 AWS Cryptography Layer Setup Complete!"
echo "========================================"
echo ""
echo "📋 What was done:"
echo "   ✅ Created cryptography layer"
echo "   ✅ Added PyJWT to the layer"
echo "   ✅ Published layer to AWS Lambda"
echo "   ✅ Updated Lambda function"
echo ""
echo "🚀 Next Steps:"
echo "   1. Test the Lambda function:"
echo "      aws lambda invoke --function-name $FUNCTION_NAME --payload file://test-payload.json --cli-binary-format raw-in-base64-out response.json"
echo "   2. Check if GitHub issues are now being created"
echo ""
echo "🔗 Layer Details:"
echo "   - ARN: $LAYER_ARN"
echo "   - Region: $REGION"
echo "" 