data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

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
# Network Firewall
################################################################################

locals {
  networkfirewall_name = "ack-networkfirewall"
}

module "networkfirewall" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_networkfirewall

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/networkfirewall-chart:0.0.8
  name             = try(var.networkfirewall.name, local.networkfirewall_name)
  description      = try(var.networkfirewall.description, "Helm Chart for Network Firewall controller for ACK")
  namespace        = try(var.networkfirewall.namespace, "ack-system")
  create_namespace = try(var.networkfirewall.create_namespace, true)
  chart            = "networkfirewall-chart"
  chart_version    = try(var.networkfirewall.chart_version, "0.0.8")
  repository       = try(var.networkfirewall.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.networkfirewall.values, [])

  timeout                    = try(var.networkfirewall.timeout, null)
  repository_key_file        = try(var.networkfirewall.repository_key_file, null)
  repository_cert_file       = try(var.networkfirewall.repository_cert_file, null)
  repository_ca_file         = try(var.networkfirewall.repository_ca_file, null)
  repository_username        = try(var.networkfirewall.repository_username, local.repository_username)
  repository_password        = try(var.networkfirewall.repository_password, local.repository_password)
  devel                      = try(var.networkfirewall.devel, null)
  verify                     = try(var.networkfirewall.verify, null)
  keyring                    = try(var.networkfirewall.keyring, null)
  disable_webhooks           = try(var.networkfirewall.disable_webhooks, null)
  reuse_values               = try(var.networkfirewall.reuse_values, null)
  reset_values               = try(var.networkfirewall.reset_values, null)
  force_update               = try(var.networkfirewall.force_update, null)
  recreate_pods              = try(var.networkfirewall.recreate_pods, null)
  cleanup_on_fail            = try(var.networkfirewall.cleanup_on_fail, null)
  max_history                = try(var.networkfirewall.max_history, null)
  atomic                     = try(var.networkfirewall.atomic, null)
  skip_crds                  = try(var.networkfirewall.skip_crds, null)
  render_subchart_notes      = try(var.networkfirewall.render_subchart_notes, null)
  disable_openapi_validation = try(var.networkfirewall.disable_openapi_validation, null)
  wait                       = try(var.networkfirewall.wait, false)
  wait_for_jobs              = try(var.networkfirewall.wait_for_jobs, null)
  dependency_update          = try(var.networkfirewall.dependency_update, null)
  replace                    = try(var.networkfirewall.replace, null)
  lint                       = try(var.networkfirewall.lint, null)

  postrender = try(var.networkfirewall.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-networkfirewall-networkfirewall-chart-xxxxxxxxxxxxx` to `ack-networkfirewall-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-networkfirewall"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.networkfirewall_name
    }],
    try(var.networkfirewall.set, [])
  )
  set_sensitive = try(var.networkfirewall.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.networkfirewall.create_role, true)
  role_name                     = try(var.networkfirewall.role_name, "ack-networkfirewall")
  role_name_use_prefix          = try(var.networkfirewall.role_name_use_prefix, true)
  role_path                     = try(var.networkfirewall.role_path, "/")
  role_permissions_boundary_arn = lookup(var.networkfirewall, "role_permissions_boundary_arn", null)
  role_description              = try(var.networkfirewall.role_description, "IRSA for Network Firewall controller for ACK")
  role_policies                 = lookup(var.networkfirewall, "role_policies", {})

  create_policy           = try(var.networkfirewall.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.networkfirewall[*].json
  policy_statements       = lookup(var.networkfirewall, "policy_statements", [])
  policy_name             = try(var.networkfirewall.policy_name, null)
  policy_name_use_prefix  = try(var.networkfirewall.policy_name_use_prefix, true)
  policy_path             = try(var.networkfirewall.policy_path, null)
  policy_description      = try(var.networkfirewall.policy_description, "IAM Policy for Network Firewall controller for ACK")

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.networkfirewall_name
    }
  }

  tags = var.tags
}

# recommended networkfirewall-controller policy https://github.com/aws-controllers-k8s/networkfirewall-controller/blob/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "networkfirewall" {
  count = var.enable_networkfirewall ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "network-firewall:CreateFirewall",
      "network-firewall:CreateFirewallPolicy",
      "network-firewall:DeleteFirewall",
      "network-firewall:DeleteFirewallPolicy",
      "network-firewall:DescribeFirewall",
      "network-firewall:DescribeLoggingConfiguration",
      "network-firewall:ListFirewallPolicies",
      "network-firewall:ListFirewalls",
      "network-firewall:UpdateLoggingConfiguration",
    ]

    resources = ["*"]
  }
}

################################################################################
# Amazon CloudWatch Logs
################################################################################

locals {
  cloudwatchlogs_name = "ack-cloudwatchlogs"
}

module "cloudwatchlogs" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_cloudwatchlogs

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/cloudwatchlogs-chart:0.0.9
  name             = try(var.cloudwatchlogs.name, local.cloudwatchlogs_name)
  description      = try(var.cloudwatchlogs.description, "Helm Chart for CloudWatch Logs controller for ACK")
  namespace        = try(var.cloudwatchlogs.namespace, "ack-system")
  create_namespace = try(var.cloudwatchlogs.create_namespace, true)
  chart            = "cloudwatchlogs-chart"
  chart_version    = try(var.cloudwatchlogs.chart_version, "0.0.9")
  repository       = try(var.cloudwatchlogs.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.cloudwatchlogs.values, [])

  timeout                    = try(var.cloudwatchlogs.timeout, null)
  repository_key_file        = try(var.cloudwatchlogs.repository_key_file, null)
  repository_cert_file       = try(var.cloudwatchlogs.repository_cert_file, null)
  repository_ca_file         = try(var.cloudwatchlogs.repository_ca_file, null)
  repository_username        = try(var.cloudwatchlogs.repository_username, local.repository_username)
  repository_password        = try(var.cloudwatchlogs.repository_password, local.repository_password)
  devel                      = try(var.cloudwatchlogs.devel, null)
  verify                     = try(var.cloudwatchlogs.verify, null)
  keyring                    = try(var.cloudwatchlogs.keyring, null)
  disable_webhooks           = try(var.cloudwatchlogs.disable_webhooks, null)
  reuse_values               = try(var.cloudwatchlogs.reuse_values, null)
  reset_values               = try(var.cloudwatchlogs.reset_values, null)
  force_update               = try(var.cloudwatchlogs.force_update, null)
  recreate_pods              = try(var.cloudwatchlogs.recreate_pods, null)
  cleanup_on_fail            = try(var.cloudwatchlogs.cleanup_on_fail, null)
  max_history                = try(var.cloudwatchlogs.max_history, null)
  atomic                     = try(var.cloudwatchlogs.atomic, null)
  skip_crds                  = try(var.cloudwatchlogs.skip_crds, null)
  render_subchart_notes      = try(var.cloudwatchlogs.render_subchart_notes, null)
  disable_openapi_validation = try(var.cloudwatchlogs.disable_openapi_validation, null)
  wait                       = try(var.cloudwatchlogs.wait, false)
  wait_for_jobs              = try(var.cloudwatchlogs.wait_for_jobs, null)
  dependency_update          = try(var.cloudwatchlogs.dependency_update, null)
  replace                    = try(var.cloudwatchlogs.replace, null)
  lint                       = try(var.cloudwatchlogs.lint, null)

  postrender = try(var.cloudwatchlogs.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-cloudwatchlogs-cloudwatchlogs-chart-xxxxxxxxxxxxx` to `ack-cloudwatchlogs-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-cloudwatchlogs"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.cloudwatchlogs_name
    }],
    try(var.cloudwatchlogs.set, [])
  )
  set_sensitive = try(var.cloudwatchlogs.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.cloudwatchlogs.create_role, true)
  role_name                     = try(var.cloudwatchlogs.role_name, "ack-cloudwatchlogs")
  role_name_use_prefix          = try(var.cloudwatchlogs.role_name_use_prefix, true)
  role_path                     = try(var.cloudwatchlogs.role_path, "/")
  role_permissions_boundary_arn = lookup(var.cloudwatchlogs, "role_permissions_boundary_arn", null)
  role_description              = try(var.cloudwatchlogs.role_description, "IRSA for CloudWatch Logs controller for ACK")
  role_policies                 = lookup(var.cloudwatchlogs, "role_policies", {})

  create_policy           = try(var.cloudwatchlogs.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.cloudwatchlogs[*].json
  policy_statements       = lookup(var.cloudwatchlogs, "policy_statements", [])
  policy_name             = try(var.cloudwatchlogs.policy_name, null)
  policy_name_use_prefix  = try(var.cloudwatchlogs.policy_name_use_prefix, true)
  policy_path             = try(var.cloudwatchlogs.policy_path, null)
  policy_description      = try(var.cloudwatchlogs.policy_description, "IAM Policy for Cloudwatch Logs controller for ACK")

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.cloudwatchlogs_name
    }
  }

  tags = var.tags
}

# recommended cloudwatchlogs-controller policy https://github.com/aws-controllers-k8s/cloudwatchlogs-controller/blob/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "cloudwatchlogs" {
  count = var.enable_cloudwatchlogs ? 1 : 0

  statement {
    sid    = "VisualEditor0"
    effect = "Allow"

    actions = [
      "logs:TagLogGroup",
      "logs:DescribeLogGroups",
      "logs:UntagLogGroup",
      "logs:DeleteLogGroup",
      "logs:UntagResource",
      "logs:TagResource",
      "logs:CreateLogGroup",
      "logs:ListTagsForResource",
    ]

    resources = ["*"]
  }
}

################################################################################
# Kinesis
################################################################################

locals {
  kinesis_name = "ack-kinesis"
}

