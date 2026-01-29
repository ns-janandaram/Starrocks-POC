# EKS Deployment Guide

This guide covers deploying the Kafka-to-StarRocks loader on Amazon EKS.

## Prerequisites

- AWS CLI configured with appropriate permissions
- `kubectl` installed and configured
- `eksctl` installed (optional, for cluster creation)
- Docker installed (for building images)
- An existing EKS cluster or permissions to create one

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Amazon EKS                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   data-pipeline namespace                │    │
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ │    │
│  │  │   ConfigMap     │    │      Deployment (2 pods)    │ │    │
│  │  │ tenant-whitelist│───▶│   kafka-starrocks-loader    │ │    │
│  │  └─────────────────┘    └─────────────────────────────┘ │    │
│  │                                    │                     │    │
│  │  ┌─────────────────┐               │                     │    │
│  │  │     Secret      │───────────────┘                     │    │
│  │  │ starrocks-creds │                                     │    │
│  │  └─────────────────┘                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
            │                                    │
            ▼                                    ▼
    ┌───────────────┐                   ┌───────────────┐
    │  Amazon MSK   │                   │   StarRocks   │
    │    (Kafka)    │                   │   Cluster     │
    └───────────────┘                   └───────────────┘
```

## Step 1: Create EKS Cluster (if needed)

```bash
# Create cluster with eksctl
eksctl create cluster \
  --name starrocks-loader-cluster \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4

# Verify cluster access
kubectl get nodes
```

## Step 2: Create ECR Repository

```bash
# Set variables
AWS_REGION=us-west-2
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO=kafka-starrocks-loader

# Create ECR repository
aws ecr create-repository \
  --repository-name $ECR_REPO \
  --region $AWS_REGION

# Get login token
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

## Step 3: Build and Push Docker Image

Create a `Dockerfile` in the project root:

```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /kafka-starrocks-loader ./cmd/loader

FROM alpine:3.19
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /kafka-starrocks-loader .

EXPOSE 8080
CMD ["./kafka-starrocks-loader"]
```

Build and push:

```bash
# Build image
docker build -t $ECR_REPO:latest .

# Tag for ECR
docker tag $ECR_REPO:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest
```

## Step 4: Create Kubernetes Resources

### 4.1 Create Namespace

```bash
kubectl create namespace data-pipeline
```

### 4.2 Create Secrets

```bash
# StarRocks credentials
kubectl create secret generic starrocks-credentials \
  --namespace data-pipeline \
  --from-literal=username=root \
  --from-literal=password='your-starrocks-password'

# (Optional) If using MSK with SASL authentication
kubectl create secret generic kafka-credentials \
  --namespace data-pipeline \
  --from-literal=username=kafka-user \
  --from-literal=password='your-kafka-password'
```

### 4.3 Update Deployment Image

Update the image in `deployment.yaml`:

```yaml
image: <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/kafka-starrocks-loader:latest
```

Or use sed:

```bash
sed -i "s|your-registry/kafka-starrocks-loader:latest|$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:latest|g" \
  ../k8s/deployment.yaml
```

### 4.4 Configure MSK Connection

Update the Kafka broker address in `deployment.yaml`:

```yaml
- name: KAFKA_BROKERS
  value: "b-1.your-msk-cluster.xxxxx.kafka.us-west-2.amazonaws.com:9092"
```

To get your MSK bootstrap servers:

```bash
aws kafka get-bootstrap-brokers \
  --cluster-arn arn:aws:kafka:us-west-2:123456789012:cluster/your-cluster/xxx \
  --query 'BootstrapBrokerString' \
  --output text
```

### 4.5 Deploy Application

```bash
# Deploy ConfigMap
kubectl apply -f ../k8s/tenant-whitelist-configmap.yaml

# Deploy application
kubectl apply -f ../k8s/deployment.yaml

# Verify deployment
kubectl get pods -n data-pipeline
kubectl get svc -n data-pipeline
```

## Step 5: Configure IAM for ECR Access

Create an IAM policy for ECR pull access:

```bash
# Create policy document
cat > ecr-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/kafka-starrocks-loader"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
EOF

# Attach to node IAM role (get role name from EKS console or eksctl)
aws iam put-role-policy \
  --role-name eksctl-starrocks-loader-cluster-nodegroup-NodeInstanceRole-XXXXX \
  --policy-name ECRPullPolicy \
  --policy-document file://ecr-policy.json
```

## Step 6: Configure Network Access

### MSK Security Group

Ensure your EKS nodes can reach MSK:

```bash
# Get EKS node security group
EKS_SG=$(aws eks describe-cluster \
  --name starrocks-loader-cluster \
  --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' \
  --output text)

# Get MSK security group
MSK_SG=sg-xxxxxxxxx  # From MSK console

# Allow EKS to MSK
aws ec2 authorize-security-group-ingress \
  --group-id $MSK_SG \
  --source-group $EKS_SG \
  --protocol tcp \
  --port 9092
```

