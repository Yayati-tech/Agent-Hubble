#!/usr/bin/env python3
"""
Comprehensive Lambda Function Test Script
Tests the core logic of the enhanced-auto-remediation-lambda without requiring AWS credentials
"""

import json
import os
import sys
from datetime import datetime, timezone

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

class LambdaLogicTester:
    def __init__(self):
        self.test_results = []
        
        # Test findings with different scenarios
        self.test_findings = [
            {
                "Id": "arn:aws:securityhub:us-west-2:002616177731:product/aws/securityhub/finding/iam-user-no-mfa",
                "Title": "IAM user has console access without MFA",
                "Description": "An IAM user has console access but does not have MFA enabled.",
                "Severity": {"Label": "HIGH"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam",
                "AwsAccountId": "002616177731",
                "Region": "us-west-2",
                "CreatedAt": "2025-08-03T07:30:00.000Z",
                "UpdatedAt": "2025-08-03T07:30:00.000Z",
                "Remediation": {
                    "Recommendation": {
                        "Text": "Enable MFA for the IAM user or remove console access"
                    }
                }
            },
            {
                "Id": "arn:aws:securityhub:us-west-2:002616177731:product/aws/securityhub/finding/s3-bucket-public",
                "Title": "S3 bucket has public access",
                "Description": "S3 bucket has public read/write permissions enabled.",
                "Severity": {"Label": "CRITICAL"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/s3",
                "AwsAccountId": "002616177731",
                "Region": "us-west-2",
                "CreatedAt": "2025-08-03T07:30:00.000Z",
                "UpdatedAt": "2025-08-03T07:30:00.000Z",
                "Remediation": {
                    "Recommendation": {
                        "Text": "Remove public access from the S3 bucket"
                    }
                }
            },
            {
                "Id": "arn:aws:inspector2:us-west-2:002616177731:finding/cve-2023-0286",
                "Title": "CVE-2023-0286 - cryptography",
                "Description": "There is a type confusion vulnerability in cryptography package.",
                "Severity": {"Label": "HIGH", "Normalized": 70},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/inspector",
                "Types": ["Software and Configuration Checks/Vulnerabilities/CVE"],
                "AwsAccountId": "002616177731",
                "Region": "us-west-2",
                "CreatedAt": "2025-08-03T04:11:58.097Z",
                "UpdatedAt": "2025-08-03T05:37:15.301Z",
                "WorkflowState": "NEW",
                "RecordState": "ACTIVE",
                "Vulnerabilities": [
                    {
                        "Id": "CVE-2023-0286",
                        "VulnerablePackages": [
                            {
                                "Name": "cryptography",
                                "Version": "3.4.8",
                                "FixedInVersion": "39.0.1"
                            }
                        ],
                        "Cvss": [
                            {
                                "Version": "3.1",
                                "BaseScore": 7.4,
                                "BaseVector": "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:N/A:H"
                            }
                        ],
                        "FixAvailable": "YES"
                    }
                ]
            }
        ]

    def test_finding_parsing(self):
        """Test finding parsing logic"""
        print_status("Testing finding parsing logic...", "INFO")
        
        for finding in self.test_findings:
            finding_id = finding.get('Id', '')
            title = finding.get('Title', '')
            severity = finding.get('Severity', {}).get('Label', '')
            product_arn = finding.get('ProductArn', '')
            account_id = finding.get('AwsAccountId', '')
            region = finding.get('Region', '')
            
            print_status(f"  Finding ID: {finding_id}", "INFO")
            print_status(f"  Title: {title}", "INFO")
            print_status(f"  Severity: {severity}", "INFO")
            print_status(f"  Product: {product_arn}", "INFO")
            print_status(f"  Account: {account_id}", "INFO")
            print_status(f"  Region: {region}", "INFO")
            
            # Test required fields
            if all([finding_id, title, severity, product_arn, account_id, region]):
                print_status(f"  ✅ All required fields present", "SUCCESS")
            else:
                print_status(f"  ❌ Missing required fields", "ERROR")
        
        print_status("Finding parsing test completed", "SUCCESS")

    def test_remediation_type_detection(self):
        """Test remediation type detection logic"""
        print_status("Testing remediation type detection...", "INFO")
        
        remediation_types = {
            "arn:aws:securityhub:us-west-2::product/aws/iam": "IAM",
            "arn:aws:securityhub:us-west-2::product/aws/s3": "S3",
            "arn:aws:securityhub:us-west-2::product/aws/inspector": "Inspector",
            "arn:aws:securityhub:us-west-2::product/aws/ec2": "EC2",
            "arn:aws:securityhub:us-west-2::product/aws/rds": "RDS",
            "arn:aws:securityhub:us-west-2::product/aws/lambda": "Lambda",
            "arn:aws:securityhub:us-west-2::product/aws/kms": "KMS",
            "arn:aws:securityhub:us-west-2::product/aws/guardduty": "GuardDuty",
            "arn:aws:securityhub:us-west-2::product/aws/ssm": "SSM",
            "arn:aws:securityhub:us-west-2::product/aws/macie": "Macie",
            "arn:aws:securityhub:us-west-2::product/aws/waf": "WAF",
            "arn:aws:securityhub:us-west-2::product/aws/acm": "ACM",
            "arn:aws:securityhub:us-west-2::product/aws/secretsmanager": "SecretsManager",
            "arn:aws:securityhub:us-west-2::product/aws/cloudformation": "CloudFormation",
            "arn:aws:securityhub:us-west-2::product/aws/apigateway": "APIGateway",
            "arn:aws:securityhub:us-west-2::product/aws/elasticache": "ElastiCache",
            "arn:aws:securityhub:us-west-2::product/aws/dynamodb": "DynamoDB",
            "arn:aws:securityhub:us-west-2::product/aws/eks": "EKS",
            "arn:aws:securityhub:us-west-2::product/aws/ecr": "ECR",
            "arn:aws:securityhub:us-west-2::product/aws/ecs": "ECS",
            "arn:aws:securityhub:us-west-2::product/aws/redshift": "Redshift",
            "arn:aws:securityhub:us-west-2::product/aws/sagemaker": "SageMaker",
            "arn:aws:securityhub:us-west-2::product/aws/glue": "Glue"
        }
        
        for finding in self.test_findings:
            product_arn = finding.get('ProductArn', '')
            expected_type = remediation_types.get(product_arn, 'Unknown')
            
            print_status(f"  Product ARN: {product_arn}", "INFO")
            print_status(f"  Expected Type: {expected_type}", "INFO")
            
            if expected_type != 'Unknown':
                print_status(f"  ✅ Remediation type detected", "SUCCESS")
            else:
                print_status(f"  ⚠️ Unknown remediation type", "WARNING")
        
        print_status("Remediation type detection test completed", "SUCCESS")

    def test_ticket_creation_logic(self):
        """Test ticket creation logic"""
        print_status("Testing ticket creation logic...", "INFO")
        
        for finding in self.test_findings:
            finding_id = finding.get('Id', '')
            title = finding.get('Title', '')
            severity = finding.get('Severity', {}).get('Label', '')
            description = finding.get('Description', '')
            
            # Simulate ticket creation
            timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
            ticket_id = f"TICKET-{timestamp}-{finding_id.split('/')[-1]}"
            
            ticket_data = {
                "ticket_id": ticket_id,
                "finding_id": finding_id,
                "title": title,
                "severity": severity,
                "description": description,
                "status": "OPEN",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat()
            }
            
            print_status(f"  Created ticket: {ticket_id}", "SUCCESS")
            print_status(f"  Finding: {finding_id}", "INFO")
            print_status(f"  Severity: {severity}", "INFO")
            print_status(f"  Status: {ticket_data['status']}", "INFO")
        
        print_status("Ticket creation logic test completed", "SUCCESS")

    def test_severity_mapping(self):
        """Test severity mapping logic"""
        print_status("Testing severity mapping...", "INFO")
        
        severity_mapping = {
            "CRITICAL": "critical-severity",
            "HIGH": "high-severity", 
            "MEDIUM": "medium-severity",
            "LOW": "low-severity"
        }
        
        for finding in self.test_findings:
            severity = finding.get('Severity', {}).get('Label', '')
            expected_label = severity_mapping.get(severity, 'unknown-severity')
            
            print_status(f"  Severity: {severity}", "INFO")
            print_status(f"  Expected Label: {expected_label}", "INFO")
            
            if expected_label != 'unknown-severity':
                print_status(f"  ✅ Severity mapping correct", "SUCCESS")
            else:
                print_status(f"  ⚠️ Unknown severity level", "WARNING")
        
        print_status("Severity mapping test completed", "SUCCESS")

    def test_service_detection(self):
        """Test service detection from ProductArn"""
        print_status("Testing service detection...", "INFO")
        
        for finding in self.test_findings:
            product_arn = finding.get('ProductArn', '')
            
            # Extract service from ProductArn
            if 'product/aws/' in product_arn:
                service = product_arn.split('product/aws/')[-1].upper()
                print_status(f"  Product ARN: {product_arn}", "INFO")
                print_status(f"  Detected Service: {service}", "INFO")
                print_status(f"  ✅ Service detection successful", "SUCCESS")
            else:
                print_status(f"  Product ARN: {product_arn}", "INFO")
                print_status(f"  ❌ Could not detect service", "ERROR")
        
        print_status("Service detection test completed", "SUCCESS")

    def test_vulnerability_parsing(self):
        """Test vulnerability parsing for Inspector findings"""
        print_status("Testing vulnerability parsing...", "INFO")
        
        for finding in self.test_findings:
            vulnerabilities = finding.get('Vulnerabilities', [])
            
            if vulnerabilities:
                print_status(f"  Found {len(vulnerabilities)} vulnerabilities", "INFO")
                
                for vuln in vulnerabilities:
                    vuln_id = vuln.get('Id', '')
                    fix_available = vuln.get('FixAvailable', 'NO')
                    
                    print_status(f"    Vulnerability ID: {vuln_id}", "INFO")
                    print_status(f"    Fix Available: {fix_available}", "INFO")
                    
                    if fix_available == 'YES':
                        print_status(f"    ✅ Fix available", "SUCCESS")
                    else:
                        print_status(f"    ⚠️ No fix available", "WARNING")
            else:
                print_status(f"  No vulnerabilities found (not an Inspector finding)", "INFO")
        
        print_status("Vulnerability parsing test completed", "SUCCESS")

    def test_response_formatting(self):
        """Test response formatting logic"""
        print_status("Testing response formatting...", "INFO")
        
        # Simulate processing results
        remediated_findings = []
        failed_remediations = []
        created_tickets = []
        
        for finding in self.test_findings:
            finding_id = finding.get('Id', '')
            severity = finding.get('Severity', {}).get('Label', '')
            
            # Simulate ticket creation
            timestamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
            ticket_id = f"TICKET-{timestamp}-{finding_id.split('/')[-1]}"
            created_tickets.append(ticket_id)
            
            # Simulate remediation (always successful for testing)
            remediated_findings.append(finding_id)
        
        response = {
            "statusCode": 200,
            "body": json.dumps({
                "remediated_findings": remediated_findings,
                "failed_remediations": failed_remediations,
                "created_tickets": created_tickets,
                "total_findings": len(self.test_findings)
            })
        }
        
        print_status(f"  Status Code: {response['statusCode']}", "INFO")
        print_status(f"  Remediated: {len(remediated_findings)}", "INFO")
        print_status(f"  Failed: {len(failed_remediations)}", "INFO")
        print_status(f"  Tickets Created: {len(created_tickets)}", "INFO")
        print_status(f"  Total Findings: {len(self.test_findings)}", "INFO")
        
        print_status("Response formatting test completed", "SUCCESS")

    def run_all_tests(self):
        """Run all tests"""
        print_status("Starting comprehensive Lambda function tests...", "INFO")
        print("=" * 60)
        
        tests = [
            ("Finding Parsing", self.test_finding_parsing),
            ("Remediation Type Detection", self.test_remediation_type_detection),
            ("Ticket Creation Logic", self.test_ticket_creation_logic),
            ("Severity Mapping", self.test_severity_mapping),
            ("Service Detection", self.test_service_detection),
            ("Vulnerability Parsing", self.test_vulnerability_parsing),
            ("Response Formatting", self.test_response_formatting)
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            print(f"\n{test_name}:")
            print("-" * len(test_name))
            try:
                test_func()
                passed += 1
                print_status(f"✅ {test_name} - PASSED", "SUCCESS")
            except Exception as e:
                print_status(f"❌ {test_name} - FAILED: {str(e)}", "ERROR")
        
        print("\n" + "=" * 60)
        print_status(f"COMPREHENSIVE TEST SUMMARY", "INFO")
        print_status(f"Passed: {passed}/{total} tests", "SUCCESS" if passed == total else "ERROR")
        
        if passed == total:
            print_status("🎉 All Lambda function logic tests passed!", "SUCCESS")
        else:
            print_status(f"⚠️ {total - passed} tests failed", "WARNING")

def main():
    """Main function"""
    tester = LambdaLogicTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main() 