module "kinesis" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_kinesis

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/kinesis-chart:0.0.17
  name             = try(var.kinesis.name, local.kinesis_name)
  description      = try(var.kinesis.description, "Helm Chart for Kinesis controller for ACK")
  namespace        = try(var.kinesis.namespace, "ack-system")
  create_namespace = try(var.kinesis.create_namespace, true)
  chart            = "kinesis-chart"
  chart_version    = try(var.kinesis.chart_version, "0.0.17")
  repository       = try(var.kinesis.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.kinesis.values, [])

  timeout                    = try(var.kinesis.timeout, null)
  repository_key_file        = try(var.kinesis.repository_key_file, null)
  repository_cert_file       = try(var.kinesis.repository_cert_file, null)
  repository_ca_file         = try(var.kinesis.repository_ca_file, null)
  repository_username        = try(var.kinesis.repository_username, local.repository_username)
  repository_password        = try(var.kinesis.repository_password, local.repository_password)
  devel                      = try(var.kinesis.devel, null)
  verify                     = try(var.kinesis.verify, null)
  keyring                    = try(var.kinesis.keyring, null)
  disable_webhooks           = try(var.kinesis.disable_webhooks, null)
  reuse_values               = try(var.kinesis.reuse_values, null)
  reset_values               = try(var.kinesis.reset_values, null)
  force_update               = try(var.kinesis.force_update, null)
  recreate_pods              = try(var.kinesis.recreate_pods, null)
  cleanup_on_fail            = try(var.kinesis.cleanup_on_fail, null)
  max_history                = try(var.kinesis.max_history, null)
  atomic                     = try(var.kinesis.atomic, null)
  skip_crds                  = try(var.kinesis.skip_crds, null)
  render_subchart_notes      = try(var.kinesis.render_subchart_notes, null)
  disable_openapi_validation = try(var.kinesis.disable_openapi_validation, null)
  wait                       = try(var.kinesis.wait, false)
  wait_for_jobs              = try(var.kinesis.wait_for_jobs, null)
  dependency_update          = try(var.kinesis.dependency_update, null)
  replace                    = try(var.kinesis.replace, null)
  lint                       = try(var.kinesis.lint, null)

  postrender = try(var.kinesis.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-kinesis-kinesis-chart-xxxxxxxxxxxxx` to `ack-kinesis-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-kinesis"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.kinesis_name
    }],
    try(var.kinesis.set, [])
  )
  set_sensitive = try(var.kinesis.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.kinesis.create_role, true)
  role_name                     = try(var.kinesis.role_name, "ack-kinesis")
  role_name_use_prefix          = try(var.kinesis.role_name_use_prefix, true)
  role_path                     = try(var.kinesis.role_path, "/")
  role_permissions_boundary_arn = lookup(var.kinesis, "role_permissions_boundary_arn", null)
  role_description              = try(var.kinesis.role_description, "IRSA for Kinesis controller for ACK")
  role_policies                 = lookup(var.kinesis, "role_policies", {})

  create_policy           = try(var.kinesis.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.kinesis[*].json
  policy_statements       = lookup(var.kinesis, "policy_statements", [])
  policy_name             = try(var.kinesis.policy_name, null)
  policy_name_use_prefix  = try(var.kinesis.policy_name_use_prefix, true)
  policy_path             = try(var.kinesis.policy_path, null)
  policy_description      = try(var.kinesis.policy_description, "IAM Policy for Kinesis controller for ACK")

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.kinesis_name
    }
  }

  tags = var.tags
}

# recommended kinesis-controller policy https://github.com/aws-controllers-k8s/kinesis-controller/blob/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "kinesis" {
  count = var.enable_kinesis ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "kinesis:ListStreams",
      "kinesis:DeleteStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:ListShards",
      "kinesis:UpdateShardCount",
      "kinesis:CreateStream",
      "kinesis:DescribeStream",
    ]

    resources = ["*"]
  }
}

################################################################################
# Secrets Manager
################################################################################

locals {
  secretsmanager_name = "ack-secretsmanager"
}

module "secretsmanager" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_secretsmanager

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/secretsmanager-chart:0.0.9
  name             = try(var.secretsmanager.name, local.secretsmanager_name)
  description      = try(var.secretsmanager.description, "Helm Chart for Secrets Manager controller for ACK")
  namespace        = try(var.secretsmanager.namespace, "ack-system")
  create_namespace = try(var.secretsmanager.create_namespace, true)
  chart            = "secretsmanager-chart"
  chart_version    = try(var.secretsmanager.chart_version, "0.0.9")
  repository       = try(var.secretsmanager.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.secretsmanager.values, [])

  timeout                    = try(var.secretsmanager.timeout, null)
  repository_key_file        = try(var.secretsmanager.repository_key_file, null)
  repository_cert_file       = try(var.secretsmanager.repository_cert_file, null)
  repository_ca_file         = try(var.secretsmanager.repository_ca_file, null)
  repository_username        = try(var.secretsmanager.repository_username, local.repository_username)
  repository_password        = try(var.secretsmanager.repository_password, local.repository_password)
  devel                      = try(var.secretsmanager.devel, null)
  verify                     = try(var.secretsmanager.verify, null)
  keyring                    = try(var.secretsmanager.keyring, null)
  disable_webhooks           = try(var.secretsmanager.disable_webhooks, null)
  reuse_values               = try(var.secretsmanager.reuse_values, null)
  reset_values               = try(var.secretsmanager.reset_values, null)
  force_update               = try(var.secretsmanager.force_update, null)
  recreate_pods              = try(var.secretsmanager.recreate_pods, null)
  cleanup_on_fail            = try(var.secretsmanager.cleanup_on_fail, null)
  max_history                = try(var.secretsmanager.max_history, null)
  atomic                     = try(var.secretsmanager.atomic, null)
  skip_crds                  = try(var.secretsmanager.skip_crds, null)
  render_subchart_notes      = try(var.secretsmanager.render_subchart_notes, null)
  disable_openapi_validation = try(var.secretsmanager.disable_openapi_validation, null)
  wait                       = try(var.secretsmanager.wait, false)
  wait_for_jobs              = try(var.secretsmanager.wait_for_jobs, null)
  dependency_update          = try(var.secretsmanager.dependency_update, null)
  replace                    = try(var.secretsmanager.replace, null)
  lint                       = try(var.secretsmanager.lint, null)

  postrender = try(var.secretsmanager.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-secretsmanager-secretsmanager-chart-xxxxxxxxxxxxx` to `ack-secretsmanager-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-secretsmanager"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.secretsmanager_name
    }],
    try(var.secretsmanager.set, [])
  )
  set_sensitive = try(var.secretsmanager.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.secretsmanager.create_role, true)
  role_name                     = try(var.secretsmanager.role_name, "ack-secretsmanager")
  role_name_use_prefix          = try(var.secretsmanager.role_name_use_prefix, true)
  role_path                     = try(var.secretsmanager.role_path, "/")
  role_permissions_boundary_arn = lookup(var.secretsmanager, "role_permissions_boundary_arn", null)
  role_description              = try(var.secretsmanager.role_description, "IRSA for Secrets Manager controller for ACK")
  role_policies = lookup(var.secretsmanager, "role_policies", {
    SecretsManagerReadWrite = "${local.iam_role_policy_prefix}/SecretsManagerReadWrite"
  })

  create_policy = try(var.secretsmanager.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.secretsmanager_name
    }
  }

  tags = var.tags
}

################################################################################
# Route 53 Resolver
################################################################################

locals {
  route53resolver_name = "ack-route53resolver"
}

module "route53resolver" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_route53resolver

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/route53resolver-chart:0.0.9
  name             = try(var.route53resolver.name, local.route53resolver_name)
  description      = try(var.route53resolver.description, "Helm Chart for Route53Resolver controller for ACK")
  namespace        = try(var.route53resolver.namespace, "ack-system")
  create_namespace = try(var.route53resolver.create_namespace, true)
  chart            = "route53resolver-chart"
  chart_version    = try(var.route53resolver.chart_version, "0.0.9")
  repository       = try(var.route53resolver.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.route53resolver.values, [])

  timeout                    = try(var.route53resolver.timeout, null)
  repository_key_file        = try(var.route53resolver.repository_key_file, null)
  repository_cert_file       = try(var.route53resolver.repository_cert_file, null)
  repository_ca_file         = try(var.route53resolver.repository_ca_file, null)
  repository_username        = try(var.route53resolver.repository_username, local.repository_username)
  repository_password        = try(var.route53resolver.repository_password, local.repository_password)
  devel                      = try(var.route53resolver.devel, null)
  verify                     = try(var.route53resolver.verify, null)
  keyring                    = try(var.route53resolver.keyring, null)
  disable_webhooks           = try(var.route53resolver.disable_webhooks, null)
  reuse_values               = try(var.route53resolver.reuse_values, null)
  reset_values               = try(var.route53resolver.reset_values, null)
  force_update               = try(var.route53resolver.force_update, null)
  recreate_pods              = try(var.route53resolver.recreate_pods, null)
  cleanup_on_fail            = try(var.route53resolver.cleanup_on_fail, null)
  max_history                = try(var.route53resolver.max_history, null)
  atomic                     = try(var.route53resolver.atomic, null)
  skip_crds                  = try(var.route53resolver.skip_crds, null)
  render_subchart_notes      = try(var.route53resolver.render_subchart_notes, null)
  disable_openapi_validation = try(var.route53resolver.disable_openapi_validation, null)
  wait                       = try(var.route53resolver.wait, false)
  wait_for_jobs              = try(var.route53resolver.wait_for_jobs, null)
  dependency_update          = try(var.route53resolver.dependency_update, null)
  replace                    = try(var.route53resolver.replace, null)
  lint                       = try(var.route53resolver.lint, null)

  postrender = try(var.route53resolver.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-route53resolver-route53resolver-chart-xxxxxxxxxxxxx` to `ack-route53resolver-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-route53resolver"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.route53resolver_name
    }],
    try(var.route53resolver.set, [])
  )
  set_sensitive = try(var.route53resolver.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.route53resolver.create_role, true)
  role_name                     = try(var.route53resolver.role_name, "ack-route53resolver")
  role_name_use_prefix          = try(var.route53resolver.role_name_use_prefix, true)
  role_path                     = try(var.route53resolver.role_path, "/")
  role_permissions_boundary_arn = lookup(var.route53resolver, "role_permissions_boundary_arn", null)
  role_description              = try(var.route53resolver.role_description, "IRSA for Route53Resolver controller for ACK")
  role_policies = lookup(var.route53resolver, "role_policies", {
    AmazonRoute53ResolverFullAccess = "${local.iam_role_policy_prefix}/AmazonRoute53ResolverFullAccess"
  })

  create_policy = try(var.route53resolver.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.route53resolver_name
    }
  }

  tags = var.tags
}

################################################################################
# Route 53
################################################################################

locals {
  route53_name = "ack-route53"
}

