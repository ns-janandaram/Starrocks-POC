-- ClickHouse table schema for email
-- Generated from schemas/data/email.json

CREATE TABLE IF NOT EXISTS emails
(
    -- Core email fields
    id                                   String                  COMMENT 'email.uid - Unique email identifier',
    message_uid                          String                  COMMENT 'email.message_uid - Message unique identifier',
    from                                 String                  COMMENT 'email.from - Sender email address',
    to                                   Array(String)           COMMENT 'email.to - Recipient email addresses',

    -- Governance (flattened)
    gov_encryption_at_rest               Bool                    COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit            Bool                    COMMENT 'governance.encryption.in_transit',
    gov_encryption_algorithm             String                  COMMENT 'governance.encryption.algorithm',
    gov_owner_name                       String                  COMMENT 'governance.owner.name',
    gov_owner_uid                        String                  COMMENT 'governance.owner.uid',
    gov_owner_email                      String                  COMMENT 'governance.owner.email',

    -- Compliance (flattened)
    compliance_status                    LowCardinality(String)  COMMENT 'compliance.status',
    compliance_status_id                 UInt8                   COMMENT 'compliance.status_id',
    compliance_standards                 Array(String)           COMMENT 'compliance.standards',
    compliance_violations_total          UInt32                  COMMENT 'compliance.privacy_violations.total_violations',
    compliance_violations_pii_count      UInt32                  COMMENT 'compliance.privacy_violations.pii_count',
    compliance_violations_phi_count      UInt32                  COMMENT 'compliance.privacy_violations.phi_count',

    -- Risks (flattened from risk.json reference)
    risk_level                           LowCardinality(String)  COMMENT 'risks.risk_level',
    risk_score                           UInt32                  COMMENT 'risks.risk_score - Overall risk score (0-100)',
    risk_confidence                      Float32                 COMMENT 'risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                          LowCardinality(String)  COMMENT 'risks.risk_domain - Primary risk domain',
    risk_assessed_at                     DateTime64(3)           COMMENT 'risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                     String                  COMMENT 'risks.assessed_by - System that performed assessment',

    -- Netskope extension fields
    tenant_id                            UInt32                  COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    app                                  LowCardinality(String)  COMMENT 'x_netskope.app - Source application name',
    instance                             String                  COMMENT 'x_netskope.instance - Application instance',
    last_scanned                         DateTime64(3)           COMMENT 'x_netskope.last_scanned - Last DLP scan time',
    mailbox_owner                        String                  COMMENT 'x_netskope.mailbox_owner - Mailbox owner email',
    num_recipients                       UInt32                  COMMENT 'x_netskope.num_recipients - Total recipients',
    num_external_recipients              UInt32                  COMMENT 'x_netskope.num_external_recipients',
    folders                              Array(String)           COMMENT 'x_netskope.folders - Email folders/labels',
    exposure                             LowCardinality(String)  COMMENT 'x_netskope.exposure - Email exposure level',
    violations_in                        Array(String)           COMMENT 'x_netskope.violations_in - Policy violations',
    discovery_source                     LowCardinality(String)  COMMENT 'x_netskope.discovery_source',
    discovery_time                       DateTime64(3)           COMMENT 'x_netskope.discovery_time',
    app_category                         LowCardinality(String)  COMMENT 'x_netskope.app_category',
    app_suite                            LowCardinality(String)  COMMENT 'x_netskope.app_suite',

    -- Special columns
    _insert_time                         DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(discovery_time, _insert_time)), id)
COMMENT 'Email object table - OCSF email object representation';
