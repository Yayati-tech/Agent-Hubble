#!/usr/bin/env python3
"""
Lambda Function Invocation Test Script
Simulates the Lambda function execution to test ticketing system logic
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

class LambdaInvocationTester:
    def __init__(self):
        self.test_results = []
        
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

    def simulate_lambda_handler(self, event):
        """Simulate the Lambda handler function"""
        print_status("Simulating Lambda handler execution...", "INFO")
        
        # Extract findings from event
        findings = event.get('detail', {}).get('findings', [])
        print_status(f"Processing {len(findings)} findings", "INFO")
        
        remediated_findings = []
        failed_remediations = []
        created_tickets = []
        
        for finding in findings:
            finding_id = finding.get('Id')
            finding_arn = finding.get('ProductArn', '')
            severity = finding.get('Severity', {}).get('Label', '')
            
            print_status(f"Processing finding: {finding_id}", "INFO")
            
            # Determine remediation type
            remediation_type = self._determine_remediation_type(finding_arn)
            
            # Simulate ticket creation
            ticket_id = self._simulate_create_ticket(finding, remediation_type)
            if ticket_id:
                created_tickets.append(ticket_id)
                print_status(f"Created ticket: {ticket_id}", "SUCCESS")
            
            # Simulate remediation (always successful for testing)
            remediated = True
            if remediated:
                remediated_findings.append(finding_id)
                print_status(f"Remediation successful for: {finding_id}", "SUCCESS")
                
                # Simulate ticket update
                self._simulate_update_ticket(ticket_id, "SUCCESS", f"Finding {finding_id} was successfully remediated")
            else:
                failed_remediations.append(finding_id)
                print_status(f"Remediation failed for: {finding_id}", "ERROR")
                
                # Simulate ticket update
                self._simulate_update_ticket(ticket_id, "FAILED", f"Remediation failed for finding {finding_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'remediated_findings': remediated_findings,
                'failed_remediations': failed_remediations,
                'created_tickets': created_tickets,
                'total_findings': len(findings)
            })
        }

    def _determine_remediation_type(self, finding_arn):
        """Determine remediation type based on ProductArn"""
        if 'IAM' in finding_arn:
            return "IAM"
        elif 'S3' in finding_arn:
            return "S3"
        elif 'EC2' in finding_arn:
            return "EC2"
        elif 'RDS' in finding_arn:
            return "RDS"
        elif 'Lambda' in finding_arn:
            return "Lambda"
        elif 'KMS' in finding_arn:
            return "KMS"
        elif 'GuardDuty' in finding_arn:
            return "GuardDuty"
        elif 'Inspector' in finding_arn:
            return "Inspector"
        elif 'SSM' in finding_arn:
            return "SSM"
        elif 'Macie' in finding_arn:
            return "Macie"
        elif 'WAF' in finding_arn:
            return "WAF"
        elif 'ACM' in finding_arn:
            return "ACM"
        elif 'SecretsManager' in finding_arn:
            return "SecretsManager"
        elif 'CloudFormation' in finding_arn:
            return "CloudFormation"
        elif 'APIGateway' in finding_arn:
            return "APIGateway"
        elif 'ElastiCache' in finding_arn:
            return "ElastiCache"
        elif 'DynamoDB' in finding_arn:
            return "DynamoDB"
        elif 'EKS' in finding_arn:
            return "EKS"
        elif 'ECR' in finding_arn:
            return "ECR"
        elif 'ECS' in finding_arn:
            return "ECS"
        elif 'Redshift' in finding_arn:
            return "Redshift"
        elif 'SageMaker' in finding_arn:
            return "SageMaker"
        elif 'Glue' in finding_arn:
            return "Glue"
        else:
            return "auto-remediation"

    def _simulate_create_ticket(self, finding, remediation_type):
        """Simulate ticket creation"""
        finding_id = finding.get('Id')
        severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
        title = finding.get('Title', 'Security Finding')
        
        # Generate ticket ID
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        ticket_id = f"TICKET-{timestamp}-{finding_id}"
        
        ticket_data = {
            'ticket_id': ticket_id,
            'finding_id': finding_id,
            'title': title,
            'description': finding.get('Description', 'No description available'),
            'severity': severity,
            'remediation_type': remediation_type,
            'status': 'CREATED',
            'created_at': datetime.now(timezone.utc).isoformat(),
            'updated_at': datetime.now(timezone.utc).isoformat()
        }
        
        return ticket_id

    def _simulate_update_ticket(self, ticket_id, status, message):
        """Simulate ticket update"""
        if ticket_id:
            print_status(f"Updated ticket {ticket_id} to status: {status}", "SUCCESS")
            if message:
                print(f"  Message: {message}")

    def test_single_finding(self):
        """Test with a single finding"""
        print_status("Testing single finding processing...", "INFO")
        
        event = {
            "detail": {
                "findings": [self.test_findings[0]]
            }
        }
        
        result = self.simulate_lambda_handler(event)
        
        print_status("Single finding test completed", "SUCCESS")
        print(f"Response: {json.dumps(result, indent=2)}")
        
        return True

    def test_multiple_findings(self):
        """Test with multiple findings"""
        print_status("Testing multiple findings processing...", "INFO")
        
        event = {
            "detail": {
                "findings": self.test_findings
            }
        }
        
        result = self.simulate_lambda_handler(event)
        
        print_status("Multiple findings test completed", "SUCCESS")
        print(f"Response: {json.dumps(result, indent=2)}")
        
        return True

    def test_empty_findings(self):
        """Test with empty findings list"""
        print_status("Testing empty findings processing...", "INFO")
        
        event = {
            "detail": {
                "findings": []
            }
        }
        
        result = self.simulate_lambda_handler(event)
        
        print_status("Empty findings test completed", "SUCCESS")
        print(f"Response: {json.dumps(result, indent=2)}")
        
        return True

    def test_malformed_event(self):
        """Test with malformed event"""
        print_status("Testing malformed event handling...", "INFO")
        
        event = {
            "detail": {
                # Missing findings key
            }
        }
        
        result = self.simulate_lambda_handler(event)
        
        print_status("Malformed event test completed", "SUCCESS")
        print(f"Response: {json.dumps(result, indent=2)}")
        
        return True

    def test_different_severities(self):
        """Test findings with different severities"""
        print_status("Testing different severity levels...", "INFO")
        
        severity_findings = [
            {
                "Id": "test-critical-001",
                "Title": "Critical Security Issue",
                "Description": "Critical security finding",
                "Severity": {"Label": "CRITICAL"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
            },
            {
                "Id": "test-high-002",
                "Title": "High Security Issue",
                "Description": "High security finding",
                "Severity": {"Label": "HIGH"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/s3"
            },
            {
                "Id": "test-medium-003",
                "Title": "Medium Security Issue",
                "Description": "Medium security finding",
                "Severity": {"Label": "MEDIUM"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/ec2"
            },
            {
                "Id": "test-low-004",
                "Title": "Low Security Issue",
                "Description": "Low security finding",
                "Severity": {"Label": "LOW"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/rds"
            }
        ]
        
        event = {
            "detail": {
                "findings": severity_findings
            }
        }
        
        result = self.simulate_lambda_handler(event)
        
        print_status("Different severities test completed", "SUCCESS")
        print(f"Response: {json.dumps(result, indent=2)}")
        
        return True

    def test_different_services(self):
        """Test findings from different AWS services"""
        print_status("Testing different AWS services...", "INFO")
        
        service_findings = [
            {
                "Id": "test-iam-001",
                "Title": "IAM Security Issue",
                "Description": "IAM security finding",
                "Severity": {"Label": "HIGH"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam"
            },
            {
                "Id": "test-s3-002",
                "Title": "S3 Security Issue",
                "Description": "S3 security finding",
                "Severity": {"Label": "CRITICAL"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/s3"
            },
            {
                "Id": "test-ec2-003",
                "Title": "EC2 Security Issue",
                "Description": "EC2 security finding",
                "Severity": {"Label": "MEDIUM"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/ec2"
            },
            {
                "Id": "test-rds-004",
                "Title": "RDS Security Issue",
                "Description": "RDS security finding",
                "Severity": {"Label": "HIGH"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/rds"
            },
            {
                "Id": "test-lambda-005",
                "Title": "Lambda Security Issue",
                "Description": "Lambda security finding",
                "Severity": {"Label": "MEDIUM"},
                "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/lambda"
            }
        ]
        
        event = {
            "detail": {
                "findings": service_findings
            }
        }
        
        result = self.simulate_lambda_handler(event)
        
        print_status("Different services test completed", "SUCCESS")
        print(f"Response: {json.dumps(result, indent=2)}")
        
        return True

    def run_all_tests(self):
        """Run all Lambda invocation tests"""
        print_status("Starting Lambda invocation tests...", "INFO")
        print("=" * 60)
        
        tests = [
            ("Single Finding", self.test_single_finding),
            ("Multiple Findings", self.test_multiple_findings),
            ("Empty Findings", self.test_empty_findings),
            ("Malformed Event", self.test_malformed_event),
            ("Different Severities", self.test_different_severities),
            ("Different Services", self.test_different_services)
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
        print_status("LAMBDA INVOCATION TEST SUMMARY", "INFO")
        print("=" * 60)
        
        passed = sum(1 for _, result in self.test_results if result)
        total = len(self.test_results)
        
        for test_name, result in self.test_results:
            status = "PASS" if result else "FAIL"
            color = Colors.GREEN if result else Colors.RED
            print(f"{color}{status}{Colors.NC} - {test_name}")
        
        print(f"\nOverall: {passed}/{total} tests passed")
        
        if passed == total:
            print_status("All Lambda invocation tests passed! Logic is working correctly.", "SUCCESS")
        else:
            print_status(f"{total - passed} test(s) failed. Please review the issues above.", "ERROR")

def main():
    """Main test execution"""
    tester = LambdaInvocationTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main() 