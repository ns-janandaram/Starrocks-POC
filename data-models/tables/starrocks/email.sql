-- StarRocks table schema for email
-- Converted from ClickHouse schema

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
