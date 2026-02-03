# StarRocks vs ClickHouse: Evaluation Framework

## Document Information
| Field | Value |
|-------|-------|
| Version | 1.0 |
| Created | February 2026 |
| Purpose | Structured evaluation framework for OLAP database selection |
| Stakeholders | Data Engineering, Analytics, Platform Engineering |

---

## 1. Executive Summary

This document provides a structured evaluation framework for comparing StarRocks and ClickHouse based on specific business requirements. The evaluation uses a weighted scoring methodology to objectively assess each platform against defined success criteria.

### Key Requirements Summary
1. **Mutable Data Ingestion** - Support for UPDATE/DELETE with multi-table joins (4-6 tables)
2. **Iceberg Federation** - Join native and Iceberg data seamlessly
3. **Materialized Views** - Automatic query rewrite capability
4. **BI Integration** - Looker connectivity and SQL compatibility
5. **Elastic Scaling** - Scale compute during business hours
6. **Cost Efficiency** - Total cost of ownership and maintenance burden
7. **SQL Extensibility** - Standard SQL support and extensibility
8. **Iceberg Sink** - Write data to Iceberg format (nice-to-have)
9. **Community & Support** - Ecosystem maturity and support options

---

## 2. Scoring Methodology

### 2.1 Scoring Scale

| Score | Rating | Description |
|-------|--------|-------------|
| 5 | Excellent | Fully meets requirements with best-in-class capabilities |
| 4 | Good | Meets requirements with minor limitations |
| 3 | Adequate | Meets basic requirements but has notable gaps |
| 2 | Limited | Partially meets requirements with significant limitations |
| 1 | Poor | Does not meet requirements or requires extensive workarounds |
| 0 | Not Supported | Feature not available |

### 2.2 Weight Categories

| Priority | Weight | Description |
|----------|--------|-------------|
| Must Have | 3x | Critical requirements that must be satisfied |
| Important | 2x | Significant requirements that strongly influence decision |
| Nice to Have | 1x | Desirable features that add value |

---

## 3. Detailed Evaluation Criteria

### 3.1 Mutable Data & Multi-Table Joins (Must Have - Weight: 3x)

#### Business Requirement
The system must support highly mutable data with efficient UPDATE and DELETE operations while maintaining query performance for complex multi-table joins involving 4-6 tables.

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| UPDATE/DELETE Performance | 30% | Latency and throughput for data mutations |
| Mutation Consistency | 20% | How quickly mutations are visible to queries |
| Join Optimizer | 25% | Quality of cost-based optimizer for multi-table joins |
| Join Performance | 25% | Actual query latency for 4-6 table joins |

#### StarRocks Assessment

**Score: 4.5/5**

| Capability | Details |
|------------|---------|
| **Primary Key Table** | Purpose-built for real-time mutations with sub-second visibility |
| **Unique Key Table** | Supports UPSERT semantics with merge-on-read |
| **Update Model** | Direct UPDATE/DELETE SQL support |
| **Consistency** | Mutations visible immediately after commit |
| **Join Optimizer** | Cascades-style CBO with cardinality estimation |
| **Join Strategies** | Broadcast, shuffle, bucket, collocated joins |
| **Runtime Optimization** | Adaptive join reordering based on runtime statistics |

**Strengths:**
- Native support for real-time mutations without background merge dependency
- Advanced cost-based optimizer designed for complex joins
- Multiple join strategies automatically selected based on data distribution
- Global runtime filter for join acceleration

**Limitations:**
- Primary Key tables have slightly higher storage overhead
- Very high mutation rates (>100K/s per table) may require tuning

#### ClickHouse Assessment

**Score: 2.5/5**

| Capability | Details |
|------------|---------|
| **ReplacingMergeTree** | Deduplication during async background merges |
| **CollapsingMergeTree** | Row versioning with +1/-1 sign columns |
| **Update Model** | ALTER TABLE UPDATE (heavy operation) or mutation via insert |
| **Consistency** | Eventual consistency - depends on merge completion |
| **Join Optimizer** | Rule-based with limited cost estimation |
| **Join Strategies** | Hash join, partial merge join |
| **Runtime Optimization** | Limited adaptive capabilities |

