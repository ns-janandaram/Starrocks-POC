-- StarRocks table schema for privilege
-- Converted from ClickHouse schema

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
