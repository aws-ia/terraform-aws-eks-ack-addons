# Complete Example

Configuration in this directory creates an AWS EKS cluster with the following ACK addons:

- ACK API Gateway controller
- ACK DynamoDB controller
- ACK RDS controller
- ACK S3 controller

In addition, this example provisions a sample application which demonstrates using the ACK controllers for resource provisioning.

## Prerequisites:

Ensure that you have the following tools installed locally:

1. [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Deploy

To provision this example:

```sh
terraform init
terraform apply
```

Enter `yes` at command prompt to apply

## Validate

The following command will update the `kubeconfig` on your local machine and allow you to interact with your EKS Cluster using `kubectl` to validate the CoreDNS deployment for Fargate.

1. Run `update-kubeconfig` command:

```sh
aws eks --region <REGION> update-kubeconfig --name <CLUSTER_NAME>
```

2. Verify ACK controllers for the services that are enabled are running:

```sh
kubectl get pods -A

NAMESPACE      NAME                                          READY   STATUS    RESTARTS        AGE
ack-apigw      ack-apigw-apigatewayv2-chart-555c4c78-mhldg   1/1     Running   0               18s
ack-dynamodb   ack-dynamodb-dynamodb-chart-5565c975d-5gkwl   1/1     Running   0               21s
ack-rds        ack-rds-rds-chart-777c864d89-prz6k            1/1     Running   0               19s
ack-s3         ack-s3-s3-chart-d8677478f-4g78p               1/1     Running   0               23s
kube-system    aws-node-2jgp6                                1/1     Running   0               4m49s
kube-system    aws-node-7rx5z                                1/1     Running   0               4m47s
kube-system    aws-node-bsrgz                                1/1     Running   0               4m48s
kube-system    coredns-d5b9bfc4-ldsq7                        1/1     Running   0               12m
kube-system    coredns-d5b9bfc4-txx29                        1/1     Running   0               12m
kube-system    kube-proxy-knsm4                              1/1     Running   0               4m49s
kube-system    kube-proxy-lcncg                              1/1     Running   0               4m48s
kube-system    kube-proxy-lt2dw                              1/1     Running   0               4m47s
```

## Sample Application Deployment

1. Update `sample-app/app.yaml` file and deploy:

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

2. Get the listener ARN of the provisioned ALB:

```sh
aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(DNSName, '$(kubectl get ingress ingress-api-dynamodb -n ack-demo -o=jsonpath="{.status.loadBalancer.ingress[].hostname}")')].LoadBalancerArn" \
  --output text) \
  --query "Listeners[0].ListenerArn" \
  --output text
```

3. Update `sample-app/apigwv2-httpapi.yaml` file and deploy:

```yaml
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: Integration
metadata:
  name: 'vpc-integration'
spec:
  apiRef:
    from:
      name: 'ack-api'
  integrationType: HTTP_PROXY
  integrationURI: '<your ALB listener arn>'
  integrationMethod: ANY
  payloadFormatVersion: '1.0'
  connectionID: '<your vpclink id>' # apigw_vpclink_id in terraform output
  connectionType: 'VPC_LINK'
```

```sh
kubectl apply -f apigwv2-httpapi.yaml
```

4. Update `sample-app/dynamodb-table.yaml` file and deploy

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
  tableName: '<your table name>' # match with the table name used by sample application
```

```sh
kubectl apply -f dynamodb-table.yaml
```

5. Test the API created. Get the api domain:

```sh
kubectl get -n ack-demo api ack-api -o jsonpath="{.status.apiEndpoint}"
```

6. Post data to dynamodb with `post` and query data with `get`

```
post {your api domain}/rows/add with json payload { "name": "external" }

get {your api domain}/rows/all
```

## Destroy

To teardown and remove the resources created in this example:

```sh
terraform destroy -target="module.eks_ack_addons" -target="module.eks_blueprints_kubernetes_addons" -auto-approve
terraform destroy -target="module.eks_blueprints" -auto-approve
terraform destroy -auto-approve
```