**Strengths:**
- High insert throughput for append-only workloads
- Flexible engine selection for different use cases

**Limitations:**
- Mutations are asynchronous and may not be immediately visible
- FINAL keyword required for consistent reads (significant performance penalty)
- Join optimizer prefers denormalized schemas
- Multi-table joins often require manual optimization hints
- No native support for immediate consistency after UPDATE

#### Test Protocol

```sql
-- Test 1: Mutation Latency
-- Insert record, update it, measure time until update is visible

-- StarRocks
UPDATE fact_table SET amount = 100 WHERE id = 12345;
SELECT * FROM fact_table WHERE id = 12345; -- Should reflect update immediately

-- ClickHouse
ALTER TABLE fact_table UPDATE amount = 100 WHERE id = 12345;
SELECT * FROM fact_table FINAL WHERE id = 12345; -- Requires FINAL for consistency

-- Test 2: Multi-table Join Performance
-- Execute representative 4-6 table join query
SELECT
    f.transaction_id,
    c.customer_name,
    p.product_name,
    s.store_name,
    d.full_date,
    r.region_name
FROM fact_transactions f
JOIN dim_customer c ON f.customer_id = c.id
JOIN dim_product p ON f.product_id = p.id
JOIN dim_store s ON f.store_id = s.id
JOIN dim_date d ON f.date_id = d.id
JOIN dim_region r ON s.region_id = r.id
WHERE d.year = 2024
GROUP BY 1, 2, 3, 4, 5, 6;

-- Measure: Query latency, memory usage, CPU utilization
```

---

### 3.2 Native + Iceberg Data Federation (Must Have - Weight: 3x)

#### Business Requirement
The system must seamlessly join data stored in native tables with data stored in Apache Iceberg format, supporting predicate pushdown and efficient query execution across both storage layers.

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| Iceberg Catalog Support | 25% | Hive Metastore, AWS Glue, REST catalog support |
| Query Performance | 30% | Join performance between native and Iceberg tables |
| Predicate Pushdown | 20% | Ability to push filters to Iceberg layer |
| Metadata Integration | 15% | Schema evolution, partition pruning support |
| Operational Simplicity | 10% | Ease of setup and maintenance |

#### StarRocks Assessment

**Score: 5/5**

| Capability | Details |
|------------|---------|
| **Catalog Types** | Hive Metastore, AWS Glue, REST Catalog, Tabular |
| **Iceberg Versions** | V1 and V2 (including merge-on-read) |
| **Query Federation** | Native SQL joins across catalogs |
| **Predicate Pushdown** | Full support including partition pruning |
| **Statistics** | Reads Iceberg statistics for query optimization |
| **Time Travel** | Supported via FOR VERSION/TIMESTAMP syntax |
| **Schema Evolution** | Automatic schema sync with Iceberg |

**Configuration Example:**
```sql
CREATE EXTERNAL CATALOG iceberg_catalog
PROPERTIES (
    "type" = "iceberg",
    "iceberg.catalog.type" = "glue",
    "aws.glue.region" = "us-east-1"
);

-- Query joining native and Iceberg data
SELECT n.*, i.*
FROM native_db.native_table n
JOIN iceberg_catalog.iceberg_db.iceberg_table i
    ON n.key = i.key
WHERE i.partition_date >= '2024-01-01';
```

**Strengths:**
- First-class Iceberg support with multiple catalog backends
- CBO optimizer considers both native and Iceberg statistics
- Transparent query planning across storage layers
- Supports Iceberg V2 row-level deletes

**Limitations:**
- Initial catalog sync can take time for large catalogs
- Some advanced Iceberg features (e.g., branching) have limited support

#### ClickHouse Assessment

