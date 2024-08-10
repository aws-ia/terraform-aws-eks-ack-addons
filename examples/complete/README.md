# Complete Example

Configuration in this directory creates an AWS EKS cluster with the following ACK addons:
- Amazon Kafka
- Amazon EFS
- Amazon ECS
- Amazon CloudTrail
- Amazon CloudFront
- Amazon Application Auto Scaling
- Amazon ACM Controller
- Amazon ApiGatewayV2 Controller
- Amazon DynamoDB Controller
- Amazon EC2 Controller
- Amazon ECR Controller
- Amazon EKS Controller
- Amazon ElastiCache Controller
- Amazon EMR Containers Controller
- Amazon EventBridge Controller
- Amazon IAM Controller
- Amazon KMS Controller
- AWS Lambda Controller
- Amazon MemoryDB Controller
- Amazon OpenSearch Service Controller
- Amazon Prometheus Service Controller
- Amazon RDS Controller
- Amazon S3 Controller
- Amazon SageMaker Controller
- AWS SFN Controller
- Amazon SNS Controller
- Amazon SQS Controller

In addition, this example provisions a sample application which demonstrates using the ACK controllers for resource provisioning.
The arhchitecture looks like this: <br>
![overall architecture](images/ACK_microservice.png)

## Prerequisites:

Ensure that you have the following tools installed locally:

