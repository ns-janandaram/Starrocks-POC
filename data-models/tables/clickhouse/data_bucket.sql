-- ClickHouse table schema for data_bucket
-- Generated from schemas/data/data-bucket.json

CREATE TABLE IF NOT EXISTS data_buckets
(
    -- Core bucket fields
    id                                       String                  COMMENT 'databucket.uid - Unique bucket identifier',
    created_time                             DateTime64(3)           COMMENT 'databucket.created_time',
    name                                     String                  COMMENT 'databucket.name - Bucket name',
    type                                     LowCardinality(String)  COMMENT 'databucket.type - Bucket type',
    is_backed_up                             Bool                    COMMENT 'databucket.is_backed_up',
    is_encrypted                             Bool                    COMMENT 'databucket.is_encrypted',
    is_public                                Bool                    COMMENT 'databucket.is_public',
    size                                     UInt64                  COMMENT 'databucket.size - Bucket size in bytes',

    -- Owner (flattened from governance.owner reference)
    owner_uid                                String                  COMMENT 'databucket.owner.uid - Owner unique identifier',
    owner_name                               String                  COMMENT 'databucket.owner.name - Owner name',
    owner_email                              String                  COMMENT 'databucket.owner.email - Owner email address',

    -- Data (flattened)
    data_object_count                        UInt32                  COMMENT 'databucket.data.object_count',
    data_public_url                          String                  COMMENT 'databucket.data.public_url',
    data_cross_account_access_enabled        Bool                    COMMENT 'databucket.data.cross_account_access_enabled',
    data_resource_id                         String                  COMMENT 'databucket.data.resource_id',
    data_region                              String                  COMMENT 'databucket.data.region',

    -- Vendor-specific configuration - Hybrid approach (flattened + JSON)
    -- S3-specific queryable fields
    s3_bucket_arn                            String                  COMMENT 'databucket.data.vendor_specific.s3.bucket_arn',
    s3_storage_class                         LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.s3.storage_class',
    s3_versioning_enabled                    Bool                    COMMENT 'databucket.data.vendor_specific.s3.versioning.enabled',
    s3_versioning_mfa_delete                 Bool                    COMMENT 'databucket.data.vendor_specific.s3.versioning.mfa_delete',
    s3_encryption_enabled                    Bool                    COMMENT 'databucket.data.vendor_specific.s3.encryption.enabled',
    s3_encryption_type                       LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.s3.encryption.type',
    s3_encryption_kms_key_id                 String                  COMMENT 'databucket.data.vendor_specific.s3.encryption.kms_key_id',
    s3_server_side_encryption                LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.s3.server_side_encryption',
    s3_replication_enabled                   Bool                    COMMENT 'databucket.data.vendor_specific.s3.replication.enabled',
    s3_replication_destination               String                  COMMENT 'databucket.data.vendor_specific.s3.replication.destination_bucket',
    s3_public_access_block_acls              Bool                    COMMENT 'databucket.data.vendor_specific.s3.public_access_block.block_public_acls',
    s3_public_access_ignore_acls             Bool                    COMMENT 'databucket.data.vendor_specific.s3.public_access_block.ignore_public_acls',
    s3_public_access_block_policy            Bool                    COMMENT 'databucket.data.vendor_specific.s3.public_access_block.block_public_policy',
    s3_public_access_restrict_buckets        Bool                    COMMENT 'databucket.data.vendor_specific.s3.public_access_block.restrict_public_buckets',

    -- GCS-specific queryable fields
    gcs_storage_class                        LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.gcs.storage_class',
    gcs_location_type                        LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.gcs.location_type',
    gcs_versioning_enabled                   Bool                    COMMENT 'databucket.data.vendor_specific.gcs.versioning.enabled',
    gcs_encryption_kms_key                   String                  COMMENT 'databucket.data.vendor_specific.gcs.encryption.default_kms_key',
    gcs_uniform_access_enabled               Bool                    COMMENT 'databucket.data.vendor_specific.gcs.iam_configuration.uniform_bucket_level_access.enabled',
    gcs_uniform_access_locked_time           DateTime64(3)           COMMENT 'databucket.data.vendor_specific.gcs.iam_configuration.uniform_bucket_level_access.locked_time',
    gcs_public_access_prevention             LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.gcs.iam_configuration.public_access_prevention',

    -- Azure-specific queryable fields
    azure_container_access_type              LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.azure.container_access_type',
    azure_account_kind                       LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.azure.account_kind',
    azure_sku_name                           LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.azure.sku.name',
    azure_sku_tier                           LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.azure.sku.tier',
    azure_access_tier                        LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.azure.access_tier',
    azure_encryption_enabled                 Bool                    COMMENT 'databucket.data.vendor_specific.azure.encryption.services.blob.enabled',
    azure_encryption_key_source              LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.azure.encryption.key_source',
    azure_encryption_key_vault_uri           String                  COMMENT 'databucket.data.vendor_specific.azure.encryption.key_vault_properties.key_vault_uri',
    azure_network_default_action             LowCardinality(String)  COMMENT 'databucket.data.vendor_specific.azure.network_acls.default_action',
    azure_versioning_enabled                 Bool                    COMMENT 'databucket.data.vendor_specific.azure.versioning.enabled',
    azure_soft_delete_enabled                Bool                    COMMENT 'databucket.data.vendor_specific.azure.soft_delete.enabled',
    azure_soft_delete_retention_days         UInt32                  COMMENT 'databucket.data.vendor_specific.azure.soft_delete.retention_days',

    -- Full vendor configuration as JSON (for complex nested data like lifecycle rules, etc.)
    vendor_config_full_json                  String                  COMMENT 'databucket.data.vendor_specific - Complete vendor configuration (JSON)',

    -- Access control - using Nested for ACL entries
    acl                                      Nested(
                                                 entity_type String,
                                                 entity_id String,
                                                 privilege_type String,
                                                 privilege_name String,
                                                 access_level String
                                             )                       COMMENT 'databucket.data.access_control.acl - Access Control List entries',
    acl_inherited_from_bucket                Bool                    COMMENT 'databucket.data.access_control.inherited_from_bucket',

    -- Shared with - using Nested for sharing information
    shared_with                              Nested(
                                                 entity_type String,
                                                 entity_id String,
                                                 access_level String
                                             )                       COMMENT 'databucket.data.shared_with - Entities with access',

    -- Tags - using Nested
    tags                                     Nested(
                                                 key String,
                                                 value String
                                             )                       COMMENT 'databucket.tags',

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
    compliance_status_id                     UInt8                   COMMENT 'compliance.status_id',
    compliance_standards                     Array(String)           COMMENT 'compliance.standards',
    compliance_matched_rules_count           UInt32                  COMMENT 'compliance.matched_rules_count',
    compliance_matched_rules                 Array(String)           COMMENT 'compliance.matched_rules',
    compliance_posture_tags                  Array(String)           COMMENT 'compliance.posture_tags',
    compliance_violations_total              UInt32                  COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_sensitive_items    UInt32                  COMMENT 'compliance.privacy_violations.sensitive_items',
    compliance_violations_sensitive_data_size UInt64                 COMMENT 'compliance.privacy_violations.sensitive_data_size',

    -- Risks (flattened from risk.json reference)
    risk_level                               LowCardinality(String)  COMMENT 'risks.risk_level',
    risk_score                               UInt32                  COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          Float32                 COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              LowCardinality(String)  COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DateTime64(3)           COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         String                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    tenant_id                                UInt32                  COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    app                                      LowCardinality(String)  COMMENT 'x_netskope.app - Cloud storage provider',
    instance                                 String                  COMMENT 'x_netskope.instance - Instance identifier',
    discovery_source                         LowCardinality(String)  COMMENT 'x_netskope.discovery_source',
    discovery_time                           DateTime64(3)           COMMENT 'x_netskope.discovery_time',
    app_category                             LowCardinality(String)  COMMENT 'x_netskope.app_category',
    app_suite                                LowCardinality(String)  COMMENT 'x_netskope.app_suite',

    -- Special columns
    _insert_time                             DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(created_time), id)
COMMENT 'Data bucket table - object storage buckets (S3, GCS, Azure Blob)';