**Score: 2/5**

| Capability | Details |
|------------|---------|
| **Catalog Types** | Limited (experimental iceberg() table function) |
| **Iceberg Versions** | V1 only (limited V2 support) |
| **Query Federation** | Via table functions, not native catalogs |
| **Predicate Pushdown** | Partial support |
| **Statistics** | Limited use of Iceberg statistics |
| **Time Travel** | Not supported |
| **Schema Evolution** | Manual refresh required |

**Configuration Example:**
```sql
-- ClickHouse uses table functions (less integrated)
SELECT * FROM iceberg('s3://bucket/path/to/iceberg/table');

-- Joining with native table
SELECT n.*, i.*
FROM native_table n
JOIN iceberg('s3://bucket/path/to/table') i ON n.key = i.key;
```

**Strengths:**
- Can read basic Iceberg tables
- S3 integration works

**Limitations:**
- No native catalog abstraction
- Table function approach is less ergonomic
- Limited optimizer integration
- No support for Iceberg time travel
- V2 merge-on-read not fully supported

#### Test Protocol

```sql
-- Test 1: Catalog Setup and Query
-- Create external catalog pointing to Iceberg
-- Run SHOW DATABASES, SHOW TABLES to verify discovery
-- Execute simple SELECT with predicate pushdown

-- Test 2: Federation Join Performance
-- Join 1M row native table with 10M row Iceberg table
-- Measure: Query latency, data scanned from Iceberg, predicate pushdown effectiveness

EXPLAIN SELECT ...  -- Verify predicate pushdown in query plan
```

---

### 3.3 Materialized Views & Query Rewrite (Must Have - Weight: 3x)

#### Business Requirement
The system must support materialized views with automatic query rewrite capability, allowing the optimizer to transparently route queries to pre-computed MVs without requiring application changes.

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| Automatic Query Rewrite | 40% | Optimizer automatically uses MVs |
| Incremental Refresh | 25% | Efficient partial refresh capabilities |
| MV on External Tables | 15% | Create MVs on Iceberg/external data |
| Refresh Strategies | 10% | Async, sync, manual refresh options |
| MV Management | 10% | Monitoring, invalidation, lifecycle |

#### StarRocks Assessment

**Score: 5/5**

| Capability | Details |
|------------|---------|
| **Query Rewrite** | Automatic, transparent query rewrite by CBO |
| **Rewrite Scope** | Aggregation, join, filter, projection lifting |
| **Incremental Refresh** | Yes, tracks changed partitions/data |
| **External Table MVs** | Supported for Iceberg, Hive, JDBC sources |
| **Refresh Modes** | ASYNC (scheduled), MANUAL, ON COMMIT (limited) |
| **Nested MVs** | MVs can be built on other MVs |
| **Monitoring** | Built-in refresh history and statistics |

**Configuration Example:**
```sql
-- Create MV with automatic refresh
CREATE MATERIALIZED VIEW daily_sales_mv
DISTRIBUTED BY HASH(date_key)
REFRESH ASYNC EVERY (INTERVAL 1 HOUR)
AS
SELECT
    date_key,
    store_id,
    SUM(amount) as total_amount,
    COUNT(*) as transaction_count
FROM fact_sales
GROUP BY date_key, store_id;

-- Query automatically rewritten to use MV
SELECT date_key, SUM(total_amount)
FROM fact_sales
WHERE date_key >= '2024-01-01'
GROUP BY date_key;

-- Verify rewrite with EXPLAIN
EXPLAIN SELECT ...;
-- Output shows: "MaterializedView: daily_sales_mv"
```

**Strengths:**
- Transparent query rewrite without application changes
- Supports partial rewrite (subset of columns/aggregations)
- Incremental refresh tracks data lineage
- MVs on Iceberg tables enable hybrid architectures
- Rich rewrite capabilities including join elimination

**Limitations:**
- Complex MVs with many joins may have longer refresh times
- Some query patterns may not be rewriteable

