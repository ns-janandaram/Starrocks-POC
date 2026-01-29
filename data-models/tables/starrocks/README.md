# StarRocks Schema Migration

This directory contains StarRocks table schemas converted from ClickHouse for the Netskope data platform.

## Overview

The migration converts ClickHouse `ReplacingMergeTree` tables to StarRocks `PRIMARY KEY` tables, optimized for:
- Fast UPSERT operations (10k+ updates/second)
- Multi-tenant data isolation via partitioning
- Real-time query performance

## Prerequisites

- StarRocks cluster (v3.1+ recommended for JSON support)
- MySQL client or StarRocks CLI
- Network access to StarRocks FE node (port 9030)

## Tables

| Table | Description | Primary Key |
|-------|-------------|-------------|
| `applications` | SaaS application instances | `(tenant_id, id)` |
| `data_buckets` | Object storage buckets (S3, GCS, Azure Blob) | `(tenant_id, id)` |
| `data_objects` | Objects within storage buckets | `(tenant_id, id)` |
| `databases` | Data warehouse/structured data stores | `(tenant_id, id)` |
| `devices` | Device information (OCSF compliant) | `(tenant_id, id)` |
| `emails` | Email objects from mail providers | `(tenant_id, id)` |
| `files` | File objects from cloud storage | `(tenant_id, id)` |
| `finding_info` | Security findings and compliance violations | `(tenant_id, id)` |
| `groups` | Group objects (OCSF 1.7.0) | `(tenant_id, id)` |
| `messages` | Chat messages from collaboration apps | `(tenant_id, id)` |
| `privileges` | Privilege objects (OCSF 1.7.0) | `(tenant_id, id)` |
| `users` | User objects (OCSF 1.7.0) | `(tenant_id, id)` |

## Quick Start

### 1. Run the Migration

```bash
# Using MySQL client
mysql -h <starrocks-fe-host> -P 9030 -u root < migration.sql

# With password
mysql -h <starrocks-fe-host> -P 9030 -u root -p < migration.sql

# Example with local StarRocks
mysql -h 127.0.0.1 -P 9030 -u root < migration.sql
```

### 2. Verify Tables

```sql
USE netskope;
SHOW TABLES;

-- Check table structure
DESC applications;

-- Verify primary key settings
SHOW CREATE TABLE applications;
```

### 3. Test Insert/Update

```sql
-- Insert a record
INSERT INTO applications (tenant_id, id, name, type)
VALUES (1, 'app-001', 'Slack', 'collaboration');

-- Update the same record (UPSERT)
INSERT INTO applications (tenant_id, id, name, type, risk_level)
VALUES (1, 'app-001', 'Slack', 'collaboration', 'low');

-- Verify only one row exists
SELECT * FROM applications WHERE tenant_id = 1 AND id = 'app-001';
```

## File Structure

```
starrocks/
├── README.md           # This file
├── migration.sql       # Combined migration script (all tables)
├── application.sql     # Individual table schema
├── data_bucket.sql
├── data_object.sql
├── database.sql
├── device.sql
├── email.sql
├── file.sql
├── finding_info.sql
├── group.sql
├── message.sql
├── privilege.sql
└── user.sql
```

## Type Mappings

| ClickHouse | StarRocks | Notes |
|------------|-----------|-------|
| `String` | `STRING` | Variable length |
| `LowCardinality(String)` | `VARCHAR(255)` | No dictionary encoding in StarRocks |
| `DateTime64(3)` | `DATETIME` | Millisecond precision |
| `UInt32` / `Int32` | `INT` | 32-bit integer |
| `UInt64` | `BIGINT` | 64-bit integer |
| `UInt8` | `TINYINT` | 8-bit integer |
| `Float32` | `FLOAT` | 32-bit float |
| `Float64` | `DOUBLE` | 64-bit float |
| `Bool` | `BOOLEAN` | True/false |
| `Array(String)` | `ARRAY<STRING>` | Array type |
| `Nested(...)` | `JSON` | Complex nested structures |

## Schema Design

### Primary Key Tables

