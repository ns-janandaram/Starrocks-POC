-- ClickHouse table schema for data_object
-- Generated from schemas/data/data-object.json

CREATE TABLE IF NOT EXISTS data_objects
(
    -- Core object fields
    id                                       String                  COMMENT 'data_object.uid - Unique object identifier',
    created_time                             DateTime64(3)           COMMENT 'data_object.created_time',
    modified_time                            DateTime64(3)           COMMENT 'data_object.modified_time',
    name                                     String                  COMMENT 'data_object.name - Object name',
    size                                     UInt64                  COMMENT 'data_object.size - Object size in bytes',
    hash                                     String                  COMMENT 'data_object.hash - Hash value',
    path                                     String                  COMMENT 'data_object.path - Object path within bucket',
    mime_type                                String                  COMMENT 'data_object.mime_type',
    is_encrypted                             Bool                    COMMENT 'data_object.is_encrypted',
    is_public                                Bool                    COMMENT 'data_object.is_public',
    type                                     LowCardinality(String)  COMMENT 'data_object.type - Object type',

    -- Parent bucket reference
    databucket_id                            String                  COMMENT 'data_object.data_bucket_id',

    -- Owner (flattened from governance.owner reference)
    owner_uid                                String                  COMMENT 'data_object.owner.uid - Owner unique identifier',
    owner_name                               String                  COMMENT 'data_object.owner.name - Owner name',
    owner_email                              String                  COMMENT 'data_object.owner.email - Owner email address',

    -- Data (flattened)
    data_public_url                          String                  COMMENT 'data_object.data.public_url',
    data_resource_id                         String                  COMMENT 'data_object.data.resource_id',
    data_region                              String                  COMMENT 'data_object.data.region',

    -- Vendor-specific configuration - Hybrid approach (flattened + JSON)
    -- S3-specific queryable fields
    s3_storage_class                         LowCardinality(String)  COMMENT 'data_object.data.vendor_specific.s3.storage_class',
    s3_server_side_encryption                LowCardinality(String)  COMMENT 'data_object.data.vendor_specific.s3.server_side_encryption',
    s3_encryption_enabled                    Bool                    COMMENT 'data_object.data.vendor_specific.s3.encryption.enabled',
    s3_encryption_type                       LowCardinality(String)  COMMENT 'data_object.data.vendor_specific.s3.encryption.type',
    s3_encryption_kms_key_id                 String                  COMMENT 'data_object.data.vendor_specific.s3.encryption.kms_key_id',
    s3_object_lock_mode                      LowCardinality(String)  COMMENT 'data_object.data.vendor_specific.s3.object_lock.mode',
    s3_object_lock_retain_until              DateTime64(3)           COMMENT 'data_object.data.vendor_specific.s3.object_lock.retain_until_date',

    -- GCS-specific queryable fields
    gcs_storage_class                        LowCardinality(String)  COMMENT 'data_object.data.vendor_specific.gcs.storage_class',
    gcs_encryption_kms_key                   String                  COMMENT 'data_object.data.vendor_specific.gcs.encryption.default_kms_key',
    gcs_uniform_access_enabled               Bool                    COMMENT 'data_object.data.vendor_specific.gcs.iam_configuration.uniform_bucket_level_access.enabled',

    -- Azure-specific queryable fields
    azure_access_tier                        LowCardinality(String)  COMMENT 'data_object.data.vendor_specific.azure.access_tier',
    azure_container_access_type              LowCardinality(String)  COMMENT 'data_object.data.vendor_specific.azure.container_access_type',
    azure_encryption_enabled                 Bool                    COMMENT 'data_object.data.vendor_specific.azure.encryption.services.blob.enabled',

    -- Full vendor configuration as JSON (for additional object-specific metadata)
    vendor_config_full_json                  String                  COMMENT 'data_object.data.vendor_specific - Complete vendor configuration (JSON)',

    -- Shared with - using Nested for sharing information
    shared_with                              Nested(
                                                 entity_type String,
                                                 entity_id String,
                                                 access_level String,
                                                 presigned_url String
                                             )                       COMMENT 'data_object.data.shared_with - Entities with access',

    -- Compliance (flattened)
    compliance_status                        LowCardinality(String)  COMMENT 'compliance.status',
    compliance_status_id                     UInt8                   COMMENT 'compliance.status_id',
    compliance_standards                     Array(String)           COMMENT 'compliance.standards',
    compliance_violations_total              UInt32                  COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_pii_count          UInt32                  COMMENT 'compliance.privacy_violations.pii_count',
    compliance_violations_phi_count          UInt32                  COMMENT 'compliance.privacy_violations.phi_count',

    -- Governance (flattened)
    gov_encryption_at_rest                   Bool                    COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit                Bool                    COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm                 String                  COMMENT 'governance.encryption.algorithm',
    gov_owner_name                           String                  COMMENT 'governance.owner.name',
    gov_owner_uid                            String                  COMMENT 'governance.owner.uid',
    gov_owner_email                          String                  COMMENT 'governance.owner.email',

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
COMMENT 'Data object table - object storage objects (S3, GCS, Azure Blob)';