#### ClickHouse Assessment

**Score: 2/5**

| Capability | Details |
|------------|---------|
| **Query Rewrite** | Not supported - must query MV directly |
| **Incremental Refresh** | Yes, via TO clause target tables |
| **External Table MVs** | Not supported |
| **Refresh Modes** | Triggered on source table inserts only |
| **Nested MVs** | Supported via chained target tables |
| **Monitoring** | Via system.mutations and system.parts |

**Configuration Example:**
```sql
-- ClickHouse MV (populates on INSERT, no query rewrite)
CREATE MATERIALIZED VIEW daily_sales_mv
ENGINE = SummingMergeTree()
ORDER BY (date_key, store_id)
AS
SELECT
    date_key,
    store_id,
    sum(amount) as total_amount,
    count() as transaction_count
FROM fact_sales
GROUP BY date_key, store_id;

-- Must query MV directly - no automatic rewrite
SELECT date_key, sum(total_amount)
FROM daily_sales_mv  -- Explicit MV reference required
WHERE date_key >= '2024-01-01'
GROUP BY date_key;
```

**Strengths:**
- Efficient incremental population on INSERT
- Good for streaming aggregation pipelines
- Flexible target table engine selection

**Limitations:**
- **No automatic query rewrite** - applications must know about MVs
- Only refreshes on INSERT, not UPDATE/DELETE
- Cannot create MVs on external/Iceberg tables
- Requires application-level routing logic

#### Test Protocol

```sql
-- Test 1: Query Rewrite Verification
-- Create MV with aggregation
-- Run query that could use MV
-- EXPLAIN to verify MV is used automatically (StarRocks)
-- Verify ClickHouse requires direct MV query

-- Test 2: Incremental Refresh
-- Insert new data into base table
-- Measure refresh time and data scanned
-- Verify MV reflects new data accurately
```

---

### 3.4 Looker Integration (Must Have - Weight: 3x)

#### Business Requirement
The system must integrate seamlessly with Looker for business intelligence, supporting standard SQL constructs, connection pooling, and query generation patterns used by Looker.

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| SQL Dialect Compatibility | 35% | Looker SQL generation compatibility |
| Connection Reliability | 25% | JDBC/ODBC stability and pooling |
| Query Performance | 25% | Performance with Looker-generated queries |
| Setup Complexity | 15% | Ease of configuration |

#### StarRocks Assessment

**Score: 4.5/5**

| Capability | Details |
|------------|---------|
| **Looker Dialect** | Uses MySQL dialect (well-supported) |
| **Connection** | MySQL protocol on port 9030 |
| **JDBC Driver** | MySQL Connector/J (official MySQL driver) |
| **SQL Compatibility** | High - standard SQL with MySQL extensions |
| **Connection Pooling** | Supported via standard MySQL connection pools |
| **Concurrent Queries** | Handles high concurrency well |

**Configuration:**
```yaml
# Looker connection settings
connection: starrocks_prod
host: starrocks-fe.example.com
port: 9030
database: analytics
username: looker_user
dialect: mysql  # Use MySQL dialect
```

**Strengths:**
- MySQL protocol compatibility means wide driver support
- Standard SQL functions work as expected
- Good handling of Looker's generated SQL patterns
- Predictable query performance

**Limitations:**
- Some MySQL-specific functions may behave slightly differently
- May need to disable certain Looker optimizations for complex queries

#### ClickHouse Assessment

**Score: 4/5**

| Capability | Details |
|------------|---------|
| **Looker Dialect** | Native ClickHouse dialect available |
| **Connection** | Native protocol (9000) or HTTP (8123) |
| **JDBC Driver** | Official ClickHouse JDBC driver |
| **SQL Compatibility** | ClickHouse SQL (some syntax differences) |
| **Connection Pooling** | Supported |
| **Concurrent Queries** | Good with proper resource management |