### StarRocks Security Group

Similarly, allow EKS nodes to reach StarRocks on ports:
- 8030 (HTTP/Stream Load)
- 9030 (MySQL protocol)

```bash
STARROCKS_SG=sg-yyyyyyyyy  # Your StarRocks security group

aws ec2 authorize-security-group-ingress \
  --group-id $STARROCKS_SG \
  --source-group $EKS_SG \
  --protocol tcp \
  --port 8030

aws ec2 authorize-security-group-ingress \
  --group-id $STARROCKS_SG \
  --source-group $EKS_SG \
  --protocol tcp \
  --port 9030
```

## Managing Tenants

### Add/Remove Tenants

```bash
# Edit tenant whitelist
kubectl edit configmap tenant-whitelist -n data-pipeline

# Or apply updated ConfigMap
kubectl apply -f ../k8s/tenant-whitelist-configmap.yaml
```

Changes are picked up within 2 minutes automatically.

### Force Immediate Reload

```bash
# Restart pods to pick up changes immediately
kubectl rollout restart deployment kafka-starrocks-loader -n data-pipeline

# Watch rollout status
kubectl rollout status deployment kafka-starrocks-loader -n data-pipeline
```

## Monitoring

### View Logs

```bash
# Stream logs from all pods
kubectl logs -f -l app=kafka-starrocks-loader -n data-pipeline

# View logs from specific pod
kubectl logs -f kafka-starrocks-loader-xxxxx -n data-pipeline

# Search for filtered messages
kubectl logs -l app=kafka-starrocks-loader -n data-pipeline | grep -i filtered
```

### Check Pod Status

```bash
# Get pod status
kubectl get pods -n data-pipeline -o wide

# Describe pod for events
kubectl describe pod -l app=kafka-starrocks-loader -n data-pipeline
```

### CloudWatch Integration (Optional)

Install CloudWatch agent for centralized logging:

```bash
# Install CloudWatch Logs agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml
```

## Scaling

### Manual Scaling

```bash
# Scale to 4 replicas
kubectl scale deployment kafka-starrocks-loader -n data-pipeline --replicas=4
```

### Horizontal Pod Autoscaler

```bash
# Create HPA based on CPU
kubectl autoscale deployment kafka-starrocks-loader \
  -n data-pipeline \
  --min=2 \
  --max=10 \
  --cpu-percent=70
```

Or apply HPA manifest:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: kafka-starrocks-loader-hpa
  namespace: data-pipeline
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: kafka-starrocks-loader
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod -l app=kafka-starrocks-loader -n data-pipeline

# Common issues:
# - ImagePullBackOff: Check ECR permissions and image tag
# - CrashLoopBackOff: Check logs for application errors
# - Pending: Check node resources
```

### Cannot Connect to Kafka/MSK

```bash
# Test connectivity from a debug pod
kubectl run -it --rm debug \
  --image=alpine \
  --namespace=data-pipeline \
  -- sh

# Inside the pod:
apk add netcat-openbsd
nc -zv b-1.your-msk-cluster.xxxxx.kafka.us-west-2.amazonaws.com 9092
```

### Cannot Connect to StarRocks

```bash
# Test StarRocks connectivity
kubectl run -it --rm debug \
  --image=mysql:8 \
  --namespace=data-pipeline \
  -- mysql -h starrocks-fe-host -P 9030 -u root -p
```

### ConfigMap Not Updating

```bash
# Verify ConfigMap contents
kubectl get configmap tenant-whitelist -n data-pipeline -o yaml

# Check mounted file in pod
kubectl exec -it <pod-name> -n data-pipeline -- cat /etc/config/tenant-whitelist.txt
```

## Cleanup

```bash
# Delete application resources
kubectl delete -f ../k8s/deployment.yaml
kubectl delete -f ../k8s/tenant-whitelist-configmap.yaml
kubectl delete secret starrocks-credentials -n data-pipeline
kubectl delete namespace data-pipeline

# Delete ECR repository (optional)
aws ecr delete-repository --repository-name $ECR_REPO --force

# Delete EKS cluster (optional)
eksctl delete cluster --name starrocks-loader-cluster
```

## Cost Optimization Tips

1. **Use Spot Instances** for worker nodes:
   ```bash
   eksctl create nodegroup \
     --cluster starrocks-loader-cluster \
     --name spot-workers \
     --spot \
     --instance-types t3.medium,t3.large
   ```

2. **Right-size pods** based on actual usage:
   ```bash
   kubectl top pods -n data-pipeline
   ```

3. **Use Karpenter** for efficient autoscaling

4. **Enable cluster autoscaler** to scale down unused nodes
