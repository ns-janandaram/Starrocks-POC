-- ClickHouse table schema for device
-- Generated from schemas/device.json

CREATE TABLE IF NOT EXISTS devices
(
    -- Core device fields
    id                                       String                  COMMENT 'device.uid - Unique device identifier',
    name                                     String                  COMMENT 'device.name - Device name',
    hostname                                 String                  COMMENT 'device.hostname - Device hostname',
    type                                     LowCardinality(String)  COMMENT 'device.type - Device type name',

    -- Owner (flattened from governance.owner reference)
    owner_uid                                String                  COMMENT 'device.owner.uid - Owner unique identifier',
    owner_name                               String                  COMMENT 'device.owner.name - Owner name',
    owner_email                              String                  COMMENT 'device.owner.email - Owner email address',

    -- OS (flattened)
    os_name                                  LowCardinality(String)  COMMENT 'device.os.name - Operating system name',
    os_version                               String                  COMMENT 'device.os.version - OS version',
    os_type                                  LowCardinality(String)  COMMENT 'device.os.type - OS type',
    os_edition                               String                  COMMENT 'device.os.edition - OS edition',
    os_build                                 String                  COMMENT 'device.os.build - OS build number',

    -- Hardware info (flattened)
    hw_vendor_name                           String                  COMMENT 'device.hw_info.vendor_name - Device manufacturer',
    hw_serial_number                         String                  COMMENT 'device.hw_info.serial_number',
    hw_cpu_type                              String                  COMMENT 'device.hw_info.cpu_type',
    hw_cpu_count                             UInt32                  COMMENT 'device.hw_info.cpu_count',
    hw_ram_size                              UInt64                  COMMENT 'device.hw_info.ram_size',

    -- Hardware metrics - Hybrid approach (flattened simple metrics + Nested for arrays)
    hw_memory_total_kb                       UInt64                  COMMENT 'x_netskope.hardware_metrics.memory_total_kb',
    hw_memory_available_kb                   UInt64                  COMMENT 'x_netskope.hardware_metrics.memory_available_kb',
    hw_battery_level                         UInt8                   COMMENT 'x_netskope.hardware_metrics.battery_level',

    -- Processor metrics - using Nested for time-series data
    hw_processors                            Nested(
                                                 type String,
                                                 name String,
                                                 usage Array(UInt8),
                                                 interval UInt32
                                             )                       COMMENT 'x_netskope.hardware_metrics.processors',

    -- Disk metrics - using Nested for storage arrays
    hw_disks                                 Nested(
                                                 type String,
                                                 name String,
                                                 total_kb UInt64,
                                                 available_kb UInt64,
                                                 read_rate_kbps Array(Float32),
                                                 write_rate_kbps Array(Float32)
                                             )                       COMMENT 'x_netskope.hardware_metrics.disks',

    -- WiFi signal strength - using Nested
    hw_wifi_signals                          Nested(
                                                 name String,
                                                 ssid String,
                                                 strength Int32
                                             )                       COMMENT 'x_netskope.hardware_metrics.wifi_signal_strength',

    -- Network interfaces - using Nested
    network_interfaces                       Nested(
                                                 name String,
                                                 type String,
                                                 mac String,
                                                 ip String,
                                                 hostname String,
                                                 uid String
                                             )                       COMMENT 'device.network_interfaces',

    -- Network basic fields
    mac                                      String                  COMMENT 'device.mac - Primary MAC address',
    ip                                       String                  COMMENT 'device.ip - Primary IP address',

    -- Location (flattened)
    location_city                            String                  COMMENT 'device.location.city',
    location_region                          String                  COMMENT 'device.location.region',
    location_country                         String                  COMMENT 'device.location.country',
    location_continent                       String                  COMMENT 'device.location.continent',
    location_lat                             Float64                 COMMENT 'device.location.lat',
    location_long                            Float64                 COMMENT 'device.location.long',
    location_postal_code                     String                  COMMENT 'device.location.postal_code',
    location_desc                            String                  COMMENT 'device.location.desc',
    location_isp                             String                  COMMENT 'device.location.isp',

    -- Device status
    domain                                   String                  COMMENT 'device.domain',

    -- Risks (flattened from risk.json reference)
    risk_level                               LowCardinality(String)  COMMENT 'device.risks.risk_level',
    risk_score                               UInt32                  COMMENT 'device.risks.risk_score - Overall risk score (0-100)',
    risk_confidence                          Float32                 COMMENT 'device.risks.confidence - Confidence in risk assessment (0-1)',
    risk_domain                              LowCardinality(String)  COMMENT 'device.risks.risk_domain - Primary risk domain',
    risk_assessed_at                         DateTime64(3)           COMMENT 'device.risks.assessed_at - Risk assessment timestamp',
    risk_assessed_by                         String                  COMMENT 'device.risks.assessed_by - System that performed assessment',

    is_managed                               Bool                    COMMENT 'device.is_managed',
    is_personal                              Bool                    COMMENT 'device.is_personal',
    is_compliant                             Bool                    COMMENT 'device.is_compliant',
    is_trusted                               Bool                    COMMENT 'device.is_trusted',
    last_seen_time                           DateTime64(3)           COMMENT 'device.last_seen_time',
    tags                                     Array(String)           COMMENT 'device.tags',

    -- Netskope extension fields (flattened)
    tenant_id                                UInt32                  COMMENT 'x_netskope.tenant_id - Netskope tenant identifier',
    logged_time                              DateTime64(3)           COMMENT 'x_netskope.logged_time',
    nsdeviceuid                              String                  COMMENT 'x_netskope.nsdeviceuid',
    hwinfo_device_make                       String                  COMMENT 'x_netskope.hwinfo_extended.device_make',
    hwinfo_hardware_model                    String                  COMMENT 'x_netskope.hwinfo_extended.hardware_model',
    hwinfo_device_model                      String                  COMMENT 'x_netskope.hwinfo_extended.device_model',
    client_version                           String                  COMMENT 'x_netskope.client_version',
    client_install_time                      DateTime64(3)           COMMENT 'x_netskope.client_install_time',
    discovery_source                         LowCardinality(String)  COMMENT 'x_netskope.discovery_source',
    discovery_time                           DateTime64(3)           COMMENT 'x_netskope.discovery_time',
    runner_version                           String                  COMMENT 'x_netskope.runner_version',
    runner_type                              LowCardinality(String)  COMMENT 'x_netskope.runner_type',
    steering_config                          String                  COMMENT 'x_netskope.steering_config',

    -- Browser (flattened)
    browser_name                             LowCardinality(String)  COMMENT 'x_netskope.browser.name',
    browser_version                          UInt32                  COMMENT 'x_netskope.browser.version',
    browser_extension_id                     String                  COMMENT 'x_netskope.browser.extension_id',
    browser_extension_version                String                  COMMENT 'x_netskope.browser.extension_version',

    -- Network extended (flattened, selected fields)
    network_transport                        String                  COMMENT 'x_netskope.network_extended.transport',
    network_type                             String                  COMMENT 'x_netskope.network_extended.type',
    network_id                               String                  COMMENT 'x_netskope.network_extended.id',
    network_name                             String                  COMMENT 'x_netskope.network_extended.name',
    network_rssi                             Int32                   COMMENT 'x_netskope.network_extended.rssi',
    network_radio_quality                    Float32                 COMMENT 'x_netskope.network_extended.radio_quality',
    network_dns_servers_v4                   Array(String)           COMMENT 'x_netskope.network_extended.dns_servers_v4',
    network_dns_servers_v6                   Array(String)           COMMENT 'x_netskope.network_extended.dns_servers_v6',
    network_send_rate_kbps                   Array(Float32)          COMMENT 'x_netskope.network_extended.send_rate_kbps',
    network_recv_rate_kbps                   Array(Float32)          COMMENT 'x_netskope.network_extended.recv_rate_kbps',
    network_last_connected_private_ip        String                  COMMENT 'x_netskope.network_extended.last_connected_from_private_ip',
    network_last_connected_public_ip         String                  COMMENT 'x_netskope.network_extended.last_connected_from_public_ip',

    -- Location extended (flattened)
    location_site_id                         String                  COMMENT 'x_netskope.location_extended.site_id',
    location_gateway_id                      String                  COMMENT 'x_netskope.location_extended.gateway_id',
    location_pop                             String                  COMMENT 'x_netskope.location_extended.pop',
    location_organization                    String                  COMMENT 'x_netskope.location_extended.organization',
    location_asn                             String                  COMMENT 'x_netskope.location_extended.asn',
    location_domain                          String                  COMMENT 'x_netskope.location_extended.domain',

    -- On-premises detection - Hybrid approach (flattened primary fields + Nested for arrays)
    onprem_status                            LowCardinality(String)  COMMENT 'x_netskope.onprem_detection.status',
    onprem_method                            String                  COMMENT 'x_netskope.onprem_detection.method',
    onprem_domain                            String                  COMMENT 'x_netskope.onprem_detection.domain',
    onprem_config_ip                         String                  COMMENT 'x_netskope.onprem_detection.config_ip',
    onprem_match_ip                          String                  COMMENT 'x_netskope.onprem_detection.match_ip',

    -- On-prem labels - using Nested
    onprem_labels                            Nested(
                                                 id UInt32,
                                                 name String,
                                                 modified_by String,
                                                 client_config_id UInt32
                                             )                       COMMENT 'x_netskope.onprem_detection.labels',

    -- On-prem detection details - using Nested
    onprem_details                           Nested(
                                                 profile_name String,
                                                 status String,
                                                 method String,
                                                 domain String,
                                                 config_ip String,
                                                 match_ip String
                                             )                       COMMENT 'x_netskope.onprem_detection.details',

    -- Device classification (flattened)
    classification_status                    LowCardinality(String)  COMMENT 'x_netskope.device_classification.status',
    classification_status_code               UInt32                  COMMENT 'x_netskope.device_classification.status_code',
    classification_custom_status             String                  COMMENT 'x_netskope.device_classification.custom_status',
    classification_label                     String                  COMMENT 'x_netskope.device_classification.label',
    classification_label_id                  UInt32                  COMMENT 'x_netskope.device_classification.label_id',
    classification_label_priority            UInt32                  COMMENT 'x_netskope.device_classification.label_priority',
    classification_label_description         String                  COMMENT 'x_netskope.device_classification.label_description',

    -- Other Netskope fields
    npa_status                               UInt32                  COMMENT 'x_netskope.npa_status',
    orgkey                                   String                  COMMENT 'x_netskope.orgkey',
    status                                   UInt32                  COMMENT 'x_netskope.status',
    device_score                             Float64                 COMMENT 'x_netskope.device_score',
    management_id                            String                  COMMENT 'x_netskope.management_id',

    -- Special columns
    _insert_time                             DateTime64(3)           DEFAULT now64(3) COMMENT 'Record insert timestamp for versioning'
)
ENGINE = ReplacingMergeTree(_insert_time)
PARTITION BY tenant_id
ORDER BY (tenant_id, toDate(COALESCE(last_seen_time, _insert_time)), id)
COMMENT 'Device information table - OCSF compliant device data';