All tables use StarRocks `PRIMARY KEY` model for:
- Immediate consistency (vs ClickHouse's eventual consistency)
- Real-time UPSERT without merge delays
- Delete support

```sql
PRIMARY KEY (tenant_id, id)
```

### Partitioning

Tables are partitioned by `tenant_id` for:
- Multi-tenant data isolation
- Efficient partition pruning
- Per-tenant data management

```sql
PARTITION BY (tenant_id)
```

### Distribution

Data is distributed by hash on `id` for even data spread:

```sql
DISTRIBUTED BY HASH(id) BUCKETS 16
```

### Persistent Index

Enabled for fast primary key lookups during updates:

```sql
PROPERTIES (
    "enable_persistent_index" = "true"
)
```

## Production Configuration

Before deploying to production, update the following:

### 1. Replication Factor

Change from 1 to 2-3 for high availability:

```sql
-- In migration.sql, find and replace:
"replication_num" = "1"

-- Replace with:
"replication_num" = "2"  -- or "3" for critical data
```

### 2. Bucket Count

Adjust based on data volume per tenant:

| Expected Rows per Tenant | Recommended Buckets |
|--------------------------|---------------------|
| < 1 million | 4-8 |
| 1-10 million | 8-16 |
| 10-100 million | 16-32 |
| > 100 million | 32-64 |

### 3. Memory Configuration

For tables with persistent index, ensure BE nodes have sufficient memory:

```sql
-- Check current memory usage
SHOW BACKENDS;

-- Recommended: 32GB+ RAM per BE for production workloads
```

## Data Ingestion

### Stream Load (Recommended for Kafka consumers)

```bash
curl -X PUT \
  -H "Authorization: Basic $(echo -n 'root:' | base64)" \
  -H "Content-Type: application/json" \
  -H "format: json" \
  -H "strip_outer_array: false" \
  --data-binary @data.json \
  "http://<fe-host>:8030/api/netskope/applications/_stream_load"
```

### INSERT Statement

```sql
INSERT INTO applications (tenant_id, id, name, type)
VALUES
  (1, 'app-001', 'Slack', 'collaboration'),
  (1, 'app-002', 'Salesforce', 'crm');
```

### Partial Updates

To update only specific columns without providing all fields:

```bash
curl -X PUT \
  -H "Authorization: Basic $(echo -n 'root:' | base64)" \
  -H "Content-Type: application/json" \
  -H "format: json" \
  -H "partial_update: true" \
  -H "columns: tenant_id,id,risk_level" \
  --data-binary '{"tenant_id":1,"id":"app-001","risk_level":"high"}' \
  "http://<fe-host>:8030/api/netskope/applications/_stream_load"
```

## Querying JSON Fields

For columns converted from ClickHouse `Nested` to StarRocks `JSON`:

```sql
-- Access JSON field
SELECT
  id,
  json_query(vendor_config_full_json, '$.s3.bucket_arn') as bucket_arn
FROM data_buckets
WHERE tenant_id = 1;

-- Filter on JSON field
SELECT * FROM data_buckets
WHERE json_query(acl, '$[0].access_level') = 'read';

-- Unnest JSON array
SELECT
  id,
  get_json_string(tag.value, '$.key') as tag_key,
  get_json_string(tag.value, '$.value') as tag_value
FROM data_buckets, unnest(cast(json_query(tags, '$') as array<json>)) as tag;
```

## Troubleshooting

### Table Creation Fails

```sql
-- Check for syntax errors
SHOW WARNINGS;

-- Verify StarRocks version supports JSON
SELECT version();
```

### Slow UPSERT Performance

```sql
-- Verify persistent index is enabled
SHOW CREATE TABLE applications;

-- Check tablet distribution
SHOW TABLET FROM applications;

-- Monitor compaction
SHOW PROC '/compactions';
```

### Memory Issues

```sql
-- Check BE memory usage
SHOW BACKENDS;

-- Reduce batch size in Stream Load
-- Change from 50000 to 10000 rows per batch
```

## Rollback

To drop all tables and start fresh:

```sql
USE netskope;

DROP TABLE IF EXISTS applications;
DROP TABLE IF EXISTS data_buckets;
DROP TABLE IF EXISTS data_objects;
DROP TABLE IF EXISTS databases;
DROP TABLE IF EXISTS devices;
DROP TABLE IF EXISTS emails;
DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS finding_info;
DROP TABLE IF EXISTS groups;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS privileges;
DROP TABLE IF EXISTS users;

-- Or drop entire database
DROP DATABASE IF EXISTS netskope;
```

## References

- [StarRocks Primary Key Table](https://docs.starrocks.io/docs/table_design/table_types/primary_key_table/)
- [StarRocks Stream Load](https://docs.starrocks.io/docs/loading/StreamLoad/)
- [StarRocks JSON Functions](https://docs.starrocks.io/docs/sql-reference/sql-functions/json-functions/)
- [StarRocks Partitioning](https://docs.starrocks.io/docs/table_design/data_distribution/)
