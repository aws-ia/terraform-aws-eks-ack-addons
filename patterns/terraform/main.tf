provider "aws" {
  region = local.region
}

# Required for public ECR where ACK artifacts are hosted
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name   = "${basename(path.cwd)}-ack-blueprints"
  region = var.aws_region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints-addons"
  }
}

################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.20"

  cluster_name    = local.name
  cluster_version = "1.30"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  kms_key_enable_default_policy   = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  # EKS Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      before_compute = true # Ensure the addon is configured before compute resources are created
      most_recent    = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = ["m5.large"]

      min_size     = 1
      max_size     = 5
      desired_size = 3
    }
  }

  tags = local.tags

  depends_on = [module.vpc]
}

################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Add-ons
  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true

  tags = local.tags

  depends_on = [module.eks]
}

################################################################################
# ACK Addons
################################################################################

module "eks_ack_addons" {
  source  = "aws-ia/eks-ack-addons/aws"
  version = "2.2.0"

  # Cluster Info
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  oidc_provider_arn = module.eks.oidc_provider_arn

  # ECR Credentials
  ecrpublic_username = data.aws_ecrpublic_authorization_token.token.user_name
  ecrpublic_token    = data.aws_ecrpublic_authorization_token.token.password

  # Controllers to enable
  enable_apigatewayv2      = true
  enable_dynamodb          = true
  enable_s3                = true
  enable_rds               = true
  enable_prometheusservice = true
  enable_emrcontainers     = true
  enable_sfn               = true
  enable_eventbridge       = true

  tags = local.tags

  depends_on = [module.eks_blueprints_addons]
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.9"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

# create irsa for api app read and write dynamodb
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:BatchGet*",
      "dynamodb:DescribeStream",
      "dynamodb:DescribeTable",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWrite*",
      "dynamodb:CreateTable",
      "dynamodb:Delete*",
      "dynamodb:Update*",
      "dynamodb:PutItem"
    ]
    resources = ["arn:aws:dynamodb:${local.region}:${data.aws_caller_identity.current.account_id}:table/ack-demo-table"]
  }

  statement {
    actions = [
      "dynamodb:List*",
      "dynamodb:DescribeReservedCapacity*",
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive"
    ]
    resources = ["*"]
  }
}

locals {
  app = "ack-demo"
}

resource "aws_iam_policy" "dynamodb_access" {
  name        = "${module.eks.cluster_name}-dynamodb-irsa-policy"
  description = "iam policy for dynamodb access"
  policy      = data.aws_iam_policy_document.dynamodb_access.json

  tags = local.tags
}

resource "kubernetes_namespace_v1" "ack_demo" {
  metadata {
    name = local.app
  }
}

resource "kubernetes_service_account_v1" "ack_demo" {
  metadata {
    name      = local.app
    namespace = kubernetes_namespace_v1.ack_demo.id
  }
  automount_service_account_token = false
}

module "irsa" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.1.1"

  # Disable helm release
  create_release = false

  # IAM role for service account (IRSA)
  create_role          = true
  role_name            = "${local.name}-${local.app}"
  role_name_use_prefix = true
  create_policy        = false
  role_policies = {
    DynamoDbAccess = aws_iam_policy.dynamodb_access.arn
  }

  oidc_providers = {
    this = {
      provider_arn    = module.eks.oidc_provider_arn
      namespace       = kubernetes_namespace_v1.ack_demo.id
      service_account = basename(kubernetes_service_account_v1.ack_demo.id)
    }
  }

  tags = local.tags
}

resource "aws_security_group" "vpc_link_sg" {
  name        = "${local.name}-vpc-link"
  description = "Security group for API Gateway v2 VPC link"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Ingress all from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    description = "Egress all to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  tags = local.tags
}

resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = local.name
  security_group_ids = [resource.aws_security_group.vpc_link_sg.id]
  subnet_ids         = module.vpc.private_subnets

  tags = local.tags
}
