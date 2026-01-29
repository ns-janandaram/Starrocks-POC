-- StarRocks table schema for finding_info
-- Converted from ClickHouse schema

CREATE TABLE IF NOT EXISTS finding_info
(
    -- Primary Key columns
    tenant_id                     INT                     COMMENT 'finding_info.x_netskope.tenant_id - Netskope tenant identifier',
    id                            STRING                  COMMENT 'finding_info.uid - Unique finding identifier',

    -- Core finding fields
    title                         STRING                  COMMENT 'finding_info.title - Brief phrase summarizing the finding',
    `desc`                        STRING                  COMMENT 'finding_info.desc - Detailed description of the finding',
    types                         ARRAY<STRING>           COMMENT 'finding_info.types - Categories of the finding (FINDING_TYPE_*)',
    src_url                       STRING                  COMMENT 'finding_info.src_url - URL pointing to the source or details',

    -- Timestamps
    created_time                  DATETIME                COMMENT 'finding_info.created_time - When the finding was created',
    modified_time                 DATETIME                COMMENT 'finding_info.modified_time - When the finding was last modified',
    first_seen_time               DATETIME                COMMENT 'finding_info.first_seen_time - When the finding was first observed',
    last_seen_time                DATETIME                COMMENT 'finding_info.last_seen_time - When the finding was most recently observed',

    -- Product information (flattened)
    product_name                  VARCHAR(255)            COMMENT 'finding_info.product.name - Netskope product name (DSPM, SSPM, CSPM, CASB)',
    product_uid                   STRING                  COMMENT 'finding_info.product.uid - Product unique identifier',
    product_version               STRING                  COMMENT 'finding_info.product.version - Product version',

    -- Data sources and related events
    data_sources                  ARRAY<STRING>           COMMENT 'finding_info.data_sources - Data sources used in generation',
    related_events_count          INT                     COMMENT 'finding_info.related_events_count - Number of related events',

    -- Tags
    tags                          ARRAY<STRING>           COMMENT 'finding_info.tags - Tags associated with the finding',

    -- Netskope extension fields (flattened)
    severity                      VARCHAR(255)            COMMENT 'finding_info.x_netskope.severity - Severity level (SEVERITY_*)',
    severity_id                   INT                     COMMENT 'finding_info.x_netskope.severity_id - Numeric severity identifier',

    -- Rule information (flattened from x_netskope.rule)
    rule_uid                      STRING                  COMMENT 'finding_info.x_netskope.rule.uid - Rule unique identifier',
    rule_name                     STRING                  COMMENT 'finding_info.x_netskope.rule.name - Rule name',
    rule_type                     VARCHAR(255)            COMMENT 'finding_info.x_netskope.rule.type - Rule type (RULE_TYPE_*)',
    rule_version                  STRING                  COMMENT 'finding_info.x_netskope.rule.version - Rule version',

    -- Compliance information (flattened from x_netskope.compliance)
    compliance_framework          VARCHAR(255)            COMMENT 'finding_info.x_netskope.compliance.framework - Compliance framework (COMPLIANCE_FRAMEWORK_*)',
    compliance_control_id         STRING                  COMMENT 'finding_info.x_netskope.compliance.control_id - Control identifier',
    compliance_control_name       STRING                  COMMENT 'finding_info.x_netskope.compliance.control_name - Control name',

    -- Remediation information (flattened from x_netskope.remediation)
    remediation_desc              STRING                  COMMENT 'finding_info.x_netskope.remediation.desc - Remediation steps',
    remediation_kb_articles       ARRAY<STRING>           COMMENT 'finding_info.x_netskope.remediation.kb_articles - KB article URLs',

    -- Status
    status                        VARCHAR(255)            COMMENT 'finding_info.x_netskope.status - Finding status (FINDING_STATUS_*)',
    status_detail                 STRING                  COMMENT 'finding_info.x_netskope.status_detail - Additional status details',

    -- Special columns
    _insert_time                  DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 16
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);
