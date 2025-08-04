import json
import boto3
import logging
import os
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
sagemaker = boto3.client('sagemaker')
dynamodb = boto3.client('dynamodb')
cloudwatch = boto3.client('cloudwatch')
securityhub = boto3.client('securityhub')

# Environment variables
SNS_TOPIC_NAME = os.environ.get('SNS_TOPIC_NAME', 'FalsePositiveAnalysisAlerts')
REGION = os.environ.get('REGION', 'us-west-2')

# Data classes for structured responses
@dataclass
class EnvironmentContext:
    environment: str
    risk_level: str
    is_production: bool
    requires_immediate_action: bool
    
    def to_dict(self):
        return asdict(self)

@dataclass
class BusinessContext:
    is_critical_resource: bool
    has_business_exception: bool
    business_impact: str
    requires_business_review: bool
    
    def to_dict(self):
        return asdict(self)

@dataclass
class FalsePositiveClassification:
    is_false_positive: bool
    confidence: float
    reasoning: str
    
    def to_dict(self):
        return asdict(self)

@dataclass
class PatternAnalysis:
    similar_findings_count: int
    false_positive_rate: float
    pattern_confidence: float
    pattern_reasoning: str
    
    def to_dict(self):
        return asdict(self)

@dataclass
class TemporalAnalysis:
    is_temporary: bool
    recurrence_pattern: str
    in_maintenance_window: bool
    temporal_risk_level: str
    
    def to_dict(self):
        return asdict(self)

@dataclass
class FindingCharacteristics:
    service: str
    finding_type: List[str]
    severity: str
    resource_type: str
    environment: str
    region: str
    account_id: str

class EnvironmentAnalyzer:
    def __init__(self):
        self.environment_patterns = {
            'test': ['test', 'dev', 'staging', 'qa', 'sandbox', 'demo'],
            'production': ['prod', 'production', 'live', 'main'],
            'development': ['dev', 'development', 'feature', 'branch']
        }
    
    async def analyze_environment_context(self, finding: Dict[str, Any]) -> EnvironmentContext:
        """Analyze the environment context of a finding"""
        resources = finding.get('Resources', [{}])
        if not resources:
            return EnvironmentContext(
                environment='unknown',
                risk_level='MEDIUM',
                is_production=False,
                requires_immediate_action=False
            )
        
        resource = resources[0]
        resource_arn = resource.get('Id', '')
        tags = resource.get('Tags', {})
        
        # Detect environment from resource ARN and tags
        environment = self.detect_environment(resource_arn, tags)
        risk_level = self.assess_environment_risk(environment)
        
        return EnvironmentContext(
            environment=environment,
            risk_level=risk_level,
            is_production=environment == 'production',
            requires_immediate_action=environment == 'production'
        )
    
    def detect_environment(self, resource_arn: str, tags: Dict[str, str]) -> str:
        """Detect environment from resource ARN and tags"""
        text_to_analyze = f"{resource_arn} {' '.join(tags.values())}".lower()
        
        for env, patterns in self.environment_patterns.items():
            if any(pattern in text_to_analyze for pattern in patterns):
                return env
        
        return 'unknown'
    
    def assess_environment_risk(self, environment: str) -> str:
        """Assess risk level based on environment"""
        risk_mapping = {
            'production': 'HIGH',
            'staging': 'MEDIUM',
            'test': 'LOW',
            'development': 'LOW',
            'unknown': 'MEDIUM'
        }
        return risk_mapping.get(environment, 'MEDIUM')