module "route53" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_route53

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/route53-chart:0.0.16
  name             = try(var.route53.name, local.route53_name)
  description      = try(var.route53.description, "Helm Chart for Route 53 controller for ACK")
  namespace        = try(var.route53.namespace, "ack-system")
  create_namespace = try(var.route53.create_namespace, true)
  chart            = "route53-chart"
  chart_version    = try(var.route53.chart_version, "0.0.16")
  repository       = try(var.route53.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.route53.values, [])

  timeout                    = try(var.route53.timeout, null)
  repository_key_file        = try(var.route53.repository_key_file, null)
  repository_cert_file       = try(var.route53.repository_cert_file, null)
  repository_ca_file         = try(var.route53.repository_ca_file, null)
  repository_username        = try(var.route53.repository_username, local.repository_username)
  repository_password        = try(var.route53.repository_password, local.repository_password)
  devel                      = try(var.route53.devel, null)
  verify                     = try(var.route53.verify, null)
  keyring                    = try(var.route53.keyring, null)
  disable_webhooks           = try(var.route53.disable_webhooks, null)
  reuse_values               = try(var.route53.reuse_values, null)
  reset_values               = try(var.route53.reset_values, null)
  force_update               = try(var.route53.force_update, null)
  recreate_pods              = try(var.route53.recreate_pods, null)
  cleanup_on_fail            = try(var.route53.cleanup_on_fail, null)
  max_history                = try(var.route53.max_history, null)
  atomic                     = try(var.route53.atomic, null)
  skip_crds                  = try(var.route53.skip_crds, null)
  render_subchart_notes      = try(var.route53.render_subchart_notes, null)
  disable_openapi_validation = try(var.route53.disable_openapi_validation, null)
  wait                       = try(var.route53.wait, false)
  wait_for_jobs              = try(var.route53.wait_for_jobs, null)
  dependency_update          = try(var.route53.dependency_update, null)
  replace                    = try(var.route53.replace, null)
  lint                       = try(var.route53.lint, null)

  postrender = try(var.route53.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-route53-route53-chart-xxxxxxxxxxxxx` to `ack-route53-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-route53"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.route53_name
    }],
    try(var.route53.set, [])
  )
  set_sensitive = try(var.route53.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.route53.create_role, true)
  role_name                     = try(var.route53.role_name, "ack-route53")
  role_name_use_prefix          = try(var.route53.role_name_use_prefix, true)
  role_path                     = try(var.route53.role_path, "/")
  role_permissions_boundary_arn = lookup(var.route53, "role_permissions_boundary_arn", null)
  role_description              = try(var.route53.role_description, "IRSA for Route 53 controller for ACK")
  role_policies = lookup(var.route53, "role_policies", {
    AmazonRoute53FullAccess = "${local.iam_role_policy_prefix}/AmazonRoute53FullAccess"
  })

  create_policy = try(var.route53.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.route53_name
    }
  }

  tags = var.tags
}

################################################################################
# Organizations
################################################################################

locals {
  organizations_name = "ack-organizations"
}

module "organizations" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_organizations

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/organizations-chart:0.0.8
  name             = try(var.organizations.name, local.organizations_name)
  description      = try(var.organizations.description, "Helm Chart for Organizations controller for ACK")
  namespace        = try(var.organizations.namespace, "ack-system")
  create_namespace = try(var.organizations.create_namespace, true)
  chart            = "organizations-chart"
  chart_version    = try(var.organizations.chart_version, "0.0.8")
  repository       = try(var.organizations.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.organizations.values, [])

  timeout                    = try(var.organizations.timeout, null)
  repository_key_file        = try(var.organizations.repository_key_file, null)
  repository_cert_file       = try(var.organizations.repository_cert_file, null)
  repository_ca_file         = try(var.organizations.repository_ca_file, null)
  repository_username        = try(var.organizations.repository_username, local.repository_username)
  repository_password        = try(var.organizations.repository_password, local.repository_password)
  devel                      = try(var.organizations.devel, null)
  verify                     = try(var.organizations.verify, null)
  keyring                    = try(var.organizations.keyring, null)
  disable_webhooks           = try(var.organizations.disable_webhooks, null)
  reuse_values               = try(var.organizations.reuse_values, null)
  reset_values               = try(var.organizations.reset_values, null)
  force_update               = try(var.organizations.force_update, null)
  recreate_pods              = try(var.organizations.recreate_pods, null)
  cleanup_on_fail            = try(var.organizations.cleanup_on_fail, null)
  max_history                = try(var.organizations.max_history, null)
  atomic                     = try(var.organizations.atomic, null)
  skip_crds                  = try(var.organizations.skip_crds, null)
  render_subchart_notes      = try(var.organizations.render_subchart_notes, null)
  disable_openapi_validation = try(var.organizations.disable_openapi_validation, null)
  wait                       = try(var.organizations.wait, false)
  wait_for_jobs              = try(var.organizations.wait_for_jobs, null)
  dependency_update          = try(var.organizations.dependency_update, null)
  replace                    = try(var.organizations.replace, null)
  lint                       = try(var.organizations.lint, null)

  postrender = try(var.organizations.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-organizations-organizations-chart-xxxxxxxxxxxxx` to `ack-organizations-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-organizations"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.organizations_name
    }],
    try(var.organizations.set, [])
  )
  set_sensitive = try(var.organizations.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.organizations.create_role, true)
  role_name                     = try(var.organizations.role_name, "ack-organizations")
  role_name_use_prefix          = try(var.organizations.role_name_use_prefix, true)
  role_path                     = try(var.organizations.role_path, "/")
  role_permissions_boundary_arn = lookup(var.organizations, "role_permissions_boundary_arn", null)
  role_description              = try(var.organizations.role_description, "IRSA for Organizations controller for ACK")
  role_policies = lookup(var.organizations, "role_policies", {
    AWSOrganizationsFullAccess = "${local.iam_role_policy_prefix}/AWSOrganizationsFullAccess"
  })

  create_policy = try(var.organizations.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.organizations_name
    }
  }

  tags = var.tags
}

################################################################################
# MQ
################################################################################

locals {
  mq_name = "ack-mq"
}

module "mq" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_mq

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/mq-chart:0.0.35
  name             = try(var.mq.name, local.mq_name)
  description      = try(var.mq.description, "Helm Chart for MQ controller for ACK")
  namespace        = try(var.mq.namespace, "ack-system")
  create_namespace = try(var.mq.create_namespace, true)
  chart            = "mq-chart"
  chart_version    = try(var.mq.chart_version, "0.0.35")
  repository       = try(var.mq.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.mq.values, [])

  timeout                    = try(var.mq.timeout, null)
  repository_key_file        = try(var.mq.repository_key_file, null)
  repository_cert_file       = try(var.mq.repository_cert_file, null)
  repository_ca_file         = try(var.mq.repository_ca_file, null)
  repository_username        = try(var.mq.repository_username, local.repository_username)
  repository_password        = try(var.mq.repository_password, local.repository_password)
  devel                      = try(var.mq.devel, null)
  verify                     = try(var.mq.verify, null)
  keyring                    = try(var.mq.keyring, null)
  disable_webhooks           = try(var.mq.disable_webhooks, null)
  reuse_values               = try(var.mq.reuse_values, null)
  reset_values               = try(var.mq.reset_values, null)
  force_update               = try(var.mq.force_update, null)
  recreate_pods              = try(var.mq.recreate_pods, null)
  cleanup_on_fail            = try(var.mq.cleanup_on_fail, null)
  max_history                = try(var.mq.max_history, null)
  atomic                     = try(var.mq.atomic, null)
  skip_crds                  = try(var.mq.skip_crds, null)
  render_subchart_notes      = try(var.mq.render_subchart_notes, null)
  disable_openapi_validation = try(var.mq.disable_openapi_validation, null)
  wait                       = try(var.mq.wait, false)
  wait_for_jobs              = try(var.mq.wait_for_jobs, null)
  dependency_update          = try(var.mq.dependency_update, null)
  replace                    = try(var.mq.replace, null)
  lint                       = try(var.mq.lint, null)

  postrender = try(var.mq.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-mq-mq-chart-xxxxxxxxxxxxx` to `ack-mq-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-mq"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.mq_name
    }],
    try(var.mq.set, [])
  )
  set_sensitive = try(var.mq.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.mq.create_role, true)
  role_name                     = try(var.mq.role_name, "ack-mq")
  role_name_use_prefix          = try(var.mq.role_name_use_prefix, true)
  role_path                     = try(var.mq.role_path, "/")
  role_permissions_boundary_arn = lookup(var.mq, "role_permissions_boundary_arn", null)
  role_description              = try(var.mq.role_description, "IRSA for MQ controller for ACK")
  role_policies = lookup(var.mq, "role_policies", {
    AmazonMQFullAccess = "${local.iam_role_policy_prefix}/AmazonMQFullAccess"
  })

  create_policy = try(var.mq.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.mq_name
    }
  }

  tags = var.tags
}

################################################################################
# CloudWatch
################################################################################

locals {
  cloudwatch_name = "ack-cloudwatch"
}

module "cloudwatch" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_cloudwatch

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/cloudwatch-chart:0.0.10
  name             = try(var.cloudwatch.name, local.cloudwatch_name)
  description      = try(var.cloudwatch.description, "Helm Chart for CloudWatch controller for ACK")
  namespace        = try(var.cloudwatch.namespace, "ack-system")
  create_namespace = try(var.cloudwatch.create_namespace, true)
  chart            = "cloudwatch-chart"
  chart_version    = try(var.cloudwatch.chart_version, "0.0.10")
  repository       = try(var.cloudwatch.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.cloudwatch.values, [])

  timeout                    = try(var.cloudwatch.timeout, null)
  repository_key_file        = try(var.cloudwatch.repository_key_file, null)
  repository_cert_file       = try(var.cloudwatch.repository_cert_file, null)
  repository_ca_file         = try(var.cloudwatch.repository_ca_file, null)
  repository_username        = try(var.cloudwatch.repository_username, local.repository_username)
  repository_password        = try(var.cloudwatch.repository_password, local.repository_password)
  devel                      = try(var.cloudwatch.devel, null)
  verify                     = try(var.cloudwatch.verify, null)
  keyring                    = try(var.cloudwatch.keyring, null)
  disable_webhooks           = try(var.cloudwatch.disable_webhooks, null)
  reuse_values               = try(var.cloudwatch.reuse_values, null)
  reset_values               = try(var.cloudwatch.reset_values, null)
  force_update               = try(var.cloudwatch.force_update, null)
  recreate_pods              = try(var.cloudwatch.recreate_pods, null)
  cleanup_on_fail            = try(var.cloudwatch.cleanup_on_fail, null)
  max_history                = try(var.cloudwatch.max_history, null)
  atomic                     = try(var.cloudwatch.atomic, null)
  skip_crds                  = try(var.cloudwatch.skip_crds, null)
  render_subchart_notes      = try(var.cloudwatch.render_subchart_notes, null)
  disable_openapi_validation = try(var.cloudwatch.disable_openapi_validation, null)
  wait                       = try(var.cloudwatch.wait, false)
  wait_for_jobs              = try(var.cloudwatch.wait_for_jobs, null)
  dependency_update          = try(var.cloudwatch.dependency_update, null)
  replace                    = try(var.cloudwatch.replace, null)
  lint                       = try(var.cloudwatch.lint, null)

  postrender = try(var.cloudwatch.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-cloudwatch-cloudwatch-chart-xxxxxxxxxxxxx` to `ack-cloudwatch-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-cloudwatch"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.cloudwatch_name
    }],
    try(var.cloudwatch.set, [])
  )
  set_sensitive = try(var.cloudwatch.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.cloudwatch.create_role, true)
  role_name                     = try(var.cloudwatch.role_name, "ack-cloudwatch")
  role_name_use_prefix          = try(var.cloudwatch.role_name_use_prefix, true)
  role_path                     = try(var.cloudwatch.role_path, "/")
  role_permissions_boundary_arn = lookup(var.cloudwatch, "role_permissions_boundary_arn", null)
  role_description              = try(var.cloudwatch.role_description, "IRSA for CloudWatch  controller for ACK")
  role_policies = lookup(var.cloudwatch, "role_policies", {
    CloudWatchFullAccessV2 = "${local.iam_role_policy_prefix}/CloudWatchFullAccessV2"
  })

  create_policy = try(var.cloudwatch.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.cloudwatch_name
    }
  }

  tags = var.tags
}

