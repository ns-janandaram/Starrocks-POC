-- ============================================================================
-- StarRocks Migration Script
-- Converted from ClickHouse schemas
--
-- Usage:
--   mysql -h <starrocks-fe-host> -P 9030 -u root < migration.sql
--
-- Tables:
--   1.  applications    - SaaS application instances
--   2.  data_buckets    - Object storage buckets (S3, GCS, Azure Blob)
--   3.  data_objects    - Object storage objects
--   4.  databases       - Data warehouse/structured data stores
--   5.  devices         - Device information (OCSF compliant)
--   6.  emails          - Email objects
--   7.  files           - File objects
--   8.  finding_info    - Security findings and compliance violations
--   9.  groups          - Group objects (OCSF 1.7.0)
--   10. messages        - Chat messages from collaboration apps
--   11. privileges      - Privilege objects (OCSF 1.7.0)
--   12. users           - User objects (OCSF 1.7.0)
--
-- Notes:
--   - All tables use PRIMARY KEY for fast UPSERT operations
--   - Partitioned by tenant_id for multi-tenant isolation
--   - enable_persistent_index=true for optimized update performance
--   - Adjust replication_num for production (recommended: 2-3)
--   - Adjust bucket counts based on data volume
-- ============================================================================

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS netskope;
USE netskope;

-- ============================================================================
-- 1. APPLICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS applications
(
    -- Primary Key columns (for UPSERT support)
    tenant_id                     INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                            STRING                  COMMENT 'application.uid - Unique application identifier',

    -- Core application fields
    name                          STRING                  COMMENT 'application.name - Application name',
    type                          VARCHAR(255)            COMMENT 'application.type - Category of application',
    labels                        ARRAY<STRING>           COMMENT 'application.labels - Tags/labels',
    risk_level                    VARCHAR(255)            COMMENT 'application.risk_level - Risk level',
    risk_score                    INT                     COMMENT 'application.risk_score - Risk score',

    -- Owner (flattened from governance.owner reference)
    owner_uid                     STRING                  COMMENT 'application.owner.uid - Owner unique identifier',
    owner_name                    STRING                  COMMENT 'application.owner.name - Owner name',
    owner_email                   STRING                  COMMENT 'application.owner.email - Owner email address',

    -- Risks (flattened from risk.json reference)
    risk_confidence               FLOAT                   COMMENT 'application.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                   VARCHAR(255)            COMMENT 'application.risks.risk_domain - Primary risk domain',
    risk_assessed_at              DATETIME                COMMENT 'application.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by              STRING                  COMMENT 'application.risks.assessed_by - System that performed assessment',

    -- Application data (flattened)
    app_management                VARCHAR(255)            COMMENT 'application.data.app_management',
    deployment                    VARCHAR(255)            COMMENT 'application.data.deployment',
    app_suite_id                  INT                     COMMENT 'application.data.app_suite.id',
    app_suite_name                VARCHAR(255)            COMMENT 'application.data.app_suite.name',
    app_suite_vendor              STRING                  COMMENT 'application.data.app_suite.vendor',
    vendor                        STRING                  COMMENT 'application.data.vendor',
    app_classification            VARCHAR(255)            COMMENT 'application.data.application_classification',

    -- Netskope extension fields (flattened)
    instance_uid                  STRING                  COMMENT 'x_netskope.instance.uid',
    instance_id                   STRING                  COMMENT 'x_netskope.instance.id',
    instance_name                 STRING                  COMMENT 'x_netskope.instance.name',
    instance_creation_time        DATETIME                COMMENT 'x_netskope.instance.created_time',
    instance_enabled              BOOLEAN                 COMMENT 'x_netskope.instance.enabled',
    instance_authorized           BOOLEAN                 COMMENT 'x_netskope.instance.authorization.authorized',
    instance_grant_time           DATETIME                COMMENT 'x_netskope.instance.authorization.grant_time',
    discovery_source              VARCHAR(255)            COMMENT 'x_netskope.discovery_source',
    discovery_time                DATETIME                COMMENT 'x_netskope.discovery_time',

    -- Special columns
    _insert_time                  DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);

-- ============================================================================
-- 2. DATA_BUCKETS TABLE
-- ============================================================================
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

-- ============================================================================
-- 3. DATA_OBJECTS TABLE
-- ============================================================================
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

