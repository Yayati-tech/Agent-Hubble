#!/usr/bin/env python3
"""
Comprehensive Test Script for Security Hub Ticketing System
Tests DynamoDB, GitHub Issues, and Jira integrations
"""

import json
import boto3
import requests
import os
import sys
from datetime import datetime, timezone
from botocore.exceptions import ClientError, NoCredentialsError

# Colors for output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

def print_status(message, status="INFO"):
    """Print colored status messages"""
    if status == "SUCCESS":
        print(f"{Colors.GREEN}✅ {message}{Colors.NC}")
    elif status == "ERROR":
        print(f"{Colors.RED}❌ {message}{Colors.NC}")
    elif status == "WARNING":
        print(f"{Colors.YELLOW}⚠️ {message}{Colors.NC}")
    elif status == "INFO":
        print(f"{Colors.BLUE}ℹ️ {message}{Colors.NC}")

class TicketingSystemTester:
    def __init__(self):
        self.test_results = []
        self.dynamodb = None
        self.table_name = os.environ.get('TICKET_TABLE_NAME', 'SecurityHubTickets')
        
        # Test findings
        self.test_findings = [
            {
                "Id": "test-iam-finding-001",
                "Title": "IAM User without MFA",
                "Description": "Test finding for IAM user without multi-factor authentication",
                "Severity": {"Label": "HIGH"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
            },
            {
                "Id": "test-s3-finding-002", 
                "Title": "S3 Bucket Public Access",
                "Description": "Test finding for S3 bucket with public access enabled",
                "Severity": {"Label": "CRITICAL"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/s3"
            },
            {
                "Id": "test-ec2-finding-003",
                "Title": "Unused EC2 Instance",
                "Description": "Test finding for unused EC2 instance",
                "Severity": {"Label": "MEDIUM"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/ec2"
            }
        ]

    def test_aws_credentials(self):
        """Test AWS credentials and basic connectivity"""
        print_status("Testing AWS credentials...", "INFO")
        try:
            sts = boto3.client('sts')
            identity = sts.get_caller_identity()
            print_status(f"AWS credentials valid. Account: {identity['Account']}", "SUCCESS")
            return True
        except NoCredentialsError:
            print_status("AWS credentials not found", "ERROR")
            return False
        except Exception as e:
            print_status(f"AWS credentials error: {str(e)}", "ERROR")
            return False

    def test_dynamodb_setup(self):
        """Test DynamoDB table setup and access"""
        print_status("Testing DynamoDB setup...", "INFO")
        try:
            self.dynamodb = boto3.resource('dynamodb')
            table = self.dynamodb.Table(self.table_name)
            
            # Test table access
            table.load()
            print_status(f"DynamoDB table '{self.table_name}' accessible", "SUCCESS")
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                print_status(f"DynamoDB table '{self.table_name}' not found", "ERROR")
                return False
            else:
                print_status(f"DynamoDB error: {str(e)}", "ERROR")
                return False
        except Exception as e:
            print_status(f"DynamoDB setup error: {str(e)}", "ERROR")
            return False

    def test_github_integration(self):
        """Test GitHub integration if configured"""
        github_token = os.environ.get('GITHUB_TOKEN')
        github_repo = os.environ.get('GITHUB_REPO')
        
        if not github_token or not github_repo:
            print_status("GitHub integration not configured", "WARNING")
            return False
        
        print_status("Testing GitHub integration...", "INFO")
        try:
            headers = {
                'Authorization': f'token {github_token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            # Test API access
            response = requests.get('https://api.github.com/user', headers=headers)
            if response.status_code == 200:
                user_data = response.json()
                print_status(f"GitHub token valid for user: {user_data['login']}", "SUCCESS")
                
                # Test repository access
                repo_response = requests.get(f'https://api.github.com/repos/{github_repo}', headers=headers)
                if repo_response.status_code == 200:
                    print_status(f"GitHub repository '{github_repo}' accessible", "SUCCESS")
                    return True
                else:
                    print_status(f"GitHub repository '{github_repo}' not accessible", "ERROR")
                    return False
            else:
                print_status("GitHub token invalid", "ERROR")
                return False
        except Exception as e:
            print_status(f"GitHub integration error: {str(e)}", "ERROR")
            return False

    def test_jira_integration(self):
        """Test Jira integration if configured"""
        jira_url = os.environ.get('JIRA_URL')
        jira_username = os.environ.get('JIRA_USERNAME')
        jira_token = os.environ.get('JIRA_API_TOKEN')
        jira_project = os.environ.get('JIRA_PROJECT_KEY')
        
        if not all([jira_url, jira_username, jira_token, jira_project]):
            print_status("Jira integration not configured", "WARNING")
            return False
        
        print_status("Testing Jira integration...", "INFO")
        try:
            import base64
            auth_string = f"{jira_username}:{jira_token}"
            auth_bytes = auth_string.encode('ascii')
            auth_b64 = base64.b64encode(auth_bytes).decode('ascii')
            
            headers = {
                'Authorization': f'Basic {auth_b64}',
                'Content-Type': 'application/json'
            }
            
            # Test API access
            response = requests.get(f"{jira_url}/rest/api/2/myself", headers=headers)
            if response.status_code == 200:
                user_data = response.json()
                print_status(f"Jira credentials valid for user: {user_data['displayName']}", "SUCCESS")
                
                # Test project access
                project_response = requests.get(f"{jira_url}/rest/api/2/project/{jira_project}", headers=headers)
                if project_response.status_code == 200:
                    print_status(f"Jira project '{jira_project}' accessible", "SUCCESS")
                    return True
                else:
                    print_status(f"Jira project '{jira_project}' not accessible", "ERROR")
                    return False
            else:
                print_status("Jira credentials invalid", "ERROR")
                return False
        except Exception as e:
            print_status(f"Jira integration error: {str(e)}", "ERROR")
            return False

    def test_lambda_function(self):
        """Test Lambda function if deployed"""
        print_status("Testing Lambda function...", "INFO")
        try:
            lambda_client = boto3.client('lambda')
            function_name = "enhanced-auto-remediation-lambda-arm64"
            
            # Check if function exists
            try:
                function_config = lambda_client.get_function(FunctionName=function_name)
                print_status(f"Lambda function '{function_name}' found", "SUCCESS")
                
                # Test environment variables
                env_vars = function_config['Configuration']['Environment']['Variables']
                print_status("Lambda environment variables:", "INFO")
                for key, value in env_vars.items():
                    if 'TOKEN' in key or 'PASSWORD' in key:
                        print(f"  {key}: {'*' * len(value)}")
                    else:
                        print(f"  {key}: {value}")
                
                return True
            except ClientError as e:
                if e.response['Error']['Code'] == 'ResourceNotFoundException':
                    print_status(f"Lambda function '{function_name}' not found", "WARNING")
                    return False
                else:
                    print_status(f"Lambda function error: {str(e)}", "ERROR")
                    return False
        except Exception as e:
            print_status(f"Lambda test error: {str(e)}", "ERROR")
            return False

    def test_ticket_creation(self):
        """Test ticket creation with sample findings"""
        print_status("Testing ticket creation...", "INFO")
        
        if not self.dynamodb:
            print_status("DynamoDB not available for ticket creation test", "ERROR")
            return False
        
        try:
            table = self.dynamodb.Table(self.table_name)
            
            for i, finding in enumerate(self.test_findings, 1):
                ticket_id = f"TEST-TICKET-{datetime.now().strftime('%Y%m%d%H%M%S')}-{i}"
                
                ticket_data = {
                    'ticket_id': ticket_id,
                    'finding_id': finding['Id'],
                    'title': finding['Title'],
                    'description': finding['Description'],
                    'severity': finding['Severity']['Label'],
                    'remediation_type': 'TEST',
                    'status': 'CREATED',
                    'created_at': datetime.now(timezone.utc).isoformat(),
                    'updated_at': datetime.now(timezone.utc).isoformat()
                }
                
                # Create ticket in DynamoDB
                table.put_item(Item=ticket_data)
                print_status(f"Created test ticket: {ticket_id}", "SUCCESS")
                
                # Test ticket update
                table.update_item(
                    Key={'ticket_id': ticket_id},
                    UpdateExpression='SET #status = :status, updated_at = :updated_at',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':status': 'SUCCESS',
                        ':updated_at': datetime.now(timezone.utc).isoformat()
                    }
                )
                print_status(f"Updated test ticket: {ticket_id}", "SUCCESS")
            
            return True
        except Exception as e:
            print_status(f"Ticket creation test error: {str(e)}", "ERROR")
            return False

    def test_lambda_invocation(self):
        """Test Lambda function invocation with test payload"""
        print_status("Testing Lambda function invocation...", "INFO")
        try:
            lambda_client = boto3.client('lambda')
            function_name = "enhanced-auto-remediation-lambda-arm64"
            
            # Test payload
            test_payload = {
                "detail": {
                    "findings": self.test_findings
                }
            }
            
            # Invoke Lambda function
            response = lambda_client.invoke(
                FunctionName=function_name,
                InvocationType='RequestResponse',
                Payload=json.dumps(test_payload)
            )
            
            if response['StatusCode'] == 200:
                response_payload = json.loads(response['Payload'].read())
                print_status("Lambda function invoked successfully", "SUCCESS")
                print(f"Response: {json.dumps(response_payload, indent=2)}")
                return True
            else:
                print_status(f"Lambda invocation failed with status: {response['StatusCode']}", "ERROR")
                return False
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                print_status("Lambda function not found - skipping invocation test", "WARNING")
                return False
            else:
                print_status(f"Lambda invocation error: {str(e)}", "ERROR")
                return False
        except Exception as e:
            print_status(f"Lambda invocation test error: {str(e)}", "ERROR")
            return False

    def run_all_tests(self):
        """Run all tests and provide summary"""
        print_status("Starting comprehensive ticketing system tests...", "INFO")
        print("=" * 60)
        
        tests = [
            ("AWS Credentials", self.test_aws_credentials),
            ("DynamoDB Setup", self.test_dynamodb_setup),
            ("GitHub Integration", self.test_github_integration),
            ("Jira Integration", self.test_jira_integration),
            ("Lambda Function", self.test_lambda_function),
            ("Ticket Creation", self.test_ticket_creation),
            ("Lambda Invocation", self.test_lambda_invocation)
        ]
        
        for test_name, test_func in tests:
            print(f"\n{test_name}:")
            print("-" * len(test_name))
            try:
                result = test_func()
                self.test_results.append((test_name, result))
            except Exception as e:
                print_status(f"Test failed with exception: {str(e)}", "ERROR")
                self.test_results.append((test_name, False))
        
        self.print_summary()

    def print_summary(self):
        """Print test summary"""
        print("\n" + "=" * 60)
        print_status("TEST SUMMARY", "INFO")
        print("=" * 60)
        
        passed = sum(1 for _, result in self.test_results if result)
        total = len(self.test_results)
        
        for test_name, result in self.test_results:
            status = "PASS" if result else "FAIL"
            color = Colors.GREEN if result else Colors.RED
            print(f"{color}{status}{Colors.NC} - {test_name}")
        
        print(f"\nOverall: {passed}/{total} tests passed")
        
        if passed == total:
            print_status("All tests passed! Ticketing system is ready.", "SUCCESS")
        else:
            print_status(f"{total - passed} test(s) failed. Please review the issues above.", "ERROR")

def main():
    """Main test execution"""
    tester = TicketingSystemTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main() 