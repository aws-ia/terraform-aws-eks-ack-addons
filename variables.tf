variable "cluster_id" {
  description = "EKS Cluster Id"
  type        = string
}

variable "data_plane_wait_arn" {
  description = "Addon deployment will not proceed until this value is known. Set to node group/Fargate profile ARN to wait for data plane to be ready before provisioning addons"
  type        = string
  default     = ""
}

variable "irsa_iam_role_path" {
  description = "IAM role path for IRSA roles"
  type        = string
  default     = "/"
}

variable "irsa_iam_permissions_boundary" {
  description = "IAM permissions boundary for IRSA roles"
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

variable "enable_api_gatewayv2" {
  description = "Enable ACK API gateway v2 add-on"
  type        = bool
  default     = false
}

variable "api_gatewayv2_helm_config" {
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

variable "dynamodb_helm_config" {
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

variable "s3_helm_config" {
  description = "ACK s3 Helm Chart config"
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

variable "rds_helm_config" {
  description = "ACK rds Helm Chart config"
  type        = any
  default     = {}
}
