output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks_blueprints.configure_kubectl
}

output "api_gatewayv2_vpc_link_id" {
  description = "API Gataway v2  VPC link ID"
  value       = resource.aws_apigatewayv2_vpc_link.vpc_link.id
}
