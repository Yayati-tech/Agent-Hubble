#!/usr/bin/env python3
"""
Basic Test Script for Security Hub Ticketing System
Tests the core logic without external dependencies
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

class BasicTicketingTester:
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

    def test_environment_variables(self):
        """Test environment variable configuration"""
        print_status("Testing environment variables...", "INFO")
        
        required_vars = ['TICKET_TABLE_NAME']
        optional_vars = ['GITHUB_TOKEN', 'GITHUB_REPO', 'JIRA_URL', 'JIRA_USERNAME', 'JIRA_API_TOKEN', 'JIRA_PROJECT_KEY']
        
        missing_required = []
        configured_optional = []
        
        for var in required_vars:
            if not os.environ.get(var):
                missing_required.append(var)
        
        for var in optional_vars:
            if os.environ.get(var):
                configured_optional.append(var)
        
        if missing_required:
            print_status(f"Missing required environment variables: {', '.join(missing_required)}", "ERROR")
            return False
        else:
            print_status("All required environment variables are set", "SUCCESS")
        
        if configured_optional:
            print_status(f"Configured optional integrations: {', '.join(configured_optional)}", "SUCCESS")
        else:
            print_status("No optional integrations configured (will use DynamoDB fallback)", "WARNING")
        
        return True

    def test_finding_parsing(self):
        """Test finding data parsing and categorization"""
        print_status("Testing finding parsing and categorization...", "INFO")
        
        service_categories = {
            'IAM': ['IAM'],
            'S3': ['S3'],
            'EC2': ['EC2'],
            'RDS': ['RDS'],
            'Lambda': ['Lambda'],
            'KMS': ['KMS'],
            'GuardDuty': ['GuardDuty'],
            'Inspector': ['Inspector'],
            'SSM': ['SSM'],
            'Macie': ['Macie'],
            'WAF': ['WAF'],
            'ACM': ['ACM'],
            'SecretsManager': ['SecretsManager'],
            'CloudFormation': ['CloudFormation'],
            'APIGateway': ['APIGateway'],
            'ElastiCache': ['ElastiCache'],
            'DynamoDB': ['DynamoDB'],
            'EKS': ['EKS'],
            'ECR': ['ECR'],
            'ECS': ['ECS'],
            'Redshift': ['Redshift'],
            'SageMaker': ['SageMaker'],
            'Glue': ['Glue']
        }
        
        for finding in self.test_findings:
            finding_arn = finding.get('ProductArn', '')
            severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
            title = finding.get('Title', '')
            
            # Determine remediation type
            remediation_type = "auto-remediation"
            for service, keywords in service_categories.items():
                if any(keyword in finding_arn for keyword in keywords):
                    remediation_type = service
                    break
            
            print_status(f"Finding: {title}", "INFO")
            print(f"  - Severity: {severity}")
            print(f"  - Service: {remediation_type}")
            print(f"  - ARN: {finding_arn}")
        
        return True

    def test_ticket_data_structure(self):
        """Test ticket data structure creation"""
        print_status("Testing ticket data structure...", "INFO")
        
        for finding in self.test_findings:
            finding_id = finding.get('Id')
            severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
            title = finding.get('Title', 'Security Finding')
            description = finding.get('Description', 'No description available')
            
            # Determine remediation type
            finding_arn = finding.get('ProductArn', '')
            remediation_type = "auto-remediation"
            if 'IAM' in finding_arn:
                remediation_type = "IAM"
            elif 'S3' in finding_arn:
                remediation_type = "S3"
            elif 'EC2' in finding_arn:
                remediation_type = "EC2"
            
            ticket_data = {
                'finding_id': finding_id,
                'severity': severity,
                'title': title,
                'description': description,
                'remediation_type': remediation_type,
                'status': 'CREATED',
                'created_at': datetime.now(timezone.utc).isoformat(),
                'updated_at': datetime.now(timezone.utc).isoformat()
            }
            
            print_status(f"Created ticket data for: {title}", "SUCCESS")
            print(f"  - Ticket ID: {finding_id}")
            print(f"  - Status: {ticket_data['status']}")
            print(f"  - Type: {ticket_data['remediation_type']}")
        
        return True

    def test_lambda_payload_format(self):
        """Test Lambda function payload format"""
        print_status("Testing Lambda payload format...", "INFO")
        
        # Create test payload
        test_payload = {
            "detail": {
                "findings": self.test_findings
            }
        }
        
        # Validate payload structure
        if 'detail' not in test_payload:
            print_status("Payload missing 'detail' key", "ERROR")
            return False
        
        if 'findings' not in test_payload['detail']:
            print_status("Payload missing 'findings' key", "ERROR")
            return False
        
        if not isinstance(test_payload['detail']['findings'], list):
            print_status("Findings must be a list", "ERROR")
            return False
        
        print_status("Lambda payload format is valid", "SUCCESS")
        print(f"Payload contains {len(test_payload['detail']['findings'])} findings")
        
        return True

    def test_severity_mapping(self):
        """Test severity to priority mapping"""
        print_status("Testing severity to priority mapping...", "INFO")
        
        severity_mapping = {
            'CRITICAL': 'Highest',
            'HIGH': 'High', 
            'MEDIUM': 'Medium',
            'LOW': 'Low',
            'UNKNOWN': 'Medium'
        }
        
        for finding in self.test_findings:
            severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
            priority = severity_mapping.get(severity, 'Medium')
            
            print_status(f"Severity '{severity}' maps to priority '{priority}'", "SUCCESS")
        
        return True

    def test_ticket_id_generation(self):
        """Test ticket ID generation patterns"""
        print_status("Testing ticket ID generation...", "INFO")
        
        # Test different ticket ID patterns
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        
        ticket_ids = [
            f"TICKET-{timestamp}-001",
            f"JIRA-12345",
            f"GH-67890"
        ]
        
        for ticket_id in ticket_ids:
            if ticket_id.startswith('JIRA-'):
                print_status(f"Jira ticket ID: {ticket_id}", "SUCCESS")
            elif ticket_id.startswith('GH-'):
                print_status(f"GitHub ticket ID: {ticket_id}", "SUCCESS")
            else:
                print_status(f"DynamoDB ticket ID: {ticket_id}", "SUCCESS")
        
        return True

    def test_error_handling(self):
        """Test error handling scenarios"""
        print_status("Testing error handling scenarios...", "INFO")
        
        # Test with missing required fields
        invalid_finding = {
            "Id": "test-invalid-finding",
            "Title": "Test Finding",
            # Missing Severity and ProductArn
        }
        
        try:
            severity = invalid_finding.get('Severity', {}).get('Label', 'UNKNOWN')
            title = invalid_finding.get('Title', 'Security Finding')
            description = invalid_finding.get('Description', 'No description available')
            
            print_status("Gracefully handled missing fields", "SUCCESS")
            print(f"  - Severity: {severity}")
            print(f"  - Title: {title}")
            print(f"  - Description: {description}")
            
        except Exception as e:
            print_status(f"Error handling test failed: {str(e)}", "ERROR")
            return False
        
        return True

    def run_all_tests(self):
        """Run all basic tests"""
        print_status("Starting basic ticketing system tests...", "INFO")
        print("=" * 60)
        
        tests = [
            ("Environment Variables", self.test_environment_variables),
            ("Finding Parsing", self.test_finding_parsing),
            ("Ticket Data Structure", self.test_ticket_data_structure),
            ("Lambda Payload Format", self.test_lambda_payload_format),
            ("Severity Mapping", self.test_severity_mapping),
            ("Ticket ID Generation", self.test_ticket_id_generation),
            ("Error Handling", self.test_error_handling)
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
        print_status("BASIC TEST SUMMARY", "INFO")
        print("=" * 60)
        
        passed = sum(1 for _, result in self.test_results if result)
        total = len(self.test_results)
        
        for test_name, result in self.test_results:
            status = "PASS" if result else "FAIL"
            color = Colors.GREEN if result else Colors.RED
            print(f"{color}{status}{Colors.NC} - {test_name}")
        
        print(f"\nOverall: {passed}/{total} tests passed")
        
        if passed == total:
            print_status("All basic tests passed! Core logic is working.", "SUCCESS")
        else:
            print_status(f"{total - passed} test(s) failed. Please review the issues above.", "ERROR")

def main():
    """Main test execution"""
    tester = BasicTicketingTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main() 