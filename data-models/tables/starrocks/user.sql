-- StarRocks table schema for user
-- Converted from ClickHouse schema

CREATE TABLE IF NOT EXISTS users
(
    -- Primary Key columns
    tenant_id                     INT                     COMMENT 'user.x_netskope.tenant_id - Netskope tenant identifier',
    id                            STRING                  COMMENT 'user.uid - Unique user identifier',

    -- Core user fields
    type                          VARCHAR(255)            COMMENT 'user.type - Type of user',
    name                          STRING                  COMMENT 'user.name - Username',
    display_name                  STRING                  COMMENT 'user.display_name - Display name',
    email_addr                    STRING                  COMMENT 'user.email_addr - Primary email address',
    phone_number                  STRING                  COMMENT 'user.phone_number - Primary phone number',
    full_name                     STRING                  COMMENT 'user.full_name - Full name',
    domain                        STRING                  COMMENT 'user.domain - Domain where user is defined',
    org                           STRING                  COMMENT 'user.org - Organization/unit',

    -- Arrays
    groups                        ARRAY<STRING>           COMMENT 'user.groups - Administrative groups',
    privileges                    ARRAY<STRING>           COMMENT 'user.privileges - Assigned privileges',

    -- Programmatic credentials (converted from Nested to JSON)
    programmatic_credentials      JSON                    COMMENT 'user.programmatic_credentials - API keys, access tokens, certificates',

    -- Risks (flattened from risk.json reference)
    risk_level                    VARCHAR(255)            COMMENT 'user.risks.risk_level - Risk level',
    risk_score                    INT                     COMMENT 'user.risks.risk_score - Overall risk score (0-100)',
    risk_confidence               FLOAT                   COMMENT 'user.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                   VARCHAR(255)            COMMENT 'user.risks.risk_domain - Primary risk domain',
    risk_assessed_at              DATETIME                COMMENT 'user.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by              STRING                  COMMENT 'user.risks.assessed_by - System that performed assessment',
    has_mfa                       BOOLEAN                 COMMENT 'user.has_mfa - Has MFA assigned',

    -- LDAP person fields (flattened)
    ldap_cost_center              STRING                  COMMENT 'user.ldap_person.cost_center',
    ldap_created_time             DATETIME                COMMENT 'user.ldap_person.created_time',
    ldap_deleted_time             DATETIME                COMMENT 'user.ldap_person.deleted_time',
    ldap_display_name             STRING                  COMMENT 'user.ldap_person.display_name',
    ldap_email_addrs              ARRAY<STRING>           COMMENT 'user.ldap_person.email_addrs',
    ldap_employee_uid             STRING                  COMMENT 'user.ldap_person.employee_uid',
    ldap_given_name               STRING                  COMMENT 'user.ldap_person.given_name',
    ldap_hire_time                DATETIME                COMMENT 'user.ldap_person.hire_time',
    ldap_job_title                STRING                  COMMENT 'user.ldap_person.job_title',
    ldap_labels                   ARRAY<STRING>           COMMENT 'user.ldap_person.labels',
    ldap_last_login_time          DATETIME                COMMENT 'user.ldap_person.last_login_time',
    ldap_cn                       STRING                  COMMENT 'user.ldap_person.ldap_cn',
    ldap_dn                       STRING                  COMMENT 'user.ldap_person.ldap_dn',
    ldap_leave_time               DATETIME                COMMENT 'user.ldap_person.leave_time',

    -- LDAP location (flattened)
    ldap_location_city            STRING                  COMMENT 'user.ldap_person.location.city',
    ldap_location_region          STRING                  COMMENT 'user.ldap_person.location.region',
    ldap_location_country         STRING                  COMMENT 'user.ldap_person.location.country',
    ldap_location_postal_code     STRING                  COMMENT 'user.ldap_person.location.postal_code',
    ldap_location_desc            STRING                  COMMENT 'user.ldap_person.location.desc',

    -- LDAP manager (flattened)
    ldap_manager_uid              STRING                  COMMENT 'user.ldap_person.manager.uid',
    ldap_manager_name             STRING                  COMMENT 'user.ldap_person.manager.name',

    ldap_modified_time            DATETIME                COMMENT 'user.ldap_person.modified_time',
    ldap_office_location          STRING                  COMMENT 'user.ldap_person.office_location',
    ldap_phone_number             STRING                  COMMENT 'user.ldap_person.phone_number',
    ldap_surname                  STRING                  COMMENT 'user.ldap_person.surname',

    -- LDAP tags (converted from Nested to JSON)
    ldap_tags                     JSON                    COMMENT 'user.ldap_person.tags',

    -- Netskope extension fields (flattened)
    source_service                ARRAY<STRING>           COMMENT 'user.x_netskope.source_service - Data ingestion sources',

    -- Source app (converted from Nested to JSON)
    source_app                    JSON                    COMMENT 'user.x_netskope.source_app - Applications data',

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