################################################################################
# Keyspaces
################################################################################

locals {
  keyspaces_name = "ack-keyspaces"
}

module "keyspaces" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_keyspaces

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/keyspaces-chart:0.0.15
  name             = try(var.keyspaces.name, local.keyspaces_name)
  description      = try(var.keyspaces.description, "Helm Chart for Keyspaces controller for ACK")
  namespace        = try(var.keyspaces.namespace, "ack-system")
  create_namespace = try(var.keyspaces.create_namespace, true)
  chart            = "keyspaces-chart"
  chart_version    = try(var.keyspaces.chart_version, "0.0.15")
  repository       = try(var.keyspaces.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.keyspaces.values, [])

  timeout                    = try(var.keyspaces.timeout, null)
  repository_key_file        = try(var.keyspaces.repository_key_file, null)
  repository_cert_file       = try(var.keyspaces.repository_cert_file, null)
  repository_ca_file         = try(var.keyspaces.repository_ca_file, null)
  repository_username        = try(var.keyspaces.repository_username, local.repository_username)
  repository_password        = try(var.keyspaces.repository_password, local.repository_password)
  devel                      = try(var.keyspaces.devel, null)
  verify                     = try(var.keyspaces.verify, null)
  keyring                    = try(var.keyspaces.keyring, null)
  disable_webhooks           = try(var.keyspaces.disable_webhooks, null)
  reuse_values               = try(var.keyspaces.reuse_values, null)
  reset_values               = try(var.keyspaces.reset_values, null)
  force_update               = try(var.keyspaces.force_update, null)
  recreate_pods              = try(var.keyspaces.recreate_pods, null)
  cleanup_on_fail            = try(var.keyspaces.cleanup_on_fail, null)
  max_history                = try(var.keyspaces.max_history, null)
  atomic                     = try(var.keyspaces.atomic, null)
  skip_crds                  = try(var.keyspaces.skip_crds, null)
  render_subchart_notes      = try(var.keyspaces.render_subchart_notes, null)
  disable_openapi_validation = try(var.keyspaces.disable_openapi_validation, null)
  wait                       = try(var.keyspaces.wait, false)
  wait_for_jobs              = try(var.keyspaces.wait_for_jobs, null)
  dependency_update          = try(var.keyspaces.dependency_update, null)
  replace                    = try(var.keyspaces.replace, null)
  lint                       = try(var.keyspaces.lint, null)

  postrender = try(var.keyspaces.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-keyspaces-keyspaces-chart-xxxxxxxxxxxxx` to `ack-keyspaces-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-keyspaces"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.keyspaces_name
    }],
    try(var.keyspaces.set, [])
  )
  set_sensitive = try(var.keyspaces.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.keyspaces.create_role, true)
  role_name                     = try(var.keyspaces.role_name, "ack-keyspaces")
  role_name_use_prefix          = try(var.keyspaces.role_name_use_prefix, true)
  role_path                     = try(var.keyspaces.role_path, "/")
  role_permissions_boundary_arn = lookup(var.keyspaces, "role_permissions_boundary_arn", null)
  role_description              = try(var.keyspaces.role_description, "IRSA for Keyspaces controller for ACK")
  role_policies = lookup(var.keyspaces, "role_policies", {
    AmazonKeyspacesFullAccess = "${local.iam_role_policy_prefix}/AmazonKeyspacesFullAccess"
  })

  create_policy = try(var.keyspaces.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.keyspaces_name
    }
  }

  tags = var.tags
}

################################################################################
# Kafka
################################################################################

locals {
  kafka_name = "ack-kafka"
}

module "kafka" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_kafka

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/kafka-chart:0.0.11
  name             = try(var.kafka.name, local.kafka_name)
  description      = try(var.kafka.description, "Helm Chart for Kafka controller for ACK")
  namespace        = try(var.kafka.namespace, "ack-system")
  create_namespace = try(var.kafka.create_namespace, true)
  chart            = "kafka-chart"
  chart_version    = try(var.kafka.chart_version, "0.0.11")
  repository       = try(var.kafka.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.kafka.values, [])

  timeout                    = try(var.kafka.timeout, null)
  repository_key_file        = try(var.kafka.repository_key_file, null)
  repository_cert_file       = try(var.kafka.repository_cert_file, null)
  repository_ca_file         = try(var.kafka.repository_ca_file, null)
  repository_username        = try(var.kafka.repository_username, local.repository_username)
  repository_password        = try(var.kafka.repository_password, local.repository_password)
  devel                      = try(var.kafka.devel, null)
  verify                     = try(var.kafka.verify, null)
  keyring                    = try(var.kafka.keyring, null)
  disable_webhooks           = try(var.kafka.disable_webhooks, null)
  reuse_values               = try(var.kafka.reuse_values, null)
  reset_values               = try(var.kafka.reset_values, null)
  force_update               = try(var.kafka.force_update, null)
  recreate_pods              = try(var.kafka.recreate_pods, null)
  cleanup_on_fail            = try(var.kafka.cleanup_on_fail, null)
  max_history                = try(var.kafka.max_history, null)
  atomic                     = try(var.kafka.atomic, null)
  skip_crds                  = try(var.kafka.skip_crds, null)
  render_subchart_notes      = try(var.kafka.render_subchart_notes, null)
  disable_openapi_validation = try(var.kafka.disable_openapi_validation, null)
  wait                       = try(var.kafka.wait, false)
  wait_for_jobs              = try(var.kafka.wait_for_jobs, null)
  dependency_update          = try(var.kafka.dependency_update, null)
  replace                    = try(var.kafka.replace, null)
  lint                       = try(var.kafka.lint, null)

  postrender = try(var.kafka.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-kafka-kafka-chart-xxxxxxxxxxxxx` to `ack-kafka-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-kafka"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.kafka_name
    }],
    try(var.kafka.set, [])
  )
  set_sensitive = try(var.kafka.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.kafka.create_role, true)
  role_name                     = try(var.kafka.role_name, "ack-kafka")
  role_name_use_prefix          = try(var.kafka.role_name_use_prefix, true)
  role_path                     = try(var.kafka.role_path, "/")
  role_permissions_boundary_arn = lookup(var.kafka, "role_permissions_boundary_arn", null)
  role_description              = try(var.kafka.role_description, "IRSA for Kafka controller for ACK")
  role_policies = lookup(var.kafka, "role_policies", {
    AmazonMSKFullAccess = "${local.iam_role_policy_prefix}/AmazonMSKFullAccess"
  })

  create_policy = try(var.kafka.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.kafka_name
    }
  }

  tags = var.tags
}

################################################################################
# EFS
################################################################################

locals {
  efs_name = "ack-efs"
}

module "efs" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_efs

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/efs-chart:0.0.9
  name             = try(var.efs.name, local.efs_name)
  description      = try(var.efs.description, "Helm Chart for EFS controller for ACK")
  namespace        = try(var.efs.namespace, "ack-system")
  create_namespace = try(var.efs.create_namespace, true)
  chart            = "efs-chart"
  chart_version    = try(var.efs.chart_version, "0.0.9")
  repository       = try(var.efs.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.efs.values, [])

  timeout                    = try(var.efs.timeout, null)
  repository_key_file        = try(var.efs.repository_key_file, null)
  repository_cert_file       = try(var.efs.repository_cert_file, null)
  repository_ca_file         = try(var.efs.repository_ca_file, null)
  repository_username        = try(var.efs.repository_username, local.repository_username)
  repository_password        = try(var.efs.repository_password, local.repository_password)
  devel                      = try(var.efs.devel, null)
  verify                     = try(var.efs.verify, null)
  keyring                    = try(var.efs.keyring, null)
  disable_webhooks           = try(var.efs.disable_webhooks, null)
  reuse_values               = try(var.efs.reuse_values, null)
  reset_values               = try(var.efs.reset_values, null)
  force_update               = try(var.efs.force_update, null)
  recreate_pods              = try(var.efs.recreate_pods, null)
  cleanup_on_fail            = try(var.efs.cleanup_on_fail, null)
  max_history                = try(var.efs.max_history, null)
  atomic                     = try(var.efs.atomic, null)
  skip_crds                  = try(var.efs.skip_crds, null)
  render_subchart_notes      = try(var.efs.render_subchart_notes, null)
  disable_openapi_validation = try(var.efs.disable_openapi_validation, null)
  wait                       = try(var.efs.wait, false)
  wait_for_jobs              = try(var.efs.wait_for_jobs, null)
  dependency_update          = try(var.efs.dependency_update, null)
  replace                    = try(var.efs.replace, null)
  lint                       = try(var.efs.lint, null)

  postrender = try(var.efs.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-efs-efs-chart-xxxxxxxxxxxxx` to `ack-efs-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-efs"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.efs_name
    }],
    try(var.efs.set, [])
  )
  set_sensitive = try(var.efs.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.efs.create_role, true)
  role_name                     = try(var.efs.role_name, "ack-efs")
  role_name_use_prefix          = try(var.efs.role_name_use_prefix, true)
  role_path                     = try(var.efs.role_path, "/")
  role_permissions_boundary_arn = lookup(var.efs, "role_permissions_boundary_arn", null)
  role_description              = try(var.efs.role_description, "IRSA for EFS controller for ACK")
  role_policies = lookup(var.efs, "role_policies", {
    AmazonElasticFileSystemFullAccess = "${local.iam_role_policy_prefix}/AmazonElasticFileSystemFullAccess"
  })

  create_policy = try(var.efs.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.efs_name
    }
  }

  tags = var.tags
}

