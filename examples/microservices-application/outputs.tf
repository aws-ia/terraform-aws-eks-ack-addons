output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks_blueprints.eks_cluster_id
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks_blueprints.configure_kubectl
}

output "region" {
  description = "AWS region"
  value       = local.region
}

output "apigw_vpclink_id" {
  description = "API Gataway vpclink id"
  value       = resource.aws_apigatewayv2_vpc_link.vpclink.id
}