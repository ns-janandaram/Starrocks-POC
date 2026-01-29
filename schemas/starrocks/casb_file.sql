-- StarRocks table schema for casb_file
-- Converted from ClickHouse schema: ns_v2.casb_file_local
-- Database: udspm_v1
-- Kafka topic: file_phx

CREATE TABLE IF NOT EXISTS casb_file
(
    -- Primary Key columns (matching ClickHouse ORDER BY for UPSERT)
    ns_tenant_id                              INT                     COMMENT 'Tenant identifier',
    instance                                  VARCHAR(255)            COMMENT 'Application instance',
    app                                       VARCHAR(255)            COMMENT 'Application name',
    id                                        STRING                  COMMENT 'Unique file identifier',

    -- Timestamps
    ns_insertion_epoch_timestamp              DATETIME                COMMENT 'Record insertion timestamp',
    created                                   DATETIME                COMMENT 'File creation time',
    timestamp                                 DATETIME                COMMENT 'Event timestamp',
    last_scanned                              DATETIME                COMMENT 'Last DLP scan time',
    ns_updated                                DATETIME                COMMENT 'Last update time',
    ns_cdc_timestamp                          DATETIME                COMMENT 'CDC timestamp for versioning',

    -- Application metadata
    appcategory                               VARCHAR(255)            COMMENT 'Application category',
    appsuite                                  VARCHAR(255)            COMMENT 'Application suite',

    -- Classification fields
    classification_label                      STRING                  COMMENT 'Classification label',
    classification_labels                     STRING                  COMMENT 'Classification labels (JSON string)',
    classification_object_labels              ARRAY<STRING>           COMMENT 'Classification object labels',
    classification_object_value_ids           ARRAY<STRING>           COMMENT 'Classification object value IDs',
    classification_object_value_texts         ARRAY<STRING>           COMMENT 'Classification object value texts',
    classification_object_vendor_apps         ARRAY<STRING>           COMMENT 'Classification vendor apps',
    classification_object_vendor_instances    ARRAY<STRING>           COMMENT 'Classification vendor instances',
    classification_vendor                     STRING                  COMMENT 'Classification vendor',

    -- File metadata
    content_hash                              STRING                  COMMENT 'Content hash',
    mime_type                                 VARCHAR(255)            COMMENT 'MIME type',
    parent_id                                 STRING                  COMMENT 'Parent folder ID',
    parent_type                               VARCHAR(255)            COMMENT 'Parent type',
    url                                       STRING                  COMMENT 'File URL',
    path                                      STRING                  COMMENT 'File path',
    name                                      STRING                  COMMENT 'File name',
    size                                      BIGINT                  COMMENT 'File size in bytes',
    geo                                       STRING                  COMMENT 'Geographic location',
    exposure                                  VARCHAR(255)            COMMENT 'Exposure level',
    media_type_category                       STRING                  COMMENT 'Media type category',

    -- Owner information
    owner_id                                  STRING                  COMMENT 'Owner ID',
    owner_email                               STRING                  COMMENT 'Owner email',
    owner_display_name                        STRING                  COMMENT 'Owner display name',
    last_modifier_id                          STRING                  COMMENT 'Last modifier ID',
    last_modifier_email                       STRING                  COMMENT 'Last modifier email',

    -- Content classification / DLP
    content_classification_dlp_rule           ARRAY<STRING>           COMMENT 'DLP rules matched',
    content_classification_dlp_hitCount       ARRAY<BIGINT>           COMMENT 'DLP hit counts per rule',
    content_classification_dlp_severity       ARRAY<STRING>           COMMENT 'DLP severity per rule',
    content_classification_dlp_profiles       JSON                    COMMENT 'DLP profiles (nested array)',
    content_classification_entity_data_types  JSON                    COMMENT 'Entity data types (nested array)',
    content_classification_entity_sensitivity_levels JSON             COMMENT 'Entity sensitivity levels (nested array)',
    content_classification_entity_counts      JSON                    COMMENT 'Entity counts (nested array)',
    content_classification_status             STRING                  COMMENT 'Classification status',
    content_classification_hash               STRING                  COMMENT 'Classification hash',

    -- File hierarchy
    file_root_id                              STRING                  COMMENT 'Root file/folder ID',
    file_root_type                            STRING                  COMMENT 'Root type',
    access_inheritance_type                   STRING                  COMMENT 'Access inheritance type',
    legacy_id                                 STRING                  COMMENT 'Legacy identifier',
    access_sources_id                         ARRAY<STRING>           COMMENT 'Access source IDs',
    access_sources_type                       ARRAY<STRING>           COMMENT 'Access source types',

    -- Exemptions
    exemption_policies                        ARRAY<STRING>           COMMENT 'Exemption policy names',
    exemption_end                             DATETIME                COMMENT 'Exemption end time',

    -- Internal fields
    ns_deleted                                TINYINT                 COMMENT 'Soft delete flag (0=active, 1=deleted)',
    ns_meta                                   SMALLINT DEFAULT 0      COMMENT 'Metadata flags'
)
PRIMARY KEY (ns_tenant_id, instance, app, id)
PARTITION BY (ns_tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 32
ORDER BY (ns_tenant_id, instance, app, id)
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);

-- Optional: Create indexes for common query patterns
-- Note: StarRocks automatically creates indexes on PRIMARY KEY columns
-- Additional bitmap indexes can be added for low-cardinality filter columns:

-- CREATE INDEX idx_casb_file_exposure ON casb_file (exposure) USING BITMAP;
-- CREATE INDEX idx_casb_file_appcategory ON casb_file (appcategory) USING BITMAP;
-- CREATE INDEX idx_casb_file_mime_type ON casb_file (mime_type) USING BITMAP;
