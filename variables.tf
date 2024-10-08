variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
}

variable "oidc_provider_arn" {
  description = "The ARN of the cluster OIDC Provider"
  type        = string
}

variable "create_delay_duration" {
  description = "The duration to wait before creating resources"
  type        = string
  default     = "30s"
}

variable "create_delay_dependencies" {
  description = "Dependency attribute which must be resolved before starting the `create_delay_duration`"
  type        = list(string)
  default     = []
}

variable "ecrpublic_username" {
  description = "User name decoded from the authorization token for accessing public ECR"
  type        = string
  default     = ""
}

variable "ecrpublic_token" {
  description = "Password decoded from the authorization token for accessing public ECR"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
  type        = map(string)
  default     = {}
}

################################################################################
# Amazon Network Firewall
################################################################################

variable "enable_networkfirewall" {
  description = "Enable ACK Network Firewall add-on"
  type        = bool
  default     = false
}

variable "networkfirewall" {
  description = "ACK Network Firewall Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Amazon CloudWatch Logs
################################################################################

variable "enable_cloudwatchlogs" {
  description = "Enable ACK CloudWatch Logs add-on"
  type        = bool
  default     = false
}

variable "cloudwatchlogs" {
  description = "ACK CloudWatch Logs Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Kinesis
################################################################################

variable "enable_kinesis" {
  description = "Enable ACK Kinesis add-on"
  type        = bool
  default     = false
}

variable "kinesis" {
  description = "ACK Kinesis Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Secrets Manager
################################################################################

variable "enable_secretsmanager" {
  description = "Enable ACK Secrets Manager add-on"
  type        = bool
  default     = false
}

variable "secretsmanager" {
  description = "ACK Secrets Manager Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Route 53 Resolver
################################################################################

variable "enable_route53resolver" {
  description = "Enable ACK Route 53 Resolver add-on"
  type        = bool
  default     = false
}

variable "route53resolver" {
  description = "ACK Route 53 Resolver Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Route 53
################################################################################

variable "enable_route53" {
  description = "Enable ACK Route 53 add-on"
  type        = bool
  default     = false
}

variable "route53" {
  description = "ACK Route 53 Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Organizations
################################################################################

variable "enable_organizations" {
  description = "Enable ACK Organizations add-on"
  type        = bool
  default     = false
}

variable "organizations" {
  description = "ACK Organizations Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# MQ
################################################################################

variable "enable_mq" {
  description = "Enable ACK MQ add-on"
  type        = bool
  default     = false
}

variable "mq" {
  description = "ACK MQ Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# CloudWatch
################################################################################

variable "enable_cloudwatch" {
  description = "Enable ACK CloudWatch add-on"
  type        = bool
  default     = false
}

variable "cloudwatch" {
  description = "ACK CloudWatch Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Keyspaces
################################################################################

variable "enable_keyspaces" {
  description = "Enable ACK Keyspaces add-on"
  type        = bool
  default     = false
}

variable "keyspaces" {
  description = "ACK Keyspaces Helm Chart config"
  type        = any
  default     = {}
}


################################################################################
# Kafka
################################################################################

variable "enable_kafka" {
  description = "Enable ACK Kafka add-on"
  type        = bool
  default     = false
}

variable "kafka" {
  description = "ACK Kafka Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# EFS
################################################################################

variable "enable_efs" {
  description = "Enable ACK EFS add-on"
  type        = bool
  default     = false
}

variable "efs" {
  description = "ACK EFS Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# ECS
################################################################################

variable "enable_ecs" {
  description = "Enable ACK ECS add-on"
  type        = bool
  default     = false
}

variable "ecs" {
  description = "ACK ECS Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Cloudtrail
################################################################################

variable "enable_cloudtrail" {
  description = "Enable ACK Cloudtrail add-on"
  type        = bool
  default     = false
}

variable "cloudtrail" {
  description = "ACK Cloudtrail Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Cloudfront
################################################################################

variable "enable_cloudfront" {
  description = "Enable ACK Cloudfront add-on"
  type        = bool
  default     = false
}

variable "cloudfront" {
  description = "ACK cloudfront Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Application Autoscaling
################################################################################

variable "enable_applicationautoscaling" {
  description = "Enable ACK Application Autoscaling add-on"
  type        = bool
  default     = false
}

variable "applicationautoscaling" {
  description = "ACK Application Autoscaling Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Sagemaker
################################################################################

variable "enable_sagemaker" {
  description = "Enable ACK Sagemaker add-on"
  type        = bool
  default     = false
}

variable "sagemaker" {
  description = "ACK Sagemaker Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# MemoryDB
################################################################################

variable "enable_memorydb" {
  description = "Enable ACK MemoryDB add-on"
  type        = bool
  default     = false
}

variable "memorydb" {
  description = "ACK MemoryDB Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# OpenSearch Service
################################################################################

variable "enable_opensearchservice" {
  description = "Enable ACK Opensearch Service add-on"
  type        = bool
  default     = false
}

variable "opensearchservice" {
  description = "ACK Opensearch Service Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# ECR
################################################################################

variable "enable_ecr" {
  description = "Enable ACK ECR add-on"
  type        = bool
  default     = false
}

variable "ecr" {
  description = "ACK ECR Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# SNS
################################################################################

variable "enable_sns" {
  description = "Enable ACK SNS add-on"
  type        = bool
  default     = false
}

variable "sns" {
  description = "ACK SNS Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# SQS
################################################################################

variable "enable_sqs" {
  description = "Enable ACK SQS add-on"
  type        = bool
  default     = false
}

variable "sqs" {
  description = "ACK SQS Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Lambda
################################################################################

variable "enable_lambda" {
  description = "Enable ACK Lambda add-on"
  type        = bool
  default     = false
}

variable "lambda" {
  description = "ACK Lambda Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# IAM
################################################################################

variable "enable_iam" {
  description = "Enable ACK iam add-on"
  type        = bool
  default     = false
}

variable "iam" {
  description = "ACK iam Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# EC2
################################################################################

variable "enable_ec2" {
  description = "Enable ACK ec2 add-on"
  type        = bool
  default     = false
}

variable "ec2" {
  description = "ACK ec2 Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# EKS
################################################################################

variable "enable_eks" {
  description = "Enable ACK eks add-on"
  type        = bool
  default     = false
}

variable "eks" {
  description = "ACK eks Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# KMS
################################################################################

variable "enable_kms" {
  description = "Enable ACK kms add-on"
  type        = bool
  default     = false
}

variable "kms" {
  description = "ACK kms Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# ACM
################################################################################

variable "enable_acm" {
  description = "Enable ACK acm add-on"
  type        = bool
  default     = false
}

variable "acm" {
  description = "ACK acm Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# API Gateway
################################################################################

variable "enable_apigatewayv2" {
  description = "Enable ACK API gateway v2 add-on"
  type        = bool
  default     = false
}

variable "apigatewayv2" {
  description = "ACK API gateway v2 Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# DynamoDB
################################################################################

variable "enable_dynamodb" {
  description = "Enable ACK dynamodb add-on"
  type        = bool
  default     = false
}

variable "dynamodb" {
  description = "ACK dynamodb Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# S3
################################################################################

variable "enable_s3" {
  description = "Enable ACK s3 add-on"
  type        = bool
  default     = false
}

variable "s3" {
  description = "ACK s3 Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# elasticache
################################################################################

variable "enable_elasticache" {
  description = "Enable ACK elasticache add-on"
  type        = bool
  default     = false
}

variable "elasticache" {
  description = "ACK elasticache Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# RDS
################################################################################

variable "enable_rds" {
  description = "Enable ACK rds add-on"
  type        = bool
  default     = false
}

variable "rds" {
  description = "ACK rds Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# EMR Containers
################################################################################

variable "enable_emrcontainers" {
  description = "Enable ACK EMR container add-on"
  type        = bool
  default     = false
}

variable "emrcontainers" {
  description = "ACK EMR container Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# AMP
################################################################################

variable "enable_prometheusservice" {
  description = "Enable ACK prometheusservice add-on"
  type        = bool
  default     = false
}

variable "prometheusservice" {
  description = "ACK prometheusservice Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Step Functions
################################################################################

variable "enable_sfn" {
  description = "Enable ACK step functions add-on"
  type        = bool
  default     = false
}

variable "sfn" {
  description = "ACK step functions Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# Event Bridge
################################################################################

variable "enable_eventbridge" {
  description = "Enable ACK EventBridge add-on"
  type        = bool
  default     = false
}

variable "eventbridge" {
  description = "ACK EventBridge Helm Chart config"
  type        = any
  default     = {}
}

################################################################################
# GitOps Bridge
################################################################################

variable "create_kubernetes_resources" {
  description = "Create Kubernetes resource with Helm or Kubernetes provider"
  type        = bool
  default     = true
}
