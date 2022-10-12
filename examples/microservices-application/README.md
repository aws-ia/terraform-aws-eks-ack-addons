# ACK example - Microservice Development in Kubernetes using ACK

This example deploys the following components:

- Creates a new sample VPC, 3 Private Subnets and 3 Public Subnets
- Creates Internet gateway for Public Subnets and NAT Gateway for Private Subnets
- Creates EKS Cluster Control plane with one managed node group
- Enable EKS Managed Add-ons: VPC_CNI, CoreDNS, Kube_Proxy, EBS_CSI_Driver
- Install ALB controller and ACK controllers for API Gateway and DynamoDB
- API Gateway VpcLink
- DynamoDB read/write IAM role for sample API application

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
cd examples/microservices-application/
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

#### Step 6: Update app.yaml file and deploy
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-api-dynamodb
  namespace: ack-demo
....

    env:
    - name: tableName     # match with your DynamoDB table setting
        value: "<your table name>"
    - name: aws_region
        value: "<same region as your eks cluster>"
```

```sh
kubectl apply -f sample-app/app.yaml
```

Get the newly deployed ALB listener arn

```sh
aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(DNSName, '$(kubectl get ingress ingress-api-dynamodb -n ack-demo -o=jsonpath="{.status.loadBalancer.ingress[].hostname}")')].LoadBalancerArn" \
  --output text) \
  --query "Listeners[0].ListenerArn" \
  --output text
```
#### Step 7: Update apigwv2-httpapi.yaml file and deploy

```yaml
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: Integration
metadata:
  name: "vpc-integration"
spec:
  apiRef:
    from:
      name: "ack-api"
  integrationType: HTTP_PROXY
  integrationURI: "<your ALB listener arn>"
  integrationMethod: ANY
  payloadFormatVersion: "1.0"
  connectionID: "<your vpclink id>" # apigw_vpclink_id in terraform output
  connectionType: "VPC_LINK"
```

```sh
kubectl apply -f apigwv2-httpapi.yaml
```
#### Step 8: Update dynamodb-table.yaml file and deploy

```yaml
apiVersion: dynamodb.services.k8s.aws/v1alpha1
kind: Table
metadata:
  name: ack-demo
  namespace: ack-dynamo
spec:
  keySchema:
    - attributeName: Id
      keyType: HASH
  attributeDefinitions:
    - attributeName: Id
      attributeType: 'S'
  provisionedThroughput:
    readCapacityUnits: 1
    writeCapacityUnits: 1
  tableName: "<your table name>" # match with the table name used by sample application
```

```sh
kubectl apply -f dynamodb-table.yaml
```

#### Step 9: Test API
Get your api domain

```sh
kubectl get -n ack-demo api ack-api -o jsonpath="{.status.apiEndpoint}"
```

then post data to dynamodb with post and query data with get

post {your api domain}/rows/add with json payload { "name": "external" }

get {your api domain}/rows/all

## Cleanup

To clean up your environment, destroy the Terraform modules in reverse order.

Destroy the Kubernetes Add-ons, EKS cluster with Node groups and VPC

```sh
terraform destroy -target="module.eks_ack_controllers" -auto-approve
terraform destroy -target="module.eks_blueprints_kubernetes_addons" -auto-approve
terraform destroy -target="module.eks_blueprints" -auto-approve
terraform destroy -target="module.vpc" -auto-approve
```

Finally, destroy any additional resources that are not in the above modules

```sh
terraform destroy -auto-approve
```
