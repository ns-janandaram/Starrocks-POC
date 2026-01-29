-- StarRocks table schema for data_object
-- Converted from ClickHouse schema

CREATE TABLE IF NOT EXISTS data_objects
(
    -- Primary Key columns
    tenant_id                                INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                       STRING                  COMMENT 'data_object.uid - Unique object identifier',

    -- Core object fields
    created_time                             DATETIME                COMMENT 'data_object.created_time',
    modified_time                            DATETIME                COMMENT 'data_object.modified_time',
    name                                     STRING                  COMMENT 'data_object.name - Object name',
    size                                     BIGINT                  COMMENT 'data_object.size - Object size in bytes',
    hash                                     STRING                  COMMENT 'data_object.hash - Hash value',
    path                                     STRING                  COMMENT 'data_object.path - Object path within bucket',
    mime_type                                STRING                  COMMENT 'data_object.mime_type',
    is_encrypted                             BOOLEAN                 COMMENT 'data_object.is_encrypted',
    is_public                                BOOLEAN                 COMMENT 'data_object.is_public',
    type                                     VARCHAR(255)            COMMENT 'data_object.type - Object type',

    -- Parent bucket reference
    databucket_id                            STRING                  COMMENT 'data_object.data_bucket_id',

    -- Owner (flattened from governance.owner reference)
    owner_uid                                STRING                  COMMENT 'data_object.owner.uid - Owner unique identifier',
    owner_name                               STRING                  COMMENT 'data_object.owner.name - Owner name',
    owner_email                              STRING                  COMMENT 'data_object.owner.email - Owner email address',

    -- Data (flattened)
    data_public_url                          STRING                  COMMENT 'data_object.data.public_url',
    data_resource_id                         STRING                  COMMENT 'data_object.data.resource_id',
    data_region                              STRING                  COMMENT 'data_object.data.region',

    -- S3-specific queryable fields
    s3_storage_class                         VARCHAR(255)            COMMENT 'data_object.data.vendor_specific.s3.storage_class',
    s3_server_side_encryption                VARCHAR(255)            COMMENT 'data_object.data.vendor_specific.s3.server_side_encryption',
    s3_encryption_enabled                    BOOLEAN                 COMMENT 'data_object.data.vendor_specific.s3.encryption.enabled',
    s3_encryption_type                       VARCHAR(255)            COMMENT 'data_object.data.vendor_specific.s3.encryption.type',
    s3_encryption_kms_key_id                 STRING                  COMMENT 'data_object.data.vendor_specific.s3.encryption.kms_key_id',
    s3_object_lock_mode                      VARCHAR(255)            COMMENT 'data_object.data.vendor_specific.s3.object_lock.mode',
    s3_object_lock_retain_until              DATETIME                COMMENT 'data_object.data.vendor_specific.s3.object_lock.retain_until_date',

    -- GCS-specific queryable fields
    gcs_storage_class                        VARCHAR(255)            COMMENT 'data_object.data.vendor_specific.gcs.storage_class',
    gcs_encryption_kms_key                   STRING                  COMMENT 'data_object.data.vendor_specific.gcs.encryption.default_kms_key',
    gcs_uniform_access_enabled               BOOLEAN                 COMMENT 'data_object.data.vendor_specific.gcs.iam_configuration.uniform_bucket_level_access.enabled',

    -- Azure-specific queryable fields
    azure_access_tier                        VARCHAR(255)            COMMENT 'data_object.data.vendor_specific.azure.access_tier',
    azure_container_access_type              VARCHAR(255)            COMMENT 'data_object.data.vendor_specific.azure.container_access_type',
    azure_encryption_enabled                 BOOLEAN                 COMMENT 'data_object.data.vendor_specific.azure.encryption.services.blob.enabled',

    -- Full vendor configuration as JSON
    vendor_config_full_json                  JSON                    COMMENT 'data_object.data.vendor_specific - Complete vendor configuration (JSON)',

    -- Shared with (converted from Nested to JSON)
    shared_with                              JSON                    COMMENT 'data_object.data.shared_with - Entities with access',

    -- Compliance (flattened)
    compliance_status                        VARCHAR(255)            COMMENT 'compliance.status',
    compliance_status_id                     TINYINT                 COMMENT 'compliance.status_id',
    compliance_standards                     ARRAY<STRING>           COMMENT 'compliance.standards',
    compliance_violations_total              INT                     COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_pii_count          INT                     COMMENT 'compliance.privacy_violations.pii_count',
    compliance_violations_phi_count          INT                     COMMENT 'compliance.privacy_violations.phi_count',

    -- Governance (flattened)
    gov_encryption_at_rest                   BOOLEAN                 COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit                BOOLEAN                 COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm                 STRING                  COMMENT 'governance.encryption.algorithm',
    gov_owner_name                           STRING                  COMMENT 'governance.owner.name',
    gov_owner_uid                            STRING                  COMMENT 'governance.owner.uid',
    gov_owner_email                          STRING                  COMMENT 'governance.owner.email',

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
DISTRIBUTED BY HASH(id) BUCKETS 32
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);
