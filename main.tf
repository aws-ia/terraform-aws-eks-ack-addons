data "aws_partition" "current" {}
data "aws_region" "current" {}

# This resource is used to provide a means of mapping an implicit dependency
# between the cluster and the addons.
resource "time_sleep" "this" {
  create_duration = var.create_delay_duration

  triggers = {
    cluster_endpoint  = var.cluster_endpoint
    cluster_name      = var.cluster_name
    custom            = join(",", var.create_delay_dependencies)
    oidc_provider_arn = var.oidc_provider_arn
  }
}

locals {
  partition = data.aws_partition.current.partition
  region    = data.aws_region.current.name

  # Threads the sleep resource into the module to make the dependency
  # tflint-ignore: terraform_unused_declarations
  cluster_endpoint = time_sleep.this.triggers["cluster_endpoint"]
  # tflint-ignore: terraform_unused_declarations
  cluster_name      = time_sleep.this.triggers["cluster_name"]
  oidc_provider_arn = time_sleep.this.triggers["oidc_provider_arn"]

  iam_role_policy_prefix = "arn:${local.partition}:iam::aws:policy"

  # ECR Credentials
  repository_username = var.create_kubernetes_resources ? var.ecrpublic_username : ""
  repository_password = var.create_kubernetes_resources ? var.ecrpublic_token : ""
}

################################################################################
# SNS
################################################################################

locals {
  sns_name = "ack-sns"
}

module "sns" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_sns

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/sns-chart:1.0.11
  name             = try(var.sns.name, local.sns_name)
  description      = try(var.sns.description, "Helm Chart for SNS controller for ACK")
  namespace        = try(var.sns.namespace, "ack-system")
  create_namespace = try(var.sns.create_namespace, true)
  chart            = "sns-chart"
  chart_version    = try(var.sns.chart_version, "1.0.11")
  repository       = try(var.sns.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.sns.values, [])

  timeout                    = try(var.sns.timeout, null)
  repository_key_file        = try(var.sns.repository_key_file, null)
  repository_cert_file       = try(var.sns.repository_cert_file, null)
  repository_ca_file         = try(var.sns.repository_ca_file, null)
  repository_username        = try(var.sns.repository_username, local.repository_username)
  repository_password        = try(var.sns.repository_password, local.repository_password)
  devel                      = try(var.sns.devel, null)
  verify                     = try(var.sns.verify, null)
  keyring                    = try(var.sns.keyring, null)
  disable_webhooks           = try(var.sns.disable_webhooks, null)
  reuse_values               = try(var.sns.reuse_values, null)
  reset_values               = try(var.sns.reset_values, null)
  force_update               = try(var.sns.force_update, null)
  recreate_pods              = try(var.sns.recreate_pods, null)
  cleanup_on_fail            = try(var.sns.cleanup_on_fail, null)
  max_history                = try(var.sns.max_history, null)
  atomic                     = try(var.sns.atomic, null)
  skip_crds                  = try(var.sns.skip_crds, null)
  render_subchart_notes      = try(var.sns.render_subchart_notes, null)
  disable_openapi_validation = try(var.sns.disable_openapi_validation, null)
  wait                       = try(var.sns.wait, false)
  wait_for_jobs              = try(var.sns.wait_for_jobs, null)
  dependency_update          = try(var.sns.dependency_update, null)
  replace                    = try(var.sns.replace, null)
  lint                       = try(var.sns.lint, null)

  postrender = try(var.sns.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-sns-sns-chart-xxxxxxxxxxxxx` to `ack-sns-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-sns"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.sns_name
    }],
    try(var.sns.set, [])
  )
  set_sensitive = try(var.sns.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.sns.create_role, true)
  role_name                     = try(var.sns.role_name, "ack-sns")
  role_name_use_prefix          = try(var.sns.role_name_use_prefix, true)
  role_path                     = try(var.sns.role_path, "/")
  role_permissions_boundary_arn = lookup(var.sns, "role_permissions_boundary_arn", null)
  role_description              = try(var.sns.role_description, "IRSA for SNS controller for ACK")
  role_policies = lookup(var.sns, "role_policies", {
    AWSSNSPolicy = var.enable_sns ? aws_iam_policy.snspolicy[0].arn : null
  })
  create_policy = try(var.sns.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.sns_name
    }
  }

  tags = var.tags
}

# recommended iam-controller policy https://github.com/aws-controllers-k8s/sns-controller/blob/main/config/iam/recommended-policy-arn
data "aws_iam_policy_document" "sns_controller" {
  count = var.enable_sns ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "sns:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "snspolicy" {
  count = var.enable_sns ? 1 : 0

  name        = "SNSController"
  description = "IAM policy for SNS Controller"
  policy      = data.aws_iam_policy_document.sns_controller[0].json

  tags = var.tags
}

################################################################################
# SQS
################################################################################

locals {
  sqs_name = "ack-sqs"
}

module "sqs" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_sqs

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/sqs-chart:1.0.14
  name             = try(var.sqs.name, local.sqs_name)
  description      = try(var.sqs.description, "Helm Chart for SQS controller for ACK")
  namespace        = try(var.sqs.namespace, "ack-system")
  create_namespace = try(var.sqs.create_namespace, true)
  chart            = "sqs-chart"
  chart_version    = try(var.sqs.chart_version, "1.0.14")
  repository       = try(var.sqs.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.sqs.values, [])

  timeout                    = try(var.sqs.timeout, null)
  repository_key_file        = try(var.sqs.repository_key_file, null)
  repository_cert_file       = try(var.sqs.repository_cert_file, null)
  repository_ca_file         = try(var.sqs.repository_ca_file, null)
  repository_username        = try(var.sqs.repository_username, local.repository_username)
  repository_password        = try(var.sqs.repository_password, local.repository_password)
  devel                      = try(var.sqs.devel, null)
  verify                     = try(var.sqs.verify, null)
  keyring                    = try(var.sqs.keyring, null)
  disable_webhooks           = try(var.sqs.disable_webhooks, null)
  reuse_values               = try(var.sqs.reuse_values, null)
  reset_values               = try(var.sqs.reset_values, null)
  force_update               = try(var.sqs.force_update, null)
  recreate_pods              = try(var.sqs.recreate_pods, null)
  cleanup_on_fail            = try(var.sqs.cleanup_on_fail, null)
  max_history                = try(var.sqs.max_history, null)
  atomic                     = try(var.sqs.atomic, null)
  skip_crds                  = try(var.sqs.skip_crds, null)
  render_subchart_notes      = try(var.sqs.render_subchart_notes, null)
  disable_openapi_validation = try(var.sqs.disable_openapi_validation, null)
  wait                       = try(var.sqs.wait, false)
  wait_for_jobs              = try(var.sqs.wait_for_jobs, null)
  dependency_update          = try(var.sqs.dependency_update, null)
  replace                    = try(var.sqs.replace, null)
  lint                       = try(var.sqs.lint, null)

  postrender = try(var.sqs.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-sqs-sqs-chart-xxxxxxxxxxxxx` to `ack-sqs-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-sqs"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.sqs_name
    }],
    try(var.sqs.set, [])
  )
  set_sensitive = try(var.sqs.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.sqs.create_role, true)
  role_name                     = try(var.sqs.role_name, "ack-sqs")
  role_name_use_prefix          = try(var.sqs.role_name_use_prefix, true)
  role_path                     = try(var.sqs.role_path, "/")
  role_permissions_boundary_arn = lookup(var.sqs, "role_permissions_boundary_arn", null)
  role_description              = try(var.sqs.role_description, "IRSA for SQS controller for ACK")
  role_policies = lookup(var.sqs, "role_policies", {
    AWSSQSPolicy = var.enable_sqs ? aws_iam_policy.sqspolicy[0].arn : null
  })
  create_policy = try(var.sqs.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.sqs_name
    }
  }

  tags = var.tags
}

