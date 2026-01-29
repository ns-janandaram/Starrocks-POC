-- ClickHouse table schema for privilege
-- Generated from schemas/identities/privilege.json

CREATE TABLE IF NOT EXISTS privileges
(
    -- Core privilege fields
    id                            String                  COMMENT 'privilege.uid - Unique privilege identifier',
    name                          String                  COMMENT 'privilege.name - Privilege name',
    type                          LowCardinality(String)  COMMENT 'privilege.type - Type of privilege',
    desc                          String                  COMMENT 'privilege.desc - Privilege description',

    -- Netskope extension fields (flattened)
    tenant_id                     UInt32                  COMMENT 'privilege.x_netskope.tenant_id - Netskope tenant identifier',
    source_service                LowCardinality(String)  COMMENT 'privilege.x_netskope.source_service - Source service',
    app                           LowCardinality(String)  COMMENT 'privilege.x_netskope.app - Application name',
    app_suite                     LowCardinality(String)  COMMENT 'privilege.x_netskope.app_suite - Application suite',
    app_category                  LowCardinality(String)  COMMENT 'privilege.x_netskope.app_category - Application category',
    instance_uid                  String                  COMMENT 'privilege.x_netskope.instance_uid - Instance identifier (alternate)',
    instance_id                   String                  COMMENT 'privilege.x_netskope.instance_id - Instance identifier',
    instance_name                 String                  COMMENT 'privilege.x_netskope.instance_name - Instance name',
    privilege_category            String                  COMMENT 'privilege.x_netskope.privilege_category',
    privilege_scope               String                  COMMENT 'privilege.x_netskope.privilege_scope',
    object_id                     String                  COMMENT 'privilege.x_netskope.object_id',
    object_type                   String                  COMMENT 'privilege.x_netskope.object_type',
    subject_id                    String                  COMMENT 'privilege.x_netskope.subject_id',
    subject_type                  String                  COMMENT 'privilege.x_netskope.subject_type',
    expiration                    DateTime64(3)           COMMENT 'privilege.x_netskope.expiration',
    is_admin_privilege            Bool                    COMMENT 'privilege.x_netskope.is_admin_privilege',
    created_time                  DateTime64(3)           COMMENT 'privilege.x_netskope.created_time',
    modified_time                 DateTime64(3)           COMMENT 'privilege.x_netskope.modified_time',
    is_deleted                    Bool                    COMMENT 'privilege.x_netskope.is_deleted',
    discovery_source              LowCardinality(String)  COMMENT 'privilege.x_netskope.discovery_source',
    discovery_time                DateTime64(3)           COMMENT 'privilege.x_netskope.discovery_time',

    -- Special columns
    _insert_time                  DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(created_time, _insert_time)), id)
COMMENT 'Privilege object table - OCSF 1.7.0 based privilege characteristics';
