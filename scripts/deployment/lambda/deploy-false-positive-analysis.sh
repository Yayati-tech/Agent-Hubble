#!/bin/bash

# False Positive Analysis Lambda Deployment Script
# This script packages and deploys the False Positive Analysis Lambda function to AWS

set -e

# Configuration
FUNCTION_NAME="false-positive-analysis-lambda"
RUNTIME="python3.9"
HANDLER="false_positive_analysis.lambda_handler"
TIMEOUT=300  # 5 minutes for ML processing
MEMORY_SIZE=2048  # 2GB for ML workloads
REGION="us-west-2"
ROLE_NAME="FalsePositiveAnalysisRole"
SNS_TOPIC_NAME="FalsePositiveAnalysisAlerts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment of False Positive Analysis Lambda...${NC}"

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

echo -e "${YELLOW}📦 Creating deployment package...${NC}"

# Create deployment directory
rm -rf deployment-fp-analysis
mkdir -p deployment-fp-analysis

# Copy Lambda function
cp false_positive_analysis.py deployment-fp-analysis/

# Create requirements.txt for dependencies
cat > deployment-fp-analysis/requirements.txt << EOF
boto3>=1.26.0
botocore>=1.29.0
scikit-learn>=1.0.0
pandas>=1.3.0
numpy>=1.21.0
cryptography>=42.0.2
EOF

# Install dependencies
echo -e "${YELLOW}📥 Installing dependencies...${NC}"
cd deployment-fp-analysis
pip install -r requirements.txt -t .
cd ..

# Create deployment package
echo -e "${YELLOW}📦 Creating ZIP package...${NC}"
cd deployment-fp-analysis
zip -r ../fp-analysis-deployment-package.zip .
cd ..

echo -e "${GREEN}✅ Deployment package created: fp-analysis-deployment-package.zip${NC}"

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

    # Create the role
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://trust-policy.json

    # Attach basic execution policy
    aws iam attach-role-policy \
        --role-name $ROLE_NAME \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

    # Create custom policy for False Positive Analysis
    cat > fp-analysis-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:InvokeEndpoint",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Query",
                "dynamodb:Scan",
                "cloudwatch:PutMetricData",
                "lambda:InvokeFunction",
                "securityhub:BatchUpdateFindings",
                "securityhub:GetFindings"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF

    # Attach custom policy
    aws iam put-role-policy \
        --role-name $ROLE_NAME \
        --policy-name FalsePositiveAnalysisPolicy \
        --policy-document file://fp-analysis-policy.json

    echo -e "${GREEN}✅ IAM role created: $ROLE_NAME${NC}"
else
    echo -e "${GREEN}✅ IAM role already exists: $ROLE_NAME${NC}"
fi

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

# Check if SNS topic exists, create if not
echo -e "${YELLOW}📢 Checking SNS topic...${NC}"
if ! aws sns get-topic-attributes --topic-arn "arn:aws:sns:$REGION:$(aws sts get-caller-identity --query 'Account' --output text):$SNS_TOPIC_NAME" &> /dev/null; then
    echo -e "${YELLOW}📝 Creating SNS topic: $SNS_TOPIC_NAME${NC}"
    aws sns create-topic --name $SNS_TOPIC_NAME
    echo -e "${GREEN}✅ SNS topic created: $SNS_TOPIC_NAME${NC}"
else
    echo -e "${GREEN}✅ SNS topic already exists: $SNS_TOPIC_NAME${NC}"
fi

# Check if Lambda function exists
echo -e "${YELLOW}🔍 Checking Lambda function...${NC}"
if aws lambda get-function --function-name $FUNCTION_NAME &> /dev/null; then
    echo -e "${YELLOW}📝 Updating existing Lambda function...${NC}"
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://fp-analysis-deployment-package.zip
    
    aws lambda update-function-configuration \
        --function-name $FUNCTION_NAME \
        --timeout $TIMEOUT \
        --memory-size $MEMORY_SIZE \
        --environment Variables='{"SNS_TOPIC_NAME":"'$SNS_TOPIC_NAME'","REGION":"'$REGION'"}'
else
    echo -e "${YELLOW}📝 Creating new Lambda function...${NC}"
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime $RUNTIME \
        --role $ROLE_ARN \
        --handler $HANDLER \
        --zip-file fileb://fp-analysis-deployment-package.zip \
        --timeout $TIMEOUT \
        --memory-size $MEMORY_SIZE \
        --environment Variables='{"SNS_TOPIC_NAME":"'$SNS_TOPIC_NAME'","REGION":"'$REGION'"}'
fi

echo -e "${GREEN}✅ Lambda function deployed: $FUNCTION_NAME${NC}"

# Clean up temporary files
rm -f trust-policy.json fp-analysis-policy.json
rm -rf deployment-fp-analysis

echo -e "${GREEN}🎉 False Positive Analysis Lambda deployment completed successfully!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "  1. Configure the main Lambda to invoke this function"
echo -e "  2. Set up ML models in SageMaker (if using ML classification)"
echo -e "  3. Create DynamoDB table for pattern storage"
echo -e "  4. Test the function with sample Security Hub findings"
echo -e "  5. Monitor CloudWatch logs for function execution"
echo -e "  6. Set up CloudWatch dashboards for monitoring"

# Display function information
echo -e "${GREEN}📊 Function Information:${NC}"
echo -e "  Function Name: $FUNCTION_NAME"
echo -e "  Runtime: $RUNTIME"
echo -e "  Handler: $HANDLER"
echo -e "  Timeout: $TIMEOUT seconds"
echo -e "  Memory: $MEMORY_SIZE MB"
echo -e "  Role: $ROLE_NAME"
echo -e "  Region: $REGION" 