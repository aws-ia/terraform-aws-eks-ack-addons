# tflint-ignore: terraform_unused_declarations
variable "eks_cluster_id" {
  description = "Name of the EKS cluster"
  type        = string
}
variable "aws_region" {
  description = "AWS Region"
  type        = string
}
variable "eks_cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  type        = string
}
variable "eks_oidc_provider" {
  description = "OpenID Connect provider URL of the EKS cluster"
  type        = string
}
variable "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  type        = string
}
