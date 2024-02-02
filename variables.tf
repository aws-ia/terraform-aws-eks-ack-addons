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
# S3
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
