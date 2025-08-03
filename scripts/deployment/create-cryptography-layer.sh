#!/bin/bash

# Create Lambda Layer with Cryptography Module
# This solves the "invalid ELF header" issue by providing Linux-compatible binaries

set -e

echo "🔧 Creating Lambda Layer with Cryptography Module"
echo "================================================="

LAYER_NAME="cryptography-layer"
REGION="us-west-2"

# Create temporary directory for the layer
mkdir -p lambda-layer/python

echo "📦 Installing cryptography for Linux..."

# Install cryptography for Linux in the layer directory
pip3 install --target lambda-layer/python cryptography==3.4.8 --platform manylinux1_x86_64 --only-binary=all --no-deps

# If the above fails, try downloading pre-compiled wheel
if [ ! -d "lambda-layer/python/cryptography" ]; then
    echo "📥 Downloading pre-compiled cryptography wheel..."
    cd lambda-layer/python
    
    # Download Linux-compatible cryptography wheel
    curl -L -o cryptography-3.4.8-cp37-cp37m-manylinux1_x86_64.whl \
         "https://files.pythonhosted.org/packages/9b/77/461087a514d2e8ece1c975d8216bc03f7048e6090c5166bc34115afdaa9c/cryptography-3.4.8-cp37-cp37m-manylinux1_x86_64.whl"
    
    # Extract the wheel
    unzip -q cryptography-3.4.8-cp37-cp37m-manylinux1_x86_64.whl
    
    # Clean up
    rm cryptography-3.4.8-cp37-cp37m-manylinux1_x86_64.whl
    
    cd ../..
fi

echo "📦 Installing PyJWT for Linux..."
pip3 install --target lambda-layer/python PyJWT==2.8.0 --platform manylinux1_x86_64 --only-binary=all --no-deps

echo "🗜️ Creating layer package..."
cd lambda-layer
zip -r ../cryptography-layer.zip .
cd ..

echo "🚀 Publishing Lambda Layer..."

# Create the layer
aws lambda publish-layer-version \
    --layer-name $LAYER_NAME \
    --description "Cryptography and PyJWT modules for GitHub App authentication" \
    --zip-file fileb://cryptography-layer.zip \
    --compatible-runtimes python3.9 \
    --compatible-architectures arm64 \
    --region $REGION

echo "✅ Lambda Layer created successfully!"

# Get the layer ARN
LAYER_ARN=$(aws lambda list-layer-versions \
    --layer-name $LAYER_NAME \
    --region $REGION \
    --query 'LayerVersions[0].LayerVersionArn' \
    --output text)

echo "📋 Layer ARN: $LAYER_ARN"

echo "🔄 Updating Lambda function with the layer..."

# Update Lambda function to use the layer
aws lambda update-function-configuration \
    --function-name enhanced-auto-remediation-lambda-arm64 \
    --layers $LAYER_ARN \
    --region $REGION

echo "✅ Lambda function updated with cryptography layer!"

echo "🧹 Cleaning up..."
rm -rf lambda-layer cryptography-layer.zip

echo ""
echo "🎉 Cryptography Layer Setup Complete!"
echo "===================================="
echo ""
echo "📋 What was done:"
echo "   ✅ Created Lambda layer with cryptography module"
echo "   ✅ Added PyJWT module to the layer"
echo "   ✅ Published layer to AWS Lambda"
echo "   ✅ Updated Lambda function to use the layer"
echo ""
echo "🚀 Next Steps:"
echo "   1. Test the Lambda function:"
echo "      aws lambda invoke --function-name enhanced-auto-remediation-lambda-arm64 --payload file://test-payload.json --cli-binary-format raw-in-base64-out response.json"
echo "   2. Check if GitHub issues are now being created"
echo ""
echo "🔗 Layer Details:"
echo "   - Name: $LAYER_NAME"
echo "   - ARN: $LAYER_ARN"
echo "   - Region: $REGION"
echo "" 