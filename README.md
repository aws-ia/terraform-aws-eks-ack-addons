# AWS EKS ACK Addons Terraform module

Terraform module which provisions [AWS controllers for Kubernetes](https://aws-controllers-k8s.github.io/community/docs/community/overview/) on EKS.

## Usage

```hcl
module "eks_ack_addons" {
  source = "aws-ia/eks-ack-addons/aws"

  # Cluster Info
  cluster_name      = "<cluster name>"
  cluster_endpoint  = "<cluster endpoint>"
  oidc_provider_arn = "<oidc provider arn>"

  # ECR Credentials
  ecrpublic_username = "<ecr user name>"
  ecrpublic_token    = "<ecr token>"

  # Controllers to enable
  enable_sagemaker         = true
  enable_memorydb          = true
  enable_opensearchservice = true
  enable_ecr               = true
  enable_sns               = true
  enable_sqs               = true
  enable_lambda            = true
  enable_iam               = true
  enable_ec2               = true
  enable_eks               = true
  enable_kms               = true
  enable_acm               = true
  enable_apigatewayv2      = true
  enable_dynamodb          = true
  enable_s3                = true
  enable_elasticache       = true
  enable_rds               = true
  enable_prometheusservice = true
  enable_emrcontainers     = true
  enable_sfn               = true
  enable_eventbridge       = true

  tags = {
    Environment = "dev"
  }
}
```

## Examples

Examples codified under the [`examples`](https://github.com/aws-ia/terraform-aws-eks-ack-addons) are intended to give users references for how to use the module as well as testing/validating changes to the source code of the module. If contributing to the project, please be sure to make any appropriate updates to the relevant examples to allow maintainers to test your changes and to keep the examples up to date for users. Thank you!

- [Complete](https://github.com/aws-ia/terraform-aws-eks-ack-addons/tree/main/examples/complete)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_apigatewayv2"></a> [apigatewayv2](#module\_apigatewayv2) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_dynamodb"></a> [dynamodb](#module\_dynamodb) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_ec2"></a> [ec2](#module\_ec2) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_eks"></a> [eks](#module\_eks) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_elasticache"></a> [elasticache](#module\_elasticache) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_emrcontainers"></a> [emrcontainers](#module\_emrcontainers) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_eventbridge"></a> [eventbridge](#module\_eventbridge) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_iam"></a> [iam](#module\_iam) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_kms"></a> [kms](#module\_kms) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_memorydb"></a> [memorydb](#module\_memorydb) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_opensearchservice"></a> [opensearchservice](#module\_opensearchservice) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_prometheusservice"></a> [prometheusservice](#module\_prometheusservice) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_rds"></a> [rds](#module\_rds) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_s3"></a> [s3](#module\_s3) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_sagemaker"></a> [sagemaker](#module\_sagemaker) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_sfn"></a> [sfn](#module\_sfn) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_sns"></a> [sns](#module\_sns) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |
| <a name="module_sqs"></a> [sqs](#module\_sqs) | aws-ia/eks-blueprints-addon/aws | 1.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.acm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.emrcontainers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.prometheusservice](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.sfn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [time_sleep.this](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.acm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.emrcontainers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.prometheusservice](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sfn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm"></a> [acm](#input\_acm) | ACK acm Helm Chart config | `any` | `{}` | no |
| <a name="input_apigatewayv2"></a> [apigatewayv2](#input\_apigatewayv2) | ACK API gateway v2 Helm Chart config | `any` | `{}` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint for your Kubernetes API server | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_create_delay_dependencies"></a> [create\_delay\_dependencies](#input\_create\_delay\_dependencies) | Dependency attribute which must be resolved before starting the `create_delay_duration` | `list(string)` | `[]` | no |
| <a name="input_create_delay_duration"></a> [create\_delay\_duration](#input\_create\_delay\_duration) | The duration to wait before creating resources | `string` | `"30s"` | no |
| <a name="input_create_kubernetes_resources"></a> [create\_kubernetes\_resources](#input\_create\_kubernetes\_resources) | Create Kubernetes resource with Helm or Kubernetes provider | `bool` | `true` | no |
| <a name="input_dynamodb"></a> [dynamodb](#input\_dynamodb) | ACK dynamodb Helm Chart config | `any` | `{}` | no |
| <a name="input_ec2"></a> [ec2](#input\_ec2) | ACK ec2 Helm Chart config | `any` | `{}` | no |
| <a name="input_ecr"></a> [ecr](#input\_ecr) | ACK ECR Helm Chart config | `any` | `{}` | no |
| <a name="input_ecrpublic_token"></a> [ecrpublic\_token](#input\_ecrpublic\_token) | Password decoded from the authorization token for accessing public ECR | `string` | `""` | no |
| <a name="input_ecrpublic_username"></a> [ecrpublic\_username](#input\_ecrpublic\_username) | User name decoded from the authorization token for accessing public ECR | `string` | `""` | no |
| <a name="input_eks"></a> [eks](#input\_eks) | ACK eks Helm Chart config | `any` | `{}` | no |
| <a name="input_elasticache"></a> [elasticache](#input\_elasticache) | ACK elasticache Helm Chart config | `any` | `{}` | no |
| <a name="input_emrcontainers"></a> [emrcontainers](#input\_emrcontainers) | ACK EMR container Helm Chart config | `any` | `{}` | no |
| <a name="input_enable_acm"></a> [enable\_acm](#input\_enable\_acm) | Enable ACK acm add-on | `bool` | `false` | no |
| <a name="input_enable_apigatewayv2"></a> [enable\_apigatewayv2](#input\_enable\_apigatewayv2) | Enable ACK API gateway v2 add-on | `bool` | `false` | no |
| <a name="input_enable_dynamodb"></a> [enable\_dynamodb](#input\_enable\_dynamodb) | Enable ACK dynamodb add-on | `bool` | `false` | no |
| <a name="input_enable_ec2"></a> [enable\_ec2](#input\_enable\_ec2) | Enable ACK ec2 add-on | `bool` | `false` | no |
| <a name="input_enable_ecr"></a> [enable\_ecr](#input\_enable\_ecr) | Enable ACK ECR add-on | `bool` | `false` | no |
| <a name="input_enable_eks"></a> [enable\_eks](#input\_enable\_eks) | Enable ACK eks add-on | `bool` | `false` | no |
| <a name="input_enable_elasticache"></a> [enable\_elasticache](#input\_enable\_elasticache) | Enable ACK elasticache add-on | `bool` | `false` | no |
| <a name="input_enable_emrcontainers"></a> [enable\_emrcontainers](#input\_enable\_emrcontainers) | Enable ACK EMR container add-on | `bool` | `false` | no |
| <a name="input_enable_eventbridge"></a> [enable\_eventbridge](#input\_enable\_eventbridge) | Enable ACK EventBridge add-on | `bool` | `false` | no |
| <a name="input_enable_iam"></a> [enable\_iam](#input\_enable\_iam) | Enable ACK iam add-on | `bool` | `false` | no |
| <a name="input_enable_kms"></a> [enable\_kms](#input\_enable\_kms) | Enable ACK kms add-on | `bool` | `false` | no |
| <a name="input_enable_lambda"></a> [enable\_lambda](#input\_enable\_lambda) | Enable ACK Lambda add-on | `bool` | `false` | no |
| <a name="input_enable_memorydb"></a> [enable\_memorydb](#input\_enable\_memorydb) | Enable ACK MemoryDB add-on | `bool` | `false` | no |
| <a name="input_enable_opensearchservice"></a> [enable\_opensearchservice](#input\_enable\_opensearchservice) | Enable ACK Opensearch Service add-on | `bool` | `false` | no |
| <a name="input_enable_prometheusservice"></a> [enable\_prometheusservice](#input\_enable\_prometheusservice) | Enable ACK prometheusservice add-on | `bool` | `false` | no |
| <a name="input_enable_rds"></a> [enable\_rds](#input\_enable\_rds) | Enable ACK rds add-on | `bool` | `false` | no |
| <a name="input_enable_s3"></a> [enable\_s3](#input\_enable\_s3) | Enable ACK s3 add-on | `bool` | `false` | no |
| <a name="input_enable_sagemaker"></a> [enable\_sagemaker](#input\_enable\_sagemaker) | Enable ACK Sagemaker add-on | `bool` | `false` | no |
| <a name="input_enable_sfn"></a> [enable\_sfn](#input\_enable\_sfn) | Enable ACK step functions add-on | `bool` | `false` | no |
| <a name="input_enable_sns"></a> [enable\_sns](#input\_enable\_sns) | Enable ACK SNS add-on | `bool` | `false` | no |
| <a name="input_enable_sqs"></a> [enable\_sqs](#input\_enable\_sqs) | Enable ACK SQS add-on | `bool` | `false` | no |
| <a name="input_eventbridge"></a> [eventbridge](#input\_eventbridge) | ACK EventBridge Helm Chart config | `any` | `{}` | no |
| <a name="input_iam"></a> [iam](#input\_iam) | ACK iam Helm Chart config | `any` | `{}` | no |
| <a name="input_kms"></a> [kms](#input\_kms) | ACK kms Helm Chart config | `any` | `{}` | no |
| <a name="input_lambda"></a> [lambda](#input\_lambda) | ACK Lambda Helm Chart config | `any` | `{}` | no |
| <a name="input_memorydb"></a> [memorydb](#input\_memorydb) | ACK MemoryDB Helm Chart config | `any` | `{}` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | The ARN of the cluster OIDC Provider | `string` | n/a | yes |
| <a name="input_opensearchservice"></a> [opensearchservice](#input\_opensearchservice) | ACK Opensearch Service Helm Chart config | `any` | `{}` | no |
| <a name="input_prometheusservice"></a> [prometheusservice](#input\_prometheusservice) | ACK prometheusservice Helm Chart config | `any` | `{}` | no |
| <a name="input_rds"></a> [rds](#input\_rds) | ACK rds Helm Chart config | `any` | `{}` | no |
| <a name="input_s3"></a> [s3](#input\_s3) | ACK s3 Helm Chart config | `any` | `{}` | no |
| <a name="input_sagemaker"></a> [sagemaker](#input\_sagemaker) | ACK Sagemaker Helm Chart config | `any` | `{}` | no |
| <a name="input_sfn"></a> [sfn](#input\_sfn) | ACK step functions Helm Chart config | `any` | `{}` | no |
| <a name="input_sns"></a> [sns](#input\_sns) | ACK SNS Helm Chart config | `any` | `{}` | no |
| <a name="input_sqs"></a> [sqs](#input\_sqs) | ACK SQS Helm Chart config | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitops_metadata"></a> [gitops\_metadata](#output\_gitops\_metadata) | GitOps Bridge metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Community

- [Code of conduct](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/refactor/flatten-modules/.github/CODE_OF_CONDUCT.md)
- [Contributing](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/refactor/flatten-modules/.github/CONTRIBUTING.md)
- [Security issue notifications](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/refactor/flatten-modules/.github/CONTRIBUTING.md#security-issue-notifications)

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/aws-ia/terraform-aws-eks-ack-addons/blob/main/LICENSE).
