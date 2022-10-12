# ACK example - Microservice Development in Kubernetes using ACK

This example deploys the following components:

- Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
- Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
- Creates EKS Cluster Control plane with one managed node group
- Enable EKS Managed Add-ons: VPC_CNI, CoreDNS, Kube_Proxy, EBS_CSI_Driver
- Install ALB controller and ACK controllers

## How to Deploy

### Prerequisites

Ensure that you have installed the following tools in your Mac or Windows Laptop before start working with this module and run Terraform Plan and Apply

1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [Kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)


### Deployment Steps

#### Step 1: Clone the repo using the command below

```sh
git clone https://github.com/aws-ia/terraform-aws-eks-ack-addons.git
```

#### Step 2: Run Terraform INIT

Initialize a working directory with configuration files

```sh
cd examples/ack-eks-cluster-with-vpc/
terraform init
```

#### Step 3: Run Terraform PLAN

Verify the resources created by this execution

```sh
export AWS_REGION=<ENTER YOUR REGION>   # Select your own region
terraform plan
```

#### Step 4: Finally, Terraform APPLY

**Deploy the pattern**

```sh
terraform apply
```

Enter `yes` to apply.

### Configure `kubectl` and test cluster

EKS Cluster details can be extracted from terraform output or from AWS Console to get the name of cluster.
This following command used to update the `kubeconfig` in your local machine where you run kubectl commands to interact with your EKS Cluster.

#### Step 5: Run `update-kubeconfig` command

`~/.kube/config` file gets updated with cluster details and certificate from the below command

    aws eks --region <enter-your-region> update-kubeconfig --name <cluster-name>

#### Step 6: Run `kubectl get pods -A` command

Verify ACK controllers for the services that are enabled are running.


```sh
kubectl get pods -A

NAMESPACE      NAME                                          READY   STATUS    RESTARTS        AGE
ack-apigw      ack-apigw-apigatewayv2-chart-555c4c78-mhldg   1/1     Running   0               18s
ack-dynamodb   ack-dynamodb-dynamodb-chart-5565c975d-5gkwl   1/1     Running   0               21s
ack-rds        ack-rds-rds-chart-777c864d89-prz6k            1/1     Running   0               19s
ack-s3         ack-s3-s3-chart-d8677478f-4g78p               1/1     Running   0               23s
kube-system    aws-node-2jgp6                                1/1     Running   1 (2m56s ago)   4m49s
kube-system    aws-node-7rx5z                                1/1     Running   1 (2m57s ago)   4m47s
kube-system    aws-node-bsrgz                                1/1     Running   1 (2m50s ago)   4m48s
kube-system    coredns-d5b9bfc4-ldsq7                        1/1     Running   0               12m
kube-system    coredns-d5b9bfc4-txx29                        1/1     Running   0               12m
kube-system    kube-proxy-knsm4                              1/1     Running   0               4m49s
kube-system    kube-proxy-lcncg                              1/1     Running   0               4m48s
kube-system    kube-proxy-lt2dw                              1/1     Running   0               4m47s
```

## Cleanup

To clean up your environment, destroy the Terraform modules in reverse order.

Destroy the Kubernetes Add-ons, EKS cluster with Node groups and VPC

```sh
terraform destroy -target="module.eks_ack_controllers" -auto-approve
terraform destroy -target="module.eks_blueprints" -auto-approve
terraform destroy -target="module.vpc" -auto-approve
```

Finally, destroy any additional resources that are not in the above modules

```sh
terraform destroy -auto-approve
```