# recommended iam-controller policy https://github.com/aws-controllers-k8s/sqs-controller/blob/main/config/iam/recommended-policy-arn
data "aws_iam_policy_document" "sqs_controller" {
  count = var.enable_sqs ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "sqs:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sqspolicy" {
  count = var.enable_sqs ? 1 : 0

  name        = "SQSController"
  description = "IAM policy for SQS Controller"
  policy      = data.aws_iam_policy_document.sqs_controller[0].json

  tags = var.tags
}

################################################################################
# Lambda
################################################################################

locals {
  lambda_name = "ack-lambda"
}

module "lambda" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_lambda

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/lambda-chart:1.5.1
  name             = try(var.lambda.name, local.lambda_name)
  description      = try(var.lambda.description, "Helm Chart for Lambda controller for ACK")
  namespace        = try(var.lambda.namespace, "ack-system")
  create_namespace = try(var.lambda.create_namespace, true)
  chart            = "lambda-chart"
  chart_version    = try(var.lambda.chart_version, "1.5.1")
  repository       = try(var.lambda.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.lambda.values, [])

  timeout                    = try(var.lambda.timeout, null)
  repository_key_file        = try(var.lambda.repository_key_file, null)
  repository_cert_file       = try(var.lambda.repository_cert_file, null)
  repository_ca_file         = try(var.lambda.repository_ca_file, null)
  repository_username        = try(var.lambda.repository_username, local.repository_username)
  repository_password        = try(var.lambda.repository_password, local.repository_password)
  devel                      = try(var.lambda.devel, null)
  verify                     = try(var.lambda.verify, null)
  keyring                    = try(var.lambda.keyring, null)
  disable_webhooks           = try(var.lambda.disable_webhooks, null)
  reuse_values               = try(var.lambda.reuse_values, null)
  reset_values               = try(var.lambda.reset_values, null)
  force_update               = try(var.lambda.force_update, null)
  recreate_pods              = try(var.lambda.recreate_pods, null)
  cleanup_on_fail            = try(var.lambda.cleanup_on_fail, null)
  max_history                = try(var.lambda.max_history, null)
  atomic                     = try(var.lambda.atomic, null)
  skip_crds                  = try(var.lambda.skip_crds, null)
  render_subchart_notes      = try(var.lambda.render_subchart_notes, null)
  disable_openapi_validation = try(var.lambda.disable_openapi_validation, null)
  wait                       = try(var.lambda.wait, false)
  wait_for_jobs              = try(var.lambda.wait_for_jobs, null)
  dependency_update          = try(var.lambda.dependency_update, null)
  replace                    = try(var.lambda.replace, null)
  lint                       = try(var.lambda.lint, null)

  postrender = try(var.lambda.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-lambda-lambda-chart-xxxxxxxxxxxxx` to `ack-lambda-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-lambda"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.lambda_name
    }],
    try(var.lambda.set, [])
  )
  set_sensitive = try(var.lambda.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.lambda.create_role, true)
  role_name                     = try(var.lambda.role_name, "ack-lambda")
  role_name_use_prefix          = try(var.lambda.role_name_use_prefix, true)
  role_path                     = try(var.lambda.role_path, "/")
  role_permissions_boundary_arn = lookup(var.lambda, "role_permissions_boundary_arn", null)
  role_description              = try(var.lambda.role_description, "IRSA for Lambda controller for ACK")
  role_policies = lookup(var.lambda, "role_policies", {
    AWSlambdaPolicy = var.enable_lambda ? aws_iam_policy.lambdapolicy[0].arn : null
  })
  create_policy = try(var.lambda.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.lambda_name
    }
  }

  tags = var.tags
}

# recommended iam-controller policy https://github.com/aws-controllers-k8s/lambda-controller/blob/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "lambda_controller" {
  count = var.enable_lambda ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "lambda:*",
      "s3:Get*",
      "ecr:Get*",
      "ecr:BatchGet*",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lambdapolicy" {
  count = var.enable_lambda ? 1 : 0

  name        = "LambdaController"
  description = "IAM policy for Lambda Controller"
  policy      = data.aws_iam_policy_document.lambda_controller[0].json

  tags = var.tags
}

################################################################################
# IAM
################################################################################

locals {
  iam_name = "ack-iam"
}

module "iam" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_iam

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/iam-chart:1.3.10
  name             = try(var.iam.name, local.iam_name)
  description      = try(var.iam.description, "Helm Chart for iam controller for ACK")
  namespace        = try(var.iam.namespace, "ack-system")
  create_namespace = try(var.iam.create_namespace, true)
  chart            = "iam-chart"
  chart_version    = try(var.iam.chart_version, "1.3.10")
  repository       = try(var.iam.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.iam.values, [])

  timeout                    = try(var.iam.timeout, null)
  repository_key_file        = try(var.iam.repository_key_file, null)
  repository_cert_file       = try(var.iam.repository_cert_file, null)
  repository_ca_file         = try(var.iam.repository_ca_file, null)
  repository_username        = try(var.iam.repository_username, local.repository_username)
  repository_password        = try(var.iam.repository_password, local.repository_password)
  devel                      = try(var.iam.devel, null)
  verify                     = try(var.iam.verify, null)
  keyring                    = try(var.iam.keyring, null)
  disable_webhooks           = try(var.iam.disable_webhooks, null)
  reuse_values               = try(var.iam.reuse_values, null)
  reset_values               = try(var.iam.reset_values, null)
  force_update               = try(var.iam.force_update, null)
  recreate_pods              = try(var.iam.recreate_pods, null)
  cleanup_on_fail            = try(var.iam.cleanup_on_fail, null)
  max_history                = try(var.iam.max_history, null)
  atomic                     = try(var.iam.atomic, null)
  skip_crds                  = try(var.iam.skip_crds, null)
  render_subchart_notes      = try(var.iam.render_subchart_notes, null)
  disable_openapi_validation = try(var.iam.disable_openapi_validation, null)
  wait                       = try(var.iam.wait, false)
  wait_for_jobs              = try(var.iam.wait_for_jobs, null)
  dependency_update          = try(var.iam.dependency_update, null)
  replace                    = try(var.iam.replace, null)
  lint                       = try(var.iam.lint, null)

  postrender = try(var.iam.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-iam-iam-chart-xxxxxxxxxxxxx` to `ack-iam-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-iam"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.iam_name
    }],
    try(var.iam.set, [])
  )
  set_sensitive = try(var.iam.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.iam.create_role, true)
  role_name                     = try(var.iam.role_name, "ack-iam")
  role_name_use_prefix          = try(var.iam.role_name_use_prefix, true)
  role_path                     = try(var.iam.role_path, "/")
  role_permissions_boundary_arn = lookup(var.iam, "role_permissions_boundary_arn", null)
  role_description              = try(var.iam.role_description, "IRSA for iam controller for ACK")
  role_policies = lookup(var.iam, "role_policies", {
    AWSIamPolicy = var.enable_iam ? aws_iam_policy.iampolicy[0].arn : null
  })
  create_policy = try(var.iam.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.iam_name
    }
  }

  tags = var.tags
}

