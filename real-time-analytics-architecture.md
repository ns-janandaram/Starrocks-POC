# Real-Time Analytics Platform Architecture

## Executive Summary

This document describes the architecture for a real-time streaming analytics platform designed to handle **60TB of daily data ingestion** with a **1-year retention policy**. The architecture uses a tiered storage approach with StarRocks for hot data and Apache Iceberg on S3 for cold storage, supporting two distinct query paths:

1. **Real-Time Analytics**: Sub-30-second data freshness via StarRocks native tables
2. **BI/Reporting**: Up to 1-hour data freshness via Trino querying Iceberg (Looker)

---

## Table of Contents

1. [Database Selection: ClickHouse vs StarRocks](#1-database-selection-clickhouse-vs-starrocks)
2. [Storage Format Analysis: Native vs Iceberg](#2-storage-format-analysis-native-vs-iceberg)
3. [Architecture Overview](#3-architecture-overview)
4. [Tiered Storage Design](#4-tiered-storage-design)
5. [Query Stitching: Hot and Cold Data](#5-query-stitching-hot-and-cold-data)
6. [Multi-Tenant Data Isolation](#6-multi-tenant-data-isolation)
7. [Cost Analysis](#7-cost-analysis)
8. [Implementation Details](#8-implementation-details)

---

## 1. Database Selection: ClickHouse vs StarRocks

### 1.1 Requirements Summary

| Requirement | Specification |
|-------------|---------------|
| Daily Ingestion | 60 TB |
| Data Retention | 1 year (~21.9 PB raw, ~3 PB compressed) |
| Hot Data Window | 30 minutes - 3 hours |
| Cold Storage | S3 with Iceberg format |
| Query Pattern | Multi-table JOINs (2+ tables) |
| Data Mutability | Mix of immutable and highly mutable tables |
| Compute Scaling | Elastic scale up/down based on load |
| BI Tool | Looker via Trino |

### 1.2 TPC-H Benchmark Comparison (Multi-Table JOINs)

This is critical for workloads requiring 2+ table joins.

| Database | TPC-H Completion | Join Performance | Notes |
|----------|------------------|------------------|-------|
| **StarRocks** | Full TPC-H/TPC-DS | Excellent | Cost-based optimizer handles complex joins |
| **ClickHouse** | Partial (14 of 22 queries) | Limited | Many queries fail or OOM on joins |

**Key Finding**: ClickHouse cannot complete the full TPC-H benchmark due to join limitations. In comparable tests, StarRocks outperforms ClickHouse in 9 out of 14 queries that both can execute.

On the **SSB (Star Schema Benchmark)**, StarRocks is **1.87-2.2x faster** than ClickHouse due to its cost-based optimizer planning join execution more efficiently.

#### Why ClickHouse Struggles with JOINs

- Rule-based query planner (vs StarRocks' cost-based optimizer)
- Not designed for complex multi-table scenarios
- Recommended workaround: Flatten/denormalize tables in Flink before ingestion
- Works best with pre-joined data

**Sources**:
- [StarRocks Benchmark](https://www.starrocks.io/blog/benchmark-test)
- [Tinybird: ClickHouse vs StarRocks](https://www.tinybird.co/blog/clickhouse-vs-starrocks)
- [CelerData Comparison](https://celerdata.com/blog/clickhouse-vs.-starrocks-a-detailed-comparison)

### 1.3 Mutable Data Handling

#### StarRocks Primary Key Table

| Feature | Capability |
|---------|------------|
| Real-time UPSERT | Yes |
| DELETE | Yes |
| Partial Updates | Yes (column mode since v3.1) |
| CDC Integration | Native Flink CDC support |
| Performance | 3-10x faster than Merge-on-Read |

Uses **Delete+Insert strategy** with primary key index and DelVector - queries only read the latest version without merge overhead.

#### ClickHouse Options

| Engine | Performance | Limitations |
|--------|-------------|-------------|
| ReplacingMergeTree | Fast writes | Eventual deduplication, FINAL overhead |
| Mutations (ALTER UPDATE) | Slow (rewrites parts) | Can cause OOM with high mutation volume |
| Lightweight Updates | 1000x faster than mutations | Recent feature, query-time overhead |

**Key Issue**: ClickHouse's ReplacingMergeTree provides **eventual consistency**, not immediate deduplication. This can return stale data until background merges complete.

**Sources**:
- [StarRocks Primary Key Tables](https://docs.starrocks.io/docs/table_design/table_types/primary_key_table/)
- [Altinity: ReplacingMergeTree Explained](https://altinity.com/blog/clickhouse-replacingmergetree-explained-the-good-the-bad-and-the-ugly)

### 1.4 Compute-Storage Separation & Scaling

#### StarRocks Shared-Data Architecture

| Capability | Support |
|------------|---------|
| Scale to zero | Yes (disable local cache) |
| Add/remove CNs | Seconds (no data migration) |
| Data migration required | No |
| Kubernetes native | Yes |
| Resource isolation | Yes (query queues, resource pools) |

#### ClickHouse Cloud

| Capability | Support |
|------------|---------|
| Scale to zero | Yes (Basic tier excluded) |
| Auto-scaling | ~15 minutes latency |
| Data migration required | Yes (rebalancing) |
| Serverless | Yes |
| Resource isolation | Limited |

**Winner for elastic scaling**: StarRocks shared-data architecture is purpose-built for this use case.

**Sources**:
- [StarRocks Architecture](https://docs.starrocks.io/docs/introduction/Architecture/)
- [ClickHouse Cloud Pricing](https://clickhouse.com/docs/cloud/manage/billing/overview)

### 1.5 Selection Summary

| Requirement | StarRocks | ClickHouse | Winner |
|-------------|-----------|------------|--------|
| 60TB/day ingestion | Excellent | Excellent | Tie |
| TPC-H (multi-table joins) | Full support | Partial/fails | **StarRocks** |
| Tiered storage (hot/cold) | Native shared-data | TTL-based | **StarRocks** |
| Compute autoscaling | Seconds, no rebalance | Minutes, rebalance | **StarRocks** |
| Mutable tables | Primary Key (real-time) | ReplacingMergeTree (eventual) | **StarRocks** |
| Iceberg support | Full (read/write) | Read-only production | **StarRocks** |
| Native vs Iceberg gap | ~5-15% | ~30-50% | **StarRocks** |

**Recommendation**: **StarRocks** for this workload due to superior JOIN performance, real-time mutation support, and elastic compute scaling.

---

## 2. Storage Format Analysis: Native vs Iceberg

### 2.1 Performance Comparison

#### StarRocks

| Format | Query Performance | Notes |
|--------|-------------------|-------|
| **Native** | Baseline (1x) | Late materialization, better partition pruning |
| **Iceberg** | ~0.85-0.95x | StarRocks 4.0 closed gap significantly |

StarRocks 4.0 delivers **near-native performance** on Iceberg through improvements in caching, metadata handling, and query optimization. In TPC-DS benchmarks, StarRocks achieves **6.93x the performance of Trino** on Iceberg queries.

#### ClickHouse

| Format | Query Performance | Notes |
|--------|-------------------|-------|
| **Native (MergeTree)** | Baseline (1x) | Tightly optimized internal format |
| **Iceberg** | ~0.5-0.7x | Performance gap acknowledged by ClickHouse |

ClickHouse explicitly states: *"The current approach does not leverage ClickHouse's optimized internal format, resulting in slower query performance on a data lake compared to data stored natively."*

### 2.2 Iceberg Write Support Comparison

| Database | Read | Write | Production-Ready |
|----------|------|-------|------------------|
| StarRocks | Full v2 | Full | Yes |
| ClickHouse | Full v2 | Experimental | No (INSERT only, no UPDATE/DELETE) |

### 2.3 When to Use Each Format

#### Use Native Format When:

| Factor | Native Advantage |
|--------|------------------|
| Query Performance | 15-50% faster |
| Mutable Tables | Much better support |
| Operational Simplicity | No compaction jobs |
| Storage Efficiency | Better compression for updates |
| Join Performance | Fully optimized |

#### Use Iceberg When:

| Factor | Iceberg Advantage |
|--------|-------------------|
| Multi-engine access | Spark, Flink, Trino, etc. |
| Vendor lock-in avoidance | Open format |
| Data sharing | Cross-team/org access |
| Schema evolution | Time travel, schema history |

### 2.4 Cost Impact Analysis

| Aspect | Native | Iceberg |
|--------|--------|---------|
| Storage | Slightly lower (better compression) | ~5-15% higher metadata overhead |
| Compute | Baseline | 10-30% higher (metadata handling) |
| Operations | Lower (no compaction) | Higher (compaction jobs required) |
| **Total for 60TB/day** | Baseline | **+15-25% TCO** |

### 2.5 Small File Problem with Streaming Iceberg Writes

Direct streaming writes to Iceberg create significant issues:

| Metric | Streaming (1-min commits) | Hourly Batch |
|--------|---------------------------|--------------|
| Files per day | ~2.4M | ~40K |
| S3 PUT cost/year | ~$4,400 | ~$73 |
| Snapshots per day | 1,440 | 24 |
| Compaction required | Heavy | None |

**Recommendation**: Use StarRocks as the single ingestion point with hourly batch exports to Iceberg to avoid small file issues.

**Sources**:
- [StarRocks 4.0 Iceberg](https://celerdata.com/blog/starrocks-4.0-delivering-query-ready-data-to-apache-iceberg)
- [ClickHouse Iceberg Blog](https://clickhouse.com/blog/climbing-the-iceberg-with-clickhouse)
- [AWS: Iceberg Small Files Problem](https://aws.amazon.com/blogs/big-data/apache-iceberg-optimization-solving-the-small-files-problem-in-amazon-emr/)

---

## 3. Architecture Overview

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DATA SOURCES                                        │
│                   (CDC, APIs, Events, Streaming)                                │
└───────────────────────────────┬─────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              INGESTION LAYER                                     │
│                                                                                 │
│   ┌─────────────┐         ┌─────────────┐         ┌─────────────────────┐      │
│   │    Kafka    │────────▶│    Flink    │────────▶│     StarRocks       │      │
│   │   Topics    │         │  Streaming  │         │   (Single Sink)     │      │
│   └─────────────┘         └─────────────┘         └─────────────────────┘      │
│                                                                                 │
│   Latency: < 30 seconds end-to-end                                             │
└─────────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            STORAGE LAYER                                         │
│                                                                                 │
│   ┌─────────────────────────────────┐    ┌─────────────────────────────────┐   │
│   │      HOT TIER (Native)          │    │      COLD TIER (Iceberg)        │   │
│   │                                 │    │                                 │   │
│   │   StarRocks Native Tables       │    │   Iceberg on S3                 │   │
│   │   • 3-hour retention            │───▶│   • Per-customer buckets        │   │
│   │   • Local NVMe SSD              │    │   • 1-year retention            │   │
│   │   • Real-time queries           │    │   • Hourly batch export         │   │
│   │                                 │    │                                 │   │
│   └─────────────────────────────────┘    └─────────────────────────────────┘   │
│                                                                                 │
│   Export: Airflow DAG (Hourly) - Avoids small file problem                     │
└─────────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                             QUERY LAYER                                          │
│                                                                                 │
│   ┌─────────────────────────────────┐    ┌─────────────────────────────────┐   │
│   │     USE CASE 1: Real-Time       │    │     USE CASE 2: BI/Reporting    │   │
│   │                                 │    │                                 │   │
│   │   • Query Engine: StarRocks     │    │   • Query Engine: Trino         │   │
│   │   • Data: Unified View          │    │   • Tool: Looker                │   │
│   │     (Hot Native + Cold Iceberg) │    │   • Data: Iceberg only          │   │
│   │   • Freshness: < 30 seconds     │    │   • Freshness: < 1 hour         │   │
│   │   • Latency: milliseconds       │    │   • Latency: seconds            │   │
│   │                                 │    │                                 │   │
│   └─────────────────────────────────┘    └─────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Data Flow Summary

| Stage | Component | Latency | Data Location |
|-------|-----------|---------|---------------|
| Ingest | Kafka → Flink → StarRocks | < 30s | StarRocks Native |
| Hot Query | StarRocks Native | < 30s freshness | Local NVMe |
| Export | Airflow (Hourly) | 1 hour | S3 Iceberg |
| Cold Query (Real-time apps) | StarRocks → Iceberg | < 1 hour freshness | S3 |
| BI Query | Trino → Iceberg | < 1 hour freshness | S3 |

---

## 4. Tiered Storage Design

### 4.1 Hot Tier: StarRocks Native

```sql
-- Real-time events table (all customers, partitioned by hour)
CREATE TABLE events_realtime (
    event_id BIGINT,
    event_time DATETIME,
    customer_id VARCHAR(64),
    user_id BIGINT,
    event_type VARCHAR(32),
    payload JSON,
    internal_trace_id VARCHAR(64),  -- Hot-only field
    INDEX idx_customer (customer_id) USING BITMAP
) PRIMARY KEY (customer_id, event_id)
PARTITION BY date_trunc('hour', event_time)
DISTRIBUTED BY HASH(customer_id) BUCKETS 32
PROPERTIES (
    "partition_live_number" = "3",           -- Keep 3 hours
    "enable_persistent_index" = "true",
    "replication_num" = "2"
);
```

**Characteristics**:
- Partition by HOUR with automatic cleanup
- Primary Key for mutable data support
- ~3-4 TB buffer at 60TB/day scale
- Sub-second query latency

### 4.2 Cold Tier: Iceberg on S3

```sql
-- Iceberg table (per-customer bucket)
CREATE TABLE customer_acme_catalog.analytics.events (
    id BIGINT,
    event_ts TIMESTAMP,
    tenant_id STRING,
    user_id BIGINT,
    event_type STRING,
    payload STRING,
    event_date DATE,
    event_hour INT
) PARTITION BY (event_date, event_hour);
```

**Characteristics**:
- Hourly batch exports (avoids small files)
- ~20 files @ 128MB per partition per hour
- 24 snapshots/day (vs 1,440 with streaming)
- Query-ready immediately (no compaction needed)

### 4.3 Export Pipeline (Airflow)

```python
# Airflow DAG: Hourly export from StarRocks to Iceberg
# Runs at :05 past each hour

CUSTOMERS = [
    {'id': 'acme', 'catalog': 'customer_acme_catalog'},
    {'id': 'globex', 'catalog': 'customer_globex_catalog'},
    # ...
]

def generate_export_sql(customer_id, catalog, execution_hour):
    return f"""
    INSERT INTO {catalog}.analytics.events
    SELECT
        event_id AS id,
        event_time AS event_ts,
        customer_id AS tenant_id,
        user_id,
        event_type,
        CAST(payload AS STRING) as payload,
        DATE(event_time) as event_date,
        HOUR(event_time) as event_hour
    FROM events_realtime
    WHERE customer_id = '{customer_id}'
      AND event_time >= TIMESTAMP '{execution_hour}'
      AND event_time < TIMESTAMP '{execution_hour}' + INTERVAL 1 HOUR
    """
```

---

## 5. Query Stitching: Hot and Cold Data

### 5.1 The Schema Mismatch Challenge

Real-time applications need to query both hot (StarRocks native) and cold (Iceberg) data, but schemas differ:

```
StarRocks Native (Hot)                 Iceberg on S3 (Cold)
━━━━━━━━━━━━━━━━━━━━━━                 ━━━━━━━━━━━━━━━━━━━━━

events_realtime                        events
├── event_id BIGINT                    ├── id BIGINT            ← Different name
├── event_time DATETIME                ├── event_ts TIMESTAMP   ← Different type
├── customer_id VARCHAR(64)            ├── tenant_id STRING     ← Different name
├── user_id BIGINT                     ├── user_id BIGINT       ← Same
├── event_type VARCHAR(32)             ├── event_type STRING    ← Same
├── payload JSON                       ├── payload STRING       ← Different type
├── internal_trace_id VARCHAR(64)      │                        ← Hot only
│                                      ├── event_date DATE      ← Cold only
│                                      ├── event_hour INT       ← Cold only
└── PARTITION BY hour(event_time)      └── PARTITION BY (event_date, event_hour)
```

### 5.2 Solution: Unified View with Schema Transformation

```sql
-- Canonical schema definition
-- All queries use these column names regardless of source

CREATE VIEW unified_events AS

-- HOT DATA: Transform native schema to canonical
SELECT
    event_id AS id,
    event_time AS event_ts,
    customer_id AS tenant_id,
    user_id,
    event_type,
    CAST(payload AS STRING) AS payload,
    DATE(event_time) AS event_date,
    HOUR(event_time) AS event_hour,
    'hot' AS data_tier
FROM default_catalog.db.events_realtime
WHERE event_time >= NOW() - INTERVAL 3 HOUR

UNION ALL

-- COLD DATA: Transform Iceberg schema to canonical
SELECT
    id,
    event_ts,
    tenant_id,
    user_id,
    event_type,
    payload,
    event_date,
    event_hour,
    'cold' AS data_tier
FROM iceberg_catalog.analytics.events
WHERE event_ts < NOW() - INTERVAL 3 HOUR;
```

### 5.3 Per-Customer Unified Views

```sql
-- Generated per customer (pointing to customer-specific Iceberg catalog)
CREATE VIEW acme_events AS

SELECT
    event_id AS id,
    event_time AS event_ts,
    customer_id AS tenant_id,
    user_id,
    event_type,
    CAST(payload AS STRING) AS payload,
    DATE(event_time) AS event_date,
    HOUR(event_time) AS event_hour
FROM default_catalog.analytics.events_realtime
WHERE customer_id = 'acme'
  AND event_time >= NOW() - INTERVAL 3 HOUR

UNION ALL

SELECT
    id,
    event_ts,
    tenant_id,
    user_id,
    event_type,
    payload,
    event_date,
    event_hour
FROM customer_acme_catalog.analytics.events
WHERE event_ts < NOW() - INTERVAL 3 HOUR;
```

### 5.4 Query Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     QUERY: SELECT * FROM unified_events                          │
│                            WHERE tenant_id = 'acme'                              │
│                              AND event_ts >= '2025-01-14'                        │
└───────────────────────────────────┬─────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          StarRocks Query Engine                                  │
│                                                                                 │
│   1. Parse unified_events VIEW                                                  │
│   2. Push predicates to both branches                                           │
│   3. Execute in PARALLEL:                                                       │
│                                                                                 │
│      ┌─────────────────────────────┐    ┌─────────────────────────────────┐    │
│      │    Hot Branch (Native)      │    │     Cold Branch (Iceberg)       │    │
│      │                             │    │                                 │    │
│      │  • Predicate pushdown       │    │  • Predicate pushdown           │    │
│      │  • Partition pruning        │    │  • Partition pruning            │    │
│      │    (hour partitions)        │    │    (event_date, event_hour)     │    │
│      │  • Local NVMe scan          │    │  • S3 Parquet scan              │    │
│      │                             │    │                                 │    │
│      └──────────────┬──────────────┘    └────────────────┬────────────────┘    │
│                     │                                    │                      │
│                     └─────────────┬──────────────────────┘                      │
│                                   │                                             │
│                                   ▼                                             │
│                        ┌─────────────────────┐                                  │
│                        │   UNION ALL Result  │                                  │
│                        └─────────────────────┘                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.5 Handling the Overlap Window

Time-based exclusion prevents duplicate data:

```sql
-- Hot: Only data from last 3 hours
WHERE event_time >= NOW() - INTERVAL 3 HOUR

-- Cold: Everything EXCEPT last 3 hours
WHERE event_ts < NOW() - INTERVAL 3 HOUR
```

### 5.6 Schema Mapping Reference

| Canonical Column | StarRocks Native | Iceberg Cold | Transform |
|------------------|------------------|--------------|-----------|
| `id` | `event_id` | `id` | Rename |
| `event_ts` | `event_time` (DATETIME) | `event_ts` (TIMESTAMP) | Type coercion |
| `tenant_id` | `customer_id` | `tenant_id` | Rename |
| `user_id` | `user_id` | `user_id` | Direct |
| `event_type` | `event_type` | `event_type` | Direct |
| `payload` | `payload` (JSON) | `payload` (STRING) | CAST |
| `event_date` | `DATE(event_time)` | `event_date` | Derived |
| `event_hour` | `HOUR(event_time)` | `event_hour` | Derived |

### 5.7 Query Best Practices

```sql
-- GOOD: Time-bounded with partition predicates
SELECT tenant_id, event_type, COUNT(*)
FROM unified_events
WHERE tenant_id = 'acme'                    -- Pushed to both sources
  AND event_date >= '2025-01-14'            -- Prunes Iceberg partitions
  AND event_ts >= '2025-01-14 00:00:00'     -- Prunes StarRocks partitions
GROUP BY tenant_id, event_type;

-- BAD: No time bounds (scans entire history)
SELECT * FROM unified_events
WHERE tenant_id = 'acme';
```

---

## 6. Multi-Tenant Data Isolation

### 6.1 Per-Customer S3 Bucket Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         MULTI-TENANT ISOLATION                                   │
│                                                                                 │
│   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐              │
│   │   Customer A    │   │   Customer B    │   │   Customer C    │              │
│   │                 │   │                 │   │                 │              │
│   │ S3 Bucket:      │   │ S3 Bucket:      │   │ S3 Bucket:      │              │
│   │ s3://cust-a/    │   │ s3://cust-b/    │   │ s3://cust-c/    │              │
│   │                 │   │                 │   │                 │              │
│   │ IAM Policy:     │   │ IAM Policy:     │   │ IAM Policy:     │              │
│   │ cust-a-policy   │   │ cust-b-policy   │   │ cust-c-policy   │              │
│   │                 │   │                 │   │                 │              │
│   │ KMS Key:        │   │ KMS Key:        │   │ KMS Key:        │              │
│   │ cust-a-key      │   │ cust-b-key      │   │ cust-c-key      │              │
│   │                 │   │                 │   │                 │              │
│   │ Iceberg Catalog:│   │ Iceberg Catalog:│   │ Iceberg Catalog:│              │
│   │ customer_a_cat  │   │ customer_b_cat  │   │ customer_c_cat  │              │
│   └─────────────────┘   └─────────────────┘   └─────────────────┘              │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Catalog Configuration

```sql
-- Separate Iceberg catalog per customer
CREATE EXTERNAL CATALOG customer_acme_catalog
PROPERTIES (
    "type" = "iceberg",
    "iceberg.catalog.type" = "rest",
    "iceberg.catalog.uri" = "http://iceberg-rest-catalog:8181/api/catalog",
    "iceberg.catalog.warehouse" = "s3://acme-corp-data-lake/warehouse",
    "aws.s3.region" = "us-east-1",
    "aws.s3.access_key" = "${ACME_S3_ACCESS_KEY}",
    "aws.s3.secret_key" = "${ACME_S3_SECRET_KEY}"
);

-- Query customer-specific data
SELECT * FROM customer_acme_catalog.analytics.events
WHERE event_date = '2025-01-14';
```

### 6.3 Isolation Benefits

| Benefit | Implementation |
|---------|----------------|
| **Data Isolation** | Separate S3 buckets |
| **Access Control** | Per-customer IAM policies |
| **Encryption** | Per-customer KMS keys |
| **Compliance** | Independent audit trails |
| **Cost Allocation** | Per-bucket cost tracking |

---

## 7. Cost Analysis

### 7.1 Data Scale Calculations

| Metric | Value |
|--------|-------|
| Daily Ingestion | 60 TB |
| Compression Ratio | ~7x (columnar) |
| Hot Data (3 hours) | ~7.5 TB raw → ~1 TB compressed |
| Cold Data (1 year) | ~21.9 PB raw → ~3 PB compressed |

### 7.2 Storage Costs

| Storage Tier | Cost/TB/month | Your Usage | Monthly Cost |
|--------------|---------------|------------|--------------|
| EBS gp3 SSD (Hot) | ~$80 | ~60 TB | ~$4,800 |
| S3 Standard-IA (Cold) | ~$12.80 | ~3 PB | ~$38,400 |

### 7.3 S3 Operations Costs (Hourly Batch vs Streaming)

| Approach | Files/Day | PUT Cost/Year | Compaction Needed |
|----------|-----------|---------------|-------------------|
| Streaming (1-min) | 2.4M | ~$4,400 | Heavy |
| **Hourly Batch** | 40K | ~$73 | None |

### 7.4 Total Annual Cost Estimate

| Component | Specification | Annual Cost |
|-----------|---------------|-------------|
| **StarRocks Cluster** | | |
| - Compute (CNs) | 10 nodes × c6i.4xlarge | ~$150K |
| - Hot Storage (NVMe) | 4TB per node | Included |
| **S3 Storage** | | |
| - Iceberg Data (3PB) | S3 Standard-IA | ~$460K |
| - PUT Operations | Hourly batch | ~$73 |
| - GET Operations | Query traffic | ~$5K |
| **Trino Cluster** | | |
| - Compute | 5 nodes × r6i.2xlarge | ~$45K |
| **Supporting Infrastructure** | | |
| - Kafka (MSK) | 6 brokers | ~$50K |
| - Flink (EMR/EKS) | 10 task managers | ~$60K |
| - Airflow (MWAA) | Medium environment | ~$15K |
| - Iceberg Catalog | Polaris/Tabular | ~$10-30K |
| **Total** | | **~$800K - $850K/year** |

---

## 8. Implementation Details

### 8.1 StarRocks Table DDL

```sql
-- Mutable events (Primary Key for UPSERT support)
CREATE TABLE events_realtime (
    event_id BIGINT,
    event_time DATETIME,
    customer_id VARCHAR(64),
    user_id BIGINT,
    event_type VARCHAR(32),
    payload JSON,
    internal_trace_id VARCHAR(64),
    INDEX idx_customer (customer_id) USING BITMAP
) PRIMARY KEY (customer_id, event_id)
PARTITION BY date_trunc('hour', event_time)
DISTRIBUTED BY HASH(customer_id) BUCKETS 32
PROPERTIES (
    "partition_live_number" = "3",
    "enable_persistent_index" = "true",
    "replication_num" = "2"
);

-- Immutable events (Duplicate Key for append-only, higher throughput)
CREATE TABLE events_immutable (
    event_id BIGINT,
    event_time DATETIME,
    customer_id VARCHAR(64),
    event_type VARCHAR(32),
    payload JSON
) DUPLICATE KEY (event_id, event_time)
PARTITION BY date_trunc('hour', event_time)
DISTRIBUTED BY HASH(customer_id) BUCKETS 32
PROPERTIES (
    "partition_live_number" = "3",
    "replication_num" = "2"
);
```

### 8.2 Unified View DDL

```sql
-- Per-customer unified view (generate for each customer)
CREATE VIEW acme_unified_events AS

-- Hot tier (StarRocks native)
SELECT
    event_id AS id,
    event_time AS event_ts,
    customer_id AS tenant_id,
    user_id,
    event_type,
    CAST(payload AS STRING) AS payload,
    DATE(event_time) AS event_date,
    HOUR(event_time) AS event_hour
FROM default_catalog.analytics.events_realtime
WHERE customer_id = 'acme'
  AND event_time >= NOW() - INTERVAL 3 HOUR

UNION ALL

-- Cold tier (Iceberg)
SELECT
    id,
    event_ts,
    tenant_id,
    user_id,
    event_type,
    payload,
    event_date,
    event_hour
FROM customer_acme_catalog.analytics.events
WHERE event_ts < NOW() - INTERVAL 3 HOUR;
```

### 8.3 Trino Catalog Configuration

```properties
# /etc/trino/catalog/iceberg_acme.properties
connector.name=iceberg
iceberg.catalog.type=rest
iceberg.rest-catalog.uri=http://iceberg-rest-catalog:8181/api/catalog
iceberg.rest-catalog.warehouse=s3://acme-corp-data-lake/warehouse

# Performance tuning
iceberg.metadata-cache-enabled=true
iceberg.metadata-cache-ttl=5m

# S3 configuration
hive.s3.region=us-east-1
hive.s3.path-style-access=false
```

### 8.4 Flink Connector Configuration

```java
// StarRocks Sink for sub-30s latency
StarRocksSink.<Event>builder()
    .setJdbcUrl("jdbc:mysql://starrocks-fe:9030")
    .setTableIdentifier("analytics.events_realtime")
    .setUsername("flink_user")
    .setPassword("${STARROCKS_PASSWORD}")
    .setSinkSemantic(SinkSemantic.AT_LEAST_ONCE)
    .setSinkProperties(new Properties() {{
        put("sink.buffer-flush.max-rows", "50000");
        put("sink.buffer-flush.interval-ms", "5000");
    }})
    .build();
```

---

## Appendix A: Decision Matrix

| Decision | Options Considered | Selected | Rationale |
|----------|-------------------|----------|-----------|
| Database | ClickHouse, StarRocks | StarRocks | Better JOINs, mutable data support |
| Hot Storage Format | Native, Iceberg | Native | 15-50% better performance |
| Cold Storage Format | Native, Iceberg | Iceberg | Open format for Trino/Looker |
| Hot-to-Cold Transfer | Streaming, Batch | Hourly Batch | Avoids small files |
| Multi-tenant Isolation | Prefix, Bucket | Bucket per customer | Stronger isolation |
| BI Query Engine | StarRocks, Trino | Trino | Looker compatibility |

---

## Appendix B: References

### StarRocks Documentation
- [StarRocks Architecture](https://docs.starrocks.io/docs/introduction/Architecture/)
- [Primary Key Tables](https://docs.starrocks.io/docs/table_design/table_types/primary_key_table/)
- [Iceberg Catalog](https://docs.starrocks.io/docs/data_source/catalog/iceberg/iceberg_catalog/)
- [Flink Connector](https://docs.starrocks.io/docs/loading/Flink-connector-starrocks/)

### Benchmarks & Comparisons
- [StarRocks Benchmark](https://www.starrocks.io/blog/benchmark-test)
- [StarRocks vs ClickHouse](https://www.starrocks.io/blog/starrocks-vs-clickhouse-the-quest-for-analytical-database-performance)
- [Tinybird Comparison](https://www.tinybird.co/blog/clickhouse-vs-starrocks)

### Iceberg Resources
- [Iceberg Small Files Problem](https://aws.amazon.com/blogs/big-data/apache-iceberg-optimization-solving-the-small-files-problem-in-amazon-emr/)
- [Iceberg MOR vs COW](https://www.dremio.com/blog/row-level-changes-on-the-lakehouse-copy-on-write-vs-merge-on-read-in-apache-iceberg/)
- [StarRocks 4.0 Iceberg](https://celerdata.com/blog/starrocks-4.0-delivering-query-ready-data-to-apache-iceberg)

### AWS Pricing
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [EBS Pricing](https://aws.amazon.com/ebs/pricing/)

---

*Document Version: 1.0*
*Last Updated: January 2025*
