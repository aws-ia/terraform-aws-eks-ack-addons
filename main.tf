data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_eks_cluster" "this" {
  name = local.cluster_id
}

locals {
  # this makes downstream resources wait for data plane to be ready
  cluster_id = time_sleep.dataplane.triggers["cluster_id"]
  region     = data.aws_region.current.name

  eks_oidc_issuer_url = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")

  addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_eks_cluster_endpoint       = data.aws_eks_cluster.this.endpoint
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = local.region
    eks_cluster_id                 = var.cluster_id
    eks_oidc_issuer_url            = local.eks_oidc_issuer_url
    eks_oidc_provider_arn          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
    tags                           = var.tags
    irsa_iam_role_path             = var.irsa_iam_role_path
    irsa_iam_permissions_boundary  = var.irsa_iam_permissions_boundary
  }
}

resource "time_sleep" "dataplane" {
  create_duration = "10s"

  triggers = {
    data_plane_wait_arn = var.data_plane_wait_arn # this waits for the data plane to be ready
    cluster_id          = var.cluster_id          # this ties it to downstream resources
  }
}

################################################################################
# API Gateway
################################################################################

locals {
  api_gateway_name = "ack-api-gateway"
}

module "api_gateway" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.12.2"

  count = var.enable_api_gateway ? 1 : 0

  helm_config = merge(
    {
      name             = local.api_gateway_name
      chart            = "apigatewayv2-chart"
      repository       = "oci://public.ecr.aws/aws-controllers-k8s"
      version          = "v0.1.4"
      namespace        = local.api_gateway_name
      create_namespace = true
      description      = "ACK API Gateway Controller v2 Helm chart deployment configuration"
    },
    var.api_gateway_helm_config
  )

  set_values = [
    {
      name  = "serviceAccount.name"
      value = local.api_gateway_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = local.region
    }
  ]

  irsa_config = {
    create_kubernetes_namespace = false
    kubernetes_namespace        = try(var.api_gateway_helm_config.namespace, local.api_gateway_name)

    create_kubernetes_service_account = true
    kubernetes_service_account        = local.api_gateway_name

    irsa_iam_policies = [
      data.aws_iam_policy.api_gateway_invoke[0].arn,
      data.aws_iam_policy.api_gateway_admin[0].arn,
    ]
  }

  addon_context = local.addon_context
}

data "aws_iam_policy" "api_gateway_invoke" {
  count = var.enable_api_gateway ? 1 : 0

  name = "AmazonAPIGatewayInvokeFullAccess"
}

data "aws_iam_policy" "api_gateway_admin" {
  count = var.enable_api_gateway ? 1 : 0

  name = "AmazonAPIGatewayAdministrator"
}

################################################################################
# DynamoDB
################################################################################

locals {
  dynamodb_name = "ack-dynamodb"
}

module "dynamodb" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.12.2"

  count = var.enable_dynamodb ? 1 : 0

  helm_config = merge(
    {
      name             = local.dynamodb_name
      chart            = "dynamodb-chart"
      repository       = "oci://public.ecr.aws/aws-controllers-k8s"
      version          = "v0-stable"
      namespace        = local.dynamodb_name
      create_namespace = true
      description      = "ACK DynamoDB Controller v2 Helm chart deployment configuration"
    },
    var.dynamodb_helm_config
  )

  set_values = [
    {
      name  = "serviceAccount.name"
      value = local.dynamodb_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = local.region
    }
  ]

  irsa_config = {
    create_kubernetes_namespace = false
    kubernetes_namespace        = try(var.dynamodb_helm_config.namespace, local.dynamodb_name)

    create_kubernetes_service_account = true
    kubernetes_service_account        = local.dynamodb_name

    irsa_iam_policies = [data.aws_iam_policy.dynamodb[0].arn]
  }

  addon_context = local.addon_context
}

data "aws_iam_policy" "dynamodb" {
  count = var.enable_dynamodb ? 1 : 0

  name = "AmazonDynamoDBFullAccess"
}

################################################################################
# S3
################################################################################

locals {
  s3_name = "ack-s3"
}

module "s3" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.12.2"

  count = var.enable_s3 ? 1 : 0

  helm_config = merge(
    {
      name             = local.s3_name
      chart            = "s3-chart"
      repository       = "oci://public.ecr.aws/aws-controllers-k8s"
      version          = "v0.1.5"
      namespace        = local.s3_name
      create_namespace = true
      description      = "ACK S3 Controller v2 Helm chart deployment configuration"
    },
    var.s3_helm_config
  )

  set_values = [
    {
      name  = "serviceAccount.name"
      value = local.s3_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = local.region
    }
  ]

  irsa_config = {
    create_kubernetes_namespace = false
    kubernetes_namespace        = try(var.s3_helm_config.namespace, local.s3_name)

    create_kubernetes_service_account = true
    kubernetes_service_account        = local.s3_name

    irsa_iam_policies = [data.aws_iam_policy.s3[0].arn]
  }

  addon_context = local.addon_context
}

data "aws_iam_policy" "s3" {
  count = var.enable_s3 ? 1 : 0

  name = "AmazonS3FullAccess"
}

################################################################################
# RDS
################################################################################

locals {
  rds_name = "ack-rds"
}

module "rds" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.12.2"

  count = var.enable_rds ? 1 : 0

  helm_config = merge(
    {
      name             = local.rds_name
      chart            = "rds-chart"
      repository       = "oci://public.ecr.aws/aws-controllers-k8s"
      version          = "v0.1.1"
      namespace        = local.rds_name
      create_namespace = true
      description      = "ACK RDS Controller v2 Helm chart deployment configuration"
    },
    var.rds_helm_config
  )

  set_values = [
    {
      name  = "serviceAccount.name"
      value = local.rds_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = local.region
    }
  ]

  irsa_config = {
    create_kubernetes_namespace = false
    kubernetes_namespace        = try(var.rds_helm_config.namespace, local.rds_name)

    create_kubernetes_service_account = true
    kubernetes_service_account        = local.rds_name

    irsa_iam_policies = [data.aws_iam_policy.rds[0].arn]
  }

  addon_context = local.addon_context
}

data "aws_iam_policy" "rds" {
  count = var.enable_rds ? 1 : 0

  name = "AmazonRDSFullAccess"
}