1. [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. [kubectl](https://Kubernetes.io/docs/tasks/tools/)
3. [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Deploy

To provision this example:

```sh
terraform init
terraform apply -var aws_region=<aws_region> # defaults to us-west-2
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

NAMESPACE     NAME                                            READY   STATUS    RESTARTS   AGE
ack-system    ack-acm-5697f4c5b4-bpkrg                        1/1     Running   0          10m
ack-system    ack-apigatewayv2-76d6bbd788-82m2h               1/1     Running   0          9m37s
ack-system    ack-applicationautoscaling-5fd6c8bf8f-kl4gt     1/1     Running   0          8m58s
ack-system    ack-cloudfront-544f4887c4-dr6ds                 1/1     Running   0          8m12s
ack-system    ack-cloudtrail-5dc78b7576-hnk4d                 1/1     Running   0          10m
ack-system    ack-dynamodb-7f4b47488d-tftpf                   1/1     Running   0          8m37s
ack-system    ack-ec2-5fbf6f55d9-smb4k                        1/1     Running   0          9m37s
ack-system    ack-ecr-5b4699f87b-j6kxq                        1/1     Running   0          9m7s
ack-system    ack-ecs-74d8d67695-dbpth                        1/1     Running   0          10m
ack-system    ack-efs-7b9f965b96-rpwts                        1/1     Running   0          9m54s
ack-system    ack-eks-54945d94d4-6stzs                        1/1     Running   0          8m34s
ack-system    ack-elasticache-5758ff66bd-dwfkh                1/1     Running   0          10m
ack-system    ack-emrcontainers-74c5d7b8c-bljlk               1/1     Running   0          10m
ack-system    ack-eventbridge-b76bd85b8-rxgsf                 1/1     Running   0          9m46s
ack-system    ack-iam-89dd5d6b5-2hzch                         1/1     Running   0          8m24s
ack-system    ack-kafka-7bd95bd59-pz258                       1/1     Running   0          9m40s
ack-system    ack-kms-58b89848db-p4w6c                        1/1     Running   0          8m21s
ack-system    ack-lambda-65bd7fbc8d-529d7                     1/1     Running   0          10m
ack-system    ack-memorydb-76c988f6dd-phbsc                   1/1     Running   0          8m7s
ack-system    ack-opensearchservice-7fd9d8c866-fg6h6          1/1     Running   0          8m33s
ack-system    ack-prometheusservice-6d657cd878-kcdsh          1/1     Running   0          9m58s
ack-system    ack-rds-7df84bf989-87j4s                        1/1     Running   0          9m31s
ack-system    ack-s3-6ffc4698c6-kg8vw                         1/1     Running   0          8m28s
ack-system    ack-sagemaker-74f65d4cb9-dzxng                  1/1     Running   0          8m24s
ack-system    ack-sfn-6b875794cb-k7dnb                        1/1     Running   0          10m
ack-system    ack-sns-5c75794dbc-6n42j                        1/1     Running   0          10m
ack-system    ack-sqs-55dfc46cd6-n6qb8                        1/1     Running   0          10m
kube-system   aws-load-balancer-controller-84b5bf9c5f-k88tj   1/1     Running   0          10m
kube-system   aws-load-balancer-controller-84b5bf9c5f-xqczl   1/1     Running   0          10m
kube-system   aws-node-6kswr                                  2/2     Running   0          8m22s
kube-system   aws-node-8fkb7                                  2/2     Running   0          8m26s
kube-system   aws-node-c482x                                  2/2     Running   0          8m18s
kube-system   coredns-787cb67946-lsxph                        1/1     Running   0          14m
kube-system   coredns-787cb67946-zbq6s                        1/1     Running   0          14m
kube-system   eks-pod-identity-agent-6b2bc                    1/1     Running   0          8m39s
kube-system   eks-pod-identity-agent-b8gh8                    1/1     Running   0          8m39s
kube-system   eks-pod-identity-agent-cq5kr                    1/1     Running   0          8m39s
kube-system   kube-proxy-6jn9z                                1/1     Running   0          10m
kube-system   kube-proxy-6mfvr                                1/1     Running   0          10m
kube-system   kube-proxy-k4c6w                                1/1     Running   0          10m
kube-system   metrics-server-7577444cf8-f4vgk                 1/1     Running   0          11m
```

## Sample Application Deployment

1. Update `sample-app/app.yaml` file and deploy:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-api-dynamodb
  namespace: ack-demo
    ... <Truncated for brevity>
    env:
    - name: tableName     # match with your dynamodb table setting
        value: ack-demo-table
    - name: aws_region
        value: "<same region as your eks cluster>"
```

```sh
kubectl apply -f sample-app/app.yaml
```

Note: app.yaml deploys a simple nodeJS image from docker hub. The source code can be found [here](https://github.com/season1946/ack-microservices/tree/main/sample-app-code)

2. Get the listener ARN of the provisioned ALB:

```sh
aws elbv2 describe-listeners \
  --region <aws_region> \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
  --region <aws_region> \
  --query "LoadBalancers[?contains(DNSName, '$(kubectl get ingress ingress-api-dynamodb -n ack-demo -o=jsonpath="{.status.loadBalancer.ingress[].hostname}")')].LoadBalancerArn" \
  --output text) \
  --query "Listeners[0].ListenerArn" \
  --output text
```

> Replace `<aws_region>` in the command above with the correspoding region you deployed the cluster

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
  connectionID: '<your vpclink id>' # api_gatewayv2_vpc_link_id in Terraform output
  connectionType: 'VPC_LINK'
```

```sh
kubectl apply -f sample-app/apigwv2-httpapi.yaml
```

Verify the status
```sh
echo API=$(kubectl get api.apigatewayv2.services.k8s.aws/ack-api -o jsonpath='{.status.conditions[?(@.type=="ACK.ResourceSynced")].status}')
echo Stage=$(kubectl get stage.apigatewayv2.services.k8s.aws/default-stage -o jsonpath='{.status.conditions[?(@.type=="ACK.ResourceSynced")].status}')
echo Route=$(kubectl get route.apigatewayv2.services.k8s.aws/ack-route-vpclink -o jsonpath='{.status.conditions[?(@.type=="ACK.ResourceSynced")].status}')
echo Integration=$(kubectl get integration.apigatewayv2.services.k8s.aws/vpc-integration -o jsonpath='{.status.conditions[?(@.type=="ACK.ResourceSynced")].status}')
```

Expected output
```
API=True
Stage=True
Route=True
Integration=True
```

4. Deploy DynamoDB table

```sh
kubectl apply -f sample-app/dynamodb-table.yaml
```

Verify the status
```sh
echo DynamoDB=$(kubectl get table.dynamodb.services.k8s.aws/ack-demo -o jsonpath='{.status.conditions[?(@.type=="ACK.ResourceSynced")].status}')
```

Expected output
```
DynamoDB=True
```

5. Test the API created. Get the api domain:

```sh
kubectl get -n ack-demo api ack-api -o jsonpath="{.status.apiEndpoint}"
```

6. Post data to dynamodb with `post` and query data with `get`

```
curl -X POST \
 -H 'Content-Type: application/json' \
 -d '{ "name": "external" }' \
 $(kubectl get -n ack-demo api ack-api -o jsonpath="{.status.apiEndpoint}")/rows/add

curl $(kubectl get -n ack-demo api ack-api -o jsonpath="{.status.apiEndpoint}")/rows/all
```

## Destroy

To teardown and remove the resources created in this example:

```sh
kubectl delete -f sample-app

terraform destroy -target="module.eks_ack_addons" -target="module.eks_blueprints_kubernetes_addons" -auto-approve
terraform destroy -target="module.eks_blueprints" -auto-approve
terraform destroy -auto-approve
```
