output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks_blueprints.configure_kubectl
}


output "emr_on_eks_role_id" {
  description = "IAM execution role ID for EMR on EKS"
  value       = module.eks_blueprints.emr_on_eks_role_id
}

output "emr_on_eks_role_arn" {
  description = "IAM execution role arn for EMR on EKS"
  value       = module.eks_blueprints.emr_on_eks_role_arn
}

output "emr_studio_service_role_arn" {
  description = "EMR studio service role ARN"
  value       = aws_iam_role.emr_studio_service_role.arn
}

output "emr_studio_S3_bucket_id" {
  description = "EMR studio s3 bucket id"
  value       = module.s3_bucket.s3_bucket_id
}