################################################################################
# ECS
################################################################################

locals {
  ecs_name = "ack-ecs"
}

module "ecs" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_ecs

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/ecs-chart:0.0.8
  name             = try(var.ecs.name, local.ecs_name)
  description      = try(var.ecs.description, "Helm Chart for ECS controller for ACK")
  namespace        = try(var.ecs.namespace, "ack-system")
  create_namespace = try(var.ecs.create_namespace, true)
  chart            = "ecs-chart"
  chart_version    = try(var.ecs.chart_version, "0.0.8")
  repository       = try(var.ecs.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.ecs.values, [])

  timeout                    = try(var.ecs.timeout, null)
  repository_key_file        = try(var.ecs.repository_key_file, null)
  repository_cert_file       = try(var.ecs.repository_cert_file, null)
  repository_ca_file         = try(var.ecs.repository_ca_file, null)
  repository_username        = try(var.ecs.repository_username, local.repository_username)
  repository_password        = try(var.ecs.repository_password, local.repository_password)
  devel                      = try(var.ecs.devel, null)
  verify                     = try(var.ecs.verify, null)
  keyring                    = try(var.ecs.keyring, null)
  disable_webhooks           = try(var.ecs.disable_webhooks, null)
  reuse_values               = try(var.ecs.reuse_values, null)
  reset_values               = try(var.ecs.reset_values, null)
  force_update               = try(var.ecs.force_update, null)
  recreate_pods              = try(var.ecs.recreate_pods, null)
  cleanup_on_fail            = try(var.ecs.cleanup_on_fail, null)
  max_history                = try(var.ecs.max_history, null)
  atomic                     = try(var.ecs.atomic, null)
  skip_crds                  = try(var.ecs.skip_crds, null)
  render_subchart_notes      = try(var.ecs.render_subchart_notes, null)
  disable_openapi_validation = try(var.ecs.disable_openapi_validation, null)
  wait                       = try(var.ecs.wait, false)
  wait_for_jobs              = try(var.ecs.wait_for_jobs, null)
  dependency_update          = try(var.ecs.dependency_update, null)
  replace                    = try(var.ecs.replace, null)
  lint                       = try(var.ecs.lint, null)

  postrender = try(var.ecs.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-ecs-ecs-chart-xxxxxxxxxxxxx` to `ack-ecs-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-ecs"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.ecs_name
    }],
    try(var.ecs.set, [])
  )
  set_sensitive = try(var.ecs.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.ecs.create_role, true)
  role_name                     = try(var.ecs.role_name, "ack-ecs")
  role_name_use_prefix          = try(var.ecs.role_name_use_prefix, true)
  role_path                     = try(var.ecs.role_path, "/")
  role_permissions_boundary_arn = lookup(var.ecs, "role_permissions_boundary_arn", null)
  role_description              = try(var.ecs.role_description, "IRSA for ECS controller for ACK")
  role_policies = lookup(var.ecs, "role_policies", {
    AmazonECS_FullAccess = "${local.iam_role_policy_prefix}/AmazonECS_FullAccess"
  })

  create_policy = try(var.ecs.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.ecs_name
    }
  }

  tags = var.tags
}

################################################################################
# Cloudtrail
################################################################################

locals {
  cloudtrail_name = "ack-cloudtrail"
}

module "cloudtrail" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_cloudtrail

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/cloudtrail-chart:1.0.13
  name             = try(var.cloudtrail.name, local.cloudtrail_name)
  description      = try(var.cloudtrail.description, "Helm Chart for Cloudtrail controller for ACK")
  namespace        = try(var.cloudtrail.namespace, "ack-system")
  create_namespace = try(var.cloudtrail.create_namespace, true)
  chart            = "cloudtrail-chart"
  chart_version    = try(var.cloudtrail.chart_version, "1.0.13")
  repository       = try(var.cloudtrail.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.cloudtrail.values, [])

  timeout                    = try(var.cloudtrail.timeout, null)
  repository_key_file        = try(var.cloudtrail.repository_key_file, null)
  repository_cert_file       = try(var.cloudtrail.repository_cert_file, null)
  repository_ca_file         = try(var.cloudtrail.repository_ca_file, null)
  repository_username        = try(var.cloudtrail.repository_username, local.repository_username)
  repository_password        = try(var.cloudtrail.repository_password, local.repository_password)
  devel                      = try(var.cloudtrail.devel, null)
  verify                     = try(var.cloudtrail.verify, null)
  keyring                    = try(var.cloudtrail.keyring, null)
  disable_webhooks           = try(var.cloudtrail.disable_webhooks, null)
  reuse_values               = try(var.cloudtrail.reuse_values, null)
  reset_values               = try(var.cloudtrail.reset_values, null)
  force_update               = try(var.cloudtrail.force_update, null)
  recreate_pods              = try(var.cloudtrail.recreate_pods, null)
  cleanup_on_fail            = try(var.cloudtrail.cleanup_on_fail, null)
  max_history                = try(var.cloudtrail.max_history, null)
  atomic                     = try(var.cloudtrail.atomic, null)
  skip_crds                  = try(var.cloudtrail.skip_crds, null)
  render_subchart_notes      = try(var.cloudtrail.render_subchart_notes, null)
  disable_openapi_validation = try(var.cloudtrail.disable_openapi_validation, null)
  wait                       = try(var.cloudtrail.wait, false)
  wait_for_jobs              = try(var.cloudtrail.wait_for_jobs, null)
  dependency_update          = try(var.cloudtrail.dependency_update, null)
  replace                    = try(var.cloudtrail.replace, null)
  lint                       = try(var.cloudtrail.lint, null)

  postrender = try(var.cloudtrail.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-cloudtrail-cloudtrail-chart-xxxxxxxxxxxxx` to `ack-cloudtrail-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-cloudtrail"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.cloudtrail_name
    }],
    try(var.cloudtrail.set, [])
  )
  set_sensitive = try(var.cloudtrail.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.cloudtrail.create_role, true)
  role_name                     = try(var.cloudtrail.role_name, "ack-cloudtrail")
  role_name_use_prefix          = try(var.cloudtrail.role_name_use_prefix, true)
  role_path                     = try(var.cloudtrail.role_path, "/")
  role_permissions_boundary_arn = lookup(var.cloudtrail, "role_permissions_boundary_arn", null)
  role_description              = try(var.cloudtrail.role_description, "IRSA for Cloudtrail controller for ACK")
  role_policies = lookup(var.cloudtrail, "role_policies", {
    AWSCloudTrail_FullAccess = "${local.iam_role_policy_prefix}/AWSCloudTrail_FullAccess"
  })

  create_policy = try(var.cloudtrail.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.cloudtrail_name
    }
  }

  tags = var.tags
}

################################################################################
# Cloudfront
################################################################################

locals {
  cloudfront_name = "ack-cloudfront"
}

module "cloudfront" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_cloudfront

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/cloudfront-chart:0.0.14
  name             = try(var.cloudfront.name, local.cloudfront_name)
  description      = try(var.cloudfront.description, "Helm Chart for Cloudfront controller for ACK")
  namespace        = try(var.cloudfront.namespace, "ack-system")
  create_namespace = try(var.cloudfront.create_namespace, true)
  chart            = "cloudfront-chart"
  chart_version    = try(var.cloudfront.chart_version, "0.0.14")
  repository       = try(var.cloudfront.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.cloudfront.values, [])

  timeout                    = try(var.cloudfront.timeout, null)
  repository_key_file        = try(var.cloudfront.repository_key_file, null)
  repository_cert_file       = try(var.cloudfront.repository_cert_file, null)
  repository_ca_file         = try(var.cloudfront.repository_ca_file, null)
  repository_username        = try(var.cloudfront.repository_username, local.repository_username)
  repository_password        = try(var.cloudfront.repository_password, local.repository_password)
  devel                      = try(var.cloudfront.devel, null)
  verify                     = try(var.cloudfront.verify, null)
  keyring                    = try(var.cloudfront.keyring, null)
  disable_webhooks           = try(var.cloudfront.disable_webhooks, null)
  reuse_values               = try(var.cloudfront.reuse_values, null)
  reset_values               = try(var.cloudfront.reset_values, null)
  force_update               = try(var.cloudfront.force_update, null)
  recreate_pods              = try(var.cloudfront.recreate_pods, null)
  cleanup_on_fail            = try(var.cloudfront.cleanup_on_fail, null)
  max_history                = try(var.cloudfront.max_history, null)
  atomic                     = try(var.cloudfront.atomic, null)
  skip_crds                  = try(var.cloudfront.skip_crds, null)
  render_subchart_notes      = try(var.cloudfront.render_subchart_notes, null)
  disable_openapi_validation = try(var.cloudfront.disable_openapi_validation, null)
  wait                       = try(var.cloudfront.wait, false)
  wait_for_jobs              = try(var.cloudfront.wait_for_jobs, null)
  dependency_update          = try(var.cloudfront.dependency_update, null)
  replace                    = try(var.cloudfront.replace, null)
  lint                       = try(var.cloudfront.lint, null)

  postrender = try(var.cloudfront.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-cloudfront-cloudfront-chart-xxxxxxxxxxxxx` to `ack-cloudfront-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-cloudfront"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.cloudfront_name
    }],
    try(var.cloudfront.set, [])
  )
  set_sensitive = try(var.cloudfront.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.cloudfront.create_role, true)
  role_name                     = try(var.cloudfront.role_name, "ack-cloudfront")
  role_name_use_prefix          = try(var.cloudfront.role_name_use_prefix, true)
  role_path                     = try(var.cloudfront.role_path, "/")
  role_permissions_boundary_arn = lookup(var.cloudfront, "role_permissions_boundary_arn", null)
  role_description              = try(var.cloudfront.role_description, "IRSA for Cloudfront controller for ACK")
  role_policies = lookup(var.cloudfront, "role_policies", {
    CloudFrontFullAccess = "${local.iam_role_policy_prefix}/CloudFrontFullAccess"
  })

  create_policy = try(var.cloudfront.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.cloudfront_name
    }
  }

  tags = var.tags
}

################################################################################
# Application Autoscaling
################################################################################

locals {
  applicationautoscaling_name = "ack-applicationautoscaling"
}

