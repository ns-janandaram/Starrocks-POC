-- StarRocks table schema for device
-- Converted from ClickHouse schema

CREATE TABLE IF NOT EXISTS devices
(
    -- Primary Key columns
    tenant_id                                INT                     COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    id                                       STRING                  COMMENT 'device.uid - Unique device identifier',

    -- Core device fields
    name                                     STRING                  COMMENT 'device.name - Device name',
    hostname                                 STRING                  COMMENT 'device.hostname - Device hostname',
    type                                     VARCHAR(255)            COMMENT 'device.type - Device type name',

    -- Owner (flattened from governance.owner reference)
    owner_uid                                STRING                  COMMENT 'device.owner.uid - Owner unique identifier',
    owner_name                               STRING                  COMMENT 'device.owner.name - Owner name',
    owner_email                              STRING                  COMMENT 'device.owner.email - Owner email address',

    -- OS (flattened)
    os_name                                  VARCHAR(255)            COMMENT 'device.os.name - Operating system name',
    os_version                               STRING                  COMMENT 'device.os.version - OS version',
    os_type                                  VARCHAR(255)            COMMENT 'device.os.type - OS type',
    os_edition                               STRING                  COMMENT 'device.os.edition - OS edition',
    os_build                                 STRING                  COMMENT 'device.os.build - OS build number',

    -- Hardware info (flattened)
    hw_vendor_name                           STRING                  COMMENT 'device.hw_info.vendor_name - Device manufacturer',
    hw_serial_number                         STRING                  COMMENT 'device.hw_info.serial_number',
    hw_cpu_type                              STRING                  COMMENT 'device.hw_info.cpu_type',
    hw_cpu_count                             INT                     COMMENT 'device.hw_info.cpu_count',
    hw_ram_size                              BIGINT                  COMMENT 'device.hw_info.ram_size',

    -- Hardware metrics (flattened)
    hw_memory_total_kb                       BIGINT                  COMMENT 'x_netskope.hardware_metrics.memory_total_kb',
    hw_memory_available_kb                   BIGINT                  COMMENT 'x_netskope.hardware_metrics.memory_available_kb',
    hw_battery_level                         TINYINT                 COMMENT 'x_netskope.hardware_metrics.battery_level',

    -- Processor metrics (converted from Nested to JSON)
    hw_processors                            JSON                    COMMENT 'x_netskope.hardware_metrics.processors',

    -- Disk metrics (converted from Nested to JSON)
    hw_disks                                 JSON                    COMMENT 'x_netskope.hardware_metrics.disks',

    -- WiFi signal strength (converted from Nested to JSON)
    hw_wifi_signals                          JSON                    COMMENT 'x_netskope.hardware_metrics.wifi_signal_strength',

    -- Network interfaces (converted from Nested to JSON)
    network_interfaces                       JSON                    COMMENT 'device.network_interfaces',

    -- Network basic fields
    mac                                      STRING                  COMMENT 'device.mac - Primary MAC address',
    ip                                       STRING                  COMMENT 'device.ip - Primary IP address',

    -- Location (flattened)
    location_city                            STRING                  COMMENT 'device.location.city',
    location_region                          STRING                  COMMENT 'device.location.region',
    location_country                         STRING                  COMMENT 'device.location.country',
    location_continent                       STRING                  COMMENT 'device.location.continent',
    location_lat                             DOUBLE                  COMMENT 'device.location.lat',
    location_long                            DOUBLE                  COMMENT 'device.location.long',
    location_postal_code                     STRING                  COMMENT 'device.location.postal_code',
    location_desc                            STRING                  COMMENT 'device.location.desc',
    location_isp                             STRING                  COMMENT 'device.location.isp',

    -- Device status
    domain                                   STRING                  COMMENT 'device.domain',

    -- Risks (flattened from risk.json reference)
    risk_level                               VARCHAR(255)            COMMENT 'device.risks.risk_level',
    risk_score                               INT                     COMMENT 'device.risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          FLOAT                   COMMENT 'device.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              VARCHAR(255)            COMMENT 'device.risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DATETIME                COMMENT 'device.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         STRING                  COMMENT 'device.risks.assessed_by - System that performed assessment',

    is_managed                               BOOLEAN                 COMMENT 'device.is_managed',
    is_personal                              BOOLEAN                 COMMENT 'device.is_personal',
    is_compliant                             BOOLEAN                 COMMENT 'device.is_compliant',
    is_trusted                               BOOLEAN                 COMMENT 'device.is_trusted',
    last_seen_time                           DATETIME                COMMENT 'device.last_seen_time',
    tags                                     ARRAY<STRING>           COMMENT 'device.tags',

    -- Netskope extension fields (flattened)
    logged_time                              DATETIME                COMMENT 'x_netskope.logged_time',
    nsdeviceuid                              STRING                  COMMENT 'x_netskope.nsdeviceuid',
    hwinfo_device_make                       STRING                  COMMENT 'x_netskope.hwinfo_extended.device_make',
    hwinfo_hardware_model                    STRING                  COMMENT 'x_netskope.hwinfo_extended.hardware_model',
    hwinfo_device_model                      STRING                  COMMENT 'x_netskope.hwinfo_extended.device_model',
    client_version                           STRING                  COMMENT 'x_netskope.client_version',
    client_install_time                      DATETIME                COMMENT 'x_netskope.client_install_time',
    discovery_source                         VARCHAR(255)            COMMENT 'x_netskope.discovery_source',
    discovery_time                           DATETIME                COMMENT 'x_netskope.discovery_time',
    runner_version                           STRING                  COMMENT 'x_netskope.runner_version',
    runner_type                              VARCHAR(255)            COMMENT 'x_netskope.runner_type',
    steering_config                          STRING                  COMMENT 'x_netskope.steering_config',

    -- Browser (flattened)
    browser_name                             VARCHAR(255)            COMMENT 'x_netskope.browser.name',
    browser_version                          INT                     COMMENT 'x_netskope.browser.version',
    browser_extension_id                     STRING                  COMMENT 'x_netskope.browser.extension_id',
    browser_extension_version                STRING                  COMMENT 'x_netskope.browser.extension_version',

    -- Network extended (flattened)
    network_transport                        STRING                  COMMENT 'x_netskope.network_extended.transport',
    network_type                             STRING                  COMMENT 'x_netskope.network_extended.type',
    network_id                               STRING                  COMMENT 'x_netskope.network_extended.id',
    network_name                             STRING                  COMMENT 'x_netskope.network_extended.name',
    network_rssi                             INT                     COMMENT 'x_netskope.network_extended.rssi',
    network_radio_quality                    FLOAT                   COMMENT 'x_netskope.network_extended.radio_quality',
    network_dns_servers_v4                   ARRAY<STRING>           COMMENT 'x_netskope.network_extended.dns_servers_v4',
    network_dns_servers_v6                   ARRAY<STRING>           COMMENT 'x_netskope.network_extended.dns_servers_v6',
    network_send_rate_kbps                   ARRAY<FLOAT>            COMMENT 'x_netskope.network_extended.send_rate_kbps',
    network_recv_rate_kbps                   ARRAY<FLOAT>            COMMENT 'x_netskope.network_extended.recv_rate_kbps',
    network_last_connected_private_ip        STRING                  COMMENT 'x_netskope.network_extended.last_connected_from_private_ip',
    network_last_connected_public_ip         STRING                  COMMENT 'x_netskope.network_extended.last_connected_from_public_ip',

    -- Location extended (flattened)
    location_site_id                         STRING                  COMMENT 'x_netskope.location_extended.site_id',
    location_gateway_id                      STRING                  COMMENT 'x_netskope.location_extended.gateway_id',
    location_pop                             STRING                  COMMENT 'x_netskope.location_extended.pop',
    location_organization                    STRING                  COMMENT 'x_netskope.location_extended.organization',
    location_asn                             STRING                  COMMENT 'x_netskope.location_extended.asn',
    location_domain                          STRING                  COMMENT 'x_netskope.location_extended.domain',

    -- On-premises detection (flattened)
    onprem_status                            VARCHAR(255)            COMMENT 'x_netskope.onprem_detection.status',
    onprem_method                            STRING                  COMMENT 'x_netskope.onprem_detection.method',
    onprem_domain                            STRING                  COMMENT 'x_netskope.onprem_detection.domain',
    onprem_config_ip                         STRING                  COMMENT 'x_netskope.onprem_detection.config_ip',
    onprem_match_ip                          STRING                  COMMENT 'x_netskope.onprem_detection.match_ip',

    -- On-prem labels (converted from Nested to JSON)
    onprem_labels                            JSON                    COMMENT 'x_netskope.onprem_detection.labels',

    -- On-prem detection details (converted from Nested to JSON)
    onprem_details                           JSON                    COMMENT 'x_netskope.onprem_detection.details',

    -- Device classification (flattened)
    classification_status                    VARCHAR(255)            COMMENT 'x_netskope.device_classification.status',
    classification_status_code               INT                     COMMENT 'x_netskope.device_classification.status_code',
    classification_custom_status             STRING                  COMMENT 'x_netskope.device_classification.custom_status',
    classification_label                     STRING                  COMMENT 'x_netskope.device_classification.label',
    classification_label_id                  INT                     COMMENT 'x_netskope.device_classification.label_id',
    classification_label_priority            INT                     COMMENT 'x_netskope.device_classification.label_priority',
    classification_label_description         STRING                  COMMENT 'x_netskope.device_classification.label_description',

    -- Other Netskope fields
    npa_status                               INT                     COMMENT 'x_netskope.npa_status',
    orgkey                                   STRING                  COMMENT 'x_netskope.orgkey',
    status                                   INT                     COMMENT 'x_netskope.status',
    device_score                             DOUBLE                  COMMENT 'x_netskope.device_score',
    management_id                            STRING                  COMMENT 'x_netskope.management_id',

    -- Special columns
    _insert_time                             DATETIME                DEFAULT CURRENT_TIMESTAMP COMMENT 'Record insert timestamp for versioning'
)
PRIMARY KEY (tenant_id, id)
PARTITION BY (tenant_id)
DISTRIBUTED BY HASH(id) BUCKETS 16
PROPERTIES (
    "replication_num" = "1",
    "enable_persistent_index" = "true"
);
