import json
import boto3
import logging
import os
import requests
from datetime import datetime, timezone
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables for ticket systems
JIRA_URL = os.environ.get('JIRA_URL')
JIRA_USERNAME = os.environ.get('JIRA_USERNAME')
JIRA_API_TOKEN = os.environ.get('JIRA_API_TOKEN')
JIRA_PROJECT_KEY = os.environ.get('JIRA_PROJECT_KEY')

GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
GITHUB_REPO = os.environ.get('GITHUB_REPO')  # format: "owner/repo"

# DynamoDB table for custom ticket system
TICKET_TABLE_NAME = os.environ.get('TICKET_TABLE_NAME', 'SecurityHubTickets')

class TicketManager:
    """Manages ticket creation and updates for Security Hub findings"""
    
    def __init__(self):
        self.dynamodb = boto3.resource('dynamodb')
        self.table = self.dynamodb.Table(TICKET_TABLE_NAME)
    
    def create_ticket(self, finding, remediation_type):
        """Create a ticket for a Security Hub finding"""
        finding_id = finding.get('Id')
        severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
        title = finding.get('Title', 'Security Finding')
        description = finding.get('Description', 'No description available')
        
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
        
        # Try Jira first, then GitHub, then DynamoDB
        try:
            if JIRA_URL and JIRA_USERNAME and JIRA_API_TOKEN:
                return self.create_jira_ticket(ticket_data)
            elif GITHUB_TOKEN and GITHUB_REPO:
                return self.create_github_issue(ticket_data)
            else:
                return self.create_dynamodb_ticket(ticket_data)
        except Exception as e:
            logger.error(f"Error creating ticket: {str(e)}")
            # Fallback to DynamoDB
            return self.create_dynamodb_ticket(ticket_data)
    
    def update_ticket(self, ticket_id, status, message=None, error=None):
        """Update ticket status and add comments"""
        try:
            if ticket_id.startswith('JIRA-'):
                return self.update_jira_ticket(ticket_id, status, message, error)
            elif ticket_id.startswith('GH-'):
                return self.update_github_issue(ticket_id, status, message, error)
            else:
                return self.update_dynamodb_ticket(ticket_id, status, message, error)
        except Exception as e:
            logger.error(f"Error updating ticket {ticket_id}: {str(e)}")
            return False
    
    def create_jira_ticket(self, ticket_data):
        """Create Jira ticket"""
        try:
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'Basic {self._get_jira_auth()}'
            }
            
            payload = {
                'fields': {
                    'project': {'key': JIRA_PROJECT_KEY},
                    'summary': f"Security Hub Finding: {ticket_data['title']}",
                    'description': self._format_jira_description(ticket_data),
                    'issuetype': {'name': 'Bug'},
                    'priority': {'name': self._map_severity_to_priority(ticket_data['severity'])},
                    'labels': ['security-hub', 'auto-remediation', ticket_data['remediation_type']]
                }
            }
            
            response = requests.post(
                f"{JIRA_URL}/rest/api/2/issue",
                headers=headers,
                json=payload
            )
            
            if response.status_code == 201:
                ticket_id = f"JIRA-{response.json()['key']}"
                logger.info(f"Created Jira ticket: {ticket_id}")
                return ticket_id
            else:
                logger.error(f"Failed to create Jira ticket: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating Jira ticket: {str(e)}")
            return None
    
    def update_jira_ticket(self, ticket_id, status, message=None, error=None):
        """Update Jira ticket status and add comments"""
        try:
            jira_key = ticket_id.replace('JIRA-', '')
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'Basic {self._get_jira_auth()}'
            }
            
            # Update status
            transition_id = self._get_jira_status_transition(status)
            if transition_id:
                transition_payload = {
                    'transition': {'id': transition_id}
                }
                
                response = requests.post(
                    f"{JIRA_URL}/rest/api/2/issue/{jira_key}/transitions",
                    headers=headers,
                    json=transition_payload
                )
                
                if response.status_code != 204:
                    logger.error(f"Failed to update Jira ticket status: {response.text}")
            
            # Add comment
            if message or error:
                comment_payload = {
                    'body': f"**Status Update**: {status}\n\n"
                }
                
                if message:
                    comment_payload['body'] += f"**Message**: {message}\n\n"
                
                if error:
                    comment_payload['body'] += f"**Error**: {error}\n\n"
                
                comment_payload['body'] += f"*Updated at: {datetime.now(timezone.utc).isoformat()}*"
                
                response = requests.post(
                    f"{JIRA_URL}/rest/api/2/issue/{jira_key}/comment",
                    headers=headers,
                    json=comment_payload
                )
                
                if response.status_code != 201:
                    logger.error(f"Failed to add Jira comment: {response.text}")
            
            logger.info(f"Updated Jira ticket: {ticket_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating Jira ticket: {str(e)}")
            return False
    
    def create_github_issue(self, ticket_data):
        """Create GitHub issue"""
        try:
            headers = {
                'Authorization': f'token {GITHUB_TOKEN}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            payload = {
                'title': f"Security Hub Finding: {ticket_data['title']}",
                'body': self._format_github_description(ticket_data),
                'labels': ['security-hub', 'auto-remediation', ticket_data['remediation_type']],
                'assignees': []
            }
            
            response = requests.post(
                f"https://api.github.com/repos/{GITHUB_REPO}/issues",
                headers=headers,
                json=payload
            )
            
            if response.status_code == 201:
                issue_data = response.json()
                ticket_id = f"GH-{issue_data['number']}"
                logger.info(f"Created GitHub issue: {ticket_id}")
                return ticket_id
            else:
                logger.error(f"Failed to create GitHub issue: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Error creating GitHub issue: {str(e)}")
            return None
    
    def update_github_issue(self, ticket_id, status, message=None, error=None):
        """Update GitHub issue status and add comments"""
        try:
            issue_number = ticket_id.replace('GH-', '')
            headers = {
                'Authorization': f'token {GITHUB_TOKEN}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            # Update issue state
            state = 'closed' if status == 'RESOLVED' else 'open'
            update_payload = {
                'state': state
            }
            
            response = requests.patch(
                f"https://api.github.com/repos/{GITHUB_REPO}/issues/{issue_number}",
                headers=headers,
                json=update_payload
            )
            
            if response.status_code != 200:
                logger.error(f"Failed to update GitHub issue: {response.text}")
            
            # Add comment
            if message or error:
                comment_body = f"**Status Update**: {status}\n\n"
                
                if message:
                    comment_body += f"**Message**: {message}\n\n"
                
                if error:
                    comment_body += f"**Error**: {error}\n\n"
                
                comment_body += f"*Updated at: {datetime.now(timezone.utc).isoformat()}*"
                
                comment_payload = {
                    'body': comment_body
                }
                
                response = requests.post(
                    f"https://api.github.com/repos/{GITHUB_REPO}/issues/{issue_number}/comments",
                    headers=headers,
                    json=comment_payload
                )
                
                if response.status_code != 201:
                    logger.error(f"Failed to add GitHub comment: {response.text}")
            
            logger.info(f"Updated GitHub issue: {ticket_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating GitHub issue: {str(e)}")
            return False
    
    def create_dynamodb_ticket(self, ticket_data):
        """Create ticket in DynamoDB"""
        try:
            ticket_id = f"TICKET-{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}"
            
            item = {
                'ticket_id': ticket_id,
                'finding_id': ticket_data['finding_id'],
                'title': ticket_data['title'],
                'description': ticket_data['description'],
                'severity': ticket_data['severity'],
                'remediation_type': ticket_data['remediation_type'],
                'status': ticket_data['status'],
                'created_at': ticket_data['created_at'],
                'updated_at': ticket_data['updated_at']
            }
            
            self.table.put_item(Item=item)
            logger.info(f"Created DynamoDB ticket: {ticket_id}")
            return ticket_id
            
        except Exception as e:
            logger.error(f"Error creating DynamoDB ticket: {str(e)}")
            return None
    
    def update_dynamodb_ticket(self, ticket_id, status, message=None, error=None):
        """Update ticket in DynamoDB"""
        try:
            update_expression = "SET #status = :status, #updated_at = :updated_at"
            expression_attrs = {
                '#status': 'status',
                '#updated_at': 'updated_at'
            }
            expression_values = {
                ':status': status,
                ':updated_at': datetime.now(timezone.utc).isoformat()
            }
            
            # Add message and error if provided
            if message:
                update_expression += ", #message = :message"
                expression_attrs['#message'] = 'message'
                expression_values[':message'] = message
            
            if error:
                update_expression += ", #error = :error"
                expression_attrs['#error'] = 'error'
                expression_values[':error'] = error
            
            self.table.update_item(
                Key={'ticket_id': ticket_id},
                UpdateExpression=update_expression,
                ExpressionAttributeNames=expression_attrs,
                ExpressionAttributeValues=expression_values
            )
            
            logger.info(f"Updated DynamoDB ticket: {ticket_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error updating DynamoDB ticket: {str(e)}")
            return False
    
    def _get_jira_auth(self):
        """Get Jira authentication string"""
        import base64
        auth_string = f"{JIRA_USERNAME}:{JIRA_API_TOKEN}"
        return base64.b64encode(auth_string.encode()).decode()
    
    def _format_jira_description(self, ticket_data):
        """Format description for Jira ticket"""
        return f"""
h2. Security Hub Finding Details

*Finding ID*: {ticket_data['finding_id']}
*Severity*: {ticket_data['severity']}
*Remediation Type*: {ticket_data['remediation_type']}
*Created*: {ticket_data['created_at']}

h3. Description
{ticket_data['description']}

h3. Auto-Remediation
This ticket was automatically created by the Security Hub Auto-Remediation system.
        """.strip()
    
    def _format_github_description(self, ticket_data):
        """Format description for GitHub issue"""
        return f"""
## Security Hub Finding Details

- **Finding ID**: {ticket_data['finding_id']}
- **Severity**: {ticket_data['severity']}
- **Remediation Type**: {ticket_data['remediation_type']}
- **Created**: {ticket_data['created_at']}

## Description
{ticket_data['description']}

## Auto-Remediation
This issue was automatically created by the Security Hub Auto-Remediation system.
        """.strip()
    
    def _map_severity_to_priority(self, severity):
        """Map Security Hub severity to Jira priority"""
        mapping = {
            'CRITICAL': 'Highest',
            'HIGH': 'High',
            'MEDIUM': 'Medium',
            'LOW': 'Low'
        }
        return mapping.get(severity, 'Medium')
    
    def _get_jira_status_transition(self, status):
        """Get Jira transition ID for status update"""
        # This would need to be customized based on your Jira workflow
        transitions = {
            'IN_PROGRESS': '11',  # Transition to "In Progress"
            'RESOLVED': '21',     # Transition to "Resolved"
            'FAILED': '31'        # Transition to "Failed"
        }
        return transitions.get(status)

def integrate_ticket_creation(lambda_handler_function):
    """Decorator to integrate ticket creation with Lambda handler"""
    def wrapper(event, context):
        # Initialize ticket manager
        ticket_manager = TicketManager()
        
        try:
            # Process Security Hub findings
            if 'detail' in event and 'findings' in event['detail']:
                findings = event['detail']['findings']
                
                for finding in findings:
                    finding_id = finding.get('Id')
                    severity = finding.get('Severity', {}).get('Label', '')
                    
                    logger.info(f"Processing finding: {finding_id} with severity: {severity}")
                    
                    # Create ticket for the finding
                    remediation_type = 'GENERAL'  # Default type
                    
                    # Determine remediation type based on finding
                    if 'IAM' in finding.get('ProductArn', ''):
                        remediation_type = 'IAM'
                    elif 'S3' in finding.get('ProductArn', ''):
                        remediation_type = 'S3'
                    elif 'EC2' in finding.get('ProductArn', ''):
                        remediation_type = 'EC2'
                    elif 'RDS' in finding.get('ProductArn', ''):
                        remediation_type = 'RDS'
                    elif 'Lambda' in finding.get('ProductArn', ''):
                        remediation_type = 'Lambda'
                    elif 'KMS' in finding.get('ProductArn', ''):
                        remediation_type = 'KMS'
                    elif 'GuardDuty' in finding.get('ProductArn', ''):
                        remediation_type = 'GuardDuty'
                    elif 'Inspector' in finding.get('ProductArn', ''):
                        remediation_type = 'Inspector'
                    elif 'SSM' in finding.get('ProductArn', ''):
                        remediation_type = 'SSM'
                    elif 'Macie' in finding.get('ProductArn', ''):
                        remediation_type = 'Macie'
                    elif 'WAF' in finding.get('ProductArn', ''):
                        remediation_type = 'WAF'
                    elif 'ACM' in finding.get('ProductArn', ''):
                        remediation_type = 'ACM'
                    elif 'SecretsManager' in finding.get('ProductArn', ''):
                        remediation_type = 'SecretsManager'
                    elif 'CloudFormation' in finding.get('ProductArn', ''):
                        remediation_type = 'CloudFormation'
                    elif 'APIGateway' in finding.get('ProductArn', ''):
                        remediation_type = 'APIGateway'
                    elif 'ElastiCache' in finding.get('ProductArn', ''):
                        remediation_type = 'ElastiCache'
                    elif 'DynamoDB' in finding.get('ProductArn', ''):
                        remediation_type = 'DynamoDB'
                    elif 'EKS' in finding.get('ProductArn', ''):
                        remediation_type = 'EKS'
                    elif 'ECR' in finding.get('ProductArn', ''):
                        remediation_type = 'ECR'
                    elif 'ECS' in finding.get('ProductArn', ''):
                        remediation_type = 'ECS'
                    elif 'Redshift' in finding.get('ProductArn', ''):
                        remediation_type = 'Redshift'
                    elif 'SageMaker' in finding.get('ProductArn', ''):
                        remediation_type = 'SageMaker'
                    elif 'Glue' in finding.get('ProductArn', ''):
                        remediation_type = 'Glue'
                    
                    # Create ticket
                    ticket_id = ticket_manager.create_ticket(finding, remediation_type)
                    
                    if ticket_id:
                        logger.info(f"Created ticket {ticket_id} for finding {finding_id}")
                        
                        # Update ticket status based on remediation result
                        try:
                            # Call the original lambda handler
                            result = lambda_handler_function(event, context)
                            
                            # Update ticket status based on result
                            if result.get('statusCode') == 200:
                                ticket_manager.update_ticket(ticket_id, 'RESOLVED', 'Remediation completed successfully')
                            else:
                                ticket_manager.update_ticket(ticket_id, 'FAILED', 'Remediation failed', result.get('body', 'Unknown error'))
                            
                            return result
                            
                        except Exception as e:
                            error_message = str(e)
                            logger.error(f"Error in remediation: {error_message}")
                            ticket_manager.update_ticket(ticket_id, 'FAILED', 'Remediation failed', error_message)
                            raise
                    else:
                        logger.error(f"Failed to create ticket for finding {finding_id}")
            
            # If no findings, call original handler
            return lambda_handler_function(event, context)
            
        except Exception as e:
            logger.error(f"Error in ticket integration: {str(e)}")
            raise
    
    return wrapper

# Example usage with the main lambda handler
@integrate_ticket_creation
def lambda_handler(event, context):
    """
    Enhanced auto-remediation function with ticket integration
    """
    logger.info(f"Processing event: {json.dumps(event)}")
    
    # Initialize AWS clients
    try:
        securityhub = boto3.client('securityhub')
        iam = boto3.client('iam')
        s3 = boto3.client('s3')
        ec2 = boto3.client('ec2')
        sns = boto3.client('sns')
        cloudwatch = boto3.client('cloudwatch')
    except Exception as e:
        logger.error(f"Error initializing AWS clients: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Failed to initialize AWS clients'})
        }
    
    try:
        # Process Security Hub findings
        if 'detail' in event and 'findings' in event['detail']:
            findings = event['detail']['findings']
            
            for finding in findings:
                finding_id = finding.get('Id')
                severity = finding.get('Severity', {}).get('Label', '')
                
                logger.info(f"Processing finding: {finding_id} with severity: {severity}")
                
                # Perform remediation based on finding type
                # This is a simplified example - the full implementation would include
                # all the remediation functions from the main lambda handler
                
                # Send notification
                send_notification(finding_id, severity, "PROCESSED", sns)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Auto-remediation completed with ticket integration',
                'total_processed': len(findings) if 'findings' in event.get('detail', {}) else 0
            })
        }
        
    except Exception as e:
        logger.error(f"Error in auto-remediation: {str(e)}")
        send_notification("SYSTEM", "CRITICAL", "SYSTEM_ERROR", sns, str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

def send_notification(finding_id, severity, status, sns, error_message=None):
    """Send notification via SNS"""
    try:
        message = {
            'finding_id': finding_id,
            'severity': severity,
            'status': status,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'remediation_type': 'auto-remediation-lambda-with-tickets'
        }
        
        if error_message:
            message['error'] = error_message
        
        sns.publish(
            TopicArn=f"arn:aws:sns:us-west-2:{os.environ.get('BACKUP_ACCOUNT_ID', '002616177731')}:{os.environ.get('SNS_TOPIC_NAME', 'SecurityHubAutoRemediationAlerts')}",
            Message=json.dumps(message),
            Subject=f"Security Hub Auto-Remediation: {status}"
        )
        logger.info(f"Sent notification for finding {finding_id}: {status}")
    except Exception as e:
        logger.error(f"Error sending notification: {str(e)}")