module "applicationautoscaling" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_applicationautoscaling

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/applicationautoscaling-chart:1.0.16
  name             = try(var.applicationautoscaling.name, local.applicationautoscaling_name)
  description      = try(var.applicationautoscaling.description, "Helm Chart for Application Autoscaling controller for ACK")
  namespace        = try(var.applicationautoscaling.namespace, "ack-system")
  create_namespace = try(var.applicationautoscaling.create_namespace, true)
  chart            = "applicationautoscaling-chart"
  chart_version    = try(var.applicationautoscaling.chart_version, "1.0.16")
  repository       = try(var.applicationautoscaling.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.applicationautoscaling.values, [])

  timeout                    = try(var.applicationautoscaling.timeout, null)
  repository_key_file        = try(var.applicationautoscaling.repository_key_file, null)
  repository_cert_file       = try(var.applicationautoscaling.repository_cert_file, null)
  repository_ca_file         = try(var.applicationautoscaling.repository_ca_file, null)
  repository_username        = try(var.applicationautoscaling.repository_username, local.repository_username)
  repository_password        = try(var.applicationautoscaling.repository_password, local.repository_password)
  devel                      = try(var.applicationautoscaling.devel, null)
  verify                     = try(var.applicationautoscaling.verify, null)
  keyring                    = try(var.applicationautoscaling.keyring, null)
  disable_webhooks           = try(var.applicationautoscaling.disable_webhooks, null)
  reuse_values               = try(var.applicationautoscaling.reuse_values, null)
  reset_values               = try(var.applicationautoscaling.reset_values, null)
  force_update               = try(var.applicationautoscaling.force_update, null)
  recreate_pods              = try(var.applicationautoscaling.recreate_pods, null)
  cleanup_on_fail            = try(var.applicationautoscaling.cleanup_on_fail, null)
  max_history                = try(var.applicationautoscaling.max_history, null)
  atomic                     = try(var.applicationautoscaling.atomic, null)
  skip_crds                  = try(var.applicationautoscaling.skip_crds, null)
  render_subchart_notes      = try(var.applicationautoscaling.render_subchart_notes, null)
  disable_openapi_validation = try(var.applicationautoscaling.disable_openapi_validation, null)
  wait                       = try(var.applicationautoscaling.wait, false)
  wait_for_jobs              = try(var.applicationautoscaling.wait_for_jobs, null)
  dependency_update          = try(var.applicationautoscaling.dependency_update, null)
  replace                    = try(var.applicationautoscaling.replace, null)
  lint                       = try(var.applicationautoscaling.lint, null)

  postrender = try(var.applicationautoscaling.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-applicationautoscaling-applicationautoscaling-chart-xxxxxxxxxxxxx` to `ack-applicationautoscaling-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-applicationautoscaling"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.applicationautoscaling_name
    }],
    try(var.applicationautoscaling.set, [])
  )
  set_sensitive = try(var.applicationautoscaling.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.applicationautoscaling.create_role, true)
  role_name                     = try(var.applicationautoscaling.role_name, "ack-applicationautoscaling")
  role_name_use_prefix          = try(var.applicationautoscaling.role_name_use_prefix, true)
  role_path                     = try(var.applicationautoscaling.role_path, "/")
  role_permissions_boundary_arn = lookup(var.applicationautoscaling, "role_permissions_boundary_arn", null)
  role_description              = try(var.applicationautoscaling.role_description, "IRSA for Application Autoscaling controller for ACK")
  role_policies = lookup(var.applicationautoscaling, "role_policies", {
    PowerUserAccess = "${local.iam_role_policy_prefix}/PowerUserAccess"
  })

  create_policy = try(var.applicationautoscaling.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.applicationautoscaling_name
    }
  }

  tags = var.tags
}

################################################################################
# SageMaker
################################################################################

locals {
  sagemaker_name = "ack-sagemaker"
}

module "sagemaker" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_sagemaker

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/sagemaker-chart:1.2.12
  name             = try(var.sagemaker.name, local.sagemaker_name)
  description      = try(var.sagemaker.description, "Helm Chart for Sagemaker controller for ACK")
  namespace        = try(var.sagemaker.namespace, "ack-system")
  create_namespace = try(var.sagemaker.create_namespace, true)
  chart            = "sagemaker-chart"
  chart_version    = try(var.sagemaker.chart_version, "1.2.12")
  repository       = try(var.sagemaker.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.sagemaker.values, [])

  timeout                    = try(var.sagemaker.timeout, null)
  repository_key_file        = try(var.sagemaker.repository_key_file, null)
  repository_cert_file       = try(var.sagemaker.repository_cert_file, null)
  repository_ca_file         = try(var.sagemaker.repository_ca_file, null)
  repository_username        = try(var.sagemaker.repository_username, local.repository_username)
  repository_password        = try(var.sagemaker.repository_password, local.repository_password)
  devel                      = try(var.sagemaker.devel, null)
  verify                     = try(var.sagemaker.verify, null)
  keyring                    = try(var.sagemaker.keyring, null)
  disable_webhooks           = try(var.sagemaker.disable_webhooks, null)
  reuse_values               = try(var.sagemaker.reuse_values, null)
  reset_values               = try(var.sagemaker.reset_values, null)
  force_update               = try(var.sagemaker.force_update, null)
  recreate_pods              = try(var.sagemaker.recreate_pods, null)
  cleanup_on_fail            = try(var.sagemaker.cleanup_on_fail, null)
  max_history                = try(var.sagemaker.max_history, null)
  atomic                     = try(var.sagemaker.atomic, null)
  skip_crds                  = try(var.sagemaker.skip_crds, null)
  render_subchart_notes      = try(var.sagemaker.render_subchart_notes, null)
  disable_openapi_validation = try(var.sagemaker.disable_openapi_validation, null)
  wait                       = try(var.sagemaker.wait, false)
  wait_for_jobs              = try(var.sagemaker.wait_for_jobs, null)
  dependency_update          = try(var.sagemaker.dependency_update, null)
  replace                    = try(var.sagemaker.replace, null)
  lint                       = try(var.sagemaker.lint, null)

  postrender = try(var.sagemaker.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-sagemaker-sagemaker-chart-xxxxxxxxxxxxx` to `ack-sagemaker-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-sagemaker"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.sagemaker_name
    }],
    try(var.sagemaker.set, [])
  )
  set_sensitive = try(var.sagemaker.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.sagemaker.create_role, true)
  role_name                     = try(var.sagemaker.role_name, "ack-sagemaker")
  role_name_use_prefix          = try(var.sagemaker.role_name_use_prefix, true)
  role_path                     = try(var.sagemaker.role_path, "/")
  role_permissions_boundary_arn = lookup(var.sagemaker, "role_permissions_boundary_arn", null)
  role_description              = try(var.sagemaker.role_description, "IRSA for Sagemaker controller for ACK")
  role_policies = lookup(var.sagemaker, "role_policies", {
    AmazonSageMakerFullAccess = "${local.iam_role_policy_prefix}/AmazonSageMakerFullAccess"
  })

  create_policy = try(var.sagemaker.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.sagemaker_name
    }
  }

  tags = var.tags
}

################################################################################
# MemoryDB
################################################################################

locals {
  memorydb_name = "ack-memorydb"
}

module "memorydb" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_memorydb

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/memorydb-chart:1.0.4
  name             = try(var.memorydb.name, local.memorydb_name)
  description      = try(var.memorydb.description, "Helm Chart for MemoryDB controller for ACK")
  namespace        = try(var.memorydb.namespace, "ack-system")
  create_namespace = try(var.memorydb.create_namespace, true)
  chart            = "memorydb-chart"
  chart_version    = try(var.memorydb.chart_version, "1.0.4")
  repository       = try(var.memorydb.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.memorydb.values, [])

  timeout                    = try(var.memorydb.timeout, null)
  repository_key_file        = try(var.memorydb.repository_key_file, null)
  repository_cert_file       = try(var.memorydb.repository_cert_file, null)
  repository_ca_file         = try(var.memorydb.repository_ca_file, null)
  repository_username        = try(var.memorydb.repository_username, local.repository_username)
  repository_password        = try(var.memorydb.repository_password, local.repository_password)
  devel                      = try(var.memorydb.devel, null)
  verify                     = try(var.memorydb.verify, null)
  keyring                    = try(var.memorydb.keyring, null)
  disable_webhooks           = try(var.memorydb.disable_webhooks, null)
  reuse_values               = try(var.memorydb.reuse_values, null)
  reset_values               = try(var.memorydb.reset_values, null)
  force_update               = try(var.memorydb.force_update, null)
  recreate_pods              = try(var.memorydb.recreate_pods, null)
  cleanup_on_fail            = try(var.memorydb.cleanup_on_fail, null)
  max_history                = try(var.memorydb.max_history, null)
  atomic                     = try(var.memorydb.atomic, null)
  skip_crds                  = try(var.memorydb.skip_crds, null)
  render_subchart_notes      = try(var.memorydb.render_subchart_notes, null)
  disable_openapi_validation = try(var.memorydb.disable_openapi_validation, null)
  wait                       = try(var.memorydb.wait, false)
  wait_for_jobs              = try(var.memorydb.wait_for_jobs, null)
  dependency_update          = try(var.memorydb.dependency_update, null)
  replace                    = try(var.memorydb.replace, null)
  lint                       = try(var.memorydb.lint, null)

  postrender = try(var.memorydb.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-memorydb-memorydb-chart-xxxxxxxxxxxxx` to `ack-memorydb-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-memorydb"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.memorydb_name
    }],
    try(var.memorydb.set, [])
  )
  set_sensitive = try(var.memorydb.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.memorydb.create_role, true)
  role_name                     = try(var.memorydb.role_name, "ack-memorydb")
  role_name_use_prefix          = try(var.memorydb.role_name_use_prefix, true)
  role_path                     = try(var.memorydb.role_path, "/")
  role_permissions_boundary_arn = lookup(var.memorydb, "role_permissions_boundary_arn", null)
  role_description              = try(var.memorydb.role_description, "IRSA for MemoryDB controller for ACK")
  role_policies = lookup(var.memorydb, "role_policies", {
    AmazonMemoryDBFullAccess = "${local.iam_role_policy_prefix}/AmazonMemoryDBFullAccess"
  })
  create_policy = try(var.memorydb.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.memorydb_name
    }
  }

  tags = var.tags
}

################################################################################
# OpenSearch Service
################################################################################

locals {
  opensearchservice_name = "ack-opensearchservice"
}

