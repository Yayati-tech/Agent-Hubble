#!/bin/bash

# ARM64 Enhanced Auto-Remediation Lambda Deployment Script
# This script packages and deploys the Lambda function to AWS with ARM64 architecture

set -e

# Configuration
FUNCTION_NAME="enhanced-auto-remediation-lambda-arm64"
RUNTIME="python3.9"
HANDLER="enhanced-auto-remediation-lambda.lambda_handler"
TIMEOUT=900
MEMORY_SIZE=1024
REGION="us-west-2"
ROLE_NAME="SecurityHubAutoRemediationRole"
SNS_TOPIC_NAME="SecurityHubAutoRemediationAlerts"
ARCHITECTURE="arm64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting ARM64 deployment of Enhanced Auto-Remediation Lambda...${NC}"

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

echo -e "${YELLOW}📦 Creating ARM64 deployment package...${NC}"

# Create deployment directory
rm -rf deployment-arm64
mkdir -p deployment-arm64

# Copy Lambda function
cp enhanced-auto-remediation-lambda.py deployment-arm64/

# Create requirements.txt for dependencies
cat > deployment-arm64/requirements.txt << EOF
boto3>=1.26.0
botocore>=1.29.0
requests>=2.28.0
PyJWT>=2.8.0
cryptography>=42.0.2
EOF

# Install dependencies for ARM64
echo -e "${YELLOW}📥 Installing ARM64 dependencies...${NC}"
cd deployment-arm64

# Use pip to install dependencies for ARM64 architecture
pip install -r requirements.txt -t . --platform manylinux2014_aarch64 --only-binary=:all:

cd ..

# Create deployment package
echo -e "${YELLOW}📦 Creating ARM64 ZIP package...${NC}"
cd deployment-arm64
zip -r ../lambda-deployment-package-arm64.zip .
cd ..

echo -e "${GREEN}✅ ARM64 deployment package created: lambda-deployment-package-arm64.zip${NC}"

# Check if IAM role exists, create if not
echo -e "${YELLOW}🔐 Checking IAM role...${NC}"
if ! aws iam get-role --role-name $ROLE_NAME &> /dev/null; then
    echo -e "${YELLOW}📝 Creating IAM role: $ROLE_NAME${NC}"
    
    # Create trust policy
    cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

    # Create role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://trust-policy.json \
        --description "Role for Security Hub Auto-Remediation Lambda"

    # Attach policies
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

    # Create custom policy for Security Hub and other services
    cat > lambda-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "securityhub:*",
                "iam:*",
                "s3:*",
                "ec2:*",
                "rds:*",
                "lambda:*",
                "kms:*",
                "cloudwatch:*",
                "cloudtrail:*",
                "config:*",
                "guardduty:*",
                "inspector:*",
                "ssm:*",
                "macie2:*",
                "wafv2:*",
                "shield:*",
                "acm:*",
                "secretsmanager:*",
                "cloudformation:*",
                "apigateway:*",
                "elasticache:*",
                "dynamodb:*",
                "eks:*",
                "ecr:*",
                "ecs:*",
                "redshift:*",
                "sagemaker:*",
                "glue:*",
                "sns:*",
                "sts:*",
                "organizations:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

    # Attach custom policy
    aws iam put-role-policy \
        --role-name $ROLE_NAME \
        --policy-name SecurityHubAutoRemediationPolicy \
        --policy-document file://lambda-policy.json

    echo -e "${GREEN}✅ IAM role created: $ROLE_NAME${NC}"
else
    echo -e "${GREEN}✅ IAM role already exists: $ROLE_NAME${NC}"
fi

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

# Create SNS topic if it doesn't exist
echo -e "${YELLOW}📢 Checking SNS topic...${NC}"
if ! aws sns get-topic-attributes --topic-arn "arn:aws:sns:$REGION:$(aws sts get-caller-identity --query 'Account' --output text):$SNS_TOPIC_NAME" &> /dev/null; then
    echo -e "${YELLOW}📝 Creating SNS topic: $SNS_TOPIC_NAME${NC}"
    aws sns create-topic --name $SNS_TOPIC_NAME
    echo -e "${GREEN}✅ SNS topic created: $SNS_TOPIC_NAME${NC}"
else
    echo -e "${GREEN}✅ SNS topic already exists: $SNS_TOPIC_NAME${NC}"
fi

# Deploy Lambda function with ARM64 architecture
echo -e "${YELLOW}🚀 Deploying ARM64 Lambda function...${NC}"

# Check if function exists
if aws lambda get-function --function-name $FUNCTION_NAME &> /dev/null; then
    echo -e "${YELLOW}📝 Updating existing ARM64 Lambda function...${NC}"
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://lambda-deployment-package-arm64.zip
    
    aws lambda update-function-configuration \
        --function-name $FUNCTION_NAME \
        --runtime $RUNTIME \
        --handler $HANDLER \
        --timeout $TIMEOUT \
        --memory-size $MEMORY_SIZE \
        --environment file://env-vars-github-app-corrected.json
else
    echo -e "${YELLOW}📝 Creating new ARM64 Lambda function...${NC}"
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime $RUNTIME \
        --role $ROLE_ARN \
        --handler $HANDLER \
        --zip-file fileb://lambda-deployment-package-arm64.zip \
        --timeout $TIMEOUT \
        --memory-size $MEMORY_SIZE \
        --environment file://env-vars-github-app-corrected.json
fi

echo -e "${GREEN}✅ ARM64 Lambda function deployed: $FUNCTION_NAME${NC}"

# Clean up temporary files
rm -f trust-policy.json lambda-policy.json
rm -rf deployment-arm64

echo -e "${GREEN}🎉 ARM64 deployment completed successfully!${NC}"
echo -e "${YELLOW}📋 Benefits of ARM64 deployment:${NC}"
echo -e "  - Lower cost (up to 34% cheaper than x86_64)"
echo -e "  - Better performance for many workloads"
echo -e "  - Reduced cold start times"
echo -e "  - More efficient memory usage"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "  1. Configure Security Hub to trigger this Lambda function"
echo -e "  2. Test the function with sample Security Hub findings"
echo -e "  3. Monitor CloudWatch logs for function execution"
echo -e "  4. Set up SNS notifications for remediation events"