# recommended iam-controller policy https://github.com/aws-controllers-k8s/iam-controller/blob/main/config/iam/recommended-inline-policy
resource "aws_iam_policy" "iampolicy" {
  count = var.enable_iam ? 1 : 0

  name_prefix = format("%s-%s", local.iam_name, "controller-iam-policies")

  path        = "/"
  description = "ACK IAM contoller policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:GetGroup",
          "iam:CreateGroup",
          "iam:DeleteGroup",
          "iam:UpdateGroup",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:PutRolePermissionsBoundary",
          "iam:PutUserPermissionsBoundary",
          "iam:GetUser",
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:UpdateUser",
          "iam:GetPolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:ListPolicyVersions",
          "iam:ListPolicyTags",
          "iam:ListAttachedGroupPolicies",
          "iam:GetGroupPolicy",
          "iam:PutGroupPolicy",
          "iam:AttachGroupPolicy",
          "iam:DetachGroupPolicy",
          "iam:DeleteGroupPolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListAttachedUserPolicies",
          "iam:ListUserPolicies",
          "iam:GetUserPolicy",
          "iam:PutUserPolicy",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:DeleteUserPolicy",
          "iam:ListRoleTags",
          "iam:ListUserTags",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagUser",
          "iam:UntagUser",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviderTags",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:UntagOpenIDConnectProvider",
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:UpdateAssumeRolePolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

################################################################################
# EC2
################################################################################

locals {
  ec2_name = "ack-ec2"
}

module "ec2" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_ec2

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/ec2-chart:1.2.15
  name             = try(var.ec2.name, local.ec2_name)
  description      = try(var.ec2.description, "Helm Chart for ec2 controller for ACK")
  namespace        = try(var.ec2.namespace, "ack-system")
  create_namespace = try(var.ec2.create_namespace, true)
  chart            = "ec2-chart"
  chart_version    = try(var.ec2.chart_version, "1.2.15")
  repository       = try(var.ec2.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.ec2.values, [])

  timeout                    = try(var.ec2.timeout, null)
  repository_key_file        = try(var.ec2.repository_key_file, null)
  repository_cert_file       = try(var.ec2.repository_cert_file, null)
  repository_ca_file         = try(var.ec2.repository_ca_file, null)
  repository_username        = try(var.ec2.repository_username, local.repository_username)
  repository_password        = try(var.ec2.repository_password, local.repository_password)
  devel                      = try(var.ec2.devel, null)
  verify                     = try(var.ec2.verify, null)
  keyring                    = try(var.ec2.keyring, null)
  disable_webhooks           = try(var.ec2.disable_webhooks, null)
  reuse_values               = try(var.ec2.reuse_values, null)
  reset_values               = try(var.ec2.reset_values, null)
  force_update               = try(var.ec2.force_update, null)
  recreate_pods              = try(var.ec2.recreate_pods, null)
  cleanup_on_fail            = try(var.ec2.cleanup_on_fail, null)
  max_history                = try(var.ec2.max_history, null)
  atomic                     = try(var.ec2.atomic, null)
  skip_crds                  = try(var.ec2.skip_crds, null)
  render_subchart_notes      = try(var.ec2.render_subchart_notes, null)
  disable_openapi_validation = try(var.ec2.disable_openapi_validation, null)
  wait                       = try(var.ec2.wait, false)
  wait_for_jobs              = try(var.ec2.wait_for_jobs, null)
  dependency_update          = try(var.ec2.dependency_update, null)
  replace                    = try(var.ec2.replace, null)
  lint                       = try(var.ec2.lint, null)

  postrender = try(var.ec2.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-ec2-ec2-chart-xxxxxxxxxxxxx` to `ack-ec2-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-ec2"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.ec2_name
    }],
    try(var.ec2.set, [])
  )
  set_sensitive = try(var.ec2.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.ec2.create_role, true)
  role_name                     = try(var.ec2.role_name, "ack-ec2")
  role_name_use_prefix          = try(var.ec2.role_name_use_prefix, true)
  role_path                     = try(var.ec2.role_path, "/")
  role_permissions_boundary_arn = lookup(var.ec2, "role_permissions_boundary_arn", null)
  role_description              = try(var.ec2.role_description, "IRSA for ec2 controller for ACK")
  role_policies = lookup(var.ec2, "role_policies", {
    AmazonEC2FullAccess = "${local.iam_role_policy_prefix}/AmazonEC2FullAccess"
  })
  create_policy = try(var.ec2.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.ec2_name
    }
  }

  tags = var.tags
}

################################################################################
# EKS
################################################################################

locals {
  eks_name = "ack-eks"
}

module "eks" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_eks

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/eks-chart:1.4.3
  name             = try(var.eks.name, local.eks_name)
  description      = try(var.eks.description, "Helm Chart for eks controller for ACK")
  namespace        = try(var.eks.namespace, "ack-system")
  create_namespace = try(var.eks.create_namespace, true)
  chart            = "eks-chart"
  chart_version    = try(var.eks.chart_version, "1.4.3")
  repository       = try(var.eks.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.eks.values, [])

  timeout                    = try(var.eks.timeout, null)
  repository_key_file        = try(var.eks.repository_key_file, null)
  repository_cert_file       = try(var.eks.repository_cert_file, null)
  repository_ca_file         = try(var.eks.repository_ca_file, null)
  repository_username        = try(var.eks.repository_username, local.repository_username)
  repository_password        = try(var.eks.repository_password, local.repository_password)
  devel                      = try(var.eks.devel, null)
  verify                     = try(var.eks.verify, null)
  keyring                    = try(var.eks.keyring, null)
  disable_webhooks           = try(var.eks.disable_webhooks, null)
  reuse_values               = try(var.eks.reuse_values, null)
  reset_values               = try(var.eks.reset_values, null)
  force_update               = try(var.eks.force_update, null)
  recreate_pods              = try(var.eks.recreate_pods, null)
  cleanup_on_fail            = try(var.eks.cleanup_on_fail, null)
  max_history                = try(var.eks.max_history, null)
  atomic                     = try(var.eks.atomic, null)
  skip_crds                  = try(var.eks.skip_crds, null)
  render_subchart_notes      = try(var.eks.render_subchart_notes, null)
  disable_openapi_validation = try(var.eks.disable_openapi_validation, null)
  wait                       = try(var.eks.wait, false)
  wait_for_jobs              = try(var.eks.wait_for_jobs, null)
  dependency_update          = try(var.eks.dependency_update, null)
  replace                    = try(var.eks.replace, null)
  lint                       = try(var.eks.lint, null)

  postrender = try(var.eks.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-eks-eks-chart-xxxxxxxxxxxxx` to `ack-eks-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-eks"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.eks_name
    }],
    try(var.eks.set, [])
  )
  set_sensitive = try(var.eks.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.eks.create_role, true)
  role_name                     = try(var.eks.role_name, "ack-eks")
  role_name_use_prefix          = try(var.eks.role_name_use_prefix, true)
  role_path                     = try(var.eks.role_path, "/")
  role_permissions_boundary_arn = lookup(var.eks, "role_permissions_boundary_arn", null)
  role_description              = try(var.eks.role_description, "IRSA for eks controller for ACK")
  role_policies = lookup(var.eks, "role_policies", {
    EKSPolicy = var.enable_eks ? aws_iam_policy.ekspolicy[0].arn : null
  })
  create_policy = try(var.eks.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.eks_name
    }
  }

  tags = var.tags
}