module "opensearchservice" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_opensearchservice

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/opensearchservice-chart:0.0.27
  name             = try(var.opensearchservice.name, local.opensearchservice_name)
  description      = try(var.opensearchservice.description, "Helm Chart for Opensearch Service controller for ACK")
  namespace        = try(var.opensearchservice.namespace, "ack-system")
  create_namespace = try(var.opensearchservice.create_namespace, true)
  chart            = "opensearchservice-chart"
  chart_version    = try(var.opensearchservice.chart_version, "0.0.27")
  repository       = try(var.opensearchservice.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.opensearchservice.values, [])

  timeout                    = try(var.opensearchservice.timeout, null)
  repository_key_file        = try(var.opensearchservice.repository_key_file, null)
  repository_cert_file       = try(var.opensearchservice.repository_cert_file, null)
  repository_ca_file         = try(var.opensearchservice.repository_ca_file, null)
  repository_username        = try(var.opensearchservice.repository_username, local.repository_username)
  repository_password        = try(var.opensearchservice.repository_password, local.repository_password)
  devel                      = try(var.opensearchservice.devel, null)
  verify                     = try(var.opensearchservice.verify, null)
  keyring                    = try(var.opensearchservice.keyring, null)
  disable_webhooks           = try(var.opensearchservice.disable_webhooks, null)
  reuse_values               = try(var.opensearchservice.reuse_values, null)
  reset_values               = try(var.opensearchservice.reset_values, null)
  force_update               = try(var.opensearchservice.force_update, null)
  recreate_pods              = try(var.opensearchservice.recreate_pods, null)
  cleanup_on_fail            = try(var.opensearchservice.cleanup_on_fail, null)
  max_history                = try(var.opensearchservice.max_history, null)
  atomic                     = try(var.opensearchservice.atomic, null)
  skip_crds                  = try(var.opensearchservice.skip_crds, null)
  render_subchart_notes      = try(var.opensearchservice.render_subchart_notes, null)
  disable_openapi_validation = try(var.opensearchservice.disable_openapi_validation, null)
  wait                       = try(var.opensearchservice.wait, false)
  wait_for_jobs              = try(var.opensearchservice.wait_for_jobs, null)
  dependency_update          = try(var.opensearchservice.dependency_update, null)
  replace                    = try(var.opensearchservice.replace, null)
  lint                       = try(var.opensearchservice.lint, null)

  postrender = try(var.opensearchservice.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-opensearchservice-opensearchservice-chart-xxxxxxxxxxxxx` to `ack-opensearchservice-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-opensearchservice"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.opensearchservice_name
    }],
    try(var.opensearchservice.set, [])
  )
  set_sensitive = try(var.opensearchservice.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.opensearchservice.create_role, true)
  role_name                     = try(var.opensearchservice.role_name, "ack-opensearchservice")
  role_name_use_prefix          = try(var.opensearchservice.role_name_use_prefix, true)
  role_path                     = try(var.opensearchservice.role_path, "/")
  role_permissions_boundary_arn = lookup(var.opensearchservice, "role_permissions_boundary_arn", null)
  role_description              = try(var.opensearchservice.role_description, "IRSA for Opensearch Service controller for ACK")
  role_policies = lookup(var.opensearchservice, "role_policies", {
    AmazonOpenSearchServiceFullAccess = "${local.iam_role_policy_prefix}/AmazonOpenSearchServiceFullAccess"
  })
  create_policy = try(var.opensearchservice.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.opensearchservice_name
    }
  }

  tags = var.tags
}

################################################################################
# ECR
################################################################################

locals {
  ecr_name = "ack-ecr"
}

module "ecr" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "1.1.1"

  create = var.enable_ecr

  # Disable helm release
  create_release = var.create_kubernetes_resources

  # public.ecr.aws/aws-controllers-k8s/ecr-chart:1.0.17
  name             = try(var.ecr.name, local.ecr_name)
  description      = try(var.ecr.description, "Helm Chart for ECR controller for ACK")
  namespace        = try(var.ecr.namespace, "ack-system")
  create_namespace = try(var.ecr.create_namespace, true)
  chart            = "ecr-chart"
  chart_version    = try(var.ecr.chart_version, "1.0.17")
  repository       = try(var.ecr.repository, "oci://public.ecr.aws/aws-controllers-k8s")
  values           = try(var.ecr.values, [])

  timeout                    = try(var.ecr.timeout, null)
  repository_key_file        = try(var.ecr.repository_key_file, null)
  repository_cert_file       = try(var.ecr.repository_cert_file, null)
  repository_ca_file         = try(var.ecr.repository_ca_file, null)
  repository_username        = try(var.ecr.repository_username, local.repository_username)
  repository_password        = try(var.ecr.repository_password, local.repository_password)
  devel                      = try(var.ecr.devel, null)
  verify                     = try(var.ecr.verify, null)
  keyring                    = try(var.ecr.keyring, null)
  disable_webhooks           = try(var.ecr.disable_webhooks, null)
  reuse_values               = try(var.ecr.reuse_values, null)
  reset_values               = try(var.ecr.reset_values, null)
  force_update               = try(var.ecr.force_update, null)
  recreate_pods              = try(var.ecr.recreate_pods, null)
  cleanup_on_fail            = try(var.ecr.cleanup_on_fail, null)
  max_history                = try(var.ecr.max_history, null)
  atomic                     = try(var.ecr.atomic, null)
  skip_crds                  = try(var.ecr.skip_crds, null)
  render_subchart_notes      = try(var.ecr.render_subchart_notes, null)
  disable_openapi_validation = try(var.ecr.disable_openapi_validation, null)
  wait                       = try(var.ecr.wait, false)
  wait_for_jobs              = try(var.ecr.wait_for_jobs, null)
  dependency_update          = try(var.ecr.dependency_update, null)
  replace                    = try(var.ecr.replace, null)
  lint                       = try(var.ecr.lint, null)

  postrender = try(var.ecr.postrender, [])

  set = concat([
    {
      # shortens pod name from `ack-ecr-ecr-chart-xxxxxxxxxxxxx` to `ack-ecr-xxxxxxxxxxxxx`
      name  = "nameOverride"
      value = "ack-ecr"
    },
    {
      name  = "aws.region"
      value = local.region
    },
    {
      name  = "serviceAccount.name"
      value = local.ecr_name
    }],
    try(var.ecr.set, [])
  )
  set_sensitive = try(var.ecr.set_sensitive, [])

  # IAM role for service account (IRSA)
  set_irsa_names                = ["serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role                   = try(var.ecr.create_role, true)
  role_name                     = try(var.ecr.role_name, "ack-ecr")
  role_name_use_prefix          = try(var.ecr.role_name_use_prefix, true)
  role_path                     = try(var.ecr.role_path, "/")
  role_permissions_boundary_arn = lookup(var.ecr, "role_permissions_boundary_arn", null)
  role_description              = try(var.ecr.role_description, "IRSA for ECR controller for ACK")
  role_policies = lookup(var.ecr, "role_policies", {
    AmazonEC2ContainerRegistryFullAccess = "${local.iam_role_policy_prefix}/AmazonEC2ContainerRegistryFullAccess"
  })
  create_policy = try(var.ecr.create_policy, false)

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.ecr_name
    }
  }

  tags = var.tags
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

  # public.ecr.aws/aws-controllers-k8s/sns-chart:1.0.12
  name             = try(var.sns.name, local.sns_name)
  description      = try(var.sns.description, "Helm Chart for SNS controller for ACK")
  namespace        = try(var.sns.namespace, "ack-system")
  create_namespace = try(var.sns.create_namespace, true)
  chart            = "sns-chart"
  chart_version    = try(var.sns.chart_version, "1.0.12")
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
    AmazonSNSFullAccess = "${local.iam_role_policy_prefix}/AmazonSNSFullAccess"
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

  # public.ecr.aws/aws-controllers-k8s/sqs-chart:1.0.15
  name             = try(var.sqs.name, local.sqs_name)
  description      = try(var.sqs.description, "Helm Chart for SQS controller for ACK")
  namespace        = try(var.sqs.namespace, "ack-system")
  create_namespace = try(var.sqs.create_namespace, true)
  chart            = "sqs-chart"
  chart_version    = try(var.sqs.chart_version, "1.0.15")
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
    AmazonSQSFullAccess = "${local.iam_role_policy_prefix}/AmazonSQSFullAccess"
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
  role_policies                 = lookup(var.lambda, "role_policies", {})

  create_policy           = try(var.lambda.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.lambda[*].json
  policy_statements       = lookup(var.lambda, "policy_statements", [])
  policy_name             = try(var.lambda.policy_name, null)
  policy_name_use_prefix  = try(var.lambda.policy_name_use_prefix, true)
  policy_path             = try(var.lambda.policy_path, null)
  policy_description      = try(var.lambda.policy_description, "IAM Policy for Lambda controller for ACK")


  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.lambda_name
    }
  }

  tags = var.tags
}