**Configuration:**
```yaml
# Looker connection settings
connection: clickhouse_prod
host: clickhouse.example.com
port: 8123  # HTTP interface
database: analytics
username: looker_user
dialect: clickhouse
```

**Strengths:**
- Official Looker dialect for ClickHouse
- Native driver with good performance
- Large user base with documented patterns

**Limitations:**
- Some SQL constructs generate less optimal queries
- JOIN syntax differences may require LookML adjustments
- FINAL clause considerations for mutable data

#### Test Protocol

1. Connect Looker to both databases
2. Create identical LookML model
3. Build sample dashboard with:
   - Simple aggregation queries
   - Multi-table join queries
   - Time-series queries
   - Filtered queries with user input
4. Compare: Query generation, performance, error rates

---

### 3.5 Elastic Scaling (Must Have for Reads, Nice-to-Have for Writes - Weight: 2.5x)

#### Business Requirement
The system must support elastic scaling of read capacity during business hours to handle peak query loads. Additionally, the ability to scale write capacity for time-of-day traffic patterns is desirable.

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| Read Scaling Speed | 30% | Time to add read capacity |
| Read Scaling Granularity | 20% | Ability to scale incrementally |
| Write Scaling Capability | 20% | Ability to scale ingestion |
| Auto-scaling Support | 15% | Automated scaling triggers |
| Cost Efficiency | 15% | Pay for actual usage |

#### StarRocks Assessment

**Score: 4.5/5**

| Capability | Details |
|------------|---------|
| **Architecture** | Shared-data with stateless Compute Nodes (CN) |
| **Read Scaling** | Add/remove CNs in minutes (no data movement) |
| **Write Scaling** | CNs handle both read and write |
| **Auto-scaling** | K8s HPA, CelerData Cloud auto-scaling |
| **Scale Granularity** | Individual CN nodes |
| **Warm-up Time** | 1-3 minutes for new nodes |
| **Data Rebalancing** | Not required (shared storage) |

**Scaling Architecture:**
```
┌─────────────────────────────────────────────────────┐
│                  StarRocks Shared-Data              │
│                                                     │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│   │  CN-1   │  │  CN-2   │  │  CN-3   │◄── Scale  │
│   │(compute)│  │(compute)│  │(compute)│    out    │
│   └────┬────┘  └────┬────┘  └────┬────┘           │
│        │            │            │                 │
│        └────────────┼────────────┘                 │
│                     ▼                              │
│        ┌────────────────────────┐                 │
│        │    Shared Storage      │                 │
│        │    (S3/HDFS/MinIO)     │                 │
│        └────────────────────────┘                 │
└─────────────────────────────────────────────────────┘
```

**Strengths:**
- Stateless compute enables rapid scaling
- No data movement required when scaling
- Can scale reads and writes independently (with warehouse isolation)
- Sub-minute scale-up achievable with warm node pools

**Limitations:**
- Shared-data mode required (not classic BE mode)
- Cold start queries may have slightly higher latency

#### ClickHouse Assessment

**Score: 3/5 (Self-hosted) / 4/5 (ClickHouse Cloud)**

| Capability | Details |
|------------|---------|
| **Architecture** | Shared-nothing (self-hosted) / SharedMergeTree (Cloud) |
| **Read Scaling** | Replicas (self-hosted) / Auto-scale (Cloud) |
| **Write Scaling** | Add shards (requires rebalancing) |
| **Auto-scaling** | ClickHouse Cloud only |
| **Scale Granularity** | Replica/shard level |
| **Warm-up Time** | 5-15 minutes (Cloud), longer for self-hosted |
| **Data Rebalancing** | Required for shard scaling (self-hosted) |

