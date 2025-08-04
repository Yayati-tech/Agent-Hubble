#!/bin/bash

# Update Lambda with new cryptography requirements
# This script updates the Lambda function with cryptography>=42.0.2

set -e

# Configuration
FUNCTION_NAME="enhanced-auto-remediation-lambda"
REGION="us-west-2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Updating Lambda function with new cryptography requirements...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Check if Lambda function exists
if ! aws lambda get-function --function-name $FUNCTION_NAME &> /dev/null; then
    echo -e "${RED}❌ Lambda function $FUNCTION_NAME does not exist. Please deploy it first using deploy.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Creating deployment package with new cryptography requirements...${NC}"

# Create deployment directory
rm -rf deployment-crypto-update
mkdir -p deployment-crypto-update

# Copy Lambda function
cp enhanced-auto-remediation-lambda.py deployment-crypto-update/

# Create requirements.txt with new cryptography version
cat > deployment-crypto-update/requirements.txt << EOF
boto3>=1.26.0
botocore>=1.29.0
requests>=2.28.0
PyJWT>=2.8.0
cryptography>=42.0.2
EOF

# Install dependencies
echo -e "${YELLOW}📥 Installing dependencies with cryptography>=42.0.2...${NC}"
cd deployment-crypto-update
pip install -r requirements.txt -t .
cd ..

# Create deployment package
echo -e "${YELLOW}📦 Creating ZIP package...${NC}"
cd deployment-crypto-update
zip -r ../lambda-crypto-update-package.zip .
cd ..

echo -e "${GREEN}✅ Deployment package created: lambda-crypto-update-package.zip${NC}"

# Update Lambda function
echo -e "${YELLOW}🚀 Updating Lambda function with new cryptography...${NC}"

aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --zip-file fileb://lambda-crypto-update-package.zip

echo -e "${GREEN}✅ Lambda function updated successfully!${NC}"

# Clean up
rm -rf deployment-crypto-update
rm -f lambda-crypto-update-package.zip

echo -e "${GREEN}🎉 Lambda function updated with cryptography>=42.0.2!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "  1. Test the function to ensure it works with the new cryptography version"
echo -e "  2. Monitor CloudWatch logs for any issues"
echo -e "  3. Verify GitHub App authentication works properly" 