-- ClickHouse table schema for group
-- Generated from schemas/identities/group.json

CREATE TABLE IF NOT EXISTS groups
(
    -- Core group fields
    id                            String                  COMMENT 'group.uid - Unique group identifier',
    name                          String                  COMMENT 'group.name - Group name',
    type                          LowCardinality(String)  COMMENT 'group.type - Type of group',
    desc                          String                  COMMENT 'group.desc - Group description',
    domain                        String                  COMMENT 'group.domain - Domain where group is defined',

    -- Arrays
    privilege_ids                 Array(String)           COMMENT 'group.privilege_ids - Assigned privilege identifiers',

    -- Netskope extension fields (flattened)
    tenant_id                     UInt32                  COMMENT 'group.x_netskope.tenant_id - Netskope tenant identifier',
    source_service                LowCardinality(String)  COMMENT 'group.x_netskope.source_service - Source system',
    app                           LowCardinality(String)  COMMENT 'group.x_netskope.app - Application name',
    app_suite                     LowCardinality(String)  COMMENT 'group.x_netskope.app_suite - Application suite',
    app_category                  LowCardinality(String)  COMMENT 'group.x_netskope.app_category - Application category',
    instance_uid                  String                  COMMENT 'group.x_netskope.instance_uid - Instance identifier (alternate)',
    instance_id                   String                  COMMENT 'group.x_netskope.instance_id - Instance identifier',
    instance_name                 String                  COMMENT 'group.x_netskope.instance_name - Instance name',
    email                         String                  COMMENT 'group.x_netskope.email - Group email address',
    parent_group_id               String                  COMMENT 'group.x_netskope.parent_group_id - Parent group identifier',
    exposure                      LowCardinality(String)  COMMENT 'group.x_netskope.exposure - Exposure level',
    region                        String                  COMMENT 'group.x_netskope.region - Geographic region',
    member_count                  UInt32                  COMMENT 'group.x_netskope.member_count - Number of direct members',
    subgroup_count                UInt32                  COMMENT 'group.x_netskope.subgroup_count - Number of subgroups',
    created_time                  DateTime64(3)           COMMENT 'group.x_netskope.created_time',
    modified_time                 DateTime64(3)           COMMENT 'group.x_netskope.modified_time',
    last_activity_time            DateTime64(3)           COMMENT 'group.x_netskope.last_activity_time',
    is_deleted                    Bool                    COMMENT 'group.x_netskope.is_deleted',
    discovery_source              LowCardinality(String)  COMMENT 'group.x_netskope.discovery_source',
    discovery_time                DateTime64(3)           COMMENT 'group.x_netskope.discovery_time',

    -- Special columns
    _insert_time                  DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(created_time, _insert_time)), id)
COMMENT 'Group object table - OCSF 1.7.0 based group characteristics';
