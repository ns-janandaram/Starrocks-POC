-- ClickHouse table schema for file
-- Generated from schemas/data/file.json

CREATE TABLE IF NOT EXISTS files
(
    -- Core file fields
    id                                       String                  COMMENT 'file.uid - Unique file identifier',
    name                                     String                  COMMENT 'file.name - File name',
    path                                     String                  COMMENT 'file.path - File path',
    type                                     LowCardinality(String)  COMMENT 'file.type - File type',
    size                                     UInt64                  COMMENT 'file.size - File size in bytes',
    created_time                             DateTime64(3)           COMMENT 'file.created_time',
    url                                      String                  COMMENT 'file.url - URL to access file',
    mime_type                                String                  COMMENT 'file.mime_type',
    modified_time                            DateTime64(3)           COMMENT 'file.modified_time',
    last_accessed_time                       DateTime64(3)           COMMENT 'file.last_accessed_time',
    parent_folder                            String                  COMMENT 'file.parent_folder',

    -- Creator (flattened from UserRef)
    creator_uid                              String                  COMMENT 'file.creator.uid',
    creator_name                             String                  COMMENT 'file.creator.name',
    creator_email                            String                  COMMENT 'file.creator.email',

    -- Modifier (flattened from UserRef)
    modifier_uid                             String                  COMMENT 'file.modifier.uid',
    modifier_name                            String                  COMMENT 'file.modifier.name',
    modifier_email                           String                  COMMENT 'file.modifier.email',

    -- Hashes - using Nested
    hashes                                   Nested(
                                                 algorithm String,
                                                 algorithm_id UInt8,
                                                 value String
                                             )                       COMMENT 'file.hashes',

    -- Extended attributes (flattened)
    xattr_parent_id                          String                  COMMENT 'file.xattributes.parent_id',
    xattr_parent_type                        LowCardinality(String)  COMMENT 'file.xattributes.parent_type',
    xattr_file_root_id                       String                  COMMENT 'file.xattributes.file_root_id',
    xattr_file_root_type                     String                  COMMENT 'file.xattributes.file_root_type',
    xattr_access_inheritance_type            LowCardinality(String)  COMMENT 'file.xattributes.access_inheritance_type',
    xattr_access_sources_id                  Array(String)           COMMENT 'file.xattributes.access_sources_id',
    xattr_access_sources_type                Array(String)           COMMENT 'file.xattributes.access_sources_type',
    xattr_media_type_category                LowCardinality(String)  COMMENT 'file.xattributes.media_type_category',

    -- Governance (flattened)
    gov_encryption_at_rest                   Bool                    COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit                Bool                    COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm                 String                  COMMENT 'governance.encryption.algorithm',
    gov_encryption_key_mgmt                  String                  COMMENT 'governance.encryption.key_management',
    gov_owner_name                           String                  COMMENT 'governance.owner.name',
    gov_owner_uid                            String                  COMMENT 'governance.owner.uid',
    gov_owner_email                          String                  COMMENT 'governance.owner.email',
    gov_resiliency_versioning_enabled        Bool                    COMMENT 'governance.resiliency.versioning_enabled',
    gov_resiliency_lifecycle_policies_enabled Bool                   COMMENT 'governance.resiliency.lifecycle_policies_enabled',
    gov_resiliency_replication_enabled       Bool                    COMMENT 'governance.resiliency.replication_enabled',
    gov_resiliency_replication_within_region Bool                    COMMENT 'governance.resiliency.replication_within_region',
    gov_resiliency_backup_enabled            Bool                    COMMENT 'governance.resiliency.backup_enabled',

    -- Compliance (flattened)
    compliance_status                        LowCardinality(String)  COMMENT 'compliance.status',
    compliance_status_id                     UInt32                  COMMENT 'compliance.status_id',
    compliance_standards                     Array(String)           COMMENT 'compliance.standards',
    compliance_matched_rules_count           UInt32                  COMMENT 'compliance.matched_rules_count',
    compliance_matched_rules                 Array(String)           COMMENT 'compliance.matched_rules',
    compliance_posture_tags                  Array(String)           COMMENT 'compliance.posture_tags',
    compliance_violations_total              UInt32                  COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_sensitive_items    UInt32                  COMMENT 'compliance.privacy_violations.sensitive_items',
    compliance_violations_sensitive_fields   UInt32                  COMMENT 'compliance.privacy_violations.sensitive_fields',
    compliance_violations_sensitive_data_size UInt64                 COMMENT 'compliance.privacy_violations.sensitive_data_size',
    compliance_violations_pii_count          UInt32                  COMMENT 'compliance.privacy_violations.pii_count',
    compliance_violations_phi_count          UInt32                  COMMENT 'compliance.privacy_violations.phi_count',
    compliance_violations_large_export       Bool                    COMMENT 'compliance.privacy_violations.large_data_export',
    compliance_violations_sensitive_export   Bool                    COMMENT 'compliance.privacy_violations.sensitive_data_export',

    -- Risks (flattened from risk.json reference)
    risk_level                               LowCardinality(String)  COMMENT 'risks.risk_level',
    risk_score                               UInt32                  COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          Float32                 COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              LowCardinality(String)  COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DateTime64(3)           COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         String                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    tenant_id                                UInt32                  COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    geo                                      String                  COMMENT 'x_netskope.geo',
    instance_id                              String                  COMMENT 'x_netskope.instance_id',
    discovery_source                         LowCardinality(String)  COMMENT 'x_netskope.discovery_source',
    discovery_time                           DateTime64(3)           COMMENT 'x_netskope.discovery_time',

    -- Special columns
    _insert_time                             DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(created_time), id)
COMMENT 'File object table - OCSF file object schema';
