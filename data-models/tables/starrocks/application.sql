-- StarRocks table schema for application
-- Converted from ClickHouse schema

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