class BusinessContextAnalyzer:
    def __init__(self):
        self.critical_resources = self.load_critical_resources()
        self.business_exceptions = self.load_business_exceptions()
    
    def load_critical_resources(self) -> List[str]:
        """Load list of critical resources from DynamoDB or environment"""
        # In a real implementation, this would load from DynamoDB
        # For now, return a basic list
        return [
            "arn:aws:iam::*:root",
            "arn:aws:s3:::production-data-*",
            "arn:aws:rds:*:*:db:production-*"
        ]
    
    def load_business_exceptions(self) -> List[str]:
        """Load business exceptions from DynamoDB or environment"""
        # In a real implementation, this would load from DynamoDB
        # For now, return a basic list
        return [
            "IAM.1:development:test-account",
            "S3.1:staging:demo-bucket",
            "EC2.1:dev:test-instance"
        ]
    
    async def analyze_business_context(self, finding: Dict[str, Any]) -> BusinessContext:
        """Analyze the business context of a finding"""
        resources = finding.get('Resources', [{}])
        if not resources:
            return BusinessContext(
                is_critical_resource=False,
                has_business_exception=False,
                business_impact='UNKNOWN',
                requires_business_review=False
            )
        
        resource_id = resources[0].get('Id', '')
        
        # Check if resource is critical
        is_critical = await self.is_critical_resource(resource_id)
        
        # Check for business exceptions
        has_exception = await self.has_business_exception(finding)
        
        # Assess business impact
        business_impact = self.assess_business_impact(finding, is_critical, has_exception)
        
        return BusinessContext(
            is_critical_resource=is_critical,
            has_business_exception=has_exception,
            business_impact=business_impact,
            requires_business_review=is_critical or has_exception
        )
    
    async def is_critical_resource(self, resource_id: str) -> bool:
        """Check if resource is critical to business operations"""
        for pattern in self.critical_resources:
            if self.matches_pattern(resource_id, pattern):
                return True
        return False
    
    async def has_business_exception(self, finding: Dict[str, Any]) -> bool:
        """Check if finding has an approved business exception"""
        finding_key = self.generate_finding_key(finding)
        return finding_key in self.business_exceptions
    
    def generate_finding_key(self, finding: Dict[str, Any]) -> str:
        """Generate a key for business exception lookup"""
        generator_id = finding.get('GeneratorId', '')
        account_id = finding.get('AwsAccountId', '')
        resources = finding.get('Resources', [{}])
        resource_id = resources[0].get('Id', '') if resources else ''
        
        # Extract service and control from generator ID
        parts = generator_id.split('/')
        if len(parts) >= 2:
            service_control = parts[-1]  # e.g., "IAM.1"
        else:
            service_control = generator_id
        
        # Extract environment from resource
        env = 'unknown'
        if resources:
            tags = resources[0].get('Tags', {})
            env = tags.get('Environment', 'unknown')
        
        return f"{service_control}:{env}:{account_id}"
    
    def assess_business_impact(self, finding: Dict[str, Any], is_critical: bool, has_exception: bool) -> str:
        """Assess business impact of the finding"""
        if is_critical:
            return 'HIGH'
        elif has_exception:
            return 'LOW'
        else:
            severity = finding.get('Severity', {}).get('Label', 'MEDIUM')
            if severity in ['HIGH', 'CRITICAL']:
                return 'MEDIUM'
            else:
                return 'LOW'
    
    def matches_pattern(self, resource_id: str, pattern: str) -> bool:
        """Check if resource ID matches a pattern"""
        # Simple pattern matching - in production, use regex
        return pattern.replace('*', '') in resource_id

class MLClassifier:
    def __init__(self):
        self.model_endpoint = os.environ.get('ML_MODEL_ENDPOINT', 'false-positive-classifier')
        self.feature_extractor = FalsePositiveFeatureExtractor()
    
    async def classify_finding(self, finding: Dict[str, Any]) -> Optional[FalsePositiveClassification]:
        """Classify whether a finding is a false positive using ML"""
        try:
            features = await self.feature_extractor.extract_features(finding)
            
            # In a real implementation, this would call SageMaker
            # For now, use a simple rule-based approach
            probability = self.simple_classification(features)
            
            classification = FalsePositiveClassification(
                is_false_positive=probability > 0.7,
                confidence=probability,
                reasoning=self.generate_reasoning(finding, features, probability)
            )
            
            return classification
            
        except Exception as e:
            logger.error(f"Error in ML classification: {str(e)}")
            return None
    
    def simple_classification(self, features: List[float]) -> float:
        """Simple rule-based classification (placeholder for ML model)"""
        # Weighted average of features
        weights = [0.3, 0.25, 0.2, 0.15, 0.1]  # Environment, Historical, Business, Temporal, Severity
        weighted_sum = sum(f * w for f, w in zip(features, weights))
        return min(max(weighted_sum, 0.0), 1.0)
    
    def generate_reasoning(self, finding: Dict[str, Any], features: List[float], probability: float) -> str:
        """Generate human-readable reasoning for classification"""
        reasoning_parts = []
        
        if features[0] > 0.8:  # Environment score
            reasoning_parts.append("Finding is in non-production environment")
        
        if features[1] > 0.7:  # Historical pattern score
            reasoning_parts.append("Similar findings were previously false positives")
        
        if features[2] > 0.6:  # Business exception score
            reasoning_parts.append("Finding matches known business exception pattern")
        
        if features[3] > 0.7:  # Temporal pattern score
            reasoning_parts.append("Finding appears to be temporary")
        
        return "; ".join(reasoning_parts) if reasoning_parts else "No specific indicators"

