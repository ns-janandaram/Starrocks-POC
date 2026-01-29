-- ClickHouse table schema for finding_info
-- Generated from proto-schemas/finding_info.proto

CREATE TABLE IF NOT EXISTS finding_info
(
    -- Core finding fields
    id                            String                  COMMENT 'finding_info.uid - Unique finding identifier',
    title                         String                  COMMENT 'finding_info.title - Brief phrase summarizing the finding',
    desc                          String                  COMMENT 'finding_info.desc - Detailed description of the finding',
    types                         Array(String)           COMMENT 'finding_info.types - Categories of the finding (FINDING_TYPE_*)',
    src_url                       String                  COMMENT 'finding_info.src_url - URL pointing to the source or details',

    -- Timestamps
    created_time                  DateTime64(3)           COMMENT 'finding_info.created_time - When the finding was created',
    modified_time                 DateTime64(3)           COMMENT 'finding_info.modified_time - When the finding was last modified',
    first_seen_time               DateTime64(3)           COMMENT 'finding_info.first_seen_time - When the finding was first observed',
    last_seen_time                DateTime64(3)           COMMENT 'finding_info.last_seen_time - When the finding was most recently observed',

    -- Product information (flattened)
    product_name                  LowCardinality(String)  COMMENT 'finding_info.product.name - Netskope product name (DSPM, SSPM, CSPM, CASB)',
    product_uid                   String                  COMMENT 'finding_info.product.uid - Product unique identifier',
    product_version               String                  COMMENT 'finding_info.product.version - Product version',

    -- Data sources and related events
    data_sources                  Array(String)           COMMENT 'finding_info.data_sources - Data sources used in generation',
    related_events_count          Int32                   COMMENT 'finding_info.related_events_count - Number of related events',

    -- Tags
    tags                          Array(String)           COMMENT 'finding_info.tags - Tags associated with the finding',

    -- Netskope extension fields (flattened)
    tenant_id                     UInt32                  COMMENT 'finding_info.x_netskope.tenant_id - Netskope tenant identifier',
    severity                      LowCardinality(String)  COMMENT 'finding_info.x_netskope.severity - Severity level (SEVERITY_*)',
    severity_id                   Int32                   COMMENT 'finding_info.x_netskope.severity_id - Numeric severity identifier',

    -- Rule information (flattened from x_netskope.rule)
    rule_uid                      String                  COMMENT 'finding_info.x_netskope.rule.uid - Rule unique identifier',
    rule_name                     String                  COMMENT 'finding_info.x_netskope.rule.name - Rule name',
    rule_type                     LowCardinality(String)  COMMENT 'finding_info.x_netskope.rule.type - Rule type (RULE_TYPE_*)',
    rule_version                  String                  COMMENT 'finding_info.x_netskope.rule.version - Rule version',

    -- Compliance information (flattened from x_netskope.compliance)
    compliance_framework          LowCardinality(String)  COMMENT 'finding_info.x_netskope.compliance.framework - Compliance framework (COMPLIANCE_FRAMEWORK_*)',
    compliance_control_id         String                  COMMENT 'finding_info.x_netskope.compliance.control_id - Control identifier',
    compliance_control_name       String                  COMMENT 'finding_info.x_netskope.compliance.control_name - Control name',

    -- Remediation information (flattened from x_netskope.remediation)
    remediation_desc              String                  COMMENT 'finding_info.x_netskope.remediation.desc - Remediation steps',
    remediation_kb_articles       Array(String)           COMMENT 'finding_info.x_netskope.remediation.kb_articles - KB article URLs',

    -- Status
    status                        LowCardinality(String)  COMMENT 'finding_info.x_netskope.status - Finding status (FINDING_STATUS_*)',
    status_detail                 String                  COMMENT 'finding_info.x_netskope.status_detail - Additional status details',

    -- Special columns
    _insert_time                  DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(created_time, _insert_time)), id)
COMMENT 'Finding info table - security findings and compliance violations';
