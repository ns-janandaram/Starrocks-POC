-- ClickHouse table schema for database (data warehouse)
-- Generated from schemas/data/database.json

CREATE TABLE IF NOT EXISTS databases
(
    -- Core data warehouse fields
    id                                       String                  COMMENT 'data_warehouse.id - Unique identifier',
    name                                     String                  COMMENT 'data_warehouse.name - User-friendly name',

    -- Platform (flattened)
    platform_id                              UInt8                   COMMENT 'data_warehouse.platform.id',
    platform_name                            LowCardinality(String)  COMMENT 'data_warehouse.platform.name',
    platform_version                         String                  COMMENT 'data_warehouse.platform.version',

    -- Cloud provider (flattened)
    cloud_provider                           LowCardinality(String)  COMMENT 'data_warehouse.cloud_provider.provider',
    cloud_account_id                         String                  COMMENT 'data_warehouse.cloud_provider.account_id',
    cloud_account_name                       String                  COMMENT 'data_warehouse.cloud_provider.account_name',
    cloud_region                             String                  COMMENT 'data_warehouse.cloud_provider.region',

    -- Platform-specific configuration - Hybrid approach (flattened + JSON)
    -- Common fields across all platforms
    platform_config_database                 String                  COMMENT 'data_warehouse.platform_configuration.database',
    platform_config_schema                   String                  COMMENT 'data_warehouse.platform_configuration.schema',
    platform_config_hostname                 String                  COMMENT 'data_warehouse.platform_configuration.hostname',
    platform_config_port                     UInt32                  COMMENT 'data_warehouse.platform_configuration.port',

    -- Athena-specific fields
    platform_config_athena_s3_output         String                  COMMENT 'data_warehouse.platform_configuration.athena.s3_output_location',
    platform_config_athena_catalog           String                  COMMENT 'data_warehouse.platform_configuration.athena.catalog_name',
    platform_config_athena_workgroup         String                  COMMENT 'data_warehouse.platform_configuration.athena.workgroup',

    -- BigQuery-specific fields
    platform_config_bq_project_id            String                  COMMENT 'data_warehouse.platform_configuration.bigquery.project_id',
    platform_config_bq_dataset_id            String                  COMMENT 'data_warehouse.platform_configuration.bigquery.dataset_id',
    platform_config_bq_location              String                  COMMENT 'data_warehouse.platform_configuration.bigquery.location',

    -- Snowflake-specific fields
    platform_config_snowflake_account        String                  COMMENT 'data_warehouse.platform_configuration.snowflake.account',
    platform_config_snowflake_warehouse      String                  COMMENT 'data_warehouse.platform_configuration.snowflake.warehouse',
    platform_config_snowflake_role           String                  COMMENT 'data_warehouse.platform_configuration.snowflake.role',

    -- Redshift-specific fields
    platform_config_redshift_cluster         String                  COMMENT 'data_warehouse.platform_configuration.redshift.cluster_identifier',

    -- Databricks-specific fields
    platform_config_databricks_http_path     String                  COMMENT 'data_warehouse.platform_configuration.databricks.http_path',
    platform_config_databricks_catalog       String                  COMMENT 'data_warehouse.platform_configuration.databricks.catalog',

    -- MongoDB-specific fields
    platform_config_mongodb_auth_db          String                  COMMENT 'data_warehouse.platform_configuration.mongodb.auth_database',
    platform_config_mongodb_replica_set      String                  COMMENT 'data_warehouse.platform_configuration.mongodb.replica_set',

    -- SAP HANA-specific fields
    platform_config_sap_hana_database        String                  COMMENT 'data_warehouse.platform_configuration.sap_hana.database',
    platform_config_sap_hana_schema          String                  COMMENT 'data_warehouse.platform_configuration.sap_hana.schema',

    -- S3 Retrieval configuration (flattened)
    platform_config_s3_enabled               Bool                    COMMENT 'data_warehouse.platform_configuration.s3_retrieval.enabled',
    platform_config_s3_bucket_name           String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.bucket_name',
    platform_config_s3_prefix                String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.prefix',
    platform_config_s3_cloud_account         String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.cloud_account',
    platform_config_s3_csv_username_index    UInt32                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.username_index',
    platform_config_s3_csv_database_index    UInt32                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.database_index',
    platform_config_s3_csv_query_text_index  UInt32                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.query_text_index',
    platform_config_s3_csv_timestamp_index   UInt32                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.timestamp_index',
    platform_config_s3_csv_schema_index      UInt32                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.schema_index',
    platform_config_s3_csv_rowcount_index    UInt32                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.csv_config.rowcount_index',
    platform_config_s3_json_username_key     String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.username_key',
    platform_config_s3_json_database_key     String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.database_key',
    platform_config_s3_json_query_text_key   String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.query_text_key',
    platform_config_s3_json_timestamp_key    String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.timestamp_key',
    platform_config_s3_json_schema_key       String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.schema_key',
    platform_config_s3_json_rowcount_key     String                  COMMENT 'data_warehouse.platform_configuration.s3_retrieval.json_config.rowcount_key',

    -- Generic SQL configuration fields (flattened)
    platform_config_generic_database         String                  COMMENT 'data_warehouse.platform_configuration.generic_sql.database',
    platform_config_generic_schema           String                  COMMENT 'data_warehouse.platform_configuration.generic_sql.schema',
    platform_config_generic_connection_string String                 COMMENT 'data_warehouse.platform_configuration.generic_sql.connection_string',
    platform_config_generic_driver           String                  COMMENT 'data_warehouse.platform_configuration.generic_sql.driver',
    platform_config_generic_hostname         String                  COMMENT 'data_warehouse.platform_configuration.generic_sql.hostname',
    platform_config_generic_port             UInt32                  COMMENT 'data_warehouse.platform_configuration.generic_sql.port',
    platform_config_generic_protocol         String                  COMMENT 'data_warehouse.platform_configuration.generic_sql.protocol',

    -- Instance configuration (flattened)
    config_scan_enabled                      Bool                    COMMENT 'data_warehouse.configuration.instance.scan_enabled',
    config_scan_frequency                    LowCardinality(String)  COMMENT 'data_warehouse.configuration.instance.scan_frequency',
    config_scan_schedule_type                UInt8                   COMMENT 'data_warehouse.configuration.instance.scan_schedule_type',
    config_classification_enabled            Bool                    COMMENT 'data_warehouse.configuration.instance.classification_enabled',
    config_query_retrieval_enabled           Bool                    COMMENT 'data_warehouse.configuration.instance.query_retrieval_enabled',
    config_dml_retrieval_enabled             Bool                    COMMENT 'data_warehouse.configuration.instance.dml_retrieval_enabled',
    config_role_retrieval_enabled            Bool                    COMMENT 'data_warehouse.configuration.instance.role_retrieval_enabled',
    config_tag_import_enabled                Bool                    COMMENT 'data_warehouse.configuration.instance.tag_import_enabled',
    config_scan_all_databases                Bool                    COMMENT 'data_warehouse.configuration.instance.scan_all_databases',
    config_is_unstructured                   Bool                    COMMENT 'data_warehouse.configuration.instance.is_unstructured',
    config_skip_schema_initialization        Bool                    COMMENT 'data_warehouse.configuration.instance.skip_schema_initialization',
    config_is_snapshot_scan                  Bool                    COMMENT 'data_warehouse.configuration.instance.is_snapshot_scan',
    config_integration_panoptica_id          String                  COMMENT 'data_warehouse.configuration.instance.integration_ids.panoptica_integration_id',
    config_integration_cohesity_id           String                  COMMENT 'data_warehouse.configuration.instance.integration_ids.cohesity_integration_id',

    -- Security configuration (flattened)
    security_encryption_at_rest              Bool                    COMMENT 'data_warehouse.configuration.security.encryption.at_rest',
    security_encryption_in_transit           Bool                    COMMENT 'data_warehouse.configuration.security.encryption.in_transit',
    security_encryption_algorithm            String                  COMMENT 'data_warehouse.configuration.security.encryption.algorithm',
    security_encryption_key_mgmt             String                  COMMENT 'data_warehouse.configuration.security.encryption.key_management',
    security_auth_mfa_enabled                Bool                    COMMENT 'data_warehouse.configuration.security.authentication.mfa_enabled',
    security_auth_methods                    Array(String)           COMMENT 'data_warehouse.configuration.security.authentication.methods',
    security_auth_has_password               Bool                    COMMENT 'data_warehouse.configuration.security.authentication.has_password',
    security_auth_has_private_key            Bool                    COMMENT 'data_warehouse.configuration.security.authentication.has_private_key',
    security_network_public_access_blocked   Bool                    COMMENT 'data_warehouse.configuration.security.network.public_access_blocked',
    security_network_vpc_id                  String                  COMMENT 'data_warehouse.configuration.security.network.vpc_id',
    security_network_allowed_cidrs           Array(String)           COMMENT 'data_warehouse.configuration.security.network.allowed_cidrs',
    security_network_firewall_enabled        Bool                    COMMENT 'data_warehouse.configuration.security.network.firewall_enabled',
    security_audit_enabled                   Bool                    COMMENT 'data_warehouse.configuration.security.audit.enabled',
    security_audit_log_destination           String                  COMMENT 'data_warehouse.configuration.security.audit.log_destination',

    -- Hierarchy metrics (flattened)
    metrics_database_count                   UInt32                  COMMENT 'data_warehouse.metrics.hierarchy.database_count',
    metrics_schema_count                     UInt32                  COMMENT 'data_warehouse.metrics.hierarchy.schema_count',
    metrics_table_count                      UInt32                  COMMENT 'data_warehouse.metrics.hierarchy.table_count',
    metrics_column_count                     UInt32                  COMMENT 'data_warehouse.metrics.hierarchy.column_count',
    metrics_field_count                      UInt32                  COMMENT 'data_warehouse.metrics.hierarchy.field_count',
    metrics_total_row_count                  UInt64                  COMMENT 'data_warehouse.metrics.hierarchy.total_row_count',

    -- Sensitivity metrics (flattened)
    metrics_sensitive_column_count           UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.sensitive_column_count',
    metrics_sensitive_field_count            UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.sensitive_field_count',
    metrics_unreviewed_column_count          UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.unreviewed_column_count',
    metrics_unreviewed_field_count           UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.unreviewed_field_count',
    metrics_sensitive_data_type_count        UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.sensitive_data_type_count',
    metrics_sensitive_data_types             Array(String)           COMMENT 'data_warehouse.metrics.sensitivity.sensitive_data_types',
    metrics_sensitive_data_type_ids          Array(String)           COMMENT 'data_warehouse.metrics.sensitivity.sensitive_data_type_ids',
    metrics_sensitivity_score                UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_score',
    metrics_sensitivity_high_count           UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_levels.high_count',
    metrics_sensitivity_medium_count         UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_levels.medium_count',
    metrics_sensitivity_low_count            UInt32                  COMMENT 'data_warehouse.metrics.sensitivity.sensitivity_levels.low_count',

    -- Size metrics (flattened)
    metrics_total_size_bytes                 UInt64                  COMMENT 'data_warehouse.metrics.size.total_size_bytes',
    metrics_structured_size_bytes            UInt64                  COMMENT 'data_warehouse.metrics.size.structured_size_bytes',
    metrics_sensitive_data_size_bytes        UInt64                  COMMENT 'data_warehouse.metrics.size.sensitive_data_size_bytes',
    metrics_structured_sensitive_size_bytes  UInt64                  COMMENT 'data_warehouse.metrics.size.structured_sensitive_size_bytes',
    metrics_unstructured_size_bytes          UInt64                  COMMENT 'data_warehouse.metrics.size.unstructured_size_bytes',
    metrics_unstructured_sensitive_size_bytes UInt64                 COMMENT 'data_warehouse.metrics.size.unstructured_sensitive_size_bytes',

    -- Exposure metrics (flattened)
    metrics_exposure                         LowCardinality(String)  COMMENT 'data_warehouse.metrics.exposure.exposure',
    metrics_exposure_score                   UInt32                  COMMENT 'data_warehouse.metrics.exposure.exposure_score',
    metrics_publicly_accessible              Bool                    COMMENT 'data_warehouse.metrics.exposure.publicly_accessible',
    metrics_externally_shared                Bool                    COMMENT 'data_warehouse.metrics.exposure.externally_shared',
    metrics_users_with_access_count          UInt32                  COMMENT 'data_warehouse.metrics.exposure.users_with_access_count',
    metrics_privileged_users_count           UInt32                  COMMENT 'data_warehouse.metrics.exposure.privileged_users_count',
    metrics_external_users_count             UInt32                  COMMENT 'data_warehouse.metrics.exposure.external_users_count',

    -- Risk metrics (flattened)
    metrics_findings_critical                UInt32                  COMMENT 'data_warehouse.metrics.risk.findings_by_severity.critical',
    metrics_findings_high                    UInt32                  COMMENT 'data_warehouse.metrics.risk.findings_by_severity.high',
    metrics_findings_medium                  UInt32                  COMMENT 'data_warehouse.metrics.risk.findings_by_severity.medium',
    metrics_findings_low                     UInt32                  COMMENT 'data_warehouse.metrics.risk.findings_by_severity.low',

    -- Activity metrics (flattened)
    metrics_last_scan_time                   DateTime64(3)           COMMENT 'data_warehouse.metrics.activity.last_scan_time',
    metrics_last_scan_id                     String                  COMMENT 'data_warehouse.metrics.activity.last_scan_id',
    metrics_last_schema_sync_time            DateTime64(3)           COMMENT 'data_warehouse.metrics.activity.last_schema_sync_time',
    metrics_last_accessed_time               DateTime64(3)           COMMENT 'data_warehouse.metrics.activity.last_accessed_time',
    metrics_query_count                      UInt32                  COMMENT 'data_warehouse.metrics.activity.query_count',
    metrics_query_count_30d                  UInt32                  COMMENT 'data_warehouse.metrics.activity.query_count_30d',
    metrics_alert_count                      UInt32                  COMMENT 'data_warehouse.metrics.activity.alert_count',
    metrics_alert_count_30d                  UInt32                  COMMENT 'data_warehouse.metrics.activity.alert_count_30d',

    -- Stale data metrics (flattened for cost optimization queries)
    stale_data_size_bytes                    UInt64                  COMMENT 'data_warehouse.metrics.activity.stale_data.size_bytes',
    stale_data_period_days                   UInt32                  COMMENT 'data_warehouse.metrics.activity.stale_data.period_days',
    stale_data_time_unit                     LowCardinality(String)  COMMENT 'data_warehouse.metrics.activity.stale_data.time_unit',
    stale_data_last_accessed_by              String                  COMMENT 'data_warehouse.metrics.activity.stale_data.last_accessed_by',
    stale_data_last_accessed                 DateTime64(3)           COMMENT 'data_warehouse.metrics.activity.stale_data.last_accessed',
    stale_data_analysis_enabled              Bool                    COMMENT 'data_warehouse.metrics.activity.stale_data.analysis_enabled',
    stale_data_employee_id                   String                  COMMENT 'data_warehouse.metrics.activity.stale_data.employee_id',

    -- Tags and labels
    tags                                     Array(String)           COMMENT 'data_warehouse.tags',

    -- Metadata (flattened)
    metadata_content_hash                    String                  COMMENT 'metadata.content_hash - Hash for change detection',

    -- Governance (flattened)
    gov_encryption_at_rest                   Bool                    COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit                Bool                    COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm                 String                  COMMENT 'governance.encryption.algorithm',
    gov_encryption_key_mgmt                  String                  COMMENT 'governance.encryption.key_management',
    gov_owner_uid                            String                  COMMENT 'governance.owner.uid',
    gov_owner_name                           String                  COMMENT 'governance.owner.name',
    gov_owner_email                          String                  COMMENT 'governance.owner.email',
    gov_steward_uid                          String                  COMMENT 'governance.steward.uid',
    gov_steward_name                         String                  COMMENT 'governance.steward.name',
    gov_steward_email                        String                  COMMENT 'governance.steward.email',
    gov_classification_level                 LowCardinality(String)  COMMENT 'governance.classification.level',
    gov_classification_labels                Array(String)           COMMENT 'governance.classification.labels',
    gov_classification_classified_by         String                  COMMENT 'governance.classification.classified_by',
    gov_classification_classified_time       DateTime64(3)           COMMENT 'governance.classification.classified_time',
    gov_retention_policy_enabled             Bool                    COMMENT 'governance.retention.policy_enabled',
    gov_retention_policy_name                String                  COMMENT 'governance.retention.policy_name',
    gov_retention_period_days                UInt32                  COMMENT 'governance.retention.retention_period_days',
    gov_retention_delete_after               Bool                    COMMENT 'governance.retention.delete_after_retention',
    gov_retention_legal_hold                 Bool                    COMMENT 'governance.retention.legal_hold',
    gov_resiliency_versioning_enabled        Bool                    COMMENT 'governance.resiliency.versioning_enabled',
    gov_resiliency_lifecycle_enabled         Bool                    COMMENT 'governance.resiliency.lifecycle_policies_enabled',
    gov_resiliency_replication_enabled       Bool                    COMMENT 'governance.resiliency.replication_enabled',
    gov_resiliency_replication_within_region Bool                    COMMENT 'governance.resiliency.replication_within_region',
    gov_resiliency_backup_enabled            Bool                    COMMENT 'governance.resiliency.backup_enabled',
    gov_exposure                             LowCardinality(String)  COMMENT 'governance.exposure',

    -- Compliance (flattened)
    compliance_status                        LowCardinality(String)  COMMENT 'compliance.status',
    compliance_status_id                     UInt32                  COMMENT 'compliance.status_id',
    compliance_standards                     Array(String)           COMMENT 'compliance.standards',
    compliance_finding_ids                   Array(String)           COMMENT 'compliance.finding_ids',
    compliance_posture_tags                  Array(String)           COMMENT 'compliance.posture_tags',
    compliance_pv_total_violations           UInt32                  COMMENT 'compliance.privacy_violations.total_violations',
    compliance_pv_pii_count                  UInt32                  COMMENT 'compliance.privacy_violations.pii_count',
    compliance_pv_phi_count                  UInt32                  COMMENT 'compliance.privacy_violations.phi_count',
    compliance_pv_hipaa_count                UInt32                  COMMENT 'compliance.privacy_violations.hipaa_count',
    compliance_pv_ccpa_count                 UInt32                  COMMENT 'compliance.privacy_violations.ccpa_count',
    compliance_pv_pci_count                  UInt32                  COMMENT 'compliance.privacy_violations.pci_count',
    compliance_pv_nist_count                 UInt32                  COMMENT 'compliance.privacy_violations.nist_count',
    compliance_pv_gdpr_count                 UInt32                  COMMENT 'compliance.privacy_violations.gdpr_count',
    compliance_pv_large_data_export          Bool                    COMMENT 'compliance.privacy_violations.large_data_export',
    compliance_pv_sensitive_data_export      Bool                    COMMENT 'compliance.privacy_violations.sensitive_data_export',
    compliance_pv_sensitive_data_modified    Bool                    COMMENT 'compliance.privacy_violations.sensitive_data_modified',
    compliance_pv_sensitive_data_accessed    Bool                    COMMENT 'compliance.privacy_violations.sensitive_data_accessed',
    compliance_pv_sensitive_data_shared      Bool                    COMMENT 'compliance.privacy_violations.sensitive_data_shared',

    -- Risks (flattened from risk.json reference)
    risk_level                               LowCardinality(String)  COMMENT 'risks.risk_level',
    risk_score                               UInt32                  COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          Float32                 COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              LowCardinality(String)  COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DateTime64(3)           COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         String                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    tenant_id                                UInt32                  COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    app_id                                   String                  COMMENT 'x_netskope.app_id',
    app_name                                 LowCardinality(String)  COMMENT 'x_netskope.app_name',
    instance_id                              String                  COMMENT 'x_netskope.instance_id',
    instance_name                            String                  COMMENT 'x_netskope.instance_name',
    instance_creation_time                   DateTime64(3)           COMMENT 'x_netskope.instance_creation_time',

    -- Special columns
    _insert_time                             DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(metrics_last_scan_time, _insert_time)), id)
COMMENT 'Data warehouse table - structured data store representation';