# recommended eks-controller policy https://github.com/aws-controllers-k8s/eks-controller/blob/main/config/iam/recommended-inline-policy
resource "aws_iam_policy" "ekspolicy" {
  count = var.enable_eks ? 1 : 0

  name_prefix = format("%s-%s", local.eks_name, "controller-eks-policies")

  path        = "/"
  description = "ACK EKS contoller policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*",
          "iam:GetRole",
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

################################################################################
# KMS
################################################################################

locals {
  kms_name = "ack-kms"
}

module "kms" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_kms

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/kms-chart:1.0.14
  name             = try(var.kms.name, local.kms_name)
  description      = try(var.kms.description, "Helm Chart for kms controller for ACK")
  namespace        = try(var.kms.namespace, "ack-system")
  create_namespace = try(var.kms.create_namespace, true)
  chart            = "kms-chart"
  chart_version    = try(var.kms.chart_version, "1.0.14")
  repository       = try(var.kms.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.kms.values, [])

  timeout                    = try(var.kms.timeout, null)
  repository_key_file        = try(var.kms.repository_key_file, null)
  repository_cert_file       = try(var.kms.repository_cert_file, null)
  repository_ca_file         = try(var.kms.repository_ca_file, null)
  repository_username        = try(var.kms.repository_username, local.repository_username)
  repository_password        = try(var.kms.repository_password, local.repository_password)
  devel                      = try(var.kms.devel, null)
  verify                     = try(var.kms.verify, null)
  keyring                    = try(var.kms.keyring, null)
  disable_webhooks           = try(var.kms.disable_webhooks, null)
  reuse_values               = try(var.kms.reuse_values, null)
  reset_values               = try(var.kms.reset_values, null)
  force_update               = try(var.kms.force_update, null)
  recreate_pods              = try(var.kms.recreate_pods, null)
  cleanup_on_fail            = try(var.kms.cleanup_on_fail, null)
  max_history                = try(var.kms.max_history, null)
  atomic                     = try(var.kms.atomic, null)
  skip_crds                  = try(var.kms.skip_crds, null)
  render_subchart_notes      = try(var.kms.render_subchart_notes, null)
  disable_openapi_validation = try(var.kms.disable_openapi_validation, null)
  wait                       = try(var.kms.wait, false)
  wait_for_jobs              = try(var.kms.wait_for_jobs, null)
  dependency_update          = try(var.kms.dependency_update, null)
  replace                    = try(var.kms.replace, null)
  lint                       = try(var.kms.lint, null)

  postrender = try(var.kms.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-kms-kms-chart-xxxxxxxxxxxxx` to `ack-kms-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-kms"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.kms_name
    }],
    try(var.kms.set, [])
  )
  set_sensitive = try(var.kms.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.kms\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.kms.create_role, true)
  role_name                     = try(var.kms.role_name, "ack-kms")
  role_name_use_prefix          = try(var.kms.role_name_use_prefix, true)
  role_path                     = try(var.kms.role_path, "/")
  role_permissions_boundary_arn = lookup(var.kms, "role_permissions_boundary_arn", null)
  role_description              = try(var.kms.role_description, "IRSA for kms controller for ACK")
  role_policies = lookup(var.kms, "role_policies", {
    policy = var.enable_kms ? aws_iam_policy.kmspolicy[0].arn : null
  })
  create_policy = try(var.kms.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.kms_name
    }
  }

  tags = var.tags
}

# recommended kms-controller policy https://github.com/aws-controllers-k8s/kms-controller/blob/main/config/iam/recommended-inline-policy
resource "aws_iam_policy" "kmspolicy" {
  count = var.enable_kms ? 1 : 0

  name_prefix = format("%s-%s", local.kms_name, "controller-kms-policies")

  path        = "/"
  description = "ACK KMS contoller policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:CreateAlias",
          "kms:CreateKey",
          "kms:DeleteAlias",
          "kms:Describe*",
          "kms:GenerateRandom",
          "kms:Get*",
          "kms:List*",
          "kms:ScheduleKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "iam:ListGroups",
          "iam:ListRoles",
          "iam:ListUsers",
          "iam:CreateServiceLinkedRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

################################################################################
# ACM
################################################################################

locals {
  acm_name = "ack-acm"
}

module "acm" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_acm

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/acm-chart:0.0.17
  name             = try(var.acm.name, local.acm_name)
  description      = try(var.acm.description, "Helm Chart for acm controller for ACK")
  namespace        = try(var.acm.namespace, "ack-system")
  create_namespace = try(var.acm.create_namespace, true)
  chart            = "acm-chart"
  chart_version    = try(var.acm.chart_version, "0.0.17")
  repository       = try(var.acm.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.acm.values, [])

  timeout                    = try(var.acm.timeout, null)
  repository_key_file        = try(var.acm.repository_key_file, null)
  repository_cert_file       = try(var.acm.repository_cert_file, null)
  repository_ca_file         = try(var.acm.repository_ca_file, null)
  repository_username        = try(var.acm.repository_username, local.repository_username)
  repository_password        = try(var.acm.repository_password, local.repository_password)
  devel                      = try(var.acm.devel, null)
  verify                     = try(var.acm.verify, null)
  keyring                    = try(var.acm.keyring, null)
  disable_webhooks           = try(var.acm.disable_webhooks, null)
  reuse_values               = try(var.acm.reuse_values, null)
  reset_values               = try(var.acm.reset_values, null)
  force_update               = try(var.acm.force_update, null)
  recreate_pods              = try(var.acm.recreate_pods, null)
  cleanup_on_fail            = try(var.acm.cleanup_on_fail, null)
  max_history                = try(var.acm.max_history, null)
  atomic                     = try(var.acm.atomic, null)
  skip_crds                  = try(var.acm.skip_crds, null)
  render_subchart_notes      = try(var.acm.render_subchart_notes, null)
  disable_openapi_validation = try(var.acm.disable_openapi_validation, null)
  wait                       = try(var.acm.wait, false)
  wait_for_jobs              = try(var.acm.wait_for_jobs, null)
  dependency_update          = try(var.acm.dependency_update, null)
  replace                    = try(var.acm.replace, null)
  lint                       = try(var.acm.lint, null)

  postrender = try(var.acm.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-acm-acm-chart-xxxxxxxxxxxxx` to `ack-acm-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-acm"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.acm_name
    }],
    try(var.acm.set, [])
  )
  set_sensitive = try(var.acm.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.acm\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.acm.create_role, true)
  role_name                     = try(var.acm.role_name, "ack-acm")
  role_name_use_prefix          = try(var.acm.role_name_use_prefix, true)
  role_path                     = try(var.acm.role_path, "/")
  role_permissions_boundary_arn = lookup(var.acm, "role_permissions_boundary_arn", null)
  role_description              = try(var.acm.role_description, "IRSA for acm controller for ACK")
  role_policies = lookup(var.acm, "role_policies", {
    policy = var.enable_acm ? aws_iam_policy.acmpolicy[0].arn : null
  })
  create_policy = try(var.acm.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.acm_name
    }
  }

  tags = var.tags
}

