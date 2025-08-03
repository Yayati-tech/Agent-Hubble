#!/bin/bash

# Build Cryptography Module Using Docker
# This creates Linux-compatible packages by building in a Linux container

set -e

echo "🐳 Building Cryptography Module Using Docker"
echo "============================================"

# Create Dockerfile for building cryptography
cat > Dockerfile.crypto << 'DOCKERFILE_EOF'
FROM public.ecr.aws/lambda/python:3.9

# Install build dependencies
RUN yum install -y gcc openssl-devel libffi-devel

# Create build directory
WORKDIR /build

# Copy requirements
COPY requirements-crypto.txt .

# Install cryptography and PyJWT
RUN pip install -r requirements-crypto.txt -t python/

# Copy the python directory to output
CMD cp -r python /output/
DOCKERFILE_EOF

# Create requirements file for cryptography
cat > requirements-crypto.txt << 'REQ_EOF'
cryptography==3.4.8
PyJWT==2.8.0
REQ_EOF

echo "🔨 Building Docker image..."

# Build the Docker image
docker build -f Dockerfile.crypto -t cryptography-builder .

echo "📦 Extracting cryptography package..."

# Create output directory
mkdir -p crypto-output

# Run container to extract the package
docker run --rm -v $(pwd)/crypto-output:/output cryptography-builder

echo "🔄 Updating Lambda deployment package..."

# Copy cryptography modules to deployment directory
cp -r crypto-output/python/* deployment-arm64/

echo "🗜️ Rebuilding Lambda deployment package..."

# Rebuild the Lambda deployment package
cd deployment-arm64
zip -r ../lambda-deployment-package-arm64.zip .
cd ..

echo "🚀 Updating Lambda function..."

# Update Lambda function
aws lambda update-function-code \
    --function-name enhanced-auto-remediation-lambda-arm64 \
    --zip-file fileb://lambda-deployment-package-arm64.zip \
    --region us-west-2

echo "✅ Lambda function updated with Linux-compatible cryptography!"

echo "🧹 Cleaning up..."
rm -rf crypto-output Dockerfile.crypto requirements-crypto.txt

echo ""
echo "🎉 Docker Build Complete!"
echo "========================"
echo ""
echo "📋 What was done:"
echo "   ✅ Built cryptography in Linux container"
echo "   ✅ Created Linux-compatible binaries"
echo "   ✅ Updated Lambda deployment package"
echo "   ✅ Updated Lambda function"
echo ""
echo "🚀 Next Steps:"
echo "   1. Test the Lambda function:"
echo "      aws lambda invoke --function-name enhanced-auto-remediation-lambda-arm64 --payload file://test-payload.json --cli-binary-format raw-in-base64-out response.json"
echo "   2. Check if GitHub issues are now being created"
echo "" 