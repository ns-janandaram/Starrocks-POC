-- StarRocks table schema for database (data warehouse)
-- Converted from ClickHouse schema

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
