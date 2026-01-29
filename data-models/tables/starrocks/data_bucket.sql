-- StarRocks table schema for data_bucket
-- Converted from ClickHouse schema

CREATE TABLE IF NOT EXISTS data_buckets
(
    -- Primary Key columns
    tenant_id                                INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                       STRING                  COMMENT 'databucket.uid - Unique bucket identifier',

    -- Core bucket fields
    created_time                             DATETIME                COMMENT 'databucket.created_time',
    name                                     STRING                  COMMENT 'databucket.name - Bucket name',
    type                                     VARCHAR(255)            COMMENT 'databucket.type - Bucket type',
    is_backed_up                             BOOLEAN                 COMMENT 'databucket.is_backed_up',
    is_encrypted                             BOOLEAN                 COMMENT 'databucket.is_encrypted',
    is_public                                BOOLEAN                 COMMENT 'databucket.is_public',
    size                                     BIGINT                  COMMENT 'databucket.size - Bucket size in bytes',

    -- Owner (flattened from governance.owner reference)
    owner_uid                                STRING                  COMMENT 'databucket.owner.uid - Owner unique identifier',
    owner_name                               STRING                  COMMENT 'databucket.owner.name - Owner name',
    owner_email                              STRING                  COMMENT 'databucket.owner.email - Owner email address',

    -- Data (flattened)
    data_object_count                        INT                     COMMENT 'databucket.data.object_count',
    data_public_url                          STRING                  COMMENT 'databucket.data.public_url',
    data_cross_account_access_enabled        BOOLEAN                 COMMENT 'databucket.data.cross_account_access_enabled',
    data_resource_id                         STRING                  COMMENT 'databucket.data.resource_id',
    data_region                              STRING                  COMMENT 'databucket.data.region',

    -- S3-specific queryable fields
    s3_bucket_arn                            STRING                  COMMENT 'databucket.data.vendor_specific.s3.bucket_arn',
    s3_storage_class                         VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.s3.storage_class',
    s3_versioning_enabled                    BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.versioning.enabled',
    s3_versioning_mfa_delete                 BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.versioning.mfa_delete',
    s3_encryption_enabled                    BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.encryption.enabled',
    s3_encryption_type                       VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.s3.encryption.type',
    s3_encryption_kms_key_id                 STRING                  COMMENT 'databucket.data.vendor_specific.s3.encryption.kms_key_id',
    s3_server_side_encryption                VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.s3.server_side_encryption',
    s3_replication_enabled                   BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.replication.enabled',
    s3_replication_destination               STRING                  COMMENT 'databucket.data.vendor_specific.s3.replication.destination_bucket',
    s3_public_access_block_acls              BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.public_access_block.block_public_acls',
    s3_public_access_ignore_acls             BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.public_access_block.ignore_public_acls',
    s3_public_access_block_policy            BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.public_access_block.block_public_policy',
    s3_public_access_restrict_buckets        BOOLEAN                 COMMENT 'databucket.data.vendor_specific.s3.public_access_block.restrict_public_buckets',

    -- GCS-specific queryable fields
    gcs_storage_class                        VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.gcs.storage_class',
    gcs_location_type                        VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.gcs.location_type',
    gcs_versioning_enabled                   BOOLEAN                 COMMENT 'databucket.data.vendor_specific.gcs.versioning.enabled',
    gcs_encryption_kms_key                   STRING                  COMMENT 'databucket.data.vendor_specific.gcs.encryption.default_kms_key',
    gcs_uniform_access_enabled               BOOLEAN                 COMMENT 'databucket.data.vendor_specific.gcs.iam_configuration.uniform_bucket_level_access.enabled',
    gcs_uniform_access_locked_time           DATETIME                COMMENT 'databucket.data.vendor_specific.gcs.iam_configuration.uniform_bucket_level_access.locked_time',
    gcs_public_access_prevention             VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.gcs.iam_configuration.public_access_prevention',

    -- Azure-specific queryable fields
    azure_container_access_type              VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.azure.container_access_type',
    azure_account_kind                       VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.azure.account_kind',
    azure_sku_name                           VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.azure.sku.name',
    azure_sku_tier                           VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.azure.sku.tier',
    azure_access_tier                        VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.azure.access_tier',
    azure_encryption_enabled                 BOOLEAN                 COMMENT 'databucket.data.vendor_specific.azure.encryption.services.blob.enabled',
    azure_encryption_key_source              VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.azure.encryption.key_source',
    azure_encryption_key_vault_uri           STRING                  COMMENT 'databucket.data.vendor_specific.azure.encryption.key_vault_properties.key_vault_uri',
    azure_network_default_action             VARCHAR(255)            COMMENT 'databucket.data.vendor_specific.azure.network_acls.default_action',
    azure_versioning_enabled                 BOOLEAN                 COMMENT 'databucket.data.vendor_specific.azure.versioning.enabled',
    azure_soft_delete_enabled                BOOLEAN                 COMMENT 'databucket.data.vendor_specific.azure.soft_delete.enabled',
    azure_soft_delete_retention_days         INT                     COMMENT 'databucket.data.vendor_specific.azure.soft_delete.retention_days',

    -- Full vendor configuration as JSON
    vendor_config_full_json                  JSON                    COMMENT 'databucket.data.vendor_specific - Complete vendor configuration (JSON)',

    -- Access control (converted from Nested to JSON)
    acl                                      JSON                    COMMENT 'databucket.data.access_control.acl - Access Control List entries',
    acl_inherited_from_bucket                BOOLEAN                 COMMENT 'databucket.data.access_control.inherited_from_bucket',

    -- Shared with (converted from Nested to JSON)
    shared_with                              JSON                    COMMENT 'databucket.data.shared_with - Entities with access',

    -- Tags (converted from Nested to JSON)
    tags                                     JSON                    COMMENT 'databucket.tags',

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
    compliance_status_id                     TINYINT                 COMMENT 'compliance.status_id',
    compliance_standards                     ARRAY<STRING>           COMMENT 'compliance.standards',
    compliance_matched_rules_count           INT                     COMMENT 'compliance.matched_rules_count',
    compliance_matched_rules                 ARRAY<STRING>           COMMENT 'compliance.matched_rules',
    compliance_posture_tags                  ARRAY<STRING>           COMMENT 'compliance.posture_tags',
    compliance_violations_total              INT                     COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_sensitive_items    INT                     COMMENT 'compliance.privacy_violations.sensitive_items',
    compliance_violations_sensitive_data_size BIGINT                 COMMENT 'compliance.privacy_violations.sensitive_data_size',

    -- Risks (flattened from risk.json reference)
    risk_level                               VARCHAR(255)            COMMENT 'risks.risk_level',
    risk_score                               INT                     COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          FLOAT                   COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              VARCHAR(255)            COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DATETIME                COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         STRING                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    app                                      VARCHAR(255)            COMMENT 'x_netskope.app - Cloud storage provider',
    instance                                 STRING                  COMMENT 'x_netskope.instance - Instance identifier',
    discovery_source                         VARCHAR(255)            COMMENT 'x_netskope.discovery_source',
    discovery_time                           DATETIME                COMMENT 'x_netskope.discovery_time',
    app_category                             VARCHAR(255)            COMMENT 'x_netskope.app_category',
    app_suite                                VARCHAR(255)            COMMENT 'x_netskope.app_suite',

    -- Special columns
    _insert_time                             DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 16
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);