-- ============================================================================
-- 4. DATABASES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS databases
(
    -- Primary Key columns
    tenant_id                                INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                       STRING                  COMMENT 'data_warehouse.id - Unique identifier',

    -- Core data warehouse fields
    name                                     STRING                  COMMENT 'data_warehouse.name - User-friendly name',

    -- Platform (flattened)
    platform_id                              TINYINT                 COMMENT 'data_warehouse.platform.id',
    platform_name                            VARCHAR(255)            COMMENT 'data_warehouse.platform.name',
    platform_version                         STRING                  COMMENT 'data_warehouse.platform.version',

    -- Cloud provider (flattened)
    cloud_provider                           VARCHAR(255)            COMMENT 'data_warehouse.cloud_provider.provider',
    cloud_account_id                         STRING                  COMMENT 'data_warehouse.cloud_provider.account_id',
    cloud_account_name                       STRING                  COMMENT 'data_warehouse.cloud_provider.account_name',
    cloud_region                             STRING                  COMMENT 'data_warehouse.cloud_provider.region',

    -- Platform-specific configuration - Common fields
    platform_config_database                 STRING                  COMMENT 'data_warehouse.platform_configuration.database',
    platform_config_schema                   STRING                  COMMENT 'data_warehouse.platform_configuration.schema',
    platform_config_hostname                 STRING                  COMMENT 'data_warehouse.platform_configuration.hostname',
    platform_config_port                     INT                     COMMENT 'data_warehouse.platform_configuration.port',

    -- Athena-specific fields
    platform_config_athena_s3_output         STRING                  COMMENT 'data_warehouse.platform_configuration.athena.s3_output_location',
    platform_config_athena_catalog           STRING                  COMMENT 'data_warehouse.platform_configuration.athena.catalog_name',
    platform_config_athena_workgroup         STRING                  COMMENT 'data_warehouse.platform_configuration.athena.workgroup',

    -- BigQuery-specific fields
    platform_config_bq_project_id            STRING                  COMMENT 'data_warehouse.platform_configuration.bigquery.project_id',
    platform_config_bq_dataset_id            STRING                  COMMENT 'data_warehouse.platform_configuration.bigquery.dataset_id',
    platform_config_bq_location              STRING                  COMMENT 'data_warehouse.platform_configuration.bigquery.location',

    -- Snowflake-specific fields
    platform_config_snowflake_account        STRING                  COMMENT 'data_warehouse.platform_configuration.snowflake.account',
    platform_config_snowflake_warehouse      STRING                  COMMENT 'data_warehouse.platform_configuration.snowflake.warehouse',
    platform_config_snowflake_role           STRING                  COMMENT 'data_warehouse.platform_configuration.snowflake.role',

    -- Redshift-specific fields
    platform_config_redshift_cluster         STRING                  COMMENT 'data_warehouse.platform_configuration.redshift.cluster_identifier',

    -- Databricks-specific fields
    platform_config_databricks_http_path     STRING                  COMMENT 'data_warehouse.platform_configuration.databricks.http_path',
    platform_config_databricks_catalog       STRING                  COMMENT 'data_warehouse.platform_configuration.databricks.catalog',

    -- MongoDB-specific fields
    platform_config_mongodb_auth_db          STRING                  COMMENT 'data_warehouse.platform_configuration.mongodb.auth_database',
    platform_config_mongodb_replica_set      STRING                  COMMENT 'data_warehouse.platform_configuration.mongodb.replica_set',

    -- SAP HANA-specific fields
    platform_config_sap_hana_database        STRING                  COMMENT 'data_warehouse.platform_configuration.sap_hana.database',
    platform_config_sap_hana_schema          STRING                  COMMENT 'data_warehouse.platform_configuration.sap_hana.schema',

    -- S3 Retrieval configuration (flattened)
    platform_config_s3_enabled               BOOLEAN                 COMMENT 'data_warehouse.platform_configuration.s3_retrieval.enabled',
    platform_config_s3_bucket_name           STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.bucket_name',
    platform_config_s3_prefix                STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.prefix',
    platform_config_s3_cloud_account         STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.cloud_account',
    platform_config_s3_csv_username_index    INT                     COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.username_index',
    platform_config_s3_csv_database_index    INT                     COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.database_index',
    platform_config_s3_csv_query_text_index  INT                     COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.query_text_index',
    platform_config_s3_csv_timestamp_index   INT                     COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.timestamp_index',
    platform_config_s3_csv_schema_index      INT                     COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.schema_index',
    platform_config_s3_csv_rowcount_index    INT                     COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.rowcount_index',
    platform_config_s3_json_username_key     STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.username_key',
    platform_config_s3_json_database_key     STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.database_key',
    platform_config_s3_json_query_text_key   STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.query_text_key',
    platform_config_s3_json_timestamp_key    STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.timestamp_key',
    platform_config_s3_json_schema_key       STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.schema_key',
    platform_config_s3_json_rowcount_key     STRING                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.rowcount_key',

    -- Generic SQL configuration fields (flattened)
    platform_config_generic_database         STRING                  COMMENT 'data_warehouse.platform_configuration.generic_sql.database',
    platform_config_generic_schema           STRING                  COMMENT 'data_warehouse.platform_configuration.generic_sql.schema',
    platform_config_generic_connection_string STRING                 COMMENT 'data_warehouse.platform_configuration.generic_sql.connection_string',
    platform_config_generic_driver           STRING                  COMMENT 'data_warehouse.platform_configuration.generic_sql.driver',
    platform_config_generic_hostname         STRING                  COMMENT 'data_warehouse.platform_configuration.generic_sql.hostname',
    platform_config_generic_port             INT                     COMMENT 'data_warehouse.platform_configuration.generic_sql.port',
    platform_config_generic_protocol         STRING                  COMMENT 'data_warehouse.platform_configuration.generic_sql.protocol',

    -- Instance configuration (flattened)
    config_scan_enabled                      BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.scan_enabled',
    config_scan_frequency                    VARCHAR(255)            COMMENT 'data_warehouse.configuration.instance.scan_frequency',
    config_scan_schedule_type                TINYINT                 COMMENT 'data_warehouse.configuration.instance.scan_schedule_type',
    config_classification_enabled            BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.classification_enabled',
    config_query_retrieval_enabled           BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.query_retrieval_enabled',
    config_dml_retrieval_enabled             BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.dml_retrieval_enabled',
    config_role_retrieval_enabled            BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.role_retrieval_enabled',
    config_tag_import_enabled                BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.tag_import_enabled',
    config_scan_all_databases                BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.scan_all_databases',
    config_is_unstructured                   BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.is_unstructured',
    config_skip_schema_initialization        BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.skip_schema_initialization',
    config_is_snapshot_scan                  BOOLEAN                 COMMENT 'data_warehouse.configuration.instance.is_snapshot_scan',
    config_integration_panoptica_id          STRING                  COMMENT 'data_warehouse.configuration.instance.integration_ids.panoptica_integration_id',
    config_integration_cohesity_id           STRING                  COMMENT 'data_warehouse.configuration.instance.integration_ids.cohesity_integration_id',

    -- Security configuration (flattened)
    security_encryption_at_rest              BOOLEAN                 COMMENT 'data_warehouse.configuration.security.encryption.at_rest',
    security_encryption_in_transit           BOOLEAN                 COMMENT 'data_warehouse.configuration.security.encryption.in_transit',
    security_encryption_algorithm            STRING                  COMMENT 'data_warehouse.configuration.security.encryption.algorithm',
    security_encryption_key_mgmt             STRING                  COMMENT 'data_warehouse.configuration.security.encryption.key_management',
    security_auth_mfa_enabled                BOOLEAN                 COMMENT 'data_warehouse.configuration.security.authentication.mfa_enabled',
    security_auth_methods                    ARRAY<STRING>           COMMENT 'data_warehouse.configuration.security.authentication.methods',
    security_auth_has_password               BOOLEAN                 COMMENT 'data_warehouse.configuration.security.authentication.has_password',
    security_auth_has_private_key            BOOLEAN                 COMMENT 'data_warehouse.configuration.security.authentication.has_private_key',
    security_network_public_access_blocked   BOOLEAN                 COMMENT 'data_warehouse.configuration.security.network.public_access_blocked',
    security_network_vpc_id                  STRING                  COMMENT 'data_warehouse.configuration.security.network.vpc_id',
    security_network_allowed_cidrs           ARRAY<STRING>           COMMENT 'data_warehouse.configuration.security.network.allowed_cidrs',
    security_network_firewall_enabled        BOOLEAN                 COMMENT 'data_warehouse.configuration.security.network.firewall_enabled',
    security_audit_enabled                   BOOLEAN                 COMMENT 'data_warehouse.configuration.security.audit.enabled',
    security_audit_log_destination           STRING                  COMMENT 'data_warehouse.configuration.security.audit.log_destination',

    -- Hierarchy metrics (flattened)
    metrics_database_count                   INT                     COMMENT 'data_warehouse.metrics.hierarchy.database_count',
    metrics_schema_count                     INT                     COMMENT 'data_warehouse.metrics.hierarchy.schema_count',
    metrics_table_count                      INT                     COMMENT 'data_warehouse.metrics.hierarchy.table_count',
    metrics_column_count                     INT                     COMMENT 'data_warehouse.metrics.hierarchy.column_count',
    metrics_field_count                      INT                     COMMENT 'data_warehouse.metrics.hierarchy.field_count',
    metrics_total_row_count                  BIGINT                  COMMENT 'data_warehouse.metrics.hierarchy.total_row_count',

    -- Sensitivity metrics (flattened)
    metrics_sensitive_column_count           INT                     COMMENT 'data_warehouse.metrics.sensitivity.sensitive_column_count',
    metrics_sensitive_field_count            INT                     COMMENT 'data_warehouse.metrics.sensitivity.sensitive_field_count',
    metrics_unreviewed_column_count          INT                     COMMENT 'data_warehouse.metrics.sensitivity.unreviewed_column_count',
    metrics_unreviewed_field_count           INT                     COMMENT 'data_warehouse.metrics.sensitivity.unreviewed_field_count',
    metrics_sensitive_data_type_count        INT                     COMMENT 'data_warehouse.metrics.sensitivity.sensitive_data_type_count',
    metrics_sensitive_data_types             ARRAY<STRING>           COMMENT 'data_warehouse.metrics.sensitivity.sensitive_data_types',
    metrics_sensitive_data_type_ids          ARRAY<STRING>           COMMENT 'data_warehouse.metrics.sensitivity.sensitive_data_type_ids',
    metrics_sensitivity_score                INT                     COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_score',
    metrics_sensitivity_high_count           INT                     COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_levels.high_count',
    metrics_sensitivity_medium_count         INT                     COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_levels.medium_count',
    metrics_sensitivity_low_count            INT                     COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_levels.low_count',

    -- Size metrics (flattened)
    metrics_total_size_bytes                 BIGINT                  COMMENT 'data_warehouse.metrics.size.total_size_bytes',
    metrics_structured_size_bytes            BIGINT                  COMMENT 'data_warehouse.metrics.size.structured_size_bytes',
    metrics_sensitive_data_size_bytes        BIGINT                  COMMENT 'data_warehouse.metrics.size.sensitive_data_size_bytes',
    metrics_structured_sensitive_size_bytes  BIGINT                  COMMENT 'data_warehouse.metrics.size.structured_sensitive_size_bytes',
    metrics_unstructured_size_bytes          BIGINT                  COMMENT 'data_warehouse.metrics.size.unstructured_size_bytes',
    metrics_unstructured_sensitive_size_bytes BIGINT                 COMMENT 'data_warehouse.metrics.size.unstructured_sensitive_size_bytes',

    -- Exposure metrics (flattened)
    metrics_exposure                         VARCHAR(255)            COMMENT 'data_warehouse.metrics.exposure.exposure',
    metrics_exposure_score                   INT                     COMMENT 'data_warehouse.metrics.exposure.exposure_score',
    metrics_publicly_accessible              BOOLEAN                 COMMENT 'data_warehouse.metrics.exposure.publicly_accessible',
    metrics_externally_shared                BOOLEAN                 COMMENT 'data_warehouse.metrics.exposure.externally_shared',
    metrics_users_with_access_count          INT                     COMMENT 'data_warehouse.metrics.exposure.users_with_access_count',
    metrics_privileged_users_count           INT                     COMMENT 'data_warehouse.metrics.exposure.privileged_users_count',
    metrics_external_users_count             INT                     COMMENT 'data_warehouse.metrics.exposure.external_users_count',

    -- Risk metrics (flattened)
    metrics_findings_critical                INT                     COMMENT 'data_warehouse.metrics.risk.findings_by_severity.critical',
    metrics_findings_high                    INT                     COMMENT 'data_warehouse.metrics.risk.findings_by_severity.high',
    metrics_findings_medium                  INT                     COMMENT 'data_warehouse.metrics.risk.findings_by_severity.medium',
    metrics_findings_low                     INT                     COMMENT 'data_warehouse.metrics.risk.findings_by_severity.low',

    -- Activity metrics (flattened)
    metrics_last_scan_time                   DATETIME                COMMENT 'data_warehouse.metrics.activity.last_scan_time',
    metrics_last_scan_id                     STRING                  COMMENT 'data_warehouse.metrics.activity.last_scan_id',
    metrics_last_schema_sync_time            DATETIME                COMMENT 'data_warehouse.metrics.activity.last_schema_sync_time',
    metrics_last_accessed_time               DATETIME                COMMENT 'data_warehouse.metrics.activity.last_accessed_time',
    metrics_query_count                      INT                     COMMENT 'data_warehouse.metrics.activity.query_count',
    metrics_query_count_30d                  INT                     COMMENT 'data_warehouse.metrics.activity.query_count_30d',
    metrics_alert_count                      INT                     COMMENT 'data_warehouse.metrics.activity.alert_count',
    metrics_alert_count_30d                  INT                     COMMENT 'data_warehouse.metrics.activity.alert_count_30d',

    -- Stale data metrics
    stale_data_size_bytes                    BIGINT                  COMMENT 'data_warehouse.metrics.activity.stale_data.size_bytes',
    stale_data_period_days                   INT                     COMMENT 'data_warehouse.metrics.activity.stale_data.period_days',
    stale_data_time_unit                     VARCHAR(255)            COMMENT 'data_warehouse.metrics.activity.stale_data.time_unit',
    stale_data_last_accessed_by              STRING                  COMMENT 'data_warehouse.metrics.activity.stale_data.last_accessed_by',
    stale_data_last_accessed                 DATETIME                COMMENT 'data_warehouse.metrics.activity.stale_data.last_accessed',
    stale_data_analysis_enabled              BOOLEAN                 COMMENT 'data_warehouse.metrics.activity.stale_data.analysis_enabled',
    stale_data_employee_id                   STRING                  COMMENT 'data_warehouse.metrics.activity.stale_data.employee_id',

    -- Tags and labels
    tags                                     ARRAY<STRING>           COMMENT 'data_warehouse.tags',

    -- Metadata (flattened)
    metadata_content_hash                    STRING                  COMMENT 'metadata.content_hash - Hash for change detection',

    -- Governance (flattened)
    gov_encryption_at_rest                   BOOLEAN                 COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit                BOOLEAN                 COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm                 STRING                  COMMENT 'governance.encryption.algorithm',
    gov_encryption_key_mgmt                  STRING                  COMMENT 'governance.encryption.key_management',
    gov_owner_uid                            STRING                  COMMENT 'governance.owner.uid',
    gov_owner_name                           STRING                  COMMENT 'governance.owner.name',
    gov_owner_email                          STRING                  COMMENT 'governance.owner.email',
    gov_steward_uid                          STRING                  COMMENT 'governance.steward.uid',
    gov_steward_name                         STRING                  COMMENT 'governance.steward.name',
    gov_steward_email                        STRING                  COMMENT 'governance.steward.email',
    gov_classification_level                 VARCHAR(255)            COMMENT 'governance.classification.level',
    gov_classification_labels                ARRAY<STRING>           COMMENT 'governance.classification.labels',
    gov_classification_classified_by         STRING                  COMMENT 'governance.classification.classified_by',
    gov_classification_classified_time       DATETIME                COMMENT 'governance.classification.classified_time',
    gov_retention_policy_enabled             BOOLEAN                 COMMENT 'governance.retention.policy_enabled',
    gov_retention_policy_name                STRING                  COMMENT 'governance.retention.policy_name',
    gov_retention_period_days                INT                     COMMENT 'governance.retention.retention_period_days',
    gov_retention_delete_after               BOOLEAN                 COMMENT 'governance.retention.delete_after_retention',
    gov_retention_legal_hold                 BOOLEAN                 COMMENT 'governance.retention.legal_hold',
    gov_resiliency_versioning_enabled        BOOLEAN                 COMMENT 'governance.resiliency.versioning_enabled',
    gov_resiliency_lifecycle_enabled         BOOLEAN                 COMMENT 'governance.resiliency.lifecycle_policies_enabled',
    gov_resiliency_replication_enabled       BOOLEAN                 COMMENT 'governance.resiliency.replication_enabled',
    gov_resiliency_replication_within_region BOOLEAN                 COMMENT 'governance.resiliency.replication_within_region',
    gov_resiliency_backup_enabled            BOOLEAN                 COMMENT 'governance.resiliency.backup_enabled',
    gov_exposure                             VARCHAR(255)            COMMENT 'governance.exposure',

    -- Compliance (flattened)
    compliance_status                        VARCHAR(255)            COMMENT 'compliance.status',
    compliance_status_id                     INT                     COMMENT 'compliance.status_id',
    compliance_standards                     ARRAY<STRING>           COMMENT 'compliance.standards',
    compliance_finding_ids                   ARRAY<STRING>           COMMENT 'compliance.finding_ids',
    compliance_posture_tags                  ARRAY<STRING>           COMMENT 'compliance.posture_tags',
    compliance_pv_total_violations           INT                     COMMENT 'compliance.privacy_violations.total_violations',
    compliance_pv_pii_count                  INT                     COMMENT 'compliance.privacy_violations.pii_count',
    compliance_pv_phi_count                  INT                     COMMENT 'compliance.privacy_violations.phi_count',
    compliance_pv_hipaa_count                INT                     COMMENT 'compliance.privacy_violations.hipaa_count',
    compliance_pv_ccpa_count                 INT                     COMMENT 'compliance.privacy_violations.ccpa_count',
    compliance_pv_pci_count                  INT                     COMMENT 'compliance.privacy_violations.pci_count',
    compliance_pv_nist_count                 INT                     COMMENT 'compliance.privacy_violations.nist_count',
    compliance_pv_gdpr_count                 INT                     COMMENT 'compliance.privacy_violations.gdpr_count',
    compliance_pv_large_data_export          BOOLEAN                 COMMENT 'compliance.privacy_violations.large_data_export',
    compliance_pv_sensitive_data_export      BOOLEAN                 COMMENT 'compliance.privacy_violations.sensitive_data_export',
    compliance_pv_sensitive_data_modified    BOOLEAN                 COMMENT 'compliance.privacy_violations.sensitive_data_modified',
    compliance_pv_sensitive_data_accessed    BOOLEAN                 COMMENT 'compliance.privacy_violations.sensitive_data_accessed',
    compliance_pv_sensitive_data_shared      BOOLEAN                 COMMENT 'compliance.privacy_violations.sensitive_data_shared',

    -- Risks (flattened from risk.json reference)
    risk_level                               VARCHAR(255)            COMMENT 'risks.risk_level',
    risk_score                               INT                     COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          FLOAT                   COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              VARCHAR(255)            COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DATETIME                COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         STRING                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    app_id                                   STRING                  COMMENT 'x_netskope.app_id',
    app_name                                 VARCHAR(255)            COMMENT 'x_netskope.app_name',
    instance_id                              STRING                  COMMENT 'x_netskope.instance_id',
    instance_name                            STRING                  COMMENT 'x_netskope.instance_name',
    instance_creation_time                   DATETIME                COMMENT 'x_netskope.instance_creation_time',

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

-- ============================================================================
-- 5. DEVICES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS devices
(
    -- Primary Key columns
    tenant_id                                INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                       STRING                  COMMENT 'device.uid - Unique device identifier',

    -- Core device fields
    name                                     STRING                  COMMENT 'device.name - Device name',
    hostname                                 STRING                  COMMENT 'device.hostname - Device hostname',
    type                                     VARCHAR(255)            COMMENT 'device.type - Device type name',

    -- Owner (flattened from governance.owner reference)
    owner_uid                                STRING                  COMMENT 'device.owner.uid - Owner unique identifier',
    owner_name                               STRING                  COMMENT 'device.owner.name - Owner name',
    owner_email                              STRING                  COMMENT 'device.owner.email - Owner email address',

    -- OS (flattened)
    os_name                                  VARCHAR(255)            COMMENT 'device.os.name - Operating system name',
    os_version                               STRING                  COMMENT 'device.os.version - OS version',
    os_type                                  VARCHAR(255)            COMMENT 'device.os.type - OS type',
    os_edition                               STRING                  COMMENT 'device.os.edition - OS edition',
    os_build                                 STRING                  COMMENT 'device.os.build - OS build number',

    -- Hardware info (flattened)
    hw_vendor_name                           STRING                  COMMENT 'device.hw_info.vendor_name - Device manufacturer',
    hw_serial_number                         STRING                  COMMENT 'device.hw_info.serial_number',
    hw_cpu_type                              STRING                  COMMENT 'device.hw_info.cpu_type',
    hw_cpu_count                             INT                     COMMENT 'device.hw_info.cpu_count',
    hw_ram_size                              BIGINT                  COMMENT 'device.hw_info.ram_size',

    -- Hardware metrics (flattened)
    hw_memory_total_kb                       BIGINT                  COMMENT 'x_netskope.hardware_metrics.memory_total_kb',
    hw_memory_available_kb                   BIGINT                  COMMENT 'x_netskope.hardware_metrics.memory_available_kb',
    hw_battery_level                         TINYINT                 COMMENT 'x_netskope.hardware_metrics.battery_level',

    -- Processor metrics (converted from Nested to JSON)
    hw_processors                            JSON                    COMMENT 'x_netskope.hardware_metrics.processors',

    -- Disk metrics (converted from Nested to JSON)
    hw_disks                                 JSON                    COMMENT 'x_netskope.hardware_metrics.disks',

    -- WiFi signal strength (converted from Nested to JSON)
    hw_wifi_signals                          JSON                    COMMENT 'x_netskope.hardware_metrics.wifi_signal_strength',

    -- Network interfaces (converted from Nested to JSON)
    network_interfaces                       JSON                    COMMENT 'device.network_interfaces',

    -- Network basic fields
    mac                                      STRING                  COMMENT 'device.mac - Primary MAC address',
    ip                                       STRING                  COMMENT 'device.ip - Primary IP address',

    -- Location (flattened)
    location_city                            STRING                  COMMENT 'device.location.city',
    location_region                          STRING                  COMMENT 'device.location.region',
    location_country                         STRING                  COMMENT 'device.location.country',
    location_continent                       STRING                  COMMENT 'device.location.continent',
    location_lat                             DOUBLE                  COMMENT 'device.location.lat',
    location_long                            DOUBLE                  COMMENT 'device.location.long',
    location_postal_code                     STRING                  COMMENT 'device.location.postal_code',
    location_desc                            STRING                  COMMENT 'device.location.desc',
    location_isp                             STRING                  COMMENT 'device.location.isp',

    -- Device status
    domain                                   STRING                  COMMENT 'device.domain',

    -- Risks (flattened from risk.json reference)
    risk_level                               VARCHAR(255)            COMMENT 'device.risks.risk_level',
    risk_score                               INT                     COMMENT 'device.risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          FLOAT                   COMMENT 'device.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              VARCHAR(255)            COMMENT 'device.risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DATETIME                COMMENT 'device.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         STRING                  COMMENT 'device.risks.assessed_by - System that performed assessment',

    is_managed                               BOOLEAN                 COMMENT 'device.is_managed',
    is_personal                              BOOLEAN                 COMMENT 'device.is_personal',
    is_compliant                             BOOLEAN                 COMMENT 'device.is_compliant',
    is_trusted                               BOOLEAN                 COMMENT 'device.is_trusted',
    last_seen_time                           DATETIME                COMMENT 'device.last_seen_time',
    tags                                     ARRAY<STRING>           COMMENT 'device.tags',

    -- Netskope extension fields (flattened)
    logged_time                              DATETIME                COMMENT 'x_netskope.logged_time',
    nsdeviceuid                              STRING                  COMMENT 'x_netskope.nsdeviceuid',
    hwinfo_device_make                       STRING                  COMMENT 'x_netskope.hwinfo_extended.device_make',
    hwinfo_hardware_model                    STRING                  COMMENT 'x_netskope.hwinfo_extended.hardware_model',
    hwinfo_device_model                      STRING                  COMMENT 'x_netskope.hwinfo_extended.device_model',
    client_version                           STRING                  COMMENT 'x_netskope.client_version',
    client_install_time                      DATETIME                COMMENT 'x_netskope.client_install_time',
    discovery_source                         VARCHAR(255)            COMMENT 'x_netskope.discovery_source',
    discovery_time                           DATETIME                COMMENT 'x_netskope.discovery_time',
    runner_version                           STRING                  COMMENT 'x_netskope.runner_version',
    runner_type                              VARCHAR(255)            COMMENT 'x_netskope.runner_type',
    steering_config                          STRING                  COMMENT 'x_netskope.steering_config',

    -- Browser (flattened)
    browser_name                             VARCHAR(255)            COMMENT 'x_netskope.browser.name',
    browser_version                          INT                     COMMENT 'x_netskope.browser.version',
    browser_extension_id                     STRING                  COMMENT 'x_netskope.browser.extension_id',
    browser_extension_version                STRING                  COMMENT 'x_netskope.browser.extension_version',

    -- Network extended (flattened)
    network_transport                        STRING                  COMMENT 'x_netskope.network_extended.transport',
    network_type                             STRING                  COMMENT 'x_netskope.network_extended.type',
    network_id                               STRING                  COMMENT 'x_netskope.network_extended.id',
    network_name                             STRING                  COMMENT 'x_netskope.network_extended.name',
    network_rssi                             INT                     COMMENT 'x_netskope.network_extended.rssi',
    network_radio_quality                    FLOAT                   COMMENT 'x_netskope.network_extended.radio_quality',
    network_dns_servers_v4                   ARRAY<STRING>           COMMENT 'x_netskope.network_extended.dns_servers_v4',
    network_dns_servers_v6                   ARRAY<STRING>           COMMENT 'x_netskope.network_extended.dns_servers_v6',
    network_send_rate_kbps                   ARRAY<FLOAT>            COMMENT 'x_netskope.network_extended.send_rate_kbps',
    network_recv_rate_kbps                   ARRAY<FLOAT>            COMMENT 'x_netskope.network_extended.recv_rate_kbps',
    network_last_connected_private_ip        STRING                  COMMENT 'x_netskope.network_extended.last_connected_from_private_ip',
    network_last_connected_public_ip         STRING                  COMMENT 'x_netskope.network_extended.last_connected_from_public_ip',

    -- Location extended (flattened)
    location_site_id                         STRING                  COMMENT 'x_netskope.location_extended.site_id',
    location_gateway_id                      STRING                  COMMENT 'x_netskope.location_extended.gateway_id',
    location_pop                             STRING                  COMMENT 'x_netskope.location_extended.pop',
    location_organization                    STRING                  COMMENT 'x_netskope.location_extended.organization',
    location_asn                             STRING                  COMMENT 'x_netskope.location_extended.asn',
    location_domain                          STRING                  COMMENT 'x_netskope.location_extended.domain',

    -- On-premises detection (flattened)
    onprem_status                            VARCHAR(255)            COMMENT 'x_netskope.onprem_detection.status',
    onprem_method                            STRING                  COMMENT 'x_netskope.onprem_detection.method',
    onprem_domain                            STRING                  COMMENT 'x_netskope.onprem_detection.domain',
    onprem_config_ip                         STRING                  COMMENT 'x_netskope.onprem_detection.config_ip',
    onprem_match_ip                          STRING                  COMMENT 'x_netskope.onprem_detection.match_ip',

    -- On-prem labels (converted from Nested to JSON)
    onprem_labels                            JSON                    COMMENT 'x_netskope.onprem_detection.labels',

    -- On-prem detection details (converted from Nested to JSON)
    onprem_details                           JSON                    COMMENT 'x_netskope.onprem_detection.details',

    -- Device classification (flattened)
    classification_status                    VARCHAR(255)            COMMENT 'x_netskope.device_classification.status',
    classification_status_code               INT                     COMMENT 'x_netskope.device_classification.status_code',
    classification_custom_status             STRING                  COMMENT 'x_netskope.device_classification.custom_status',
    classification_label                     STRING                  COMMENT 'x_netskope.device_classification.label',
    classification_label_id                  INT                     COMMENT 'x_netskope.device_classification.label_id',
    classification_label_priority            INT                     COMMENT 'x_netskope.device_classification.label_priority',
    classification_label_description         STRING                  COMMENT 'x_netskope.device_classification.label_description',

    -- Other Netskope fields
    npa_status                               INT                     COMMENT 'x_netskope.npa_status',
    orgkey                                   STRING                  COMMENT 'x_netskope.orgkey',
    status                                   INT                     COMMENT 'x_netskope.status',
    device_score                             DOUBLE                  COMMENT 'x_netskope.device_score',
    management_id                            STRING                  COMMENT 'x_netskope.management_id',

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

-- ============================================================================
-- 6. EMAILS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS emails
(
    -- Primary Key columns
    tenant_id                            INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                   STRING                  COMMENT 'email.uid - Unique email identifier',

    -- Core email fields
    message_uid                          STRING                  COMMENT 'email.message_uid - Message unique identifier',
    `from`                               STRING                  COMMENT 'email.from - Sender email address',
    `to`                                 ARRAY<STRING>           COMMENT 'email.to - Recipient email addresses',

    -- Governance (flattened)
    gov_encryption_at_rest               BOOLEAN                 COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit            BOOLEAN                 COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm             STRING                  COMMENT 'governance.encryption.algorithm',
    gov_owner_name                       STRING                  COMMENT 'governance.owner.name',
    gov_owner_uid                        STRING                  COMMENT 'governance.owner.uid',
    gov_owner_email                      STRING                  COMMENT 'governance.owner.email',

    -- Compliance (flattened)
    compliance_status                    VARCHAR(255)            COMMENT 'compliance.status',
    compliance_status_id                 TINYINT                 COMMENT 'compliance.status_id',
    compliance_standards                 ARRAY<STRING>           COMMENT 'compliance.standards',
    compliance_violations_total          INT                     COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_pii_count      INT                     COMMENT 'compliance.privacy_violations.pii_count',
    compliance_violations_phi_count      INT                     COMMENT 'compliance.privacy_violations.phi_count',

    -- Risks (flattened from risk.json reference)
    risk_level                           VARCHAR(255)            COMMENT 'risks.risk_level',
    risk_score                           INT                     COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                      FLOAT                   COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                          VARCHAR(255)            COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                     DATETIME                COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                     STRING                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    app                                  VARCHAR(255)            COMMENT 'x_netskope.app - Source application name',
    instance                             STRING                  COMMENT 'x_netskope.instance - Application instance',
    last_scanned                         DATETIME                COMMENT 'x_netskope.last_scanned - Last DLP scan time',
    mailbox_owner                        STRING                  COMMENT 'x_netskope.mailbox_owner - Mailbox owner email',
    num_recipients                       INT                     COMMENT 'x_netskope.num_recipients - Total recipients',
    num_external_recipients              INT                     COMMENT 'x_netskope.num_external_recipients',
    folders                              ARRAY<STRING>           COMMENT 'x_netskope.folders - Email folders/labels',
    exposure                             VARCHAR(255)            COMMENT 'x_netskope.exposure - Email exposure level',
    violations_in                        ARRAY<STRING>           COMMENT 'x_netskope.violations_in - Policy violations',
    discovery_source                     VARCHAR(255)            COMMENT 'x_netskope.discovery_source',
    discovery_time                       DATETIME                COMMENT 'x_netskope.discovery_time',
    app_category                         VARCHAR(255)            COMMENT 'x_netskope.app_category',
    app_suite                            VARCHAR(255)            COMMENT 'x_netskope.app_suite',

    -- Special columns
    _insert_time                         DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 16
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);

-- ============================================================================
-- 7. FILES TABLE
-- ============================================================================
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

-- ============================================================================
-- 8. FINDING_INFO TABLE
-- ============================================================================
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

-- ============================================================================
-- 9. GROUPS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS groups
(
    -- Primary Key columns
    tenant_id                     INT                     COMMENT 'group.x_netskope.tenant_id - Netskope tenant identifier',
    id                            STRING                  COMMENT 'group.uid - Unique group identifier',

    -- Core group fields
    name                          STRING                  COMMENT 'group.name - Group name',
    type                          VARCHAR(255)            COMMENT 'group.type - Type of group',
    `desc`                        STRING                  COMMENT 'group.desc - Group description',
    domain                        STRING                  COMMENT 'group.domain - Domain where group is defined',

    -- Arrays
    privilege_ids                 ARRAY<STRING>           COMMENT 'group.privilege_ids - Assigned privilege identifiers',

    -- Netskope extension fields (flattened)
    source_service                VARCHAR(255)            COMMENT 'group.x_netskope.source_service - Source system',
    app                           VARCHAR(255)            COMMENT 'group.x_netskope.app - Application name',
    app_suite                     VARCHAR(255)            COMMENT 'group.x_netskope.app_suite - Application suite',
    app_category                  VARCHAR(255)            COMMENT 'group.x_netskope.app_category - Application category',
    instance_uid                  STRING                  COMMENT 'group.x_netskope.instance_uid - Instance identifier (alternate)',
    instance_id                   STRING                  COMMENT 'group.x_netskope.instance_id - Instance identifier',
    instance_name                 STRING                  COMMENT 'group.x_netskope.instance_name - Instance name',
    email                         STRING                  COMMENT 'group.x_netskope.email - Group email address',
    parent_group_id               STRING                  COMMENT 'group.x_netskope.parent_group_id - Parent group identifier',
    exposure                      VARCHAR(255)            COMMENT 'group.x_netskope.exposure - Exposure level',
    region                        STRING                  COMMENT 'group.x_netskope.region - Geographic region',
    member_count                  INT                     COMMENT 'group.x_netskope.member_count - Number of direct members',
    subgroup_count                INT                     COMMENT 'group.x_netskope.subgroup_count - Number of subgroups',
    created_time                  DATETIME                COMMENT 'group.x_netskope.created_time',
    modified_time                 DATETIME                COMMENT 'group.x_netskope.modified_time',
    last_activity_time            DATETIME                COMMENT 'group.x_netskope.last_activity_time',
    is_deleted                    BOOLEAN                 COMMENT 'group.x_netskope.is_deleted',
    discovery_source              VARCHAR(255)            COMMENT 'group.x_netskope.discovery_source',
    discovery_time                DATETIME                COMMENT 'group.x_netskope.discovery_time',

    -- Special columns
    _insert_time                  DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 8
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);

-- ============================================================================
-- 10. MESSAGES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages
(
    -- Primary Key columns
    tenant_id                            INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                   STRING                  COMMENT 'chat_message.uid - Unique message identifier',

    -- Core message fields
    sender_id                            STRING                  COMMENT 'chat_message.sender_id - Message sender ID',
    sender_email                         STRING                  COMMENT 'chat_message.sender_email',
    conversation                         STRING                  COMMENT 'chat_message.conversation - Conversation name',
    conversation_id                      STRING                  COMMENT 'chat_message.conversation_id',
    num_attachments                      INT                     COMMENT 'chat_message.num_attachments',
    exposure                             VARCHAR(255)            COMMENT 'chat_message.exposure - Message exposure level',

    -- Compliance (flattened)
    compliance_status                    VARCHAR(255)            COMMENT 'compliance.status',
    compliance_status_id                 TINYINT                 COMMENT 'compliance.status_id',
    compliance_standards                 ARRAY<STRING>           COMMENT 'compliance.standards',
    compliance_matched_rules_count       INT                     COMMENT 'compliance.matched_rules_count',
    compliance_violations_total          INT                     COMMENT 'compliance.privacy_violations.total_violations',

    -- Governance (flattened)
    gov_encryption_at_rest               BOOLEAN                 COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit            BOOLEAN                 COMMENT 'governance.encryption.in_transit',
    gov_owner_name                       STRING                  COMMENT 'governance.owner.name',
    gov_owner_email                      STRING                  COMMENT 'governance.owner.email',

    -- Risks (flattened from risk.json reference)
    risk_level                           VARCHAR(255)            COMMENT 'risks.risk_level',
    risk_score                           INT                     COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                      FLOAT                   COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                          VARCHAR(255)            COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                     DATETIME                COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                     STRING                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    app                                  VARCHAR(255)            COMMENT 'x_netskope.app - Source application name',
    instance                             STRING                  COMMENT 'x_netskope.instance - Application instance',
    last_scanned                         DATETIME                COMMENT 'x_netskope.last_scanned - Last DLP scan time',
    discovery_source                     VARCHAR(255)            COMMENT 'x_netskope.discovery_source',
    discovery_time                       DATETIME                COMMENT 'x_netskope.discovery_time',
    app_category                         VARCHAR(255)            COMMENT 'x_netskope.app_category',
    app_suite                            STRING                  COMMENT 'x_netskope.app_suite',

    -- Special columns
    _insert_time                         DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 16
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);

-- ============================================================================
-- 11. PRIVILEGES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS privileges
(
    -- Primary Key columns
    tenant_id                     INT                     COMMENT 'privilege.x_netskope.tenant_id - Netskope tenant identifier',
    id                            STRING                  COMMENT 'privilege.uid - Unique privilege identifier',

    -- Core privilege fields
    name                          STRING                  COMMENT 'privilege.name - Privilege name',
    type                          VARCHAR(255)            COMMENT 'privilege.type - Type of privilege',
    `desc`                        STRING                  COMMENT 'privilege.desc - Privilege description',

    -- Netskope extension fields (flattened)
    source_service                VARCHAR(255)            COMMENT 'privilege.x_netskope.source_service - Source service',
    app                           VARCHAR(255)            COMMENT 'privilege.x_netskope.app - Application name',
    app_suite                     VARCHAR(255)            COMMENT 'privilege.x_netskope.app_suite - Application suite',
    app_category                  VARCHAR(255)            COMMENT 'privilege.x_netskope.app_category - Application category',
    instance_uid                  STRING                  COMMENT 'privilege.x_netskope.instance_uid - Instance identifier (alternate)',
    instance_id                   STRING                  COMMENT 'privilege.x_netskope.instance_id - Instance identifier',
    instance_name                 STRING                  COMMENT 'privilege.x_netskope.instance_name - Instance name',
    privilege_category            STRING                  COMMENT 'privilege.x_netskope.privilege_category',
    privilege_scope               STRING                  COMMENT 'privilege.x_netskope.privilege_scope',
    object_id                     STRING                  COMMENT 'privilege.x_netskope.object_id',
    object_type                   STRING                  COMMENT 'privilege.x_netskope.object_type',
    subject_id                    STRING                  COMMENT 'privilege.x_netskope.subject_id',
    subject_type                  STRING                  COMMENT 'privilege.x_netskope.subject_type',
    expiration                    DATETIME                COMMENT 'privilege.x_netskope.expiration',
    is_admin_privilege            BOOLEAN                 COMMENT 'privilege.x_netskope.is_admin_privilege',
    created_time                  DATETIME                COMMENT 'privilege.x_netskope.created_time',
    modified_time                 DATETIME                COMMENT 'privilege.x_netskope.modified_time',
    is_deleted                    BOOLEAN                 COMMENT 'privilege.x_netskope.is_deleted',
    discovery_source              VARCHAR(255)            COMMENT 'privilege.x_netskope.discovery_source',
    discovery_time                DATETIME                COMMENT 'privilege.x_netskope.discovery_time',

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

-- ============================================================================
-- 12. USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users
(
    -- Primary Key columns
    tenant_id                     INT                     COMMENT 'user.x_netskope.tenant_id - Netskope tenant identifier',
    id                            STRING                  COMMENT 'user.uid - Unique user identifier',

    -- Core user fields
    type                          VARCHAR(255)            COMMENT 'user.type - Type of user',
    name                          STRING                  COMMENT 'user.name - Username',
    display_name                  STRING                  COMMENT 'user.display_name - Display name',
    email_addr                    STRING                  COMMENT 'user.email_addr - Primary email address',
    phone_number                  STRING                  COMMENT 'user.phone_number - Primary phone number',
    full_name                     STRING                  COMMENT 'user.full_name - Full name',
    domain                        STRING                  COMMENT 'user.domain - Domain where user is defined',
    org                           STRING                  COMMENT 'user.org - Organization/unit',

    -- Arrays
    groups                        ARRAY<STRING>           COMMENT 'user.groups - Administrative groups',
    privileges                    ARRAY<STRING>           COMMENT 'user.privileges - Assigned privileges',

    -- Programmatic credentials (converted from Nested to JSON)
    programmatic_credentials      JSON                    COMMENT 'user.programmatic_credentials - API keys, access tokens, certificates',

    -- Risks (flattened from risk.json reference)
    risk_level                    VARCHAR(255)            COMMENT 'user.risks.risk_level - Risk level',
    risk_score                    INT                     COMMENT 'user.risks.risk_score - Overall risk score (0-100)',
    risk_confidence               FLOAT                   COMMENT 'user.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                   VARCHAR(255)            COMMENT 'user.risks.risk_domain - Primary risk domain',
    risk_assessed_at              DATETIME                COMMENT 'user.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by              STRING                  COMMENT 'user.risks.assessed_by - System that performed assessment',
    has_mfa                       BOOLEAN                 COMMENT 'user.has_mfa - Has MFA assigned',

    -- LDAP person fields (flattened)
    ldap_cost_center              STRING                  COMMENT 'user.ldap_person.cost_center',
    ldap_created_time             DATETIME                COMMENT 'user.ldap_person.created_time',
    ldap_deleted_time             DATETIME                COMMENT 'user.ldap_person.deleted_time',
    ldap_display_name             STRING                  COMMENT 'user.ldap_person.display_name',
    ldap_email_addrs              ARRAY<STRING>           COMMENT 'user.ldap_person.email_addrs',
    ldap_employee_uid             STRING                  COMMENT 'user.ldap_person.employee_uid',
    ldap_given_name               STRING                  COMMENT 'user.ldap_person.given_name',
    ldap_hire_time                DATETIME                COMMENT 'user.ldap_person.hire_time',
    ldap_job_title                STRING                  COMMENT 'user.ldap_person.job_title',
    ldap_labels                   ARRAY<STRING>           COMMENT 'user.ldap_person.labels',
    ldap_last_login_time          DATETIME                COMMENT 'user.ldap_person.last_login_time',
    ldap_cn                       STRING                  COMMENT 'user.ldap_person.ldap_cn',
    ldap_dn                       STRING                  COMMENT 'user.ldap_person.ldap_dn',
    ldap_leave_time               DATETIME                COMMENT 'user.ldap_person.leave_time',

    -- LDAP location (flattened)
    ldap_location_city            STRING                  COMMENT 'user.ldap_person.location.city',
    ldap_location_region          STRING                  COMMENT 'user.ldap_person.location.region',
    ldap_location_country         STRING                  COMMENT 'user.ldap_person.location.country',
    ldap_location_postal_code     STRING                  COMMENT 'user.ldap_person.location.postal_code',
    ldap_location_desc            STRING                  COMMENT 'user.ldap_person.location.desc',

    -- LDAP manager (flattened)
    ldap_manager_uid              STRING                  COMMENT 'user.ldap_person.manager.uid',
    ldap_manager_name             STRING                  COMMENT 'user.ldap_person.manager.name',

    ldap_modified_time            DATETIME                COMMENT 'user.ldap_person.modified_time',
    ldap_office_location          STRING                  COMMENT 'user.ldap_person.office_location',
    ldap_phone_number             STRING                  COMMENT 'user.ldap_person.phone_number',
    ldap_surname                  STRING                  COMMENT 'user.ldap_person.surname',

    -- LDAP tags (converted from Nested to JSON)
    ldap_tags                     JSON                    COMMENT 'user.ldap_person.tags',

    -- Netskope extension fields (flattened)
    source_service                ARRAY<STRING>           COMMENT 'user.x_netskope.source_service - Data ingestion sources',

    -- Source app (converted from Nested to JSON)
    source_app                    JSON                    COMMENT 'user.x_netskope.source_app - Applications data',

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

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Verify tables created:
SHOW TABLES;
