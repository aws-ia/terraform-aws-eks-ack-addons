module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.18.1"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  #---------------------------------------
  # Amazon EKS Managed Add-ons
  #---------------------------------------
  enable_amazon_eks_vpc_cni            = true
  enable_amazon_eks_coredns            = true
  enable_amazon_eks_kube_proxy         = true
  enable_amazon_eks_aws_ebs_csi_driver = true

  enable_aws_load_balancer_controller = true
  enable_cert_manager                 = true
  #---------------------------------------
  # Metrics Server
  #---------------------------------------
  enable_metrics_server = true
  metrics_server_helm_config = {
    name       = "metrics-server"
    repository = "https://kubernetes-sigs.github.io/metrics-server/" # (Optional) Repository URL where to locate the requested chart.
    chart      = "metrics-server"
    version    = "3.8.2"
    namespace  = "kube-system"
    timeout    = "300"
    values = [templatefile("${path.module}/helm-values/metrics-server-values.yaml", {
      operating_system = "linux"
    })]
  }

  #---------------------------------------
  # Cluster Autoscaler
  #---------------------------------------
  enable_cluster_autoscaler = true
  cluster_autoscaler_helm_config = {
    name       = "cluster-autoscaler"
    repository = "https://kubernetes.github.io/autoscaler" # (Optional) Repository URL where to locate the requested chart.
    chart      = "cluster-autoscaler"
    version    = "9.15.0"
    namespace  = "kube-system"
    timeout    = "300"
    values = [templatefile("${path.module}/helm-values/cluster-autoscaler-values.yaml", {
      aws_region       = var.region,
      eks_cluster_id   = local.name,
      operating_system = "linux"
    })]
  }

  #---------------------------------------
  # CloudWatch metrics for EKS
  #---------------------------------------
  enable_aws_cloudwatch_metrics = true
  aws_cloudwatch_metrics_helm_config = {
    name       = "aws-cloudwatch-metrics"
    chart      = "aws-cloudwatch-metrics"
    repository = "https://aws.github.io/eks-charts"
    version    = "0.0.7"
    namespace  = "amazon-cloudwatch"
    values = [templatefile("${path.module}/helm-values/aws-cloudwatch-metrics-valyes.yaml", {
      eks_cluster_id = var.name
    })]
  }

  #---------------------------------------
  # AWS for FluentBit - DaemonSet
  #---------------------------------------
  enable_aws_for_fluentbit = true
  aws_for_fluentbit_helm_config = {
    name                                      = "aws-for-fluent-bit"
    chart                                     = "aws-for-fluent-bit"
    repository                                = "https://aws.github.io/eks-charts"
    version                                   = "0.1.21"
    namespace                                 = "aws-for-fluent-bit"
    aws_for_fluent_bit_cw_log_group           = "/${var.name}/worker-fluentbit-logs" # Optional
    aws_for_fluentbit_cwlog_retention_in_days = 90
    values = [templatefile("${path.module}/helm-values/aws-for-fluentbit-values.yaml", {
      region                    = var.region,
      aws_for_fluent_bit_cw_log = "/${var.name}/worker-fluentbit-logs"
    })]
  }

  tags = local.tags
}

################################################################################
# ACK Addons
################################################################################
module "eks_ack_addons" {

  source = "github.com/aws-ia/terraform-aws-eks-ack-addons"

  cluster_id          = module.eks_blueprints.eks_cluster_id
  data_plane_wait_arn = module.eks_blueprints.managed_node_group_arn[0] # Wait for data plane to be ready

  ecrpublic_username = data.aws_ecrpublic_authorization_token.token.user_name
  ecrpublic_token    = data.aws_ecrpublic_authorization_token.token.password

  enable_sfn = true

  tags = local.tags
}