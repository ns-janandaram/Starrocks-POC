-- ClickHouse table schema for application
-- Generated from schemas/application.json

CREATE TABLE IF NOT EXISTS applications
(
    -- Core application fields
    id                            String                  COMMENT 'application.uid - Unique application identifier',
    name                          String                  COMMENT 'application.name - Application name',
    type                          LowCardinality(String)  COMMENT 'application.type - Category of application',
    labels                        Array(String)           COMMENT 'application.labels - Tags/labels',
    risk_level                    LowCardinality(String)  COMMENT 'application.risk_level - Risk level',
    risk_score                    UInt32                  COMMENT 'application.risk_score - Risk score',

    -- Owner (flattened from governance.owner reference)
    owner_uid                     String                  COMMENT 'application.owner.uid - Owner unique identifier',
    owner_name                    String                  COMMENT 'application.owner.name - Owner name',
    owner_email                   String                  COMMENT 'application.owner.email - Owner email address',

    -- Risks (flattened from risk.json reference)
    risk_confidence               Float32                 COMMENT 'application.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                   LowCardinality(String)  COMMENT 'application.risks.risk_domain - Primary risk domain',
    risk_assessed_at              DateTime64(3)           COMMENT 'application.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by              String                  COMMENT 'application.risks.assessed_by - System that performed assessment',

    -- Application data (flattened)
    app_management                LowCardinality(String)  COMMENT 'application.data.app_management',
    deployment                    LowCardinality(String)  COMMENT 'application.data.deployment',
    app_suite_id                  UInt32                  COMMENT 'application.data.app_suite.id',
    app_suite_name                LowCardinality(String)  COMMENT 'application.data.app_suite.name',
    app_suite_vendor              String                  COMMENT 'application.data.app_suite.vendor',
    vendor                        String                  COMMENT 'application.data.vendor',
    app_classification            LowCardinality(String)  COMMENT 'application.data.application_classification',

    -- Netskope extension fields (flattened)
    tenant_id                     UInt32                  COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    instance_uid                  String                  COMMENT 'x_netskope.instance.uid',
    instance_id                   String                  COMMENT 'x_netskope.instance.id',
    instance_name                 String                  COMMENT 'x_netskope.instance.name',
    instance_creation_time        DateTime64(3)           COMMENT 'x_netskope.instance.created_time',
    instance_enabled              Bool                    COMMENT 'x_netskope.instance.enabled',
    instance_authorized           Bool                    COMMENT 'x_netskope.instance.authorization.authorized',
    instance_grant_time           DateTime64(3)           COMMENT 'x_netskope.instance.authorization.grant_time',
    discovery_source              LowCardinality(String)  COMMENT 'x_netskope.discovery_source',
    discovery_time                DateTime64(3)           COMMENT 'x_netskope.discovery_time',

    -- Special columns
    _insert_time                  DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(instance_creation_time, _insert_time)), id)
COMMENT 'Application instance table - SaaS application instances';
