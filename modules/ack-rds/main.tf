locals {
  name                 = "ack-rds"
  service_account_name = "ack-rds-sa"
  default_helm_config = {
    name             = local.name
    chart            = "rds-chart"
    repository       = "oci://public.ecr.aws/aws-controllers-k8s"
    version          = "v0.1.1"
    namespace        = local.name
    create_namespace = true
    values           = [templatefile("${path.module}/values.yaml", {})]
    description      = "ACK rds Controller Helm chart deployment configuration"
  }

  set_values = [{
    name  = "serviceAccount.name"
    value = local.service_account_name
    },
    {
      name  = "serviceAccount.create"
      value = false
    },
    {
      name  = "aws.region"
      value = var.addon_context.aws_region_name
    }
  ]

  irsa_config = {
    kubernetes_namespace              = local.helm_config["namespace"]
    kubernetes_service_account        = local.service_account_name
    create_kubernetes_namespace       = try(local.helm_config["create_namespace"], true)
    create_kubernetes_service_account = true
    irsa_iam_policies                 = [data.aws_iam_policy.rds_fullaccess.arn]
  }

  helm_config = merge(local.default_helm_config, var.helm_config)
}

#-------------------------------------------------
# ACK API Gateway Controller V2 Helm Add-on
#-------------------------------------------------
module "helm_addon" {
  source        = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons/helm-addon"
  helm_config   = local.helm_config
  irsa_config   = local.irsa_config
  set_values    = local.set_values
  addon_context = var.addon_context
}

data "aws_iam_policy" "rds_fullaccess" {
  name = "AmazonRDSFullAccess"
}
