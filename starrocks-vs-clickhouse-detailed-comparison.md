# StarRocks vs ClickHouse: Detailed Technical Comparison

## Executive Summary

This document provides a comprehensive technical comparison between StarRocks and ClickHouse for building a real-time analytics platform with the following requirements:

- **Scale**: 60 TB daily ingestion, 1-year retention
- **Storage**: Tiered architecture (hot SSD + cold S3)
- **Query Patterns**: Multi-table JOINs (2+ tables)
- **Data Types**: Mix of immutable and mutable tables
- **Compute**: Elastic scaling based on workload
- **Format**: Native and open table formats (Iceberg)

**Recommendation**: StarRocks is the recommended choice for this workload due to superior JOIN performance, real-time mutation support, native compute-storage separation, and better Iceberg integration.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Benchmark Performance](#2-benchmark-performance)
3. [Query Engine & Optimizer](#3-query-engine--optimizer)
4. [JOIN Performance](#4-join-performance)
5. [Mutable Data Handling](#5-mutable-data-handling)
6. [Tiered Storage](#6-tiered-storage)
7. [Compute-Storage Separation](#7-compute-storage-separation)
8. [Iceberg Integration](#8-iceberg-integration)
9. [Concurrency & Scalability](#9-concurrency--scalability)
10. [Operational Complexity](#10-operational-complexity)
11. [Cost Analysis](#11-cost-analysis)
12. [Decision Matrix](#12-decision-matrix)

---

## 1. Architecture Overview

### 1.1 ClickHouse Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           CLICKHOUSE ARCHITECTURE                                │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                         ClickHouse Cluster                               │   │
│   │                                                                         │   │
│   │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                  │   │
│   │   │   Node 1    │   │   Node 2    │   │   Node 3    │                  │   │
│   │   │             │   │             │   │             │                  │   │
│   │   │ ┌─────────┐ │   │ ┌─────────┐ │   │ ┌─────────┐ │                  │   │
│   │   │ │ Compute │ │   │ │ Compute │ │   │ │ Compute │ │                  │   │
│   │   │ └────┬────┘ │   │ └────┬────┘ │   │ └────┬────┘ │                  │   │
│   │   │      │      │   │      │      │   │      │      │                  │   │
│   │   │ ┌────▼────┐ │   │ ┌────▼────┐ │   │ ┌────▼────┐ │                  │   │
│   │   │ │ Storage │ │   │ │ Storage │ │   │ │ Storage │ │                  │   │
│   │   │ │ (Local) │ │   │ │ (Local) │ │   │ │ (Local) │ │                  │   │
│   │   │ └─────────┘ │   │ └─────────┘ │   │ └─────────┘ │                  │   │
│   │   └─────────────┘   └─────────────┘   └─────────────┘                  │   │
│   │                                                                         │   │
│   │   Characteristics:                                                      │   │
│   │   • Shared-nothing architecture                                        │   │
│   │   • Compute & storage tightly coupled                                  │   │
│   │   • Each node owns its data shards                                     │   │
│   │   • Scaling requires data rebalancing                                  │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│   ClickHouse Cloud (Managed):                                                  │
│   • Rearchitected for compute-storage separation                               │
│   • SharedMergeTree engine                                                     │
│   • Auto-scaling with ~15 minute latency                                       │
│   • Distributed cache for S3 data                                              │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 StarRocks Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           STARROCKS ARCHITECTURE                                 │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                      Shared-Data Architecture                            │   │
│   │                                                                         │   │
│   │   ┌─────────────────────────────────────────────────────────────────┐   │   │
│   │   │                   Frontend Engines (FE)                          │   │   │
│   │   │                                                                 │   │   │
│   │   │   • Query parsing & planning                                    │   │   │
│   │   │   • Metadata management                                         │   │   │
│   │   │   • Cost-based optimizer                                        │   │   │
│   │   └─────────────────────────────────────────────────────────────────┘   │   │
│   │                              │                                          │   │
│   │                              ▼                                          │   │
│   │   ┌─────────────────────────────────────────────────────────────────┐   │   │
│   │   │                  Compute Nodes (CN) - Stateless                  │   │   │
│   │   │                                                                 │   │   │
│   │   │   ┌───────────┐   ┌───────────┐   ┌───────────┐                │   │   │
│   │   │   │   CN 1    │   │   CN 2    │   │   CN 3    │                │   │   │
│   │   │   │           │   │           │   │           │                │   │   │
│   │   │   │ ┌───────┐ │   │ ┌───────┐ │   │ ┌───────┐ │                │   │   │
│   │   │   │ │ Cache │ │   │ │ Cache │ │   │ │ Cache │ │                │   │   │
│   │   │   │ │ (SSD) │ │   │ │ (SSD) │ │   │ │ (SSD) │ │                │   │   │
│   │   │   │ └───────┘ │   │ └───────┘ │   │ └───────┘ │                │   │   │
│   │   │   └───────────┘   └───────────┘   └───────────┘                │   │   │
│   │   │                                                                 │   │   │
│   │   │   • Stateless compute (can scale in seconds)                   │   │   │
│   │   │   • Local SSD cache for hot data                               │   │   │
│   │   │   • No data rebalancing needed                                 │   │   │
│   │   └─────────────────────────────────────────────────────────────────┘   │   │
│   │                              │                                          │   │
│   │                              ▼                                          │   │
│   │   ┌─────────────────────────────────────────────────────────────────┐   │   │
│   │   │                    Object Storage (S3)                           │   │   │
│   │   │                                                                 │   │   │
│   │   │   • All data stored in S3                                       │   │   │
│   │   │   • Single source of truth                                      │   │   │
│   │   │   • Infinite scalability                                        │   │   │
│   │   └─────────────────────────────────────────────────────────────────┘   │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 1.3 Architecture Comparison Summary

| Aspect | ClickHouse | StarRocks |
|--------|------------|-----------|
| **Default Mode** | Shared-nothing | Shared-nothing & Shared-data |
| **Compute-Storage** | Tightly coupled (Cloud: separated) | Natively separated |
| **Scaling** | Requires data rebalancing | No data movement |
| **Scale Time** | ~15 minutes (Cloud) | Seconds |
| **Metadata** | Distributed (ZooKeeper/Keeper) | Centralized (FE nodes) |

---

## 2. Benchmark Performance

### 2.1 TPC-H Benchmark Results

TPC-H is the industry-standard benchmark for analytical query performance with complex JOINs.

| Database | TPC-H Completion | Queries Passed | Notes |
|----------|------------------|----------------|-------|
| **StarRocks** | ✅ Full (22/22) | 22 | All queries complete successfully |
| **ClickHouse** | ❌ Partial (14/22) | 14 | 8 queries fail or OOM on JOINs |

**Critical Finding**: ClickHouse cannot complete the full TPC-H benchmark. Many queries involving complex JOINs either fail outright or run out of memory.

```
TPC-H Query Completion Status:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Query   StarRocks   ClickHouse   Notes
─────   ─────────   ──────────   ─────
Q1      ✅ Pass     ✅ Pass      Simple aggregation
Q2      ✅ Pass     ❌ Fail      Complex JOIN (5 tables)
Q3      ✅ Pass     ✅ Pass      3-way JOIN
Q4      ✅ Pass     ✅ Pass      Subquery
Q5      ✅ Pass     ❌ Fail      6-way JOIN
Q6      ✅ Pass     ✅ Pass      Simple filter
Q7      ✅ Pass     ❌ Fail      Complex JOIN with date logic
Q8      ✅ Pass     ❌ Fail      8-way JOIN
Q9      ✅ Pass     ❌ OOM       Complex JOIN + aggregation
Q10     ✅ Pass     ✅ Pass      4-way JOIN
Q11     ✅ Pass     ✅ Pass      Subquery with GROUP BY
Q12     ✅ Pass     ✅ Pass      2-way JOIN
Q13     ✅ Pass     ✅ Pass      LEFT JOIN
Q14     ✅ Pass     ✅ Pass      2-way JOIN
Q15     ✅ Pass     ✅ Pass      View + JOIN
Q16     ✅ Pass     ❌ Fail      Subquery with NOT IN
Q17     ✅ Pass     ❌ Fail      Correlated subquery
Q18     ✅ Pass     ✅ Pass      Large GROUP BY
Q19     ✅ Pass     ✅ Pass      Complex OR conditions
Q20     ✅ Pass     ❌ Fail      Correlated subquery
Q21     ✅ Pass     ✅ Pass      Complex EXISTS
Q22     ✅ Pass     ✅ Pass      Subquery with NOT EXISTS

Summary:
• StarRocks: 22/22 queries passed (100%)
• ClickHouse: 14/22 queries passed (64%)
```

### 2.2 TPC-DS Benchmark Results

TPC-DS is a more complex benchmark with 99 queries covering a broader range of analytics patterns.

| Database | TPC-DS Completion | Notes |
|----------|-------------------|-------|
| **StarRocks** | ✅ Full | All 99 queries supported |
| **ClickHouse** | ❌ Partial | Does not follow standard SQL syntax |

### 2.3 SSB (Star Schema Benchmark) Results

SSB is ClickHouse's preferred benchmark using pre-joined flat tables.

| Metric | StarRocks | ClickHouse | Comparison |
|--------|-----------|------------|------------|
| SSB Flat Table | 1.0x (baseline) | 2.2x slower | StarRocks 2.2x faster |
| SSB with JOINs | 1.0x (baseline) | 1.87x slower | StarRocks 1.87x faster |

**Note**: Even on ClickHouse's preferred benchmark (flat tables), StarRocks outperforms due to better vectorized execution and optimization.

### 2.4 Real-World Performance (Third-Party Tests)

| Source | Test Type | Result |
|--------|-----------|--------|
| Tinybird | Mixed workload | StarRocks faster on JOINs, ClickHouse faster on single-table |
| CelerData | Multi-table | StarRocks 2-3x faster |
| Alibaba Cloud | Production | StarRocks handles complex analytics better |

**Sources**:
- [StarRocks Official Benchmark](https://www.starrocks.io/blog/benchmark-test)
- [Tinybird: ClickHouse vs StarRocks](https://www.tinybird.co/blog/clickhouse-vs-starrocks)
- [CelerData Comparison](https://celerdata.com/blog/clickhouse-vs.-starrocks-a-detailed-comparison)
- [GitHub: Database Comparison](https://github.com/alberttwong/databasecomparison)

---

## 3. Query Engine & Optimizer

### 3.1 Optimizer Comparison

| Feature | ClickHouse | StarRocks |
|---------|------------|-----------|
| **Optimizer Type** | Rule-based | Cost-based (CBO) |
| **Statistics Collection** | Limited | Comprehensive |
| **JOIN Reordering** | Manual hints | Automatic |
| **Predicate Pushdown** | Basic | Advanced |
| **Partition Pruning** | Supported | Supported |
| **Materialized View Rewrite** | Limited | Full support |

### 3.2 Cost-Based Optimizer (StarRocks)

StarRocks' CBO analyzes:
- Table statistics and histograms
- Data distribution across partitions
- JOIN selectivity estimates
- Network and I/O costs

```sql
-- StarRocks automatically chooses optimal JOIN order
SELECT *
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN products p ON o.product_id = p.id
JOIN regions r ON c.region_id = r.id
WHERE o.order_date >= '2025-01-01';

-- CBO determines:
-- 1. Best JOIN order based on table sizes
-- 2. Optimal JOIN algorithm (hash, broadcast, shuffle)
-- 3. Predicate pushdown opportunities
-- 4. Partition pruning strategy
```

### 3.3 Rule-Based Optimizer (ClickHouse)

ClickHouse uses predefined rules that work well for simple queries but struggle with complex JOINs:

```sql
-- ClickHouse requires manual optimization hints
SELECT *
FROM orders o
GLOBAL JOIN customers c ON o.customer_id = c.id  -- Must specify GLOBAL
SETTINGS join_algorithm = 'hash'  -- Must specify algorithm
```

### 3.4 Query Execution Engine

| Feature | ClickHouse | StarRocks |
|---------|------------|-----------|
| **Execution Model** | Vectorized | Vectorized + Pipeline |
| **Pipeline Execution** | Yes (recent) | Yes (native) |
| **Parallel Execution** | Per-shard | Global MPP |
| **Spill to Disk** | Limited | Full support |
| **Memory Management** | Per-query limits | Global memory pool |

---

## 4. JOIN Performance

### 4.1 The Fundamental Difference

This is the most significant differentiator between the two databases.

#### ClickHouse JOIN Limitations

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        CLICKHOUSE JOIN BEHAVIOR                                  │
│                                                                                 │
│   Query: SELECT * FROM large_table a JOIN small_table b ON a.id = b.id         │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                        Execution Strategy                                │   │
│   │                                                                         │   │
│   │   1. Right table (b) loaded entirely into memory on EACH node          │   │
│   │   2. No automatic broadcasting or shuffling                            │   │
│   │   3. Large right tables cause OOM                                      │   │
│   │   4. Complex JOINs require manual intervention                         │   │
│   │                                                                         │   │
│   │   Problems:                                                             │   │
│   │   • Memory explosion with large dimension tables                       │   │
│   │   • No automatic JOIN reordering                                       │   │
│   │   • Poor performance on star/snowflake schemas                         │   │
│   │   • Requires denormalization for good performance                      │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│   Recommended Workaround:                                                       │
│   • Pre-join tables in ETL (Flink/Spark)                                       │
│   • Denormalize into flat tables                                               │
│   • Use dictionaries for small dimension tables                                │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

#### StarRocks JOIN Capabilities

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        STARROCKS JOIN BEHAVIOR                                   │
│                                                                                 │
│   Query: SELECT * FROM large_table a JOIN small_table b ON a.id = b.id         │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                    Cost-Based JOIN Selection                             │   │
│   │                                                                         │   │
│   │   CBO automatically selects optimal strategy:                           │   │
│   │                                                                         │   │
│   │   ┌─────────────────┐                                                   │   │
│   │   │ Broadcast JOIN  │  Small table < threshold                         │   │
│   │   │                 │  → Replicate to all nodes                        │   │
│   │   └─────────────────┘                                                   │   │
│   │                                                                         │   │
│   │   ┌─────────────────┐                                                   │   │
│   │   │ Shuffle JOIN    │  Both tables large                               │   │
│   │   │                 │  → Partition by JOIN key                         │   │
│   │   └─────────────────┘                                                   │   │
│   │                                                                         │   │
│   │   ┌─────────────────┐                                                   │   │
│   │   │ Colocate JOIN   │  Tables co-partitioned                           │   │
│   │   │                 │  → Local JOIN, no network                        │   │
│   │   └─────────────────┘                                                   │   │
│   │                                                                         │   │
│   │   ┌─────────────────┐                                                   │   │
│   │   │ Bucket JOIN     │  Same bucket distribution                        │   │
│   │   │                 │  → Parallel local JOINs                          │   │
│   │   └─────────────────┘                                                   │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│   Additional Features:                                                          │
│   • Automatic JOIN reordering                                                  │
│   • Spill to disk for large JOINs                                             │
│   • Runtime filters for predicate pushdown                                     │
│   • Adaptive query execution                                                   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 JOIN Performance Comparison

| Scenario | ClickHouse | StarRocks | Winner |
|----------|------------|-----------|--------|
| 2-table JOIN (small) | Good | Good | Tie |
| 2-table JOIN (large) | Poor (OOM risk) | Good | StarRocks |
| 3+ table JOIN | Often fails | Good | StarRocks |
| Star schema (5+ tables) | Manual optimization | Automatic | StarRocks |
| Snowflake schema | Not recommended | Supported | StarRocks |

### 4.3 Best Practices by Database

#### ClickHouse: Flatten Before Load

```sql
-- ClickHouse works best with pre-joined flat tables
-- ETL in Flink/Spark before loading:

CREATE TABLE events_flat (
    event_id UInt64,
    event_time DateTime,
    -- Denormalized user fields
    user_id UInt64,
    user_name String,
    user_email String,
    user_country String,
    -- Denormalized product fields
    product_id UInt64,
    product_name String,
    product_category String,
    -- Event data
    event_type String,
    event_value Float64
) ENGINE = MergeTree()
ORDER BY (event_time, user_id);
```

#### StarRocks: Use Star Schema Naturally

```sql
-- StarRocks handles JOINs efficiently
-- Use normalized schema:

CREATE TABLE fact_events (
    event_id BIGINT,
    event_time DATETIME,
    user_id BIGINT,
    product_id BIGINT,
    event_type VARCHAR(32),
    event_value DOUBLE
) DISTRIBUTED BY HASH(event_id);

CREATE TABLE dim_users (
    user_id BIGINT,
    user_name VARCHAR(100),
    user_email VARCHAR(100),
    country_id INT
) DISTRIBUTED BY HASH(user_id);

CREATE TABLE dim_products (
    product_id BIGINT,
    product_name VARCHAR(100),
    category_id INT
) DISTRIBUTED BY HASH(product_id);

-- Query with JOINs works efficiently
SELECT
    u.user_name,
    p.product_name,
    SUM(e.event_value)
FROM fact_events e
JOIN dim_users u ON e.user_id = u.user_id
JOIN dim_products p ON e.product_id = p.product_id
WHERE e.event_time >= '2025-01-01'
GROUP BY u.user_name, p.product_name;
```

---

## 5. Mutable Data Handling

### 5.1 Update/Delete Support Comparison

| Operation | ClickHouse | StarRocks |
|-----------|------------|-----------|
| INSERT | Excellent | Excellent |
| UPDATE (single row) | Slow (mutation) | Fast (Primary Key) |
| UPDATE (bulk) | Very slow | Fast |
| DELETE | Slow (mutation) | Fast |
| UPSERT | Via ReplacingMergeTree | Native Primary Key |
| Partial UPDATE | Not supported | Supported (v3.1+) |

### 5.2 ClickHouse Mutation Model

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      CLICKHOUSE MUTATION BEHAVIOR                                │
│                                                                                 │
│   UPDATE users SET status = 'inactive' WHERE last_login < '2024-01-01'         │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                         How Mutations Work                               │   │
│   │                                                                         │   │
│   │   1. Query identifies affected data parts                               │   │
│   │   2. ENTIRE parts are rewritten (not just affected rows)               │   │
│   │   3. Background process merges old and new parts                       │   │
│   │   4. Old parts eventually deleted                                      │   │
│   │                                                                         │   │
│   │   Timeline:                                                             │   │
│   │   ─────────────────────────────────────────────────────────────────    │   │
│   │   T=0        T=1s       T=10s      T=1min     T=5min                   │   │
│   │   │          │          │          │          │                        │   │
│   │   │ Mutation │ Queued   │ Writing  │ Merging  │ Complete               │   │
│   │   │ issued   │          │ new      │          │                        │   │
│   │   │          │          │ parts    │          │                        │   │
│   │   ─────────────────────────────────────────────────────────────────    │   │
│   │                                                                         │   │
│   │   Problems:                                                             │   │
│   │   • Very slow for frequent updates                                     │   │
│   │   • High I/O amplification                                             │   │
│   │   • Can cause OOM with many pending mutations                          │   │
│   │   • Queries may return stale data until merge completes                │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 ClickHouse ReplacingMergeTree

```sql
-- ReplacingMergeTree for eventual deduplication
CREATE TABLE users (
    user_id UInt64,
    user_name String,
    email String,
    status String,
    updated_at DateTime
) ENGINE = ReplacingMergeTree(updated_at)
ORDER BY user_id;

-- Insert new version (acts as UPDATE)
INSERT INTO users VALUES (1, 'John', 'john@new.com', 'active', now());

-- Problem: Must use FINAL for correct results
SELECT * FROM users FINAL WHERE user_id = 1;
-- Without FINAL, may return multiple versions!
```

**ReplacingMergeTree Limitations**:
- Deduplication is **eventual**, not immediate
- `FINAL` keyword required for consistent reads (slower)
- Updates only work by full row replacement
- Cannot update by arbitrary WHERE clause
- No partial column updates

### 5.4 StarRocks Primary Key Model

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      STARROCKS PRIMARY KEY MODEL                                 │
│                                                                                 │
│   UPDATE users SET status = 'inactive' WHERE last_login < '2024-01-01'         │
│                                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────────┐   │
│   │                     Delete+Insert Strategy                               │   │
│   │                                                                         │   │
│   │   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐             │   │
│   │   │   Primary    │    │   DelVector  │    │   New Data   │             │   │
│   │   │   Key Index  │    │   (Bitmap)   │    │   File       │             │   │
│   │   │              │    │              │    │              │             │   │
│   │   │  user_id → ──┼────▶  Marks old  ─┼────▶  Contains   │             │   │
│   │   │  location    │    │  version as │    │  new values  │             │   │
│   │   │              │    │  deleted    │    │              │             │   │
│   │   └──────────────┘    └──────────────┘    └──────────────┘             │   │
│   │                                                                         │   │
│   │   Benefits:                                                             │   │
│   │   • Immediate consistency (no FINAL needed)                            │   │
│   │   • Only new data written, not entire parts                            │   │
│   │   • Fast point lookups via primary key index                           │   │
│   │   • 3-10x faster than merge-on-read approaches                         │   │
│   │                                                                         │   │
│   └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.5 StarRocks Primary Key Table

```sql
-- Primary Key table for real-time UPSERT
CREATE TABLE users (
    user_id BIGINT,
    user_name VARCHAR(100),
    email VARCHAR(100),
    status VARCHAR(20),
    updated_at DATETIME
) PRIMARY KEY (user_id)
DISTRIBUTED BY HASH(user_id);

-- Standard UPDATE works efficiently
UPDATE users SET status = 'inactive'
WHERE last_login < '2024-01-01';

-- UPSERT via INSERT
INSERT INTO users VALUES (1, 'John', 'john@new.com', 'active', now())
ON DUPLICATE KEY UPDATE
    email = VALUES(email),
    status = VALUES(status),
    updated_at = VALUES(updated_at);

-- Partial update (v3.1+)
UPDATE users SET email = 'newemail@test.com' WHERE user_id = 1;

-- No FINAL needed - always returns latest version
SELECT * FROM users WHERE user_id = 1;
```

### 5.6 Performance Comparison

| Operation | ClickHouse | StarRocks |
|-----------|------------|-----------|
| Single row UPDATE | ~1-5 seconds | ~10-50 ms |
| Bulk UPDATE (1M rows) | Minutes | Seconds |
| Point lookup after UPDATE | Requires FINAL | Direct read |
| CDC streaming ingestion | Complex | Native support |

**Benchmark** (ClickHouse blog):
- ReplacingMergeTree: ~0.03-0.04s per update
- Traditional mutations: ~30-40s per update
- StarRocks Primary Key: Comparable to ReplacingMergeTree but with immediate consistency

---

## 6. Tiered Storage

### 6.1 ClickHouse Tiered Storage

```sql
-- ClickHouse storage policy configuration
<storage_configuration>
    <disks>
        <hot>
            <path>/var/lib/clickhouse/hot/</path>
        </hot>
        <cold>
            <type>s3</type>
            <endpoint>https://s3.amazonaws.com/bucket/</endpoint>
            <access_key_id>xxx</access_key_id>
            <secret_access_key>xxx</secret_access_key>
        </cold>
    </disks>
    <policies>
        <tiered>
            <volumes>
                <hot>
                    <disk>hot</disk>
                </hot>
                <cold>
                    <disk>cold</disk>
                </cold>
            </volumes>
            <move_factor>0.1</move_factor>
        </tiered>
    </policies>
</storage_configuration>

-- Table with TTL-based tiering
CREATE TABLE events (
    event_id UInt64,
    event_time DateTime,
    data String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_time)
ORDER BY event_id
TTL event_time + INTERVAL 7 DAY TO VOLUME 'cold'
SETTINGS storage_policy = 'tiered';
```

**ClickHouse Tiered Storage Characteristics**:
- TTL-based automatic movement
- `move_factor` for capacity-based movement
- Data must be merged before moving to S3
- No guarantee on which parts move first

### 6.2 StarRocks Tiered Storage (Shared-Data)

```sql
-- StarRocks shared-data mode (inherently tiered)
-- All data stored in S3, hot data cached locally

CREATE TABLE events (
    event_id BIGINT,
    event_time DATETIME,
    data STRING
) PRIMARY KEY (event_id)
PARTITION BY date_trunc('day', event_time)
DISTRIBUTED BY HASH(event_id)
PROPERTIES (
    "storage_medium" = "SSD",           -- Cache medium
    "storage_cooldown_ttl" = "7 days"   -- Cache retention
);
```

**StarRocks Tiered Storage Characteristics**:
- S3 as primary storage (source of truth)
- Local SSD as transparent cache
- No explicit data movement needed
- Cache automatically managed

### 6.3 Comparison

| Aspect | ClickHouse | StarRocks (Shared-Data) |
|--------|------------|-------------------------|
| Primary Storage | Local disk | S3 |
| Cold Storage | S3 (explicit) | S3 (native) |
| Data Movement | TTL-based rules | Automatic caching |
| Cache Management | Manual | Automatic |
| Consistency | Eventual | Immediate |
| Scaling Impact | Requires rebalancing | No impact |

---

## 7. Compute-Storage Separation

### 7.1 ClickHouse Scaling Model

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      CLICKHOUSE SCALING (Self-Managed)                           │
│                                                                                 │
│   Adding a New Node:                                                            │
│                                                                                 │
│   Before:  [Node1: 33%] [Node2: 33%] [Node3: 33%]                              │
│                                                                                 │
│   After:   [Node1: 25%] [Node2: 25%] [Node3: 25%] [Node4: 25%]                 │
│                    │           │           │                                    │
│                    └───────────┴───────────┴──────▶ Data rebalancing           │
│                                                     required!                   │
│                                                                                 │
│   Timeline:                                                                     │
│   ─────────────────────────────────────────────────────────────────            │
│   T=0        T=5min     T=30min    T=2hr      T=4hr                            │
│   │          │          │          │          │                                │
│   │ Add node │ Start    │ Data     │ Still    │ Complete                       │
│   │          │ rebalance│ moving   │ moving   │                                │
│   ─────────────────────────────────────────────────────────────────            │
│                                                                                 │
│   ClickHouse Cloud:                                                            │
│   • SharedMergeTree decouples compute/storage                                  │
│   • Auto-scaling available (~15 min latency)                                   │
│   • Still requires internal coordination                                       │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 StarRocks Scaling Model

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      STARROCKS SCALING (Shared-Data)                             │
│                                                                                 │
│   Adding a New Compute Node:                                                    │
│                                                                                 │
│   Before:  [CN1] [CN2] [CN3]  ──────────▶  S3 (All Data)                       │
│                                                                                 │
│   After:   [CN1] [CN2] [CN3] [CN4]  ────▶  S3 (All Data)                       │
│                               │                                                 │
│                               └──── No data movement!                          │
│                                     Just add compute.                          │
│                                                                                 │
│   Timeline:                                                                     │
│   ─────────────────────────────────────────────────────────────────            │
│   T=0        T=10s      T=30s                                                  │
│   │          │          │                                                      │
│   │ Add CN   │ CN joins │ Ready for                                            │
│   │          │ cluster  │ queries                                              │
│   ─────────────────────────────────────────────────────────────────            │
│                                                                                 │
│   Benefits:                                                                     │
│   • Scale in seconds, not hours                                                │
│   • No data movement or rebalancing                                            │
│   • Perfect for bursty workloads                                               │
│   • Kubernetes-native scaling                                                  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 7.3 Scaling Comparison

| Aspect | ClickHouse (Self-Managed) | ClickHouse Cloud | StarRocks (Shared-Data) |
|--------|---------------------------|------------------|-------------------------|
| Scale-out time | Hours (rebalancing) | ~15 minutes | Seconds |
| Scale-in time | Hours (rebalancing) | ~15 minutes | Seconds |
| Data movement | Required | Minimal | None |
| Scale to zero | No | Yes | Yes |
| Kubernetes native | Manual | N/A | Yes |
| Bursty workloads | Poor fit | Moderate | Excellent |

---

## 8. Iceberg Integration

### 8.1 Feature Comparison

| Feature | ClickHouse | StarRocks |
|---------|------------|-----------|
| **Read Support** | Full v2 | Full v2 |
| **Write Support** | Experimental (INSERT only) | Full (INSERT, CTAS) |
| **UPDATE/DELETE** | Not supported | Via Iceberg MOR/COW |
| **Partition Pruning** | Supported | Supported |
| **Time Travel** | Supported | Supported |
| **Schema Evolution** | Supported | Supported |
| **Production Ready** | Read: Yes, Write: No | Yes |

### 8.2 Performance Gap: Native vs Iceberg

#### StarRocks

| Format | Performance | Gap |
|--------|-------------|-----|
| Native | 1.0x (baseline) | - |
| Iceberg | 0.85-0.95x | 5-15% slower |

StarRocks 4.0 significantly closed the Iceberg performance gap through:
- Improved metadata caching
- Native Parquet reader optimization
- Better predicate pushdown
- Global shuffle for writes (fewer small files)

#### ClickHouse

| Format | Performance | Gap |
|--------|-------------|-----|
| Native (MergeTree) | 1.0x (baseline) | - |
| Iceberg | 0.5-0.7x | 30-50% slower |

ClickHouse explicitly acknowledges: *"The current approach does not leverage ClickHouse's optimized internal format, resulting in slower query performance on a data lake compared to data stored natively."*

### 8.3 Iceberg Query Examples

#### StarRocks

```sql
-- Create Iceberg catalog
CREATE EXTERNAL CATALOG iceberg_catalog
PROPERTIES (
    "type" = "iceberg",
    "iceberg.catalog.type" = "rest",
    "iceberg.catalog.uri" = "http://rest-catalog:8181"
);

-- Query Iceberg tables
SELECT * FROM iceberg_catalog.db.events
WHERE event_date = '2025-01-14';

-- Write to Iceberg (production ready)
INSERT INTO iceberg_catalog.db.events
SELECT * FROM native_table WHERE ...;

-- Time travel
SELECT * FROM iceberg_catalog.db.events
FOR VERSION AS OF 12345;
```

#### ClickHouse

```sql
-- Create Iceberg table function (read-only recommended)
SELECT * FROM iceberg(
    's3://bucket/warehouse/db/events',
    'access_key',
    'secret_key'
)
WHERE event_date = '2025-01-14';

-- Write support (experimental, not production ready)
INSERT INTO FUNCTION iceberg(...) SELECT ...;
-- Note: No UPDATE/DELETE support
```

### 8.4 Iceberg Write Quality

StarRocks 4.0 introduced improvements to avoid the small file problem:

| Metric | Before 4.0 | After 4.0 |
|--------|------------|-----------|
| Files (100 partitions) | 170,000+ | 259 |
| Files (500 partitions) | 230,000+ | 596 |

This is achieved through **global shuffle** that routes data to avoid overlapping writes across backends.

---

## 9. Concurrency & Scalability

### 9.1 Concurrency Limits

| Metric | ClickHouse | StarRocks |
|--------|------------|-----------|
| Concurrent queries | ~100-500 | ~1,000-10,000 |
| P95 latency degradation | Significant at 500 QPS | Minimal at 1000 QPS |
| Resource isolation | Limited | Query pools, resource groups |

### 9.2 ClickHouse Concurrency Behavior

```
Concurrent Queries vs P95 Latency (ClickHouse):

P95 Latency (ms)
    │
4000├                                          ╱
    │                                        ╱
3000├                                      ╱
    │                                    ╱
2000├                              ────╱
    │                        ────
1000├                  ────
    │            ────
 500├──────────
    │
    └───────────────────────────────────────────▶
        50    100   200   300   400   500   QPS

Note: Significant degradation starts around 200-300 concurrent queries
```

### 9.3 StarRocks Concurrency Behavior

```
Concurrent Queries vs P95 Latency (StarRocks):

P95 Latency (ms)
    │
4000├
    │
3000├
    │
2000├
    │                                          ╱
1000├                                    ────╱
    │                              ────
 500├────────────────────────────
    │
    └───────────────────────────────────────────▶
        100   500   1000  2000  3000  5000  QPS

Note: Maintains sub-second P95 up to ~3000 concurrent queries
```

### 9.4 Resource Isolation

#### StarRocks Resource Groups

```sql
-- Create resource groups for workload isolation
CREATE RESOURCE GROUP etl_group
WITH (
    cpu_core_limit = 8,
    mem_limit = '32G',
    concurrency_limit = 20
);

CREATE RESOURCE GROUP analytics_group
WITH (
    cpu_core_limit = 16,
    mem_limit = '64G',
    concurrency_limit = 100
);

-- Assign queries to resource groups
SET resource_group = 'analytics_group';
SELECT * FROM events WHERE ...;
```

#### ClickHouse Resource Management

```sql
-- Basic resource limits via settings
SET max_memory_usage = 10000000000;
SET max_threads = 8;

-- User-level quotas
CREATE QUOTA analytics_quota
FOR INTERVAL 1 hour MAX queries = 1000, result_rows = 1000000000;
```

---

## 10. Operational Complexity

### 10.1 Deployment Complexity

| Aspect | ClickHouse | StarRocks |
|--------|------------|-----------|
| Minimum nodes | 1 | 3 (1 FE + 2 BE/CN) |
| HA configuration | ZooKeeper/Keeper required | Built-in FE HA |
| Kubernetes operator | Community maintained | Official operator |
| Configuration complexity | High (many settings) | Moderate |

### 10.2 Maintenance Operations

| Operation | ClickHouse | StarRocks |
|-----------|------------|-----------|
| Schema changes | Online DDL (most) | Online DDL |
| Partition management | Manual | Automatic options |
| Compaction | Automatic (merges) | Automatic |
| Backup/Restore | Built-in | Built-in |
| Cluster expansion | Complex (rebalancing) | Simple (no rebalancing) |

### 10.3 Monitoring & Observability

| Feature | ClickHouse | StarRocks |
|---------|------------|-----------|
| System tables | Extensive | Extensive |
| Query profiling | Built-in | Built-in |
| Prometheus metrics | Supported | Supported |
| Slow query log | Supported | Supported |
| Distributed tracing | Limited | Supported |

---

## 11. Cost Analysis

### 11.1 TCO Components

| Component | ClickHouse | StarRocks |
|-----------|------------|-----------|
| Compute (query) | Lower single-table | Lower multi-table |
| Compute (JOIN) | Higher (pre-processing needed) | Lower (native) |
| Storage (native) | Similar | Similar |
| Storage (updates) | Higher (write amplification) | Lower |
| Operations (scaling) | Higher (rebalancing) | Lower |
| ETL (denormalization) | Required for JOINs | Not required |

### 11.2 When ClickHouse is More Cost-Effective

- Single-table aggregations at massive scale
- Pre-denormalized data (flat tables)
- Simple queries without JOINs
- Log analytics with grep-like patterns
- Time-series with simple rollups

### 11.3 When StarRocks is More Cost-Effective

- Multi-table JOIN workloads
- Star/snowflake schema analytics
- Mixed mutable and immutable data
- Bursty workloads requiring elastic scaling
- Iceberg/lakehouse integration

### 11.4 Hidden Costs

#### ClickHouse Hidden Costs

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      CLICKHOUSE HIDDEN COSTS                                     │
│                                                                                 │
│   1. ETL Pipeline for Denormalization                                          │
│      • Flink/Spark jobs to pre-join data                                       │
│      • Additional compute resources                                            │
│      • Pipeline maintenance overhead                                           │
│                                                                                 │
│   2. Storage Amplification from Mutations                                      │
│      • Updates create new data parts                                           │
│      • Storage usage spikes during merges                                      │
│      • Need to over-provision storage                                          │
│                                                                                 │
│   3. Query Failures and Retries                                                │
│      • Complex JOINs may OOM                                                   │
│      • Need query retry logic                                                  │
│      • User experience impact                                                  │
│                                                                                 │
│   4. Scaling Downtime                                                          │
│      • Rebalancing takes hours                                                 │
│      • Performance degradation during rebalance                                │
│      • Cannot quickly respond to load changes                                  │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

#### StarRocks Hidden Costs

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                      STARROCKS HIDDEN COSTS                                      │
│                                                                                 │
│   1. Learning Curve                                                            │
│      • Less documentation than ClickHouse                                      │
│      • Smaller community (but growing)                                         │
│      • Fewer third-party integrations                                          │
│                                                                                 │
│   2. FE Node Requirements                                                      │
│      • Need minimum 3 FE nodes for HA                                          │
│      • FE memory requirements for metadata                                     │
│                                                                                 │
│   3. S3 Request Costs (Shared-Data Mode)                                       │
│      • More S3 GET requests than local storage                                 │
│      • Cache misses result in S3 reads                                         │
│      • Need to size cache appropriately                                        │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 12. Decision Matrix

### 12.1 Feature-by-Feature Comparison

| Feature | ClickHouse | StarRocks | Winner |
|---------|------------|-----------|--------|
| Single-table queries | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Tie |
| Multi-table JOINs | ⭐⭐ | ⭐⭐⭐⭐⭐ | **StarRocks** |
| TPC-H/TPC-DS | ⭐⭐ (partial) | ⭐⭐⭐⭐⭐ | **StarRocks** |
| UPDATE/DELETE | ⭐⭐ | ⭐⭐⭐⭐⭐ | **StarRocks** |
| Real-time UPSERT | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **StarRocks** |
| Tiered storage | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **StarRocks** |
| Elastic scaling | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **StarRocks** |
| Iceberg read | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **StarRocks** |
| Iceberg write | ⭐⭐ | ⭐⭐⭐⭐ | **StarRocks** |
| Concurrency | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | **StarRocks** |
| Community size | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | **ClickHouse** |
| Documentation | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **ClickHouse** |
| Managed offerings | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | **ClickHouse** |

### 12.2 Use Case Recommendations

| Use Case | Recommended | Reason |
|----------|-------------|--------|
| Log analytics (simple) | ClickHouse | Optimized for grep-like queries |
| Time-series (simple) | Either | Both perform well |
| Star schema analytics | **StarRocks** | Native JOIN support |
| Real-time dashboards | **StarRocks** | Better concurrency |
| CDC streaming | **StarRocks** | Primary Key tables |
| Data lakehouse | **StarRocks** | Better Iceberg integration |
| Pre-aggregated metrics | ClickHouse | MaterializedViews |
| Ad-hoc exploration | **StarRocks** | Flexible JOINs |

### 12.3 Final Recommendation for This Workload

Given the requirements:
- 60 TB/day ingestion
- Multi-table JOINs (2+ tables)
- Mix of mutable and immutable data
- Tiered storage (hot SSD + cold S3)
- Elastic compute scaling
- Iceberg for cold storage

**Recommendation: StarRocks**

| Requirement | StarRocks Fit |
|-------------|---------------|
| 60TB/day ingestion | ✅ Excellent throughput |
| Multi-table JOINs | ✅ Native CBO support |
| Mutable tables | ✅ Primary Key tables |
| Tiered storage | ✅ Native shared-data |
| Elastic scaling | ✅ Seconds to scale |
| Iceberg integration | ✅ Full read/write |

---

## Appendix A: Benchmark Reproduction

### A.1 TPC-H Setup (StarRocks)

```sql
-- Generate TPC-H data
-- Use dbgen tool from TPC

-- Create tables
CREATE DATABASE tpch;
USE tpch;

CREATE TABLE lineitem (...)
DISTRIBUTED BY HASH(l_orderkey);

CREATE TABLE orders (...)
DISTRIBUTED BY HASH(o_orderkey);

-- ... other tables

-- Run TPC-H queries
-- All 22 queries should complete
```

### A.2 TPC-H Setup (ClickHouse)

```sql
-- Generate TPC-H data
-- Use dbgen tool from TPC

-- Create tables
CREATE DATABASE tpch;
USE tpch;

CREATE TABLE lineitem (...)
ENGINE = MergeTree()
ORDER BY (l_shipdate, l_orderkey);

-- ... other tables

-- Note: Queries Q2, Q5, Q7, Q8, Q9, Q16, Q17, Q20
-- may fail or require modification
```

---

## Appendix B: References

### Official Documentation
- [StarRocks Documentation](https://docs.starrocks.io/)
- [ClickHouse Documentation](https://clickhouse.com/docs)

### Benchmarks
- [StarRocks Benchmark Blog](https://www.starrocks.io/blog/benchmark-test)
- [ClickHouse Benchmark](https://clickhouse.com/benchmark)
- [Third-Party: Tinybird Comparison](https://www.tinybird.co/blog/clickhouse-vs-starrocks)

### Technical Deep Dives
- [StarRocks Primary Key Tables](https://docs.starrocks.io/docs/table_design/table_types/primary_key_table/)
- [ClickHouse ReplacingMergeTree](https://altinity.com/blog/clickhouse-replacingmergetree-explained-the-good-the-bad-and-the-ugly)
- [StarRocks Cost-Based Optimizer](https://docs.starrocks.io/docs/administration/Query_planning/)
- [ClickHouse JOIN Algorithms](https://clickhouse.com/docs/en/sql-reference/statements/select/join)

### Architecture
- [StarRocks Shared-Data Architecture](https://docs.starrocks.io/docs/deployment/shared_data/s3)
- [ClickHouse Cloud Architecture](https://clickhouse.com/blog/building-clickhouse-cloud-from-scratch-in-a-year)

---

*Document Version: 1.0*
*Last Updated: January 2025*
*Classification: Technical Evaluation*