**Self-hosted Scaling:**
```
┌─────────────────────────────────────────────────────┐
│              ClickHouse Self-Hosted                 │
│                                                     │
│   Shard 1              Shard 2                      │
│   ┌─────────┐          ┌─────────┐                 │
│   │ Node 1  │          │ Node 3  │                 │
│   │ (data)  │          │ (data)  │                 │
│   └─────────┘          └─────────┘                 │
│   ┌─────────┐          ┌─────────┐                 │
│   │ Node 2  │◄──Read   │ Node 4  │                 │
│   │(replica)│   Scale  │(replica)│                 │
│   └─────────┘          └─────────┘                 │
│                                                     │
│   Note: Adding shards requires data rebalancing    │
└─────────────────────────────────────────────────────┘
```

**Strengths:**
- ClickHouse Cloud has good auto-scaling
- Read replicas work well for read scaling
- Mature operational tooling

**Limitations:**
- Self-hosted scaling is operationally complex
- Write scaling requires shard rebalancing
- SharedMergeTree only available in managed Cloud
- Scale-up latency higher than StarRocks

#### Test Protocol

1. Establish baseline query performance
2. Increase query load 3x
3. Trigger scale-out (add compute)
4. Measure: Time to scale, query latency during scaling, cost

---

### 3.6 Cost & Maintenance (Important - Weight: 2x)

#### Business Requirement
The system should provide cost-effective operation with manageable maintenance overhead, including clear visibility into resource consumption and predictable pricing.

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| License Cost | 20% | Software licensing fees |
| Compute Cost | 25% | CPU/memory resource efficiency |
| Storage Cost | 20% | Storage efficiency and tiering |
| Operational Overhead | 20% | Day-to-day maintenance effort |
| Managed Service Options | 15% | Availability of managed offerings |

#### StarRocks Assessment

**Score: 4/5**

| Factor | Details |
|--------|---------|
| **License** | Apache 2.0 (free) |
| **Managed Options** | CelerData Cloud, AWS Marketplace |
| **Self-hosted Components** | FE (coordinator) + CN (compute) |
| **Storage Efficiency** | Columnar + LZ4/ZSTD compression |
| **Monitoring** | Built-in metrics, Prometheus integration |
| **Upgrades** | Rolling upgrades supported |
| **Backup** | Built-in backup/restore to S3 |

**Cost Drivers:**
- Compute: CN nodes (CPU/memory intensive)
- Storage: S3/object storage (cost-effective)
- FE nodes: 3 for HA (modest resource requirements)

**Operational Tasks:**
- Monitor FE leader election
- Manage compute node scaling
- Configure data tiering policies
- Regular compaction monitoring

#### ClickHouse Assessment

**Score: 3.5/5**

| Factor | Details |
|--------|---------|
| **License** | Apache 2.0 (free) |
| **Managed Options** | ClickHouse Cloud |
| **Self-hosted Components** | ClickHouse nodes + Keeper (ZK replacement) |
| **Storage Efficiency** | Columnar + high compression ratios |
| **Monitoring** | system.* tables, Grafana dashboards |
| **Upgrades** | Rolling upgrades (can be complex) |
| **Backup** | clickhouse-backup tool |

**Cost Drivers:**
- Compute: Each node has local storage (more nodes = more storage)
- Storage: Local SSDs for performance, S3 for cold tier
- Keeper: 3 nodes for coordination

**Operational Tasks:**
- Monitor ZooKeeper/Keeper health
- Manage shard rebalancing
- Handle merge operations and mutations
- Storage capacity planning per node

---

### 3.7 SQL Support & Extensibility (Important - Weight: 2x)

#### Business Requirement
The system should support standard ANSI SQL for ease of migration and development, with extensibility options for custom functions and integrations.

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| ANSI SQL Compliance | 35% | Standard SQL syntax support |
| Window Functions | 20% | Advanced analytical functions |
| UDF Support | 20% | Custom function extensibility |
| Query Features | 15% | CTEs, subqueries, set operations |
| Migration Ease | 10% | Compatibility with existing queries |

#### StarRocks Assessment

**Score: 4.5/5**

