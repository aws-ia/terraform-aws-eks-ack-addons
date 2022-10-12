# Existing Cluster with EKS Blueprints ACK module
This example demonstrates how to use EKS Blueprints ACK module with your existing EKS.
If you don't have an EKS cluster yet, please refer to [EKS cluster with ack module example](./ack-eks-cluster-with-vpc/).


## Prerequisites

Ensure that you have the following tools installed locally:

1. [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. [kubectl](https://kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Setup
1. Clone the repo using the command below
```sh
git clone https://github.com/aws-ia/terraform-aws-eks-ack-addons.git
```

2. Initialize terraform

```sh
cd examples/ack-existing-cluster
terraform init
```

3. Review and update the base.tfvars
Create a Terraform variable definition file called base.tfvars and update the values for the variables. The following shows an example for the variables for ACK module.
```sh
aws_region           = "us-west-2"
eks_cluster_id       = "<your eks cluster name>"
eks_cluster_endpoint = "https://xxxxxxxxxxxxxxxxx.sk1.us-west-2.eks.amazonaws.com"
eks_oidc_provider    = "https://oidc.eks.us-west-2.amazonaws.com/id/xxxxxxxxxxxxxxxxx"
eks_cluster_version  = "1.22"
```

## Deploy

```sh
terraform apply -var-file base.tfvars
```

Enter `yes` to apply

Note : Once the stack completes, you will see an output of the vpc-id and the private subnets for the eks-vpc. Note them so we can use them in the EKS Terraform stack.

## Cleanup

```sh
terraform destroy -var-file base.tfvars -auto-approve
```
