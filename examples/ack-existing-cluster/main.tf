provider "aws" {
  region = local.region
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_id
}

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_id
}

provider "kubernetes" {
  host                   = local.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

locals {
  region               = var.aws_region
  eks_cluster_endpoint = data.aws_eks_cluster.this.endpoint

  tags = {
    Source = "github.com/aws-ia/terraform-aws-eks-ack-addons"
  }
}

# deploys the base module
module "eks_ack_controllers" {
  source = "../../"

  eks_cluster_id       = var.eks_cluster_id
  eks_cluster_endpoint = var.eks_cluster_endpoint
  eks_oidc_provider    = var.eks_oidc_provider
  eks_cluster_version  = var.eks_cluster_version

  # install ack api gateway controller and ack dynamodb controller in this example
  enable_ack-apigw    = true
  enable_ack-dynamodb = true
  enable_ack-s3       = true
  enable_ack-rds      = true

  tags = local.tags
}
