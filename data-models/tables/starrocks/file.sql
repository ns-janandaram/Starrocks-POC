-- StarRocks table schema for file
-- Converted from ClickHouse schema

CREATE TABLE IF NOT EXISTS files
(
    -- Primary Key columns
    tenant_id                                INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                       STRING                  COMMENT 'file.uid - Unique file identifier',

    -- Core file fields
    name                                     STRING                  COMMENT 'file.name - File name',
    path                                     STRING                  COMMENT 'file.path - File path',
    type                                     VARCHAR(255)            COMMENT 'file.type - File type',
    size                                     BIGINT                  COMMENT 'file.size - File size in bytes',
    created_time                             DATETIME                COMMENT 'file.created_time',
    url                                      STRING                  COMMENT 'file.url - URL to access file',
    mime_type                                STRING                  COMMENT 'file.mime_type',
    modified_time                            DATETIME                COMMENT 'file.modified_time',
    last_accessed_time                       DATETIME                COMMENT 'file.last_accessed_time',
    parent_folder                            STRING                  COMMENT 'file.parent_folder',

    -- Creator (flattened from UserRef)
    creator_uid                              STRING                  COMMENT 'file.creator.uid',
    creator_name                             STRING                  COMMENT 'file.creator.name',
    creator_email                            STRING                  COMMENT 'file.creator.email',

    -- Modifier (flattened from UserRef)
    modifier_uid                             STRING                  COMMENT 'file.modifier.uid',
    modifier_name                            STRING                  COMMENT 'file.modifier.name',
    modifier_email                           STRING                  COMMENT 'file.modifier.email',

    -- Hashes (converted from Nested to JSON)
    hashes                                   JSON                    COMMENT 'file.hashes',

    -- Extended attributes (flattened)
    xattr_parent_id                          STRING                  COMMENT 'file.xattributes.parent_id',
    xattr_parent_type                        VARCHAR(255)            COMMENT 'file.xattributes.parent_type',
    xattr_file_root_id                       STRING                  COMMENT 'file.xattributes.file_root_id',
    xattr_file_root_type                     STRING                  COMMENT 'file.xattributes.file_root_type',
    xattr_access_inheritance_type            VARCHAR(255)            COMMENT 'file.xattributes.access_inheritance_type',
    xattr_access_sources_id                  ARRAY<STRING>           COMMENT 'file.xattributes.access_sources_id',
    xattr_access_sources_type                ARRAY<STRING>           COMMENT 'file.xattributes.access_sources_type',
    xattr_media_type_category                VARCHAR(255)            COMMENT 'file.xattributes.media_type_category',

    -- Governance (flattened)
    gov_encryption_at_rest                   BOOLEAN                 COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit                BOOLEAN                 COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm                 STRING                  COMMENT 'governance.encryption.algorithm',
    gov_encryption_key_mgmt                  STRING                  COMMENT 'governance.encryption.key_management',
    gov_owner_name                           STRING                  COMMENT 'governance.owner.name',
    gov_owner_uid                            STRING                  COMMENT 'governance.owner.uid',
    gov_owner_email                          STRING                  COMMENT 'governance.owner.email',
    gov_resiliency_versioning_enabled        BOOLEAN                 COMMENT 'governance.resiliency.versioning_enabled',
    gov_resiliency_lifecycle_policies_enabled BOOLEAN                COMMENT 'governance.resiliency.lifecycle_policies_enabled',
    gov_resiliency_replication_enabled       BOOLEAN                 COMMENT 'governance.resiliency.replication_enabled',
    gov_resiliency_replication_within_region BOOLEAN                 COMMENT 'governance.resiliency.replication_within_region',
    gov_resiliency_backup_enabled            BOOLEAN                 COMMENT 'governance.resiliency.backup_enabled',

    -- Compliance (flattened)
    compliance_status                        VARCHAR(255)            COMMENT 'compliance.status',
    compliance_status_id                     INT                     COMMENT 'compliance.status_id',
    compliance_standards                     ARRAY<STRING>           COMMENT 'compliance.standards',
    compliance_matched_rules_count           INT                     COMMENT 'compliance.matched_rules_count',
    compliance_matched_rules                 ARRAY<STRING>           COMMENT 'compliance.matched_rules',
    compliance_posture_tags                  ARRAY<STRING>           COMMENT 'compliance.posture_tags',
    compliance_violations_total              INT                     COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_sensitive_items    INT                     COMMENT 'compliance.privacy_violations.sensitive_items',
    compliance_violations_sensitive_fields   INT                     COMMENT 'compliance.privacy_violations.sensitive_fields',
    compliance_violations_sensitive_data_size BIGINT                 COMMENT 'compliance.privacy_violations.sensitive_data_size',
    compliance_violations_pii_count          INT                     COMMENT 'compliance.privacy_violations.pii_count',
    compliance_violations_phi_count          INT                     COMMENT 'compliance.privacy_violations.phi_count',
    compliance_violations_large_export       BOOLEAN                 COMMENT 'compliance.privacy_violations.large_data_export',
    compliance_violations_sensitive_export   BOOLEAN                 COMMENT 'compliance.privacy_violations.sensitive_data_export',

    -- Risks (flattened from risk.json reference)
    risk_level                               VARCHAR(255)            COMMENT 'risks.risk_level',
    risk_score                               INT                     COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          FLOAT                   COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              VARCHAR(255)            COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DATETIME                COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         STRING                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    geo                                      STRING                  COMMENT 'x_netskope.geo',
    instance_id                              STRING                  COMMENT 'x_netskope.instance_id',
    discovery_source                         VARCHAR(255)            COMMENT 'x_netskope.discovery_source',
    discovery_time                           DATETIME                COMMENT 'x_netskope.discovery_time',

    -- Special columns
    _insert_time                             DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 32
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);
