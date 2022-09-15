variable "eks_cluster_id" {
  description = "EKS Cluster Id"
  type        = string
}

variable "eks_cluster_domain" {
  description = "The domain for the EKS cluster"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
  type        = map(string)
  default     = {}
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

variable "eks_oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  type        = string
  default     = null
}

variable "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
  default     = null
}

variable "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  type        = string
  default     = null
}

#-----------ACK API gateway ADDON-------------
variable "enable_ack-apigw" {
  description = "Enable ACK API gateway add-on"
  type        = bool
  default     = false
}

variable "ack-apigw_helm_config" {
  description = "ACK API gateway v2 Helm Chart config"
  type        = any
  default     = {}
}

#-----------ACK dynamodb ADDON-------------
variable "enable_ack-dynamodb" {
  description = "Enable ACK dynamodb add-on"
  type        = bool
  default     = false
}

variable "ack-dynamo_helm_config" {
  description = "ACK dynamodb Helm Chart config"
  type        = any
  default     = {}
}

#-----------ACK s3 ADDON-------------
variable "enable_ack-s3" {
  description = "Enable ACK s3 add-on"
  type        = bool
  default     = false
}

variable "ack-s3_helm_config" {
  description = "ACK s3 Helm Chart config"
  type        = any
  default     = {}
}

#-----------ACK rds ADDON-------------
variable "enable_ack-rds" {
  description = "Enable ACK rds add-on"
  type        = bool
  default     = false
}

variable "ack-rds_helm_config" {
  description = "ACK rds Helm Chart config"
  type        = any
  default     = {}
}
