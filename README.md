# AWS EKS ACK Addons Terraform module

Terraform module which provisions [AWS controllers for Kubernetes](https://aws-controllers-k8s.github.io/community/docs/community/overview/) on EKS.

## Usage

```hcl
module "eks_ack_addons" {
  source = "aws-ia/eks-ack-addons/aws"

  cluster_id = "example-ack"

  enable_api_gatewayv2 = true
  enable_dynamodb      = true
  enable_s3            = true
  enable_rds           = true
  enable_amp           = true
  enable_emrcontainers = true
  enable_ecr           = true

  tags = {
    Environment = "dev"
  }
}
```

## Examples

Examples codified under the [`examples`](https://github.com/aws-ia/terraform-aws-eks-ack-addons) are intended to give users references for how to use the module as well as testing/validating changes to the source code of the module. If contributing to the project, please be sure to make any appropriate updates to the relevant examples to allow maintainers to test your changes and to keep the examples up to date for users. Thank you!

- [Complete](https://github.com/aws-ia/terraform-aws-eks-addon/examples/complete)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.8 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_amp"></a> [amp](#module\_amp) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.12.2 |
| <a name="module_api_gatewayv2"></a> [api\_gatewayv2](#module\_api\_gatewayv2) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.12.2 |
| <a name="module_dynamodb"></a> [dynamodb](#module\_dynamodb) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.12.2 |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.12.2 |
| <a name="module_emrcontainers"></a> [emrcontainers](#module\_emrcontainers) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.18.0 |
| <a name="module_rds"></a> [rds](#module\_rds) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.12.2 |
| <a name="module_s3"></a> [s3](#module\_s3) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.12.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.emrcontainers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [time_sleep.dataplane](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_policy.amp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.api_gatewayv2_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.api_gatewayv2_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.emrcontainers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amp_helm_config"></a> [amp\_helm\_config](#input\_amp\_helm\_config) | ACK amp Helm Chart config | `any` | `{}` | no |
| <a name="input_api_gatewayv2_helm_config"></a> [api\_gatewayv2\_helm\_config](#input\_api\_gatewayv2\_helm\_config) | ACK API gateway v2 Helm Chart config | `any` | `{}` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | EKS Cluster Id | `string` | n/a | yes |
| <a name="input_data_plane_wait_arn"></a> [data\_plane\_wait\_arn](#input\_data\_plane\_wait\_arn) | Addon deployment will not proceed until this value is known. Set to node group/Fargate profile ARN to wait for data plane to be ready before provisioning addons | `string` | `""` | no |
| <a name="input_dynamodb_helm_config"></a> [dynamodb\_helm\_config](#input\_dynamodb\_helm\_config) | ACK dynamodb Helm Chart config | `any` | `{}` | no |
| <a name="input_ecr_helm_config"></a> [ecr\_helm\_config](#input\_ecr\_helm\_config) | ACK ecr Helm Chart config | `any` | `{}` | no |
| <a name="input_emrcontainers_helm_config"></a> [emrcontainers\_helm\_config](#input\_emrcontainers\_helm\_config) | ACK EMR container Helm Chart config | `any` | `{}` | no |
| <a name="input_enable_amp"></a> [enable\_amp](#input\_enable\_amp) | Enable ACK amp add-on | `bool` | `false` | no |
| <a name="input_enable_api_gatewayv2"></a> [enable\_api\_gatewayv2](#input\_enable\_api\_gatewayv2) | Enable ACK API gateway v2 add-on | `bool` | `false` | no |
| <a name="input_enable_dynamodb"></a> [enable\_dynamodb](#input\_enable\_dynamodb) | Enable ACK dynamodb add-on | `bool` | `false` | no |
| <a name="input_enable_ecr"></a> [enable\_ecr](#input\_enable\_ecr) | Enable ACK ecr add-on | `bool` | `false` | no |
| <a name="input_enable_emrcontainers"></a> [enable\_emrcontainers](#input\_enable\_emrcontainers) | Enable ACK EMR container add-on | `bool` | `false` | no |
| <a name="input_enable_rds"></a> [enable\_rds](#input\_enable\_rds) | Enable ACK rds add-on | `bool` | `false` | no |
| <a name="input_enable_s3"></a> [enable\_s3](#input\_enable\_s3) | Enable ACK s3 add-on | `bool` | `false` | no |
| <a name="input_irsa_iam_permissions_boundary"></a> [irsa\_iam\_permissions\_boundary](#input\_irsa\_iam\_permissions\_boundary) | IAM permissions boundary for IRSA roles | `string` | `""` | no |
| <a name="input_irsa_iam_role_path"></a> [irsa\_iam\_role\_path](#input\_irsa\_iam\_role\_path) | IAM role path for IRSA roles | `string` | `"/"` | no |
| <a name="input_rds_helm_config"></a> [rds\_helm\_config](#input\_rds\_helm\_config) | ACK rds Helm Chart config | `any` | `{}` | no |
| <a name="input_s3_helm_config"></a> [s3\_helm\_config](#input\_s3\_helm\_config) | ACK s3 Helm Chart config | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Community

- [Code of conduct](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/refactor/flatten-modules/.github/CODE_OF_CONDUCT.md)
- [Contributing](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/refactor/flatten-modules/.github/CONTRIBUTING.md)
- [Security issue notifications](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/refactor/flatten-modules/.github/CONTRIBUTING.md#security-issue-notifications)

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/main/LICENSE).
