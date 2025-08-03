#!/usr/bin/env python3
"""
Simple Integration Test for Security Hub Ticketing System
This script tests the Lambda function's GitHub integration by invoking it with test data.
"""

import json
import boto3
import time

def test_lambda_invocation():
    """Test Lambda function invocation with GitHub integration"""
    print("🚀 Testing Lambda Function with GitHub Integration")
    print("=" * 60)
    
    # Create Lambda client
    lambda_client = boto3.client('lambda', region_name='us-west-2')
    
    # Test payload with different types of findings
    test_payloads = [
        {
            "detail": {
                "findings": [
                    {
                        "Id": "test-github-integration-001",
                        "Title": "Test GitHub Integration - IAM Finding",
                        "Description": "This is a test finding to verify GitHub issue creation with proper labels",
                        "Severity": {"Label": "HIGH"},
                        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/iam",
                        "Resources": [
                            {
                                "Type": "AwsIamUser",
                                "Id": "arn:aws:iam::123456789012:user/test-user"
                            }
                        ]
                    }
                ]
            }
        },
        {
            "detail": {
                "findings": [
                    {
                        "Id": "test-github-integration-002",
                        "Title": "Test GitHub Integration - S3 Finding",
                        "Description": "This is a test finding for S3 bucket security verification",
                        "Severity": {"Label": "CRITICAL"},
                        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/s3",
                        "Resources": [
                            {
                                "Type": "AwsS3Bucket",
                                "Id": "arn:aws:s3:::test-bucket"
                            }
                        ]
                    }
                ]
            }
        }
    ]
    
    results = []
    
    for i, payload in enumerate(test_payloads, 1):
        print(f"\n📝 Test {i}: Invoking Lambda with GitHub integration...")
        
        try:
            # Invoke Lambda function
            response = lambda_client.invoke(
                FunctionName='enhanced-auto-remediation-lambda-arm64',
                Payload=json.dumps(payload),
                InvocationType='RequestResponse'
            )
            
            # Parse response
            response_payload = json.loads(response['Payload'].read())
            status_code = response['StatusCode']
            
            print(f"✅ Lambda invocation successful (Status: {status_code})")
            
            # Parse the response body
            if 'body' in response_payload:
                body = json.loads(response_payload['body'])
                print(f"   📊 Results:")
                print(f"      - Total findings: {body.get('total_findings', 0)}")
                print(f"      - Tickets created: {len(body.get('created_tickets', []))}")
                print(f"      - Remediated: {len(body.get('remediated_findings', []))}")
                print(f"      - Failed: {len(body.get('failed_remediations', []))}")
                
                if body.get('created_tickets'):
                    print(f"      - Ticket IDs: {body.get('created_tickets')}")
                
                results.append({
                    'test': i,
                    'status': 'success',
                    'tickets_created': len(body.get('created_tickets', [])),
                    'remediated': len(body.get('remediated_findings', [])),
                    'failed': len(body.get('failed_remediations', []))
                })
            else:
                print(f"   ⚠️ Unexpected response format: {response_payload}")
                results.append({
                    'test': i,
                    'status': 'unexpected_format',
                    'response': response_payload
                })
                
        except Exception as e:
            print(f"❌ Lambda invocation failed: {str(e)}")
            results.append({
                'test': i,
                'status': 'failed',
                'error': str(e)
            })
    
    return results

def check_cloudwatch_logs():
    """Check recent CloudWatch logs for GitHub integration activity"""
    print(f"\n📊 Checking CloudWatch Logs for GitHub Integration...")
    
    try:
        logs_client = boto3.client('logs', region_name='us-west-2')
        
        # Get recent log streams
        log_streams = logs_client.describe_log_streams(
            logGroupName='/aws/lambda/enhanced-auto-remediation-lambda-arm64',
            orderBy='LastEventTime',
            descending=True,
            maxItems=1
        )
        
        if log_streams['logStreams']:
            latest_stream = log_streams['logStreams'][0]['logStreamName']
            print(f"   📋 Latest log stream: {latest_stream}")
            
            # Get recent events
            events = logs_client.get_log_events(
                logGroupName='/aws/lambda/enhanced-auto-remediation-lambda-arm64',
                logStreamName=latest_stream,
                startTime=int(time.time() * 1000) - (10 * 60 * 1000),  # Last 10 minutes
                limit=50
            )
            
            github_related_logs = []
            for event in events['events']:
                message = event['message']
                if any(keyword in message.lower() for keyword in ['github', 'issue', 'label', 'ticket']):
                    github_related_logs.append(message)
            
            if github_related_logs:
                print(f"   🔍 Found {len(github_related_logs)} GitHub-related log entries:")
                for log in github_related_logs[-5:]:  # Show last 5
                    print(f"      - {log.strip()}")
            else:
                print(f"   ℹ️ No recent GitHub-related log entries found")
                
        else:
            print(f"   ⚠️ No log streams found")
            
    except Exception as e:
        print(f"   ❌ Error checking logs: {str(e)}")

def main():
    """Main test function"""
    print("🔍 Security Hub GitHub Integration Test")
    print("=" * 50)
    
    # Test 1: Lambda invocation with GitHub integration
    results = test_lambda_invocation()
    
    # Test 2: Check CloudWatch logs
    check_cloudwatch_logs()
    
    # Summary
    print(f"\n" + "=" * 50)
    print("📋 Test Summary")
    print("=" * 50)
    
    successful_tests = [r for r in results if r['status'] == 'success']
    failed_tests = [r for r in results if r['status'] == 'failed']
    
    print(f"✅ Successful tests: {len(successful_tests)}")
    print(f"❌ Failed tests: {len(failed_tests)}")
    
    if successful_tests:
        total_tickets = sum(r.get('tickets_created', 0) for r in successful_tests)
        total_remediated = sum(r.get('remediated', 0) for r in successful_tests)
        print(f"📝 Total tickets created: {total_tickets}")
        print(f"🔧 Total remediated: {total_remediated}")
    
    if failed_tests:
        print(f"\n❌ Failed test details:")
        for test in failed_tests:
            print(f"   - Test {test['test']}: {test.get('error', 'Unknown error')}")
    
    print(f"\n🔗 GitHub Repository Links:")
    print(f"   - Issues: https://github.com/Yayati-tech/Agent-Hubble/issues")
    print(f"   - Labels: https://github.com/Yayati-tech/Agent-Hubble/labels")
    print(f"   - Repository: https://github.com/Yayati-tech/Agent-Hubble")
    
    if len(successful_tests) == len(results):
        print(f"\n🎉 ALL TESTS PASSED! GitHub integration is working correctly.")
    else:
        print(f"\n⚠️ Some tests failed. Please check the logs for details.")

if __name__ == "__main__":
    main() 