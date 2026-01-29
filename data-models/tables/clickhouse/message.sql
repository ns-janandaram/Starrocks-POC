-- ClickHouse table schema for message
-- Generated from schemas/data/message.json

CREATE TABLE IF NOT EXISTS messages
(
    -- Core message fields
    id                                   String                  COMMENT 'chat_message.uid - Unique message identifier',
    sender_id                            String                  COMMENT 'chat_message.sender_id - Message sender ID',
    sender_email                         String                  COMMENT 'chat_message.sender_email',
    conversation                         String                  COMMENT 'chat_message.conversation - Conversation name',
    conversation_id                      String                  COMMENT 'chat_message.conversation_id',
    num_attachments                      UInt32                  COMMENT 'chat_message.num_attachments',
    exposure                             LowCardinality(String)  COMMENT 'chat_message.exposure - Message exposure level',

    -- Compliance (flattened)
    compliance_status                    LowCardinality(String)  COMMENT 'compliance.status',
    compliance_status_id                 UInt8                   COMMENT 'compliance.status_id',
    compliance_standards                 Array(String)           COMMENT 'compliance.standards',
    compliance_matched_rules_count       UInt32                  COMMENT 'compliance.matched_rules_count',
    compliance_violations_total          UInt32                  COMMENT 'compliance.privacy_violations.total_violations',

    -- Governance (flattened)
    gov_encryption_at_rest               Bool                    COMMENT 'governance.encryption.at_rest',
    gov_encryption_in_transit            Bool                    COMMENT 'governance.encryption.in_transit',
    gov_owner_name                       String                  COMMENT 'governance.owner.name',
    gov_owner_email                      String                  COMMENT 'governance.owner.email',

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
    discovery_source                     LowCardinality(String)  COMMENT 'x_netskope.discovery_source',
    discovery_time                       DateTime64(3)           COMMENT 'x_netskope.discovery_time',
    app_category                         LowCardinality(String)  COMMENT 'x_netskope.app_category',
    app_suite                            String                  COMMENT 'x_netskope.app_suite',

    -- Special columns
    _insert_time                         DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(last_scanned, _insert_time)), id)
COMMENT 'Message object table - chat messages from collaboration apps';