| Capability | Details |
|------------|---------|
| **SQL Standard** | High ANSI compliance, MySQL compatible |
| **Window Functions** | Full support (ROW_NUMBER, RANK, LAG, LEAD, etc.) |
| **CTEs** | Supported (WITH clause) |
| **Subqueries** | Correlated and uncorrelated |
| **UDFs** | Java UDFs, Python UDFs (upcoming) |
| **Set Operations** | UNION, INTERSECT, EXCEPT |
| **Lateral Joins** | Supported |

**Strengths:**
- MySQL syntax familiarity
- Most standard SQL queries work without modification
- Good window function performance

**Limitations:**
- Some PostgreSQL-specific syntax not supported
- UDF ecosystem less mature than ClickHouse

#### ClickHouse Assessment

**Score: 4/5**

| Capability | Details |
|------------|---------|
| **SQL Standard** | Moderate compliance with ClickHouse extensions |
| **Window Functions** | Full support |
| **CTEs** | Supported |
| **Subqueries** | Some limitations with correlated subqueries |
| **UDFs** | C++, SQL, JavaScript UDFs |
| **Set Operations** | UNION ALL (UNION DISTINCT has limitations) |
| **Array/Map Functions** | Extensive (strength) |

**Strengths:**
- Rich array and map manipulation functions
- Powerful aggregation combinators (-If, -Array, etc.)
- Extensive built-in functions
- Mature UDF ecosystem

**Limitations:**
- Non-standard SQL syntax in some areas
- JOINs have different semantics (ALL vs ANY)
- Some queries require rewriting from standard SQL

---

### 3.8 Iceberg Sink / Write Capability (Nice-to-Have - Weight: 1x)

#### Business Requirement
The ability to write data from the OLAP system into Iceberg format would enable data sharing with other systems in the data lakehouse architecture.

#### StarRocks Assessment

**Score: 5/5**

| Capability | Details |
|------------|---------|
| **INSERT INTO Iceberg** | Fully supported |
| **CTAS to Iceberg** | CREATE TABLE AS SELECT supported |
| **Iceberg Table Management** | CREATE, ALTER, DROP tables |
| **Partition Write** | Dynamic and static partitioning |
| **Data Formats** | Parquet output format |

**Example:**
```sql
-- Write query results to Iceberg
INSERT INTO iceberg_catalog.db.output_table
SELECT * FROM native_table WHERE date >= '2024-01-01';

-- Create new Iceberg table from query
CREATE TABLE iceberg_catalog.db.new_table AS
SELECT customer_id, SUM(amount) as total
FROM fact_sales
GROUP BY customer_id;
```

#### ClickHouse Assessment

**Score: 1/5**

| Capability | Details |
|------------|---------|
| **INSERT INTO Iceberg** | Not supported |
| **CTAS to Iceberg** | Not supported |
| **Iceberg Table Management** | Read-only |

**Workaround:** Export to Parquet, use external tools (Spark) to write to Iceberg.

---

### 3.9 Community & Ecosystem (Nice-to-Have - Weight: 1x)

#### Evaluation Criteria

| Sub-Criteria | Weight | Description |
|--------------|--------|-------------|
| Community Size | 25% | Active users and contributors |
| Documentation | 25% | Quality and completeness |
| Release Cadence | 20% | Regular updates and bug fixes |
| Commercial Support | 15% | Enterprise support options |
| Integrations | 15% | Ecosystem connectors and tools |

#### StarRocks Assessment

**Score: 3.5/5**

| Factor | Details |
|--------|---------|
| **GitHub Stars** | ~9,000 |
| **Contributors** | 300+ |
| **Slack Community** | Active, growing |
| **Documentation** | Good, improving |
| **Release Cadence** | Monthly minor releases |
| **Commercial Support** | CelerData |
| **Integrations** | Kafka, Flink, Spark, DBT, Airflow |

#### ClickHouse Assessment

**Score: 4.5/5**

