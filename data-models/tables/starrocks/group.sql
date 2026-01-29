-- StarRocks table schema for group
-- Converted from ClickHouse schema

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
