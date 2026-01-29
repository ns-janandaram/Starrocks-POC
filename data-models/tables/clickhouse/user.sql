-- ClickHouse table schema for user
-- Generated from schemas/identities/user.json

CREATE TABLE IF NOT EXISTS users
(
    -- Core user fields
    id                            String                  COMMENT 'user.uid - Unique user identifier',
    type                          LowCardinality(String)  COMMENT 'user.type - Type of user',
    name                          String                  COMMENT 'user.name - Username',
    display_name                  String                  COMMENT 'user.display_name - Display name',
    email_addr                    String                  COMMENT 'user.email_addr - Primary email address',
    phone_number                  String                  COMMENT 'user.phone_number - Primary phone number',
    full_name                     String                  COMMENT 'user.full_name - Full name',
    domain                        String                  COMMENT 'user.domain - Domain where user is defined',
    org                           String                  COMMENT 'user.org - Organization/unit',

    -- Arrays
    groups                        Array(String)           COMMENT 'user.groups - Administrative groups',
    privileges                    Array(String)           COMMENT 'user.privileges - Assigned privileges',

    -- Programmatic credentials - using Nested
    programmatic_credentials      Nested(
                                      credential_type String,
                                      encrypted_value String
                                  )                       COMMENT 'user.programmatic_credentials - API keys, access tokens, certificates',

    -- Risks (flattened from risk.json reference)
    risk_level                    LowCardinality(String)  COMMENT 'user.risks.risk_level - Risk level',
    risk_score                    UInt32                  COMMENT 'user.risks.risk_score - Overall risk score (0-100)',
    risk_confidence               Float32                 COMMENT 'user.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                   LowCardinality(String)  COMMENT 'user.risks.risk_domain - Primary risk domain',
    risk_assessed_at              DateTime64(3)           COMMENT 'user.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by              String                  COMMENT 'user.risks.assessed_by - System that performed assessment',
    has_mfa                       Bool                    COMMENT 'user.has_mfa - Has MFA assigned',

    -- LDAP person fields (flattened)
    ldap_cost_center              String                  COMMENT 'user.ldap_person.cost_center',
    ldap_created_time             DateTime64(3)           COMMENT 'user.ldap_person.created_time',
    ldap_deleted_time             DateTime64(3)           COMMENT 'user.ldap_person.deleted_time',
    ldap_display_name             String                  COMMENT 'user.ldap_person.display_name',
    ldap_email_addrs              Array(String)           COMMENT 'user.ldap_person.email_addrs',
    ldap_employee_uid             String                  COMMENT 'user.ldap_person.employee_uid',
    ldap_given_name               String                  COMMENT 'user.ldap_person.given_name',
    ldap_hire_time                DateTime64(3)           COMMENT 'user.ldap_person.hire_time',
    ldap_job_title                String                  COMMENT 'user.ldap_person.job_title',
    ldap_labels                   Array(String)           COMMENT 'user.ldap_person.labels',
    ldap_last_login_time          DateTime64(3)           COMMENT 'user.ldap_person.last_login_time',
    ldap_cn                       String                  COMMENT 'user.ldap_person.ldap_cn',
    ldap_dn                       String                  COMMENT 'user.ldap_person.ldap_dn',
    ldap_leave_time               DateTime64(3)           COMMENT 'user.ldap_person.leave_time',

    -- LDAP location (flattened)
    ldap_location_city            String                  COMMENT 'user.ldap_person.location.city',
    ldap_location_region          String                  COMMENT 'user.ldap_person.location.region',
    ldap_location_country         String                  COMMENT 'user.ldap_person.location.country',
    ldap_location_postal_code     String                  COMMENT 'user.ldap_person.location.postal_code',
    ldap_location_desc            String                  COMMENT 'user.ldap_person.location.desc',

    -- LDAP manager (flattened)
    ldap_manager_uid              String                  COMMENT 'user.ldap_person.manager.uid',
    ldap_manager_name             String                  COMMENT 'user.ldap_person.manager.name',

    ldap_modified_time            DateTime64(3)           COMMENT 'user.ldap_person.modified_time',
    ldap_office_location          String                  COMMENT 'user.ldap_person.office_location',
    ldap_phone_number             String                  COMMENT 'user.ldap_person.phone_number',
    ldap_surname                  String                  COMMENT 'user.ldap_person.surname',

    -- LDAP tags - using Nested
    ldap_tags                     Nested(
                                      key String,
                                      value String
                                  )                       COMMENT 'user.ldap_person.tags',

    -- Netskope extension fields (flattened)
    tenant_id                     UInt32                  COMMENT 'user.x_netskope.tenant_id - Netskope tenant identifier',
    source_service                Array(String)           COMMENT 'user.x_netskope.source_service - Data ingestion sources',

    -- Source app nested structure - using Nested type
    source_app Nested(
        application_name String,
        instance_id      String,
        instance_name    String,
        status           Bool,
        exposure         Bool,
        is_admin         Bool,
        privilege_level  UInt32,
        is_sso_user      Bool,
        scopes           Array(String),
        last_login_time  DateTime64(3)
    )                                                     COMMENT 'user.x_netskope.source_app - Applications data',

    -- Special columns
    _insert_time                  DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(ldap_created_time, _insert_time)), id)
COMMENT 'User object table - OCSF 1.7.0 based user characteristics';