class FalsePositiveFeatureExtractor:
    def __init__(self):
        self.environment_analyzer = EnvironmentAnalyzer()
        self.business_analyzer = BusinessContextAnalyzer()
    
    async def extract_features(self, finding: Dict[str, Any]) -> List[float]:
        """Extract features for false positive classification"""
        features = [
            await self.extract_environment_score(finding),
            await self.extract_historical_pattern_score(finding),
            await self.extract_business_exception_score(finding),
            await self.extract_temporal_pattern_score(finding),
            await self.extract_severity_mismatch_score(finding)
        ]
        return features
    
    async def extract_environment_score(self, finding: Dict[str, Any]) -> float:
        """Extract environment-based false positive likelihood"""
        environment_analyzer = EnvironmentAnalyzer()
        context = await environment_analyzer.analyze_environment_context(finding)
        
        # Higher score for non-production environments
        if context.environment in ['test', 'development', 'staging']:
            return 0.9
        elif context.environment == 'production':
            return 0.1
        else:
            return 0.5
    
    async def extract_historical_pattern_score(self, finding: Dict[str, Any]) -> float:
        """Extract historical pattern-based false positive likelihood"""
        # In a real implementation, this would query DynamoDB for historical patterns
        # For now, return a default score
        return 0.5
    
    async def extract_business_exception_score(self, finding: Dict[str, Any]) -> float:
        """Extract business exception-based false positive likelihood"""
        business_analyzer = BusinessContextAnalyzer()
        context = await business_analyzer.analyze_business_context(finding)
        
        if context.has_business_exception:
            return 0.8
        elif context.is_critical_resource:
            return 0.2
        else:
            return 0.5
    
    async def extract_temporal_pattern_score(self, finding: Dict[str, Any]) -> float:
        """Extract temporal pattern-based false positive likelihood"""
        # In a real implementation, this would analyze temporal patterns
        # For now, return a default score
        return 0.5
    
    async def extract_severity_mismatch_score(self, finding: Dict[str, Any]) -> float:
        """Extract severity mismatch-based false positive likelihood"""
        severity = finding.get('Severity', {}).get('Label', 'MEDIUM')
        
        # Check if severity seems appropriate for the finding type
        # This is a simplified check
        if severity == 'CRITICAL' and 'test' in str(finding).lower():
            return 0.8  # High likelihood of false positive
        elif severity == 'LOW' and 'production' in str(finding).lower():
            return 0.3  # Lower likelihood of false positive
        else:
            return 0.5

