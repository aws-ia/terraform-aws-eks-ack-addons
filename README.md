#Terraform EKS Blueprints AddOns for AWS Controllers for Kubernetes (ACK)

Welcome to Terraform EKS Blueprints AddOns for AWS Controllers for Kubernetes (ACK)!

This repo includes a set of EKS Blueprints Terraform modules to help you configure ACK controllers for your Amazon EKS clusters.

We will be leveraging [EKS Blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints)
repository to deploy the solution.

## Getting started
To quickstart a Amazon EKS cluster with ACK controllers, visit the [EKS cluster with ack module example](./examples/ack-eks-cluster-with-vpc/)

## How it works

The sections below demonstrate how you can leverage EKS Blueprints Terraform for ACK
to enable ACK controllers to an existing EKS cluster.

### Base Module
The base module allows you to configure ACK controllers for your cluster. You don't have to install all the ACK controllers. Just enable the ones you need.


```hcl
module "eks_ack_controllers" {
  source = "https://github.com/aws-ia/terraform-aws-eks-ack-addons"

  eks_cluster_id       = "my-eks-cluster"
  eks_cluster_endpoint = "https://xxxxxxxxxxxxxxxxxxx.gr7.us-east-2.eks.amazonaws.com"
  eks_oidc_provider    = "https://oidc.eks.us-east-2.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxxxxx"
  eks_cluster_version  = "1.23"

  enable_ack_apigw     = true
  enable_ack_dynamodb  = true
  enable_ack_s3        = true
  enable_ack_rds       = true
}
```

## Motivation

Kubernetes is a powerful and extensible container orchestration technology that allows you to deploy and manage containerized applications at scale. The extensible nature of Kubernetes also allows you to use a wide range of popular open-source tools, commonly referred to as add-ons, in Kubernetes clusters. With such a large number of tools and design choices available, building a tailored EKS cluster that meets your application’s specific needs can take a significant amount of time. It involves integrating a wide range of open-source tools and AWS services and requires deep expertise in AWS and Kubernetes.

Some AWS customers need a solution to provision and configure AWS service resources directly from Kubernetes. With ACK, you can take advantage of AWS-managed services for your Kubernetes applications without needing to define resources outside of the cluster or run services that provide supporting capabilities like databases or message queues within the cluster. ACK has a set of controllers to provide services. It is time consuming to install ACK controllers manually one by one. By leveraging EKS Blueprints and this addon, user can quickly install the ACK controllers they need.


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.33.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ack_apigw"></a> [ack\_apigw](#module\_ack\_apigw) | ./modules/ack-apigw | n/a |
| <a name="module_ack_dynamodb"></a> [ack\_dynamodb](#module\_ack\_dynamodb) | ./modules/ack-dynamodb | n/a |
| <a name="module_ack_rds"></a> [ack\_rds](#module\_ack\_rds) | ./modules/ack-rds | n/a |
| <a name="module_ack_s3"></a> [ack\_s3](#module\_ack\_s3) | ./modules/ack-s3 | n/a |

## Resources

| Name | Type |
|------|------|
| [time_sleep.dataplane](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ack_apigw_helm_config"></a> [ack\_apigw\_helm\_config](#input\_ack\_apigw\_helm\_config) | ACK API gateway v2 Helm Chart config | `any` | `{}` | no |
| <a name="input_ack_dynamodb_helm_config"></a> [ack\_dynamodb\_helm\_config](#input\_ack\_dynamodb\_helm\_config) | ACK dynamodb Helm Chart config | `any` | `{}` | no |
| <a name="input_ack_rds_helm_config"></a> [ack\_rds\_helm\_config](#input\_ack\_rds\_helm\_config) | ACK rds Helm Chart config | `any` | `{}` | no |
| <a name="input_ack_s3_helm_config"></a> [ack\_s3\_helm\_config](#input\_ack\_s3\_helm\_config) | ACK s3 Helm Chart config | `any` | `{}` | no |
| <a name="input_data_plane_wait_arn"></a> [data\_plane\_wait\_arn](#input\_data\_plane\_wait\_arn) | Addon deployment will not proceed until this value is known. Set to node group/Fargate profile ARN to wait for data plane to be ready before provisioning addons | `string` | `""` | no |
| <a name="input_eks_cluster_domain"></a> [eks\_cluster\_domain](#input\_eks\_cluster\_domain) | The domain for the EKS cluster | `string` | `""` | no |
| <a name="input_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#input\_eks\_cluster\_endpoint) | Endpoint for your Kubernetes API server | `string` | `null` | no |
| <a name="input_eks_cluster_id"></a> [eks\_cluster\_id](#input\_eks\_cluster\_id) | EKS Cluster Id | `string` | n/a | yes |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | The Kubernetes version for the cluster | `string` | `null` | no |
| <a name="input_eks_oidc_provider"></a> [eks\_oidc\_provider](#input\_eks\_oidc\_provider) | The OpenID Connect identity provider (issuer URL without leading `https://`) | `string` | `null` | no |
| <a name="input_enable_ack_apigw"></a> [enable\_ack\_apigw](#input\_enable\_ack\_apigw) | Enable ACK API gateway add-on | `bool` | `false` | no |
| <a name="input_enable_ack_dynamodb"></a> [enable\_ack\_dynamodb](#input\_enable\_ack\_dynamodb) | Enable ACK dynamodb add-on | `bool` | `false` | no |
| <a name="input_enable_ack_rds"></a> [enable\_ack\_rds](#input\_enable\_ack\_rds) | Enable ACK rds add-on | `bool` | `false` | no |
| <a name="input_enable_ack_s3"></a> [enable\_ack\_s3](#input\_enable\_ack\_s3) | Enable ACK s3 add-on | `bool` | `false` | no |
| <a name="input_irsa_iam_permissions_boundary"></a> [irsa\_iam\_permissions\_boundary](#input\_irsa\_iam\_permissions\_boundary) | IAM permissions boundary for IRSA roles | `string` | `""` | no |
| <a name="input_irsa_iam_role_path"></a> [irsa\_iam\_role\_path](#input\_irsa\_iam\_role\_path) | IAM role path for IRSA roles | `string` | `"/"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | `map(string)` | `{}` | no |

## Outputs

No outputs.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/main/LICENSE).