# recommended acm-controller policy https://github.com/aws-controllers-k8s/acm-controller/blob/main/config/iam/recommended-inline-policy
resource "aws_iam_policy" "acmpolicy" {
  count = var.enable_acm ? 1 : 0

  name_prefix = format("%s-%s", local.acm_name, "controller-acm-policies")

  path        = "/"
  description = "ACK ACM contoller policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "acm:DescribeCertificate",
          "acm:RequestCertificate",
          "acm:UpdateCertificateOptions",
          "acm:DeleteCertificate",
          "acm:AddTagsToCertificate",
          "acm:RemoveTagsFromCertificate",
          "acm:ListTagsForCertificate"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

################################################################################
# API Gateway V2
################################################################################

locals {
  apigatewayv2_name = "ack-apigatewayv2"
}

module "apigatewayv2" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_apigatewayv2

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/apigatewayv2-chart:1.0.14
  name             = try(var.apigatewayv2.name, local.apigatewayv2_name)
  description      = try(var.apigatewayv2.description, "Helm Chart for apigatewayv2 controller for ACK")
  namespace        = try(var.apigatewayv2.namespace, "ack-system")
  create_namespace = try(var.apigatewayv2.create_namespace, true)
  chart            = "apigatewayv2-chart"
  chart_version    = try(var.apigatewayv2.chart_version, "1.0.14")
  repository       = try(var.apigatewayv2.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.apigatewayv2.values, [])

  timeout                    = try(var.apigatewayv2.timeout, null)
  repository_key_file        = try(var.apigatewayv2.repository_key_file, null)
  repository_cert_file       = try(var.apigatewayv2.repository_cert_file, null)
  repository_ca_file         = try(var.apigatewayv2.repository_ca_file, null)
  repository_username        = try(var.apigatewayv2.repository_username, local.repository_username)
  repository_password        = try(var.apigatewayv2.repository_password, local.repository_password)
  devel                      = try(var.apigatewayv2.devel, null)
  verify                     = try(var.apigatewayv2.verify, null)
  keyring                    = try(var.apigatewayv2.keyring, null)
  disable_webhooks           = try(var.apigatewayv2.disable_webhooks, null)
  reuse_values               = try(var.apigatewayv2.reuse_values, null)
  reset_values               = try(var.apigatewayv2.reset_values, null)
  force_update               = try(var.apigatewayv2.force_update, null)
  recreate_pods              = try(var.apigatewayv2.recreate_pods, null)
  cleanup_on_fail            = try(var.apigatewayv2.cleanup_on_fail, null)
  max_history                = try(var.apigatewayv2.max_history, null)
  atomic                     = try(var.apigatewayv2.atomic, null)
  skip_crds                  = try(var.apigatewayv2.skip_crds, null)
  render_subchart_notes      = try(var.apigatewayv2.render_subchart_notes, null)
  disable_openapi_validation = try(var.apigatewayv2.disable_openapi_validation, null)
  wait                       = try(var.apigatewayv2.wait, false)
  wait_for_jobs              = try(var.apigatewayv2.wait_for_jobs, null)
  dependency_update          = try(var.apigatewayv2.dependency_update, null)
  replace                    = try(var.apigatewayv2.replace, null)
  lint                       = try(var.apigatewayv2.lint, null)

  postrender = try(var.apigatewayv2.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-apigatewayv2-apigatewayv2-chart-xxxxxxxxxxxxx` to `ack-apigatewayv2-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-apigatewayv2"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.apigatewayv2_name
    }],
    try(var.apigatewayv2.set, [])
  )
  set_sensitive = try(var.apigatewayv2.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.apigatewayv2.create_role, true)
  role_name                     = try(var.apigatewayv2.role_name, "ack-apigatewayv2")
  role_name_use_prefix          = try(var.apigatewayv2.role_name_use_prefix, true)
  role_path                     = try(var.apigatewayv2.role_path, "/")
  role_permissions_boundary_arn = lookup(var.apigatewayv2, "role_permissions_boundary_arn", null)
  role_description              = try(var.apigatewayv2.role_description, "IRSA for apigatewayv2 controller for ACK")
  role_policies = lookup(var.apigatewayv2, "role_policies", {
    AmazonAPIGatewayInvokeFullAccess = "${local.iam_role_policy_prefix}/AmazonAPIGatewayInvokeFullAccess"
    AmazonAPIGatewayAdministrator    = "${local.iam_role_policy_prefix}/AmazonAPIGatewayAdministrator"
  })
  create_policy = try(var.apigatewayv2.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.apigatewayv2_name
    }
  }

  tags = var.tags
}

################################################################################
# DynamoDB
################################################################################

locals {
  dynamodb_name = "ack-dynamodb"
}

module "dynamodb" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_dynamodb

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/dynamodb-chart:1.2.12
  name             = try(var.dynamodb.name, local.dynamodb_name)
  description      = try(var.dynamodb.description, "Helm Chart for dynamodb controller for ACK")
  namespace        = try(var.dynamodb.namespace, "ack-system")
  create_namespace = try(var.dynamodb.create_namespace, true)
  chart            = "dynamodb-chart"
  chart_version    = try(var.dynamodb.chart_version, "1.2.12")
  repository       = try(var.dynamodb.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.dynamodb.values, [])

  timeout                    = try(var.dynamodb.timeout, null)
  repository_key_file        = try(var.dynamodb.repository_key_file, null)
  repository_cert_file       = try(var.dynamodb.repository_cert_file, null)
  repository_ca_file         = try(var.dynamodb.repository_ca_file, null)
  repository_username        = try(var.apigatewayv2.repository_username, local.repository_username)
  repository_password        = try(var.apigatewayv2.repository_password, local.repository_password)
  devel                      = try(var.dynamodb.devel, null)
  verify                     = try(var.dynamodb.verify, null)
  keyring                    = try(var.dynamodb.keyring, null)
  disable_webhooks           = try(var.dynamodb.disable_webhooks, null)
  reuse_values               = try(var.dynamodb.reuse_values, null)
  reset_values               = try(var.dynamodb.reset_values, null)
  force_update               = try(var.dynamodb.force_update, null)
  recreate_pods              = try(var.dynamodb.recreate_pods, null)
  cleanup_on_fail            = try(var.dynamodb.cleanup_on_fail, null)
  max_history                = try(var.dynamodb.max_history, null)
  atomic                     = try(var.dynamodb.atomic, null)
  skip_crds                  = try(var.dynamodb.skip_crds, null)
  render_subchart_notes      = try(var.dynamodb.render_subchart_notes, null)
  disable_openapi_validation = try(var.dynamodb.disable_openapi_validation, null)
  wait                       = try(var.dynamodb.wait, false)
  wait_for_jobs              = try(var.dynamodb.wait_for_jobs, null)
  dependency_update          = try(var.dynamodb.dependency_update, null)
  replace                    = try(var.dynamodb.replace, null)
  lint                       = try(var.dynamodb.lint, null)

  postrender = try(var.dynamodb.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-dynamodb-dynamodb-chart-xxxxxxxxxxxxx` to `ack-dynamodb-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-dynamodb"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.dynamodb_name
    }],
    try(var.dynamodb.set, [])
  )
  set_sensitive = try(var.dynamodb.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.dynamodb.create_role, true)
  role_name                     = try(var.dynamodb.role_name, "ack-dynamodb")
  role_name_use_prefix          = try(var.dynamodb.role_name_use_prefix, true)
  role_path                     = try(var.dynamodb.role_path, "/")
  role_permissions_boundary_arn = lookup(var.dynamodb, "role_permissions_boundary_arn", null)
  role_description              = try(var.dynamodb.role_description, "IRSA for dynamodb controller for ACK")
  role_policies = lookup(var.dynamodb, "role_policies", {
    AmazonDynamoDBFullAccess = "${local.iam_role_policy_prefix}/AmazonDynamoDBFullAccess"
  })
  create_policy = try(var.dynamodb.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.dynamodb_name
    }
  }

  tags = var.tags
}

################################################################################
# S3
################################################################################

locals {
  s3_name = "ack-s3"
}