class PatternRecognitionEngine:
    def __init__(self):
        self.pattern_table = os.environ.get('PATTERN_DB_TABLE', 'false-positive-patterns')
    
    async def analyze_historical_patterns(self, finding: Dict[str, Any]) -> PatternAnalysis:
        """Analyze historical patterns for the finding"""
        try:
            # Find similar historical findings
            similar_findings = await self.find_similar_findings(finding)
            
            # Analyze outcomes of similar findings
            outcome_analysis = await self.analyze_outcomes(similar_findings)
            
            # Calculate pattern-based false positive probability
            false_positive_probability = self.calculate_pattern_probability(outcome_analysis)
            
            return PatternAnalysis(
                similar_findings_count=len(similar_findings),
                false_positive_rate=outcome_analysis.get('false_positive_rate', 0.5),
                pattern_confidence=false_positive_probability,
                pattern_reasoning=self.generate_pattern_reasoning(outcome_analysis)
            )
            
        except Exception as e:
            logger.error(f"Error in pattern analysis: {str(e)}")
            return PatternAnalysis(
                similar_findings_count=0,
                false_positive_rate=0.5,
                pattern_confidence=0.5,
                pattern_reasoning="Pattern analysis failed"
            )
    
    async def find_similar_findings(self, finding: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Find historically similar findings"""
        # In a real implementation, this would query DynamoDB
        # For now, return an empty list
        return []
    
    async def analyze_outcomes(self, similar_findings: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Analyze outcomes of similar findings"""
        if not similar_findings:
            return {'false_positive_rate': 0.5}
        
        false_positive_count = sum(1 for f in similar_findings if f.get('WorkflowState') == 'SUPPRESSED')
        total_count = len(similar_findings)
        
        return {
            'false_positive_rate': false_positive_count / total_count if total_count > 0 else 0.5,
            'total_findings': total_count,
            'false_positive_count': false_positive_count
        }
    
    def calculate_pattern_probability(self, outcome_analysis: Dict[str, Any]) -> float:
        """Calculate pattern-based false positive probability"""
        false_positive_rate = outcome_analysis.get('false_positive_rate', 0.5)
        total_findings = outcome_analysis.get('total_findings', 0)
        
        # Weight by number of similar findings
        if total_findings > 10:
            return false_positive_rate
        elif total_findings > 5:
            return false_positive_rate * 0.8
        else:
            return 0.5  # Default if not enough data
    
    def generate_pattern_reasoning(self, outcome_analysis: Dict[str, Any]) -> str:
        """Generate reasoning for pattern analysis"""
        false_positive_rate = outcome_analysis.get('false_positive_rate', 0.5)
        total_findings = outcome_analysis.get('total_findings', 0)
        
        if total_findings == 0:
            return "No similar historical findings found"
        
        percentage = false_positive_rate * 100
        return f"{percentage:.0f}% of similar findings were false positives"

class TemporalAnalyzer:
    def __init__(self):
        self.temporal_patterns = self.load_temporal_patterns()
    
    def load_temporal_patterns(self) -> Dict[str, Any]:
        """Load temporal patterns from DynamoDB or environment"""
        # In a real implementation, this would load from DynamoDB
        return {
            'maintenance_windows': [
                {'start': '02:00', 'end': '04:00', 'days': ['saturday', 'sunday']}
            ],
            'temporary_patterns': [
                {'duration_hours': 24, 'resolution_rate': 0.8}
            ]
        }
    
    async def analyze_temporal_context(self, finding: Dict[str, Any]) -> TemporalAnalysis:
        """Analyze temporal context of a finding"""
        try:
            # Check if finding is temporary
            is_temporary = await self.is_temporary_finding(finding)
            
            # Check for recurring patterns
            recurrence_pattern = await self.analyze_recurrence_pattern(finding)
            
            # Check for maintenance windows
            in_maintenance_window = await self.is_in_maintenance_window(finding)
            
            return TemporalAnalysis(
                is_temporary=is_temporary,
                recurrence_pattern=recurrence_pattern,
                in_maintenance_window=in_maintenance_window,
                temporal_risk_level=self.calculate_temporal_risk(is_temporary, recurrence_pattern, in_maintenance_window)
            )
            
        except Exception as e:
            logger.error(f"Error in temporal analysis: {str(e)}")
            return TemporalAnalysis(
                is_temporary=False,
                recurrence_pattern='NONE',
                in_maintenance_window=False,
                temporal_risk_level='MEDIUM'
            )
    
    async def is_temporary_finding(self, finding: Dict[str, Any]) -> bool:
        """Check if finding is likely temporary"""
        # In a real implementation, this would analyze temporal patterns
        # For now, return False
        return False
    
    async def analyze_recurrence_pattern(self, finding: Dict[str, Any]) -> str:
        """Analyze recurrence pattern of the finding"""
        # In a real implementation, this would analyze recurrence patterns
        # For now, return 'NONE'
        return 'NONE'
    
    async def is_in_maintenance_window(self, finding: Dict[str, Any]) -> bool:
        """Check if finding is in a maintenance window"""
        # In a real implementation, this would check maintenance windows
        # For now, return False
        return False
    
    def calculate_temporal_risk(self, is_temporary: bool, recurrence_pattern: str, in_maintenance_window: bool) -> str:
        """Calculate temporal risk level"""
        if is_temporary:
            return 'LOW'
        elif in_maintenance_window:
            return 'MEDIUM'
        elif recurrence_pattern != 'NONE':
            return 'MEDIUM'
        else:
            return 'HIGH'

class FalsePositiveAnalysisLambda:
    def __init__(self):
        self.environment_analyzer = EnvironmentAnalyzer()
        self.ml_classifier = MLClassifier()
        self.pattern_recognizer = PatternRecognitionEngine()
        self.business_analyzer = BusinessContextAnalyzer()
        self.temporal_analyzer = TemporalAnalyzer()
    
    async def analyze_finding(self, finding: Dict[str, Any], options: Dict[str, Any]) -> Dict[str, Any]:
        """Main analysis function"""
        start_time = datetime.now()
        analysis_id = f"fp-analysis-{finding['Id'].split('/')[-1]}"
        
        try:
            # Environment analysis
            environment_analysis = await self.environment_analyzer.analyze_environment_context(finding)
            
            # ML classification (if enabled)
            ml_classification = None
            if options.get('include_ml_classification', True):
                ml_classification = await self.ml_classifier.classify_finding(finding)
            
            # Pattern analysis (if enabled)
            pattern_analysis = None
            if options.get('include_pattern_analysis', True):
                pattern_analysis = await self.pattern_recognizer.analyze_historical_patterns(finding)
            
            # Business context analysis (if enabled)
            business_context = None
            if options.get('include_business_context', True):
                business_context = await self.business_analyzer.analyze_business_context(finding)
            
            # Temporal analysis (if enabled)
            temporal_analysis = None
            if options.get('include_temporal_analysis', True):
                temporal_analysis = await self.temporal_analyzer.analyze_temporal_context(finding)
            
            # Combine results for final classification
            classification = self.combine_analysis_results(
                environment_analysis, ml_classification, pattern_analysis, 
                business_context, temporal_analysis
            )
            
            # Calculate processing time
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return {
                "analysis_id": analysis_id,
                "finding_id": finding['Id'],
                "classification": classification,
                "environment_analysis": environment_analysis.to_dict(),
                "ml_classification": ml_classification.to_dict() if ml_classification else None,
                "pattern_analysis": pattern_analysis.to_dict() if pattern_analysis else None,
                "business_context": business_context.to_dict() if business_context else None,
                "temporal_analysis": temporal_analysis.to_dict() if temporal_analysis else None,
                "processing_metadata": {
                    "processing_time_ms": processing_time,
                    "models_used": self.get_models_used(options),
                    "timestamp": datetime.now().isoformat()
                }
            }
            
        except Exception as e:
            logger.error(f"Error analyzing finding {finding['Id']}: {str(e)}")
            raise
    
    def combine_analysis_results(self, environment_analysis, ml_classification, 
                               pattern_analysis, business_context, temporal_analysis):
        """Combine all analysis results for final classification"""
        
        # Calculate combined confidence score
        confidence_scores = []
        reasoning_parts = []
        
        # Environment-based scoring
        if environment_analysis:
            env_score = self.calculate_environment_score(environment_analysis)
            confidence_scores.append(env_score)
            if env_score > 0.8:
                reasoning_parts.append("Finding is in non-production environment")
        
        # ML-based scoring
        if ml_classification:
            confidence_scores.append(ml_classification.confidence)
            if ml_classification.confidence > 0.7:
                reasoning_parts.append(ml_classification.reasoning)
        
        # Pattern-based scoring
        if pattern_analysis:
            pattern_score = pattern_analysis.pattern_confidence
            confidence_scores.append(pattern_score)
            if pattern_score > 0.8:
                reasoning_parts.append(pattern_analysis.pattern_reasoning)
        
        # Business context scoring
        if business_context:
            business_score = self.calculate_business_score(business_context)
            confidence_scores.append(business_score)
            if business_context.has_business_exception:
                reasoning_parts.append("Finding matches known business exception")
        
        # Temporal scoring
        if temporal_analysis:
            temporal_score = self.calculate_temporal_score(temporal_analysis)
            confidence_scores.append(temporal_score)
            if temporal_analysis.is_temporary:
                reasoning_parts.append("Finding appears to be temporary")
        
        # Calculate final confidence
        final_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0.5
        
        # Determine if false positive
        is_false_positive = final_confidence > 0.7
        
        # Determine recommended action
        if final_confidence > 0.9:
            recommended_action = "SUPPRESS"
        elif final_confidence > 0.7:
            recommended_action = "DOWNGRADE"
        else:
            recommended_action = "REVIEW"
        
        return {
            "is_false_positive": is_false_positive,
            "confidence": final_confidence,
            "reasoning": "; ".join(reasoning_parts) if reasoning_parts else "No specific indicators",
            "recommended_action": recommended_action
        }
    
    def calculate_environment_score(self, environment_analysis):
        """Calculate environment-based false positive score"""
        if environment_analysis.environment in ['test', 'development', 'staging']:
            return 0.9
        elif environment_analysis.environment == 'production':
            return 0.1
        else:
            return 0.5
    
    def calculate_business_score(self, business_context):
        """Calculate business context-based false positive score"""
        if business_context.has_business_exception:
            return 0.8
        elif business_context.is_critical_resource:
            return 0.2
        else:
            return 0.5
    
    def calculate_temporal_score(self, temporal_analysis):
        """Calculate temporal-based false positive score"""
        if temporal_analysis.is_temporary:
            return 0.8
        elif temporal_analysis.in_maintenance_window:
            return 0.7
        else:
            return 0.5
    
    def get_models_used(self, options):
        """Get list of models used in analysis"""
        models = ["environment_analyzer"]
        if options.get('include_ml_classification', True):
            models.append("ml_classifier")
        if options.get('include_pattern_analysis', True):
            models.append("pattern_recognizer")
        if options.get('include_business_context', True):
            models.append("business_analyzer")
        if options.get('include_temporal_analysis', True):
            models.append("temporal_analyzer")
        return models

# Initialize the analyzer
analyzer = FalsePositiveAnalysisLambda()

def lambda_handler(event, context):
    """Main Lambda handler"""
    try:
        # Extract finding and options from event
        finding = event.get('finding')
        options = event.get('analysis_options', {})
        
        if not finding:
            raise ValueError("No finding provided in event")
        
        # Perform analysis
        result = analyzer.analyze_finding(finding, options)
        
        # Send metrics to CloudWatch
        send_metrics(result)
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def send_metrics(result):
    """Send metrics to CloudWatch"""
    try:
        cloudwatch.put_metric_data(
            Namespace='Agent-Hubble/FalsePositiveAnalysis',
            MetricData=[
                {
                    'MetricName': 'ProcessingTime',
                    'Value': result['processing_metadata']['processing_time_ms'],
                    'Unit': 'Milliseconds'
                },
                {
                    'MetricName': 'ConfidenceScore',
                    'Value': result['classification']['confidence'],
                    'Unit': 'None'
                },
                {
                    'MetricName': 'IsFalsePositive',
                    'Value': 1 if result['classification']['is_false_positive'] else 0,
                    'Unit': 'Count'
                }
            ]
        )
    except Exception as e:
        logger.warning(f"Failed to send metrics: {str(e)}")

# For testing purposes
if __name__ == "__main__":
    # Test with a sample finding
    test_finding = {
        "Id": "arn:aws:securityhub:us-west-2:123456789012:subscription/aws-foundational-security-best-practices/v/1.0.0/IAM.1/finding/12345678-1234-1234-1234-123456789012",
        "ProductArn": "arn:aws:securityhub:us-west-2::product/aws/securityhub",
        "GeneratorId": "aws-foundational-security-best-practices/v/1.0.0/IAM.1",
        "AwsAccountId": "123456789012",
        "Types": ["Software and Configuration Checks/Industry and Regulatory Standards/AWS-Foundational-Security-Best-Practices"],
        "FirstObservedAt": "2023-01-01T00:00:00.000Z",
        "LastObservedAt": "2023-01-01T00:00:00.000Z",
        "Severity": {
            "Label": "MEDIUM",
            "Original": "MEDIUM"
        },
        "Title": "IAM.1 IAM root user access key should not exist",
        "Description": "This control checks whether the root user access key exists.",
        "Resources": [
            {
                "Type": "AwsAccount",
                "Id": "arn:aws:iam::123456789012:root",
                "Region": "us-west-2",
                "Tags": {
                    "Environment": "development",
                    "Project": "test-project"
                }
            }
        ]
    }
    
    test_event = {
        "finding": test_finding,
        "analysis_options": {
            "include_ml_classification": True,
            "include_pattern_analysis": True,
            "include_business_context": True,
            "include_temporal_analysis": True
        }
    }
    
    result = lambda_handler(test_event, None)
    print(json.dumps(result, indent=2)) 