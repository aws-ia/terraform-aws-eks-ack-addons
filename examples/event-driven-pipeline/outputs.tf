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

output "stepfunctions_role_arn" {
  description = "IAM execution role arn for step functions"
  value       = aws_iam_role.sfn_execution_role.arn
}

output "eventbridge_role_arn" {
  description = "IAM execution role arn for eventbridge"
  value       = aws_iam_role.eb_execution_role.arn
}