module "s3" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_s3

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/s3-chart:1.0.13
  name             = try(var.s3.name, local.s3_name)
  description      = try(var.s3.description, "Helm Chart for s3 controller for ACK")
  namespace        = try(var.s3.namespace, "ack-system")
  create_namespace = try(var.s3.create_namespace, true)
  chart            = "s3-chart"
  chart_version    = try(var.s3.chart_version, "1.0.13")
  repository       = try(var.s3.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.s3.values, [])

  timeout                    = try(var.s3.timeout, null)
  repository_key_file        = try(var.s3.repository_key_file, null)
  repository_cert_file       = try(var.s3.repository_cert_file, null)
  repository_ca_file         = try(var.s3.repository_ca_file, null)
  repository_username        = try(var.apigatewayv2.repository_username, local.repository_username)
  repository_password        = try(var.apigatewayv2.repository_password, local.repository_password)
  devel                      = try(var.s3.devel, null)
  verify                     = try(var.s3.verify, null)
  keyring                    = try(var.s3.keyring, null)
  disable_webhooks           = try(var.s3.disable_webhooks, null)
  reuse_values               = try(var.s3.reuse_values, null)
  reset_values               = try(var.s3.reset_values, null)
  force_update               = try(var.s3.force_update, null)
  recreate_pods              = try(var.s3.recreate_pods, null)
  cleanup_on_fail            = try(var.s3.cleanup_on_fail, null)
  max_history                = try(var.s3.max_history, null)
  atomic                     = try(var.s3.atomic, null)
  skip_crds                  = try(var.s3.skip_crds, null)
  render_subchart_notes      = try(var.s3.render_subchart_notes, null)
  disable_openapi_validation = try(var.s3.disable_openapi_validation, null)
  wait                       = try(var.s3.wait, false)
  wait_for_jobs              = try(var.s3.wait_for_jobs, null)
  dependency_update          = try(var.s3.dependency_update, null)
  replace                    = try(var.s3.replace, null)
  lint                       = try(var.s3.lint, null)

  postrender = try(var.s3.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-s3-s3-chart-xxxxxxxxxxxxx` to `ack-s3-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-s3"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.s3_name
    }],
    try(var.s3.set, [])
  )
  set_sensitive = try(var.s3.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.s3.create_role, true)
  role_name                     = try(var.s3.role_name, "ack-s3")
  role_name_use_prefix          = try(var.s3.role_name_use_prefix, true)
  role_path                     = try(var.s3.role_path, "/")
  role_permissions_boundary_arn = lookup(var.s3, "role_permissions_boundary_arn", null)
  role_description              = try(var.s3.role_description, "IRSA for s3 controller for ACK")
  role_policies = lookup(var.s3, "role_policies", {
    AmazonS3FullAccess = "${local.iam_role_policy_prefix}/AmazonS3FullAccess"
  })
  create_policy = try(var.s3.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.s3_name
    }
  }

  tags = var.tags
}

################################################################################
# elasticache
################################################################################

locals {
  elasticache_name = "ack-elasticache"
}

module "elasticache" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_elasticache

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/elasticache-chart:0.1.0
  name             = try(var.elasticache.name, local.elasticache_name)
  description      = try(var.elasticache.description, "Helm Chart for elasticache controller for ACK")
  namespace        = try(var.elasticache.namespace, "ack-system")
  create_namespace = try(var.elasticache.create_namespace, true)
  chart            = "elasticache-chart"
  chart_version    = try(var.elasticache.chart_version, "0.1.0")
  repository       = try(var.elasticache.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.elasticache.values, [])

  timeout                    = try(var.elasticache.timeout, null)
  repository_key_file        = try(var.elasticache.repository_key_file, null)
  repository_cert_file       = try(var.elasticache.repository_cert_file, null)
  repository_ca_file         = try(var.elasticache.repository_ca_file, null)
  repository_username        = try(var.apigatewayv2.repository_username, local.repository_username)
  repository_password        = try(var.apigatewayv2.repository_password, local.repository_password)
  devel                      = try(var.elasticache.devel, null)
  verify                     = try(var.elasticache.verify, null)
  keyring                    = try(var.elasticache.keyring, null)
  disable_webhooks           = try(var.elasticache.disable_webhooks, null)
  reuse_values               = try(var.elasticache.reuse_values, null)
  reset_values               = try(var.elasticache.reset_values, null)
  force_update               = try(var.elasticache.force_update, null)
  recreate_pods              = try(var.elasticache.recreate_pods, null)
  cleanup_on_fail            = try(var.elasticache.cleanup_on_fail, null)
  max_history                = try(var.elasticache.max_history, null)
  atomic                     = try(var.elasticache.atomic, null)
  skip_crds                  = try(var.elasticache.skip_crds, null)
  render_subchart_notes      = try(var.elasticache.render_subchart_notes, null)
  disable_openapi_validation = try(var.elasticache.disable_openapi_validation, null)
  wait                       = try(var.elasticache.wait, false)
  wait_for_jobs              = try(var.elasticache.wait_for_jobs, null)
  dependency_update          = try(var.elasticache.dependency_update, null)
  replace                    = try(var.elasticache.replace, null)
  lint                       = try(var.elasticache.lint, null)

  postrender = try(var.elasticache.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-elasticache-elasticache-chart-xxxxxxxxxxxxx` to `ack-elasticache-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-elasticache"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.elasticache_name
    }],
    try(var.elasticache.set, [])
  )
  set_sensitive = try(var.elasticache.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.elasticache.create_role, true)
  role_name                     = try(var.elasticache.role_name, "ack-elasticache")
  role_name_use_prefix          = try(var.elasticache.role_name_use_prefix, true)
  role_path                     = try(var.elasticache.role_path, "/")
  role_permissions_boundary_arn = lookup(var.elasticache, "role_permissions_boundary_arn", null)
  role_description              = try(var.elasticache.role_description, "IRSA for elasticache controller for ACK")
  role_policies = lookup(var.elasticache, "role_policies", {
    AmazonElastiCacheFullAccess = "${local.iam_role_policy_prefix}/AmazonElastiCacheFullAccess"
  })
  create_policy = try(var.elasticache.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.elasticache_name
    }
  }

  tags = var.tags
}

################################################################################
# RDS
################################################################################

locals {
  rds_name = "ack-rds"
}

module "rds" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_rds

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/rds-chart:1.4.2
  name             = try(var.rds.name, local.rds_name)
  description      = try(var.rds.description, "Helm Chart for rds controller for ACK")
  namespace        = try(var.rds.namespace, "ack-system")
  create_namespace = try(var.rds.create_namespace, true)
  chart            = "rds-chart"
  chart_version    = try(var.rds.chart_version, "1.4.2")
  repository       = try(var.rds.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.rds.values, [])

  timeout                    = try(var.rds.timeout, null)
  repository_key_file        = try(var.rds.repository_key_file, null)
  repository_cert_file       = try(var.rds.repository_cert_file, null)
  repository_ca_file         = try(var.rds.repository_ca_file, null)
  repository_username        = try(var.apigatewayv2.repository_username, local.repository_username)
  repository_password        = try(var.apigatewayv2.repository_password, local.repository_password)
  devel                      = try(var.rds.devel, null)
  verify                     = try(var.rds.verify, null)
  keyring                    = try(var.rds.keyring, null)
  disable_webhooks           = try(var.rds.disable_webhooks, null)
  reuse_values               = try(var.rds.reuse_values, null)
  reset_values               = try(var.rds.reset_values, null)
  force_update               = try(var.rds.force_update, null)
  recreate_pods              = try(var.rds.recreate_pods, null)
  cleanup_on_fail            = try(var.rds.cleanup_on_fail, null)
  max_history                = try(var.rds.max_history, null)
  atomic                     = try(var.rds.atomic, null)
  skip_crds                  = try(var.rds.skip_crds, null)
  render_subchart_notes      = try(var.rds.render_subchart_notes, null)
  disable_openapi_validation = try(var.rds.disable_openapi_validation, null)
  wait                       = try(var.rds.wait, false)
  wait_for_jobs              = try(var.rds.wait_for_jobs, null)
  dependency_update          = try(var.rds.dependency_update, null)
  replace                    = try(var.rds.replace, null)
  lint                       = try(var.rds.lint, null)

  postrender = try(var.rds.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-rds-rds-chart-xxxxxxxxxxxxx` to `ack-rds-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-rds"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.rds_name
    }],
    try(var.rds.set, [])
  )
  set_sensitive = try(var.rds.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.rds.create_role, true)
  role_name                     = try(var.rds.role_name, "ack-rds")
  role_name_use_prefix          = try(var.rds.role_name_use_prefix, true)
  role_path                     = try(var.rds.role_path, "/")
  role_permissions_boundary_arn = lookup(var.rds, "role_permissions_boundary_arn", null)
  role_description              = try(var.rds.role_description, "IRSA for rds controller for ACK")
  role_policies = lookup(var.rds, "role_policies", {
    AmazonRDSFullAccess = "${local.iam_role_policy_prefix}/AmazonRDSFullAccess"
  })
  create_policy = try(var.rds.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.rds_name
    }
  }

  tags = var.tags
}

