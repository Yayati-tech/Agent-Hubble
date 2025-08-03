#!/bin/bash

# Fix GitHub App Configuration
# This script helps identify and fix GitHub App installation ID issues

set -e

echo "🔧 GitHub App Configuration Fix"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📋 Current GitHub App Configuration:${NC}"
echo -e "${BLUE}   App ID: 1719009${NC}"
echo -e "${BLUE}   Current Installation ID: Iv23lipU7TXAKNYvi57H${NC}"
echo -e "${BLUE}   Repository: Yayati-tech/Agent-Hubble${NC}"
echo ""

echo -e "${YELLOW}🔍 Issue Analysis:${NC}"
echo -e "${RED}   ❌ Installation ID 'Iv23lipU7TXAKNYvi57H' is not numeric${NC}"
echo -e "${RED}   ❌ This is likely a GitHub App installation slug, not the numeric ID${NC}"
echo -e "${RED}   ❌ The Lambda function expects a numeric installation ID${NC}"
echo ""

echo -e "${YELLOW}🛠️ How to Fix:${NC}"
echo -e "${BLUE}1. Go to your GitHub App settings:${NC}"
echo -e "${BLUE}   https://github.com/settings/apps/security-hub-ticketing${NC}"
echo ""
echo -e "${BLUE}2. Click on 'Install App' in the left sidebar${NC}"
echo ""
echo -e "${BLUE}3. Find your installation and note the numeric ID from the URL:${NC}"
echo -e "${BLUE}   https://github.com/settings/installations/[NUMERIC_ID]${NC}"
echo ""
echo -e "${BLUE}4. The numeric ID is what you need for the Lambda function${NC}"
echo ""

echo -e "${YELLOW}🔧 Alternative Solutions:${NC}"
echo -e "${BLUE}Option 1: Use Personal Access Token (Simpler)${NC}"
echo -e "${BLUE}   Run: ./setup-github-pat.sh <your-github-token>${NC}"
echo ""
echo -e "${BLUE}Option 2: Fix GitHub App Installation ID${NC}"
echo -e "${BLUE}   Once you have the correct numeric ID, update the Lambda:${NC}"
echo -e "${BLUE}   aws lambda update-function-configuration \\${NC}"
echo -e "${BLUE}     --function-name enhanced-auto-remediation-lambda-arm64 \\${NC}"
echo -e "${BLUE}     --environment Variables='{GITHUB_AUTH_VALUE=\"{\\\"app_id\\\":\\\"1719009\\\",\\\"installation_id\\\":\\\"[CORRECT_NUMERIC_ID]\\\",\\\"private_key\\\":\\\"...\\\"}\"}' \\${NC}"
echo -e "${BLUE}     --region us-west-2${NC}"
echo ""

echo -e "${YELLOW}🧪 Test the Fix:${NC}"
echo -e "${BLUE}   After updating the configuration, test with:${NC}"
echo -e "${BLUE}   aws lambda invoke \\${NC}"
echo -e "${BLUE}     --function-name enhanced-auto-remediation-lambda-arm64 \\${NC}"
echo -e "${BLUE}     --payload file://test-crypto-fix.json \\${NC}"
echo -e "${BLUE}     response-test.json \\${NC}"
echo -e "${BLUE}     --region us-west-2${NC}"
echo ""

echo -e "${GREEN}✅ Script completed. Follow the steps above to fix the GitHub App configuration.${NC}" 