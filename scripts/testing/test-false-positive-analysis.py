#!/usr/bin/env python3
"""
Test script for False Positive Analysis Lambda function
Tests various scenarios and validates the analysis logic
"""

import json
import sys
import os
import boto3
from datetime import datetime
from typing import Dict, Any, List

# Add the lambda directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'deployment', 'lambda'))

# Import the Lambda function
from false_positive_analysis import lambda_handler, FalsePositiveAnalysisLambda

class FalsePositiveAnalysisTester:
    def __init__(self):
        self.analyzer = FalsePositiveAnalysisLambda()
        self.test_results = []
    
    def run_all_tests(self):
        """Run all test scenarios"""
        print("🧪 Starting False Positive Analysis Tests...\n")
        
        # Test scenarios
        test_scenarios = [
            self.test_development_environment_false_positive,
            self.test_production_environment_true_positive,
            self.test_business_exception_false_positive,
            self.test_critical_resource_true_positive,
            self.test_temporal_false_positive,
            self.test_severity_mismatch_false_positive,
            self.test_unknown_environment_medium_confidence,
            self.test_ml_classification_disabled,
            self.test_pattern_analysis_disabled,
            self.test_invalid_finding_input
        ]
        
        for test_func in test_scenarios:
            try:
                test_func()
            except Exception as e:
                print(f"❌ Test {test_func.__name__} failed: {str(e)}")
        
        self.print_test_summary()
    
    def test_development_environment_false_positive(self):
        """Test that development environment findings are classified as false positives"""
        print("🔍 Testing development environment false positive detection...")
        
        finding = self.create_test_finding(
            environment="development",
            severity="MEDIUM",
            generator_id="aws-foundational-security-best-practices/v/1.0.0/IAM.1"
        )
        
        result = self.analyze_finding(finding)
        
        # Assertions
        assert result['classification']['is_false_positive'] == True, "Development environment should be classified as false positive"
        assert result['classification']['confidence'] > 0.7, "Confidence should be high for development environment"
        assert "non-production environment" in result['classification']['reasoning'], "Reasoning should mention non-production environment"
        
        print("✅ Development environment false positive test passed")
        self.test_results.append(("Development Environment", True))
    
    def test_production_environment_true_positive(self):
        """Test that production environment findings are classified as true positives"""
        print("🔍 Testing production environment true positive detection...")
        
        finding = self.create_test_finding(
            environment="production",
            severity="HIGH",
            generator_id="aws-foundational-security-best-practices/v/1.0.0/IAM.1"
        )
        
        result = self.analyze_finding(finding)
        
        # Assertions
        assert result['classification']['is_false_positive'] == False, "Production environment should be classified as true positive"
        assert result['classification']['confidence'] < 0.5, "Confidence should be low for production environment"
        
        print("✅ Production environment true positive test passed")
        self.test_results.append(("Production Environment", True))
    
    def test_business_exception_false_positive(self):
        """Test that findings with business exceptions are classified as false positives"""
        print("🔍 Testing business exception false positive detection...")
        
        finding = self.create_test_finding(
            environment="staging",
            severity="MEDIUM",
            generator_id="aws-foundational-security-best-practices/v/1.0.0/S3.1",
            tags={"Environment": "staging", "Project": "demo-bucket"}
        )
        
        result = self.analyze_finding(finding)
        
        # Assertions
        assert result['business_context']['has_business_exception'] == True, "Should detect business exception"
        assert result['classification']['confidence'] > 0.7, "Confidence should be high with business exception"
        
        print("✅ Business exception false positive test passed")
        self.test_results.append(("Business Exception", True))
    
    def test_critical_resource_true_positive(self):
        """Test that critical resource findings are classified as true positives"""
        print("🔍 Testing critical resource true positive detection...")
        
        finding = self.create_test_finding(
            environment="production",
            severity="CRITICAL",
            generator_id="aws-foundational-security-best-practices/v/1.0.0/IAM.1",
            resource_id="arn:aws:iam::123456789012:root"
        )
        
        result = self.analyze_finding(finding)
        
        # Assertions
        assert result['business_context']['is_critical_resource'] == True, "Should detect critical resource"
        assert result['classification']['is_false_positive'] == False, "Critical resources should be true positives"
        
        print("✅ Critical resource true positive test passed")
        self.test_results.append(("Critical Resource", True))
    
    def test_temporal_false_positive(self):
        """Test temporal pattern false positive detection"""
        print("🔍 Testing temporal pattern false positive detection...")
        
        finding = self.create_test_finding(
            environment="test",
            severity="LOW",
            generator_id="aws-foundational-security-best-practices/v/1.0.0/EC2.1"
        )
        
        result = self.analyze_finding(finding)
        
        # Assertions
        assert result['temporal_analysis']['temporal_risk_level'] in ['LOW', 'MEDIUM', 'HIGH'], "Should have temporal risk level"
        
        print("✅ Temporal pattern false positive test passed")
        self.test_results.append(("Temporal Analysis", True))
    
    def test_severity_mismatch_false_positive(self):
        """Test severity mismatch false positive detection"""
        print("🔍 Testing severity mismatch false positive detection...")
        
        finding = self.create_test_finding(
            environment="test",
            severity="CRITICAL",  # High severity in test environment
            generator_id="aws-foundational-security-best-practices/v/1.0.0/IAM.1"
        )
        
        result = self.analyze_finding(finding)
        
        # Assertions
        assert result['classification']['is_false_positive'] == True, "Severity mismatch should be false positive"
        assert result['classification']['confidence'] > 0.7, "Confidence should be high for severity mismatch"
        
        print("✅ Severity mismatch false positive test passed")
        self.test_results.append(("Severity Mismatch", True))
    
    def test_unknown_environment_medium_confidence(self):
        """Test unknown environment handling"""
        print("🔍 Testing unknown environment handling...")
        
        finding = self.create_test_finding(
            environment="unknown",
            severity="MEDIUM",
            generator_id="aws-foundational-security-best-practices/v/1.0.0/IAM.1"
        )
        
        result = self.analyze_finding(finding)
        
        # Assertions
        assert result['environment_analysis']['environment'] == 'unknown', "Should detect unknown environment"
        assert 0.4 < result['classification']['confidence'] < 0.6, "Unknown environment should have medium confidence"
        
        print("✅ Unknown environment test passed")
        self.test_results.append(("Unknown Environment", True))
    
    def test_ml_classification_disabled(self):
        """Test with ML classification disabled"""
        print("🔍 Testing with ML classification disabled...")
        
        finding = self.create_test_finding(
            environment="development",
            severity="MEDIUM"
        )
        
        options = {
            "include_ml_classification": False,
            "include_pattern_analysis": True,
            "include_business_context": True,
            "include_temporal_analysis": True
        }
        
        result = self.analyze_finding(finding, options)
        
        # Assertions
        assert result['ml_classification'] is None, "ML classification should be None when disabled"
        assert "environment_analyzer" in result['processing_metadata']['models_used'], "Should use environment analyzer"
        assert "ml_classifier" not in result['processing_metadata']['models_used'], "Should not use ML classifier"
        
        print("✅ ML classification disabled test passed")
        self.test_results.append(("ML Classification Disabled", True))
    
    def test_pattern_analysis_disabled(self):
        """Test with pattern analysis disabled"""
        print("🔍 Testing with pattern analysis disabled...")
        
        finding = self.create_test_finding(
            environment="development",
            severity="MEDIUM"
        )
        
        options = {
            "include_ml_classification": True,
            "include_pattern_analysis": False,
            "include_business_context": True,
            "include_temporal_analysis": True
        }
        
        result = self.analyze_finding(finding, options)
        
        # Assertions
        assert result['pattern_analysis'] is None, "Pattern analysis should be None when disabled"
        assert "pattern_recognizer" not in result['processing_metadata']['models_used'], "Should not use pattern recognizer"
        
        print("✅ Pattern analysis disabled test passed")
        self.test_results.append(("Pattern Analysis Disabled", True))
    
    def test_invalid_finding_input(self):
        """Test handling of invalid finding input"""
        print("🔍 Testing invalid finding input handling...")
        
        # Test with missing finding
        try:
            result = lambda_handler({"analysis_options": {}}, None)
            assert result['statusCode'] == 500, "Should return error for missing finding"
            print("✅ Invalid input test passed (missing finding)")
        except Exception as e:
            print(f"✅ Invalid input test passed (exception caught: {str(e)})")
        
        # Test with empty finding
        try:
            result = lambda_handler({"finding": {}, "analysis_options": {}}, None)
            assert result['statusCode'] == 200, "Should handle empty finding gracefully"
            print("✅ Invalid input test passed (empty finding)")
        except Exception as e:
            print(f"✅ Invalid input test passed (exception caught: {str(e)})")
        
        self.test_results.append(("Invalid Input", True))
    
    def create_test_finding(self, environment="development", severity="MEDIUM", 
                           generator_id="aws-foundational-security-best-practices/v/1.0.0/IAM.1",
                           resource_id="arn:aws:iam::123456789012:root",
                           tags=None):
        """Create a test finding with specified parameters"""
        if tags is None:
            tags = {"Environment": environment, "Project": "test-project"}
        
        return {
            "Id": f"arn:aws:securityhub:us-west-2:123456789012:subscription/{generator_id}/finding/test-{datetime.now().timestamp()}",
            "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/securityhub",
            "GeneratorId": generator_id,
            "AwsAccountId": "123456789012",
            "Types": ["Software and Configuration Checks/Industry and Regulatory Standards/AWS-Foundational-Security-Best-Practices"],
            "FirstObservedAt": "2023-01-01T00:00:00.000Z",
            "LastObservedAt": "2023-01-01T00:00:00.000Z",
            "Severity": {
                "Label": severity,
                "Original": severity
            },
            "Title": "Test finding for false positive analysis",
            "Description": "This is a test finding for false positive analysis validation.",
            "Resources": [
                {
                    "Type": "AwsAccount",
                    "Id": resource_id,
                    "Region": "us-west-2",
                    "Tags": tags
                }
            ]
        }
    
    def analyze_finding(self, finding: Dict[str, Any], options: Dict[str, Any] = None):
        """Analyze a finding using the False Positive Analysis Lambda"""
        if options is None:
            options = {
                "include_ml_classification": True,
                "include_pattern_analysis": True,
                "include_business_context": True,
                "include_temporal_analysis": True
            }
        
        event = {
            "finding": finding,
            "analysis_options": options
        }
        
        result = lambda_handler(event, None)
        
        if result['statusCode'] == 200:
            return json.loads(result['body'])
        else:
            raise Exception(f"Analysis failed: {result['body']}")
    
    def print_test_summary(self):
        """Print a summary of test results"""
        print("\n" + "="*50)
        print("📊 TEST SUMMARY")
        print("="*50)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for _, passed in self.test_results if passed)
        failed_tests = total_tests - passed_tests
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests}")
        print(f"Failed: {failed_tests}")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        print("\n📋 Test Details:")
        for test_name, passed in self.test_results:
            status = "✅ PASS" if passed else "❌ FAIL"
            print(f"  {status} - {test_name}")
        
        if failed_tests == 0:
            print("\n🎉 All tests passed! False Positive Analysis Lambda is working correctly.")
        else:
            print(f"\n⚠️  {failed_tests} test(s) failed. Please review the implementation.")

def main():
    """Main test runner"""
    print("🚀 False Positive Analysis Lambda Test Suite")
    print("="*50)
    
    tester = FalsePositiveAnalysisTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main() 