################################################################################
# Amazon Managed Service for Prometheus
################################################################################

locals {
  prometheusservice_name = "ack-prometheusservice"
}

module "prometheusservice" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_prometheusservice

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/prometheusservice_name-chart:1.2.12
  name             = try(var.prometheusservice.name, local.prometheusservice_name)
  description      = try(var.prometheusservice.description, "Helm Chart for prometheusservice controller for ACK")
  namespace        = try(var.prometheusservice.namespace, "ack-system")
  create_namespace = try(var.prometheusservice.create_namespace, true)
  chart            = "prometheusservice-chart"
  chart_version    = try(var.prometheusservice.chart_version, "1.2.12")
  repository       = try(var.prometheusservice.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.prometheusservice.values, [])

  timeout                    = try(var.prometheusservice.timeout, null)
  repository_key_file        = try(var.prometheusservice.repository_key_file, null)
  repository_cert_file       = try(var.prometheusservice.repository_cert_file, null)
  repository_ca_file         = try(var.prometheusservice.repository_ca_file, null)
  repository_username        = try(var.prometheusservice.repository_username, local.repository_username)
  repository_password        = try(var.prometheusservice.repository_password, local.repository_password)
  devel                      = try(var.prometheusservice.devel, null)
  verify                     = try(var.prometheusservice.verify, null)
  keyring                    = try(var.prometheusservice.keyring, null)
  disable_webhooks           = try(var.prometheusservice.disable_webhooks, null)
  reuse_values               = try(var.prometheusservice.reuse_values, null)
  reset_values               = try(var.prometheusservice.reset_values, null)
  force_update               = try(var.prometheusservice.force_update, null)
  recreate_pods              = try(var.prometheusservice.recreate_pods, null)
  cleanup_on_fail            = try(var.prometheusservice.cleanup_on_fail, null)
  max_history                = try(var.prometheusservice.max_history, null)
  atomic                     = try(var.prometheusservice.atomic, null)
  skip_crds                  = try(var.prometheusservice.skip_crds, null)
  render_subchart_notes      = try(var.prometheusservice.render_subchart_notes, null)
  disable_openapi_validation = try(var.prometheusservice.disable_openapi_validation, null)
  wait                       = try(var.prometheusservice.wait, false)
  wait_for_jobs              = try(var.prometheusservice.wait_for_jobs, null)
  dependency_update          = try(var.prometheusservice.dependency_update, null)
  replace                    = try(var.prometheusservice.replace, null)
  lint                       = try(var.prometheusservice.lint, null)

  postrender = try(var.prometheusservice.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-prometheusservice-prometheusservice-chart-xxxxxxxxxxxxx` to `ack-prometheusservice-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-prometheusservice"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.prometheusservice_name
    }],
    try(var.prometheusservice.set, [])
  )
  set_sensitive = try(var.prometheusservice.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.prometheusservice.create_role, true)
  role_name                     = try(var.prometheusservice.role_name, "ack-prometheusservice")
  role_name_use_prefix          = try(var.prometheusservice.role_name_use_prefix, true)
  role_path                     = try(var.prometheusservice.role_path, "/")
  role_permissions_boundary_arn = lookup(var.prometheusservice, "role_permissions_boundary_arn", null)
  role_description              = try(var.prometheusservice.role_description, "IRSA for prometheusservice controller for ACK")
  role_policies = lookup(var.prometheusservice, "role_policies", {
    AmazonPrometheusFullAccess = "${local.iam_role_policy_prefix}/AmazonPrometheusFullAccess"
  })
  create_policy = try(var.prometheusservice.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.prometheusservice_name
    }
  }

  tags = var.tags
}

################################################################################
# EMR Containers
################################################################################

locals {
  emrcontainers_name = "ack-emrcontainers"
}

module "emrcontainers" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_emrcontainers

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/emrcontainers_name-chart:1.0.11
  name             = try(var.emrcontainers.name, local.emrcontainers_name)
  description      = try(var.emrcontainers.description, "Helm Chart for emrcontainers controller for ACK")
  namespace        = try(var.emrcontainers.namespace, "ack-system")
  create_namespace = try(var.emrcontainers.create_namespace, true)
  chart            = "emrcontainers-chart"
  chart_version    = try(var.emrcontainers.chart_version, "1.0.11")
  repository       = try(var.emrcontainers.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.emrcontainers.values, [])

  timeout                    = try(var.emrcontainers.timeout, null)
  repository_key_file        = try(var.emrcontainers.repository_key_file, null)
  repository_cert_file       = try(var.emrcontainers.repository_cert_file, null)
  repository_ca_file         = try(var.emrcontainers.repository_ca_file, null)
  repository_username        = try(var.emrcontainers.repository_username, local.repository_username)
  repository_password        = try(var.emrcontainers.repository_password, local.repository_password)
  devel                      = try(var.emrcontainers.devel, null)
  verify                     = try(var.emrcontainers.verify, null)
  keyring                    = try(var.emrcontainers.keyring, null)
  disable_webhooks           = try(var.emrcontainers.disable_webhooks, null)
  reuse_values               = try(var.emrcontainers.reuse_values, null)
  reset_values               = try(var.emrcontainers.reset_values, null)
  force_update               = try(var.emrcontainers.force_update, null)
  recreate_pods              = try(var.emrcontainers.recreate_pods, null)
  cleanup_on_fail            = try(var.emrcontainers.cleanup_on_fail, null)
  max_history                = try(var.emrcontainers.max_history, null)
  atomic                     = try(var.emrcontainers.atomic, null)
  skip_crds                  = try(var.emrcontainers.skip_crds, null)
  render_subchart_notes      = try(var.emrcontainers.render_subchart_notes, null)
  disable_openapi_validation = try(var.emrcontainers.disable_openapi_validation, null)
  wait                       = try(var.emrcontainers.wait, false)
  wait_for_jobs              = try(var.emrcontainers.wait_for_jobs, null)
  dependency_update          = try(var.emrcontainers.dependency_update, null)
  replace                    = try(var.emrcontainers.replace, null)
  lint                       = try(var.emrcontainers.lint, null)

  postrender = try(var.emrcontainers.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-emrcontainers-emrcontainers-chart-xxxxxxxxxxxxx` to `ack-emrcontainers-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-emrcontainers"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.emrcontainers_name
    }],
    try(var.emrcontainers.set, [])
  )
  set_sensitive = try(var.emrcontainers.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.emrcontainers.create_role, true)
  role_name                     = try(var.emrcontainers.role_name, "ack-emrcontainers")
  role_name_use_prefix          = try(var.emrcontainers.role_name_use_prefix, true)
  role_path                     = try(var.emrcontainers.role_path, "/")
  role_permissions_boundary_arn = lookup(var.emrcontainers, "role_permissions_boundary_arn", null)
  role_description              = try(var.emrcontainers.role_description, "IRSA for emrcontainers controller for ACK")
  role_policies = lookup(var.emrcontainers, "role_policies", {
    AmazonEmrContainers = var.enable_emrcontainers ? aws_iam_policy.emrcontainers[0].arn : null
  })
  create_policy = try(var.emrcontainers.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.emrcontainers_name
    }
  }

  tags = var.tags
}

resource "aws_iam_policy" "emrcontainers" {
  count = var.enable_emrcontainers ? 1 : 0

  name_prefix = format("%s-%s", local.emrcontainers_name, "controller-iam-policies")
  description = "IAM policy for EMRcontainers controller"
  path        = "/"
  policy      = data.aws_iam_policy_document.emrcontainers.json

  tags = var.tags
}