# recommended lambda-controller policy https://github.com/aws-controllers-k8s/lambda-controller/blob/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "lambda" {
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

  # public.ecr.aws/aws-controllers-k8s/iam-chart:1.3.11
  name             = try(var.iam.name, local.iam_name)
  description      = try(var.iam.description, "Helm Chart for iam controller for ACK")
  namespace        = try(var.iam.namespace, "ack-system")
  create_namespace = try(var.iam.create_namespace, true)
  chart            = "iam-chart"
  chart_version    = try(var.iam.chart_version, "1.3.11")
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
  role_policies                 = lookup(var.iam, "role_policies", {})

  create_policy           = try(var.iam.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.iam[*].json
  policy_statements       = lookup(var.iam, "policy_statements", [])
  policy_name             = try(var.iam.policy_name, null)
  policy_name_use_prefix  = try(var.iam.policy_name_use_prefix, true)
  policy_path             = try(var.iam.policy_path, null)
  policy_description      = try(var.iam.policy_description, "IAM Policy for IAM controller for ACK")

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
data "aws_iam_policy_document" "iam" {
  count = var.enable_iam ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
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
      "iam:UpdateAssumeRolePolicy",
    ]

    resources = ["*"]
  }
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

  # public.ecr.aws/aws-controllers-k8s/ec2-chart:1.2.16
  name             = try(var.ec2.name, local.ec2_name)
  description      = try(var.ec2.description, "Helm Chart for ec2 controller for ACK")
  namespace        = try(var.ec2.namespace, "ack-system")
  create_namespace = try(var.ec2.create_namespace, true)
  chart            = "ec2-chart"
  chart_version    = try(var.ec2.chart_version, "1.2.16")
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

  # public.ecr.aws/aws-controllers-k8s/eks-chart:1.4.4
  name             = try(var.eks.name, local.eks_name)
  description      = try(var.eks.description, "Helm Chart for eks controller for ACK")
  namespace        = try(var.eks.namespace, "ack-system")
  create_namespace = try(var.eks.create_namespace, true)
  chart            = "eks-chart"
  chart_version    = try(var.eks.chart_version, "1.4.4")
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
  role_policies                 = lookup(var.eks, "role_policies", {})

  create_policy           = try(var.eks.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.eks[*].json
  policy_statements       = lookup(var.eks, "policy_statements", [])
  policy_name             = try(var.eks.policy_name, null)
  policy_name_use_prefix  = try(var.eks.policy_name_use_prefix, true)
  policy_path             = try(var.eks.policy_path, null)
  policy_description      = try(var.eks.policy_description, "IAM Policy for EKS controller for ACK")

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
data "aws_iam_policy_document" "eks" {
  count = var.enable_eks ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "eks:*",
      "iam:GetRole",
      "iam:PassRole",
    ]
    resources = ["*"]
  }
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

  # public.ecr.aws/aws-controllers-k8s/kms-chart:1.0.15
  name             = try(var.kms.name, local.kms_name)
  description      = try(var.kms.description, "Helm Chart for kms controller for ACK")
  namespace        = try(var.kms.namespace, "ack-system")
  create_namespace = try(var.kms.create_namespace, true)
  chart            = "kms-chart"
  chart_version    = try(var.kms.chart_version, "1.0.15")
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
  role_policies                 = lookup(var.kms, "role_policies", {})

  create_policy           = try(var.kms.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.kms[*].json
  policy_statements       = lookup(var.kms, "policy_statements", [])
  policy_name             = try(var.kms.policy_name, null)
  policy_name_use_prefix  = try(var.kms.policy_name_use_prefix, true)
  policy_path             = try(var.kms.policy_path, null)
  policy_description      = try(var.kms.policy_description, "IAM Policy for KMS controller for ACK")

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
data "aws_iam_policy_document" "kms" {
  count = var.enable_kms ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
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
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
  }
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

  # public.ecr.aws/aws-controllers-k8s/acm-chart:0.0.18
  name             = try(var.acm.name, local.acm_name)
  description      = try(var.acm.description, "Helm Chart for acm controller for ACK")
  namespace        = try(var.acm.namespace, "ack-system")
  create_namespace = try(var.acm.create_namespace, true)
  chart            = "acm-chart"
  chart_version    = try(var.acm.chart_version, "0.0.18")
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
  role_policies                 = lookup(var.acm, "role_policies", {})

  create_policy           = try(var.acm.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.acm[*].json
  policy_statements       = lookup(var.acm, "policy_statements", [])
  policy_name             = try(var.acm.policy_name, null)
  policy_name_use_prefix  = try(var.acm.policy_name_use_prefix, true)
  policy_path             = try(var.acm.policy_path, null)
  policy_description      = try(var.acm.policy_description, "IAM Policy for ACM controller for ACK")

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
data "aws_iam_policy_document" "acm" {
  count = var.enable_acm ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:RequestCertificate",
      "acm:UpdateCertificateOptions",
      "acm:DeleteCertificate",
      "acm:AddTagsToCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:ListTagsForCertificate",
    ]
    resources = ["*"]
  }

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

  # public.ecr.aws/aws-controllers-k8s/apigatewayv2-chart:1.0.15
  name             = try(var.apigatewayv2.name, local.apigatewayv2_name)
  description      = try(var.apigatewayv2.description, "Helm Chart for apigatewayv2 controller for ACK")
  namespace        = try(var.apigatewayv2.namespace, "ack-system")
  create_namespace = try(var.apigatewayv2.create_namespace, true)
  chart            = "apigatewayv2-chart"
  chart_version    = try(var.apigatewayv2.chart_version, "1.0.15")
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

  # public.ecr.aws/aws-controllers-k8s/dynamodb-chart:1.2.13
  name             = try(var.dynamodb.name, local.dynamodb_name)
  description      = try(var.dynamodb.description, "Helm Chart for dynamodb controller for ACK")
  namespace        = try(var.dynamodb.namespace, "ack-system")
  create_namespace = try(var.dynamodb.create_namespace, true)
  chart            = "dynamodb-chart"
  chart_version    = try(var.dynamodb.chart_version, "1.2.13")
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

  # public.ecr.aws/aws-controllers-k8s/s3-chart:1.0.15
  name             = try(var.s3.name, local.s3_name)
  description      = try(var.s3.description, "Helm Chart for s3 controller for ACK")
  namespace        = try(var.s3.namespace, "ack-system")
  create_namespace = try(var.s3.create_namespace, true)
  chart            = "s3-chart"
  chart_version    = try(var.s3.chart_version, "1.0.15")
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

  # public.ecr.aws/aws-controllers-k8s/rds-chart:1.4.3
  name             = try(var.rds.name, local.rds_name)
  description      = try(var.rds.description, "Helm Chart for rds controller for ACK")
  namespace        = try(var.rds.namespace, "ack-system")
  create_namespace = try(var.rds.create_namespace, true)
  chart            = "rds-chart"
  chart_version    = try(var.rds.chart_version, "1.4.3")
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

  # public.ecr.aws/aws-controllers-k8s/prometheusservice-chart:1.2.13
  name             = try(var.prometheusservice.name, local.prometheusservice_name)
  description      = try(var.prometheusservice.description, "Helm Chart for prometheusservice controller for ACK")
  namespace        = try(var.prometheusservice.namespace, "ack-system")
  create_namespace = try(var.prometheusservice.create_namespace, true)
  chart            = "prometheusservice-chart"
  chart_version    = try(var.prometheusservice.chart_version, "1.2.13")
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
  role_policies                 = lookup(var.prometheusservice, "role_policies", {})

  create_policy           = try(var.prometheusservice.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.prometheusservice[*].json
  policy_statements       = lookup(var.prometheusservice, "policy_statements", [])
  policy_name             = try(var.prometheusservice.policy_name, null)
  policy_name_use_prefix  = try(var.prometheusservice.policy_name_use_prefix, true)
  policy_path             = try(var.prometheusservice.policy_path, null)
  policy_description      = try(var.prometheusservice.policy_description, "IAM Policy for Prometheus Service controller for ACK")

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.prometheusservice_name
    }
  }

  tags = var.tags
}

# recommended prometheusservice-controller policy https://github.com/aws-controllers-k8s/prometheusservice-controller/blob/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "prometheusservice" {
  count = var.enable_prometheusservice ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "aps:*",
      "logs:CreateLogDelivery",
      "logs:DescribeLogGroups",
      "logs:DescribeResourcePolicies",
      "logs:PutResourcePolicy",
    ]

    resources = ["*"]
  }
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

  # public.ecr.aws/aws-controllers-k8s/emrcontainers-chart:1.0.12
  name             = try(var.emrcontainers.name, local.emrcontainers_name)
  description      = try(var.emrcontainers.description, "Helm Chart for emrcontainers controller for ACK")
  namespace        = try(var.emrcontainers.namespace, "ack-system")
  create_namespace = try(var.emrcontainers.create_namespace, true)
  chart            = "emrcontainers-chart"
  chart_version    = try(var.emrcontainers.chart_version, "1.0.12")
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
  role_policies                 = lookup(var.emrcontainers, "role_policies", {})

  create_policy           = try(var.emrcontainers.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.emrcontainers[*].json
  policy_statements       = lookup(var.emrcontainers, "policy_statements", [])
  policy_name             = try(var.emrcontainers.policy_name, null)
  policy_name_use_prefix  = try(var.emrcontainers.policy_name_use_prefix, true)
  policy_path             = try(var.emrcontainers.policy_path, null)
  policy_description      = try(var.emrcontainers.policy_description, "IAM Policy for EMR Containers controller for ACK")

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.emrcontainers_name
    }
  }

  tags = var.tags
}

# recommended emrcontainers-controller policy https://github.com/aws-controllers-k8s/emrcontainers-controller/blob/main/config/iam/recommended-inline-policy
data "aws_iam_policy_document" "emrcontainers" {
  count = var.enable_emrcontainers ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole",
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
      "emr-containers:DeleteVirtualCluster",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "emr-containers:StartJobRun",
      "emr-containers:ListJobRuns",
      "emr-containers:DescribeJobRun",
      "emr-containers:CancelJobRun",
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
      "elasticmapreduce:GetPersistentAppUIPresignedURL",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:Get*",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
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

  # public.ecr.aws/aws-controllers-k8s/sfn-chart:1.0.13
  name             = try(var.sfn.name, local.sfn_name)
  description      = try(var.sfn.description, "Helm Chart for sfn controller for ACK")
  namespace        = try(var.sfn.namespace, "ack-system")
  create_namespace = try(var.sfn.create_namespace, true)
  chart            = "sfn-chart"
  chart_version    = try(var.sfn.chart_version, "1.0.13")
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
    AWSStepFunctionsFullAccess = "${local.iam_role_policy_prefix}/AWSStepFunctionsFullAccess"
  })

  create_policy           = try(var.sfn.create_policy, true)
  source_policy_documents = data.aws_iam_policy_document.sfn[*].json
  policy_statements       = lookup(var.sfn, "policy_statements", [])
  policy_name             = try(var.sfn.policy_name, null)
  policy_name_use_prefix  = try(var.sfn.policy_name_use_prefix, true)
  policy_path             = try(var.sfn.policy_path, null)
  policy_description      = try(var.sfn.policy_description, "IAM Policy for SFN controller for ACK")

  oidc_providers = {
    this = {
      provider_arn = local.oidc_provider_arn
      # namespace is inherited from chart
      service_account = local.sfn_name
    }
  }

  tags = var.tags
}

# recommended sfn-controller policy https://github.com/aws-controllers-k8s/sfn-controller/blob/main/config/iam/recommended-policy-arn
data "aws_iam_policy_document" "sfn" {
  count = var.enable_sfn ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ack-sfn-execution-role"
    ]
  }

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

  # public.ecr.aws/aws-controllers-k8s/eventbridge-chart:1.0.13
  name             = try(var.eventbridge.name, local.eventbridge_name)
  description      = try(var.eventbridge.description, "Helm Chart for eventbridge controller for ACK")
  namespace        = try(var.eventbridge.namespace, "ack-system")
  create_namespace = try(var.eventbridge.create_namespace, true)
  chart            = "eventbridge-chart"
  chart_version    = try(var.eventbridge.chart_version, "1.0.13")
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
