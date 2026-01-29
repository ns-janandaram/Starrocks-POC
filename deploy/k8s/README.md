# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Kafka-to-StarRocks loader with tenant filtering.

## Files

| File | Description |
|------|-------------|
| `deployment.yaml` | Main deployment with ConfigMap mount |
| `tenant-whitelist-configmap.yaml` | Tenant whitelist configuration |

## Tenant Filtering

The loader filters Kafka messages based on a tenant whitelist. Only messages from whitelisted tenants are processed.

### How It Works

1. Tenant whitelist is stored in a ConfigMap
2. ConfigMap is mounted as a file at `/etc/config/tenant-whitelist.txt`
3. Loader reads the whitelist on startup
4. Loader refreshes the whitelist every 2 minutes
5. Messages from non-whitelisted tenants are silently dropped

### Whitelist Format

```txt
# Allowed tenant IDs
# One per line, comments start with #
18988
12345
67890
```

## Deployment

### 1. Create Namespace

```bash
kubectl create namespace data-pipeline
```

### 2. Create Secrets

```bash
kubectl create secret generic starrocks-credentials \
  --namespace data-pipeline \
  --from-literal=username=root \
  --from-literal=password=your-password
```

### 3. Deploy ConfigMap

```bash
kubectl apply -f tenant-whitelist-configmap.yaml
```

### 4. Deploy Application

```bash
kubectl apply -f deployment.yaml
```

## Managing Tenants

### Add a Tenant

```bash
# Edit the ConfigMap
kubectl edit configmap tenant-whitelist -n data-pipeline

# Or patch it
kubectl patch configmap tenant-whitelist -n data-pipeline --type merge -p '
data:
  tenant-whitelist.txt: |
    # Allowed tenant IDs
    18988
    12345
    67890
    99999
'
```

### Remove a Tenant

Edit the ConfigMap and remove the tenant ID from the list.

### View Current Whitelist

```bash
kubectl get configmap tenant-whitelist -n data-pipeline -o jsonpath='{.data.tenant-whitelist\.txt}'
```

### Force Immediate Reload

The loader checks for changes every 2 minutes. To force immediate reload:

```bash
# Option 1: Restart the pods
kubectl rollout restart deployment kafka-starrocks-loader -n data-pipeline

# Option 2: Call the reload endpoint (if implemented)
kubectl exec -it <pod-name> -n data-pipeline -- curl -X POST localhost:8080/reload-tenants
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TENANT_FILTER_ENABLED` | Enable/disable tenant filtering | `true` |
| `TENANT_WHITELIST_PATH` | Path to whitelist file | `/etc/config/tenant-whitelist.txt` |
| `TENANT_REFRESH_INTERVAL` | How often to check for updates | `2m` |

### Disabling Tenant Filtering

To process all tenants without filtering:

```yaml
env:
- name: TENANT_FILTER_ENABLED
  value: "false"
```

## Monitoring

### Check Filtered Message Count

```bash
# View logs
kubectl logs -l app=kafka-starrocks-loader -n data-pipeline | grep -i filtered

# Example output:
# Filtered 10000 messages (tenant not in whitelist)
# Processed 50000 messages, filtered 10000
```

### Metrics (if Prometheus enabled)

```
# Messages filtered due to tenant whitelist
kafka_starrocks_loader_messages_filtered_total

# Current number of allowed tenants
kafka_starrocks_loader_allowed_tenants_count
```

## Troubleshooting

### ConfigMap Not Updating

ConfigMaps mounted as volumes may take up to 2 minutes to propagate changes (kubelet sync period). The loader also checks every 2 minutes, so maximum delay is ~4 minutes.

To reduce delay:
```yaml
# In deployment.yaml, add to volumes
volumes:
- name: tenant-whitelist
  configMap:
    name: tenant-whitelist
    # Optional: reduce kubelet sync delay
    optional: false
```

### Whitelist File Not Found

Check the mount:
```bash
kubectl exec -it <pod-name> -n data-pipeline -- cat /etc/config/tenant-whitelist.txt
```

### All Messages Being Filtered

1. Verify whitelist has correct tenant IDs
2. Check tenant ID extraction from Kafka messages
3. Verify `TENANT_FILTER_ENABLED` is set correctly

```bash
# Check current allowed tenants
kubectl exec -it <pod-name> -n data-pipeline -- curl localhost:8080/tenants
```
