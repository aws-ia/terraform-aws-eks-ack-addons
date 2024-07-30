terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13"
    }
  }
}