| Factor | Details |
|--------|---------|
| **GitHub Stars** | ~38,000 |
| **Contributors** | 1,500+ |
| **Slack Community** | Very active, large |
| **Documentation** | Extensive |
| **Release Cadence** | Monthly releases |
| **Commercial Support** | ClickHouse Inc., Altinity |
| **Integrations** | Extensive ecosystem |

---

## 4. Summary Score Card

| Category | Weight | StarRocks | ClickHouse | SR Weighted | CH Weighted |
|----------|--------|-----------|------------|-------------|-------------|
| Mutable Data & Joins | 3x | 4.5 | 2.5 | 13.5 | 7.5 |
| Iceberg Federation | 3x | 5.0 | 2.0 | 15.0 | 6.0 |
| Materialized View Rewrite | 3x | 5.0 | 2.0 | 15.0 | 6.0 |
| Looker Integration | 3x | 4.5 | 4.0 | 13.5 | 12.0 |
| Elastic Scaling | 2.5x | 4.5 | 3.5 | 11.25 | 8.75 |
| Cost & Maintenance | 2x | 4.0 | 3.5 | 8.0 | 7.0 |
| SQL Extensibility | 2x | 4.5 | 4.0 | 9.0 | 8.0 |
| Iceberg Sink | 1x | 5.0 | 1.0 | 5.0 | 1.0 |
| Community | 1x | 3.5 | 4.5 | 3.5 | 4.5 |
| **TOTAL** | **20.5x** | **40.5** | **27.0** | **93.75** | **60.75** |
| **Weighted Average** | | | | **4.57** | **2.96** |

---

## 5. Recommendation

### Primary Recommendation: StarRocks

Based on the weighted evaluation, **StarRocks** is the recommended choice with a weighted score of **93.75** compared to ClickHouse's **60.75**.

### Key Decision Factors

| Requirement | Decision Driver |
|-------------|-----------------|
| **Mutable Data** | StarRocks Primary Key model provides real-time mutations with immediate consistency |
| **Iceberg Federation** | StarRocks has native catalog support; ClickHouse requires workarounds |
| **MV Query Rewrite** | StarRocks automatic rewrite is a major differentiator; ClickHouse lacks this |
| **Elastic Scaling** | StarRocks shared-data architecture enables faster, simpler scaling |
| **Iceberg Sink** | StarRocks can write to Iceberg; ClickHouse cannot |

### When ClickHouse May Be Better

- Append-only, immutable data workloads
- Single-table analytical queries
- Established team expertise with ClickHouse
- Requirement for ClickHouse Cloud managed service specifically

---

## 6. POC Test Plan

### Phase 1: Setup (Week 1)
- [ ] Deploy StarRocks cluster (shared-data mode)
- [ ] Deploy ClickHouse cluster
- [ ] Configure Iceberg catalog in both
- [ ] Load sample dataset (representative schema)

### Phase 2: Functional Testing (Week 2)
- [ ] Test mutation operations (UPDATE/DELETE)
- [ ] Test multi-table joins (4-6 tables)
- [ ] Test Iceberg federation queries
- [ ] Test materialized view creation and query rewrite
- [ ] Connect Looker and build test dashboard

### Phase 3: Performance Testing (Week 3)
- [ ] Benchmark ingestion throughput
- [ ] Benchmark query latency (single user)
- [ ] Benchmark concurrent query performance
- [ ] Test scaling operations (add/remove compute)

### Phase 4: Operational Testing (Week 4)
- [ ] Test backup and restore
- [ ] Test failure recovery
- [ ] Test upgrade procedures
- [ ] Document operational runbooks

---

## 7. Appendix

### A. Reference Queries for Testing

See accompanying test script file for complete query set.

### B. Configuration Templates

See deployment directory for Kubernetes manifests and Helm charts.

### C. Glossary

| Term | Definition |
|------|------------|
| CBO | Cost-Based Optimizer |
| CN | Compute Node (StarRocks) |
| FE | Frontend (StarRocks coordinator) |
| MV | Materialized View |
| OLAP | Online Analytical Processing |