# inline policy provided by ack https://raw.githubusercontent.com/aws-controllers-k8s/emrcontainers-controller/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "emrcontainers" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values   = ["emr-containers.amazonaws.com"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "emr-containers:CreateVirtualCluster",
      "emr-containers:ListVirtualClusters",
      "emr-containers:DescribeVirtualCluster",
      "emr-containers:DeleteVirtualCluster"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "emr-containers:StartJobRun",
      "emr-containers:ListJobRuns",
      "emr-containers:DescribeJobRun",
      "emr-containers:CancelJobRun"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "emr-containers:DescribeJobRun",
      "emr-containers:TagResource",
      "elasticmapreduce:CreatePersistentAppUI",
      "elasticmapreduce:DescribePersistentAppUI",
      "elasticmapreduce:GetPersistentAppUIPresignedURL"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:Get*",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }

}

################################################################################
# Step Functions
################################################################################

locals {
  sfn_name = "ack-sfn"
}

module "sfn" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_sfn

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/sfn_name-chart:1.0.12
  name             = try(var.sfn.name, local.sfn_name)
  description      = try(var.sfn.description, "Helm Chart for sfn controller for ACK")
  namespace        = try(var.sfn.namespace, "ack-system")
  create_namespace = try(var.sfn.create_namespace, true)
  chart            = "sfn-chart"
  chart_version    = try(var.sfn.chart_version, "1.0.12")
  repository       = try(var.sfn.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.sfn.values, [])

  timeout                    = try(var.sfn.timeout, null)
  repository_key_file        = try(var.sfn.repository_key_file, null)
  repository_cert_file       = try(var.sfn.repository_cert_file, null)
  repository_ca_file         = try(var.sfn.repository_ca_file, null)
  repository_username        = try(var.sfn.repository_username, local.repository_username)
  repository_password        = try(var.sfn.repository_password, local.repository_password)
  devel                      = try(var.sfn.devel, null)
  verify                     = try(var.sfn.verify, null)
  keyring                    = try(var.sfn.keyring, null)
  disable_webhooks           = try(var.sfn.disable_webhooks, null)
  reuse_values               = try(var.sfn.reuse_values, null)
  reset_values               = try(var.sfn.reset_values, null)
  force_update               = try(var.sfn.force_update, null)
  recreate_pods              = try(var.sfn.recreate_pods, null)
  cleanup_on_fail            = try(var.sfn.cleanup_on_fail, null)
  max_history                = try(var.sfn.max_history, null)
  atomic                     = try(var.sfn.atomic, null)
  skip_crds                  = try(var.sfn.skip_crds, null)
  render_subchart_notes      = try(var.sfn.render_subchart_notes, null)
  disable_openapi_validation = try(var.sfn.disable_openapi_validation, null)
  wait                       = try(var.sfn.wait, false)
  wait_for_jobs              = try(var.sfn.wait_for_jobs, null)
  dependency_update          = try(var.sfn.dependency_update, null)
  replace                    = try(var.sfn.replace, null)
  lint                       = try(var.sfn.lint, null)

  postrender = try(var.sfn.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-sfn-sfn-chart-xxxxxxxxxxxxx` to `ack-sfn-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-sfn"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.sfn_name
    }],
    try(var.sfn.set, [])
  )
  set_sensitive = try(var.sfn.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.sfn.create_role, true)
  role_name                     = try(var.sfn.role_name, "ack-sfn")
  role_name_use_prefix          = try(var.sfn.role_name_use_prefix, true)
  role_path                     = try(var.sfn.role_path, "/")
  role_permissions_boundary_arn = lookup(var.sfn, "role_permissions_boundary_arn", null)
  role_description              = try(var.sfn.role_description, "IRSA for sfn controller for ACK")
  role_policies = lookup(var.sfn, "role_policies", {
    AWSStepFunctionsFullAccess  = "${local.iam_role_policy_prefix}/AWSStepFunctionsFullAccess"
    AWSStepFunctionsIamPassRole = var.enable_sfn ? aws_iam_policy.sfnpasspolicy[0].arn : null
  })
  create_policy = try(var.sfn.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.sfn_name
    }
  }

  tags = var.tags
}

resource "aws_iam_policy" "sfnpasspolicy" {
  count = var.enable_sfn ? 1 : 0

  name_prefix = format("%s-%s", local.sfn_name, "controller-iam-policies")

  path        = "/"
  description = "passrole policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = var.tags
}

################################################################################
# EventBridge
################################################################################

locals {
  eventbridge_name = "ack-eventbridge"
}

module "eventbridge" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_eventbridge

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/eventbridge_name-chart:1.0.12
  name             = try(var.eventbridge.name, local.eventbridge_name)
  description      = try(var.eventbridge.description, "Helm Chart for eventbridge controller for ACK")
  namespace        = try(var.eventbridge.namespace, "ack-system")
  create_namespace = try(var.eventbridge.create_namespace, true)
  chart            = "eventbridge-chart"
  chart_version    = try(var.eventbridge.chart_version, "1.0.12")
  repository       = try(var.eventbridge.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.eventbridge.values, [])

  timeout                    = try(var.eventbridge.timeout, null)
  repository_key_file        = try(var.eventbridge.repository_key_file, null)
  repository_cert_file       = try(var.eventbridge.repository_cert_file, null)
  repository_ca_file         = try(var.eventbridge.repository_ca_file, null)
  repository_username        = try(var.eventbridge.repository_username, local.repository_username)
  repository_password        = try(var.eventbridge.repository_password, local.repository_password)
  devel                      = try(var.eventbridge.devel, null)
  verify                     = try(var.eventbridge.verify, null)
  keyring                    = try(var.eventbridge.keyring, null)
  disable_webhooks           = try(var.eventbridge.disable_webhooks, null)
  reuse_values               = try(var.eventbridge.reuse_values, null)
  reset_values               = try(var.eventbridge.reset_values, null)
  force_update               = try(var.eventbridge.force_update, null)
  recreate_pods              = try(var.eventbridge.recreate_pods, null)
  cleanup_on_fail            = try(var.eventbridge.cleanup_on_fail, null)
  max_history                = try(var.eventbridge.max_history, null)
  atomic                     = try(var.eventbridge.atomic, null)
  skip_crds                  = try(var.eventbridge.skip_crds, null)
  render_subchart_notes      = try(var.eventbridge.render_subchart_notes, null)
  disable_openapi_validation = try(var.eventbridge.disable_openapi_validation, null)
  wait                       = try(var.eventbridge.wait, false)
  wait_for_jobs              = try(var.eventbridge.wait_for_jobs, null)
  dependency_update          = try(var.eventbridge.dependency_update, null)
  replace                    = try(var.eventbridge.replace, null)
  lint                       = try(var.eventbridge.lint, null)

  postrender = try(var.eventbridge.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-eventbridge-eventbridge-chart-xxxxxxxxxxxxx` to `ack-eventbridge-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-eventbridge"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.eventbridge_name
    }],
    try(var.eventbridge.set, [])
  )
  set_sensitive = try(var.eventbridge.set_sensitive, [])


  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.eventbridge.create_role, true)
  role_name                     = try(var.eventbridge.role_name, "ack-eventbridge")
  role_name_use_prefix          = try(var.eventbridge.role_name_use_prefix, true)
  role_path                     = try(var.eventbridge.role_path, "/")
  role_permissions_boundary_arn = lookup(var.eventbridge, "role_permissions_boundary_arn", null)
  role_description              = try(var.eventbridge.role_description, "IRSA for eventbridge controller for ACK")
  role_policies = lookup(var.eventbridge, "role_policies", {
    AmazonEventBridgeFullAccess = "${local.iam_role_policy_prefix}/AmazonEventBridgeFullAccess"
  })
  create_policy = try(var.eventbridge.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.eventbridge_name
    }
  }

  tags = var.tags
}
