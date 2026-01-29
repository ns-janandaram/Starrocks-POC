# Kafka to StarRocks Field Mappings

This directory contains field mapping configurations and transformer code for ingesting Kafka messages into StarRocks.

## casb_file Mapping

### Quick Reference

| StarRocks Column | Kafka Source Path | Transform |
|------------------|-------------------|-----------|
| **PRIMARY KEY** | | |
| `ns_tenant_id` | `inventory_fields.ns_tenant_id` | Parse JSON |
| `instance` | `inventory_fields.app_instance` | Parse JSON |
| `app` | `inventory_fields.app_name` | Parse JSON |
| `id` | `unified_data.id` | Parse JSON |
| **TIMESTAMPS** | | |
| `ns_insertion_epoch_timestamp` | `__ts_ms` | `ms -> datetime` |
| `created` | `unified_data.created` | ISO8601 -> datetime |
| `timestamp` | `modified` | ISO8601 -> datetime |
| `last_scanned` | `unified_data.exposureData.updatedAt` | ISO8601 -> datetime |
| `ns_updated` | `updated` | ISO8601 -> datetime |
| `ns_cdc_timestamp` | `__ts_ms` | `ms -> datetime` |
| **APP METADATA** | | |
| `appcategory` | `inventory_fields.app_category` | Parse JSON |
| `appsuite` | `inventory_fields.app_suite` | Parse JSON |
| **FILE METADATA** | | |
| `content_hash` | `unified_data.contentHash` | Parse JSON |
| `mime_type` | `unified_data.mimeType` | Parse JSON |
| `parent_id` | `unified_data.parentId` | Parse JSON |
| `parent_type` | `unified_data.parentType` | Parse JSON |
| `url` | `unified_data.url` | Parse JSON |
| `path` | `unified_data.path` | Parse JSON |
| `name` | `unified_data.name` | Parse JSON |
| `size` | `unified_data.size` | Parse JSON, string -> int |
| `exposure` | `unified_data.exposureData.rawExposure` | Base64 gzip (store raw) |
| **OWNER INFO** | | |
| `owner_id` | `unified_data.owner.id` | Parse JSON |
| `owner_email` | `unified_data.owner.email` | Parse JSON |
| `owner_display_name` | `unified_data.owner.displayName` | Parse JSON |
| `last_modifier_id` | `unified_data.lastModifier.id` | Parse JSON |
| `last_modifier_email` | `unified_data.lastModifier.email` | Parse JSON |
| **FILE HIERARCHY** | | |
| `file_root_id` | `unified_data.root.id` | Parse JSON |
| `file_root_type` | `unified_data.root.type` | Parse JSON |
| `access_inheritance_type` | `unified_data.accessInheritanceType` | Parse JSON |
| `legacy_id` | `unified_data.ids[1]` | Second element |
| **INTERNAL** | | |
| `ns_deleted` | `__deleted` | `"true"->1, "false"->0` |
| `ns_meta` | - | Default: 0 |

### Kafka Message Structure

```json
{
  "__ts_ms": 1769667332,           // Unix timestamp in milliseconds
  "__deleted": "false",            // String boolean
  "__op": "c",                     // Operation: c=create, u=update, d=delete
  "id": "iG7DDf/nKdhEv0HWk5AWtw==",
  "created_at": "2022-07-08T19:50:11Z",
  "modified": "2026-01-29T06:15:32Z",
  "updated": "2026-01-29T06:15:32Z",

  "inventory_fields": "{...}",     // JSON string - needs parsing
  "unified_data": "{...}"          // JSON string - needs parsing
}
```

### inventory_fields (JSON string)

```json
{
  "app_category": "Cloud Storage",
  "app_instance": "grupocomafi-my.sharepoint.com",
  "app_name": "Microsoft Office 365 OneDrive for Business",
  "app_suite": "Office365",
  "ns_tenant_id": 18988
}
```

### unified_data (JSON string)

```json
{
  "id": "iG7DDf/nKdhEv0HWk5AWtw==",
  "name": "hunter 11.08.LNK",
  "mimeType": "application/octet-stream",
  "created": "2022-07-08T19:50:11Z",
  "modified": "2011-08-11T21:59:38Z",
  "parentId": "KQ00keCV7ex68xu+TcQZeg==",
  "parentType": "netskope.kormorantpb.File",
  "path": "/personal/.../hunter 11.08.LNK",
  "size": "471",
  "contentHash": "RkrGh6u9RgwHr5bJ1TPB4jkM9+Q=",
  "url": "https://...",
  "metadataHash": "2978e1f9a03f55793e0c24a3f5d23b85",
  "accessInheritanceType": "ACCESS_INHERITANCE_TYPE_INHERITED",
  "ids": ["iG7DDf/nKdhEv0HWk5AWtw==", "E1txnVjLykCFJRgi+X7NlQ=="],

  "creator": {
    "id": "JITmMZfQDr33u61u16Zmjg==",
    "username": "user@example.com",
    "displayName": "User, Example",
    "email": "user@example.com"
  },
  "owner": { ... },
  "lastModifier": { ... },

  "exposureData": {
    "rawExposure": "H4sIAAAAAAAA/6pWcsnPTczMc84vzStRsqqu1VFyT81H4rlWFOQXlxalwoSUDJSsDGtrAQEAAP//azI/tTgAAAA=",
    "updatedAt": "2026-01-29T06:15:32.375692421Z"
  },

  "root": {
    "id": "cgUyV+3EjKShI82CdYH6uQ==",
    "type": "netskope.kormorantpb.File"
  }
}
```

## Files

| File | Description |
|------|-------------|
| `casb_file_mapping.yaml` | Declarative field mapping configuration |
| `casb_file_transformer.go` | Go implementation for Kafka consumer |

## Usage

### Go Transformer

```go
import "your-module/transformer"

func main() {
    t := transformer.NewCASBFileTransformer()

    // From Kafka consumer
    kafkaMessage := []byte(`{"__ts_ms":1769667332,...}`)

    // Transform to StarRocks record
    record, err := t.Transform(kafkaMessage)
    if err != nil {
        log.Fatal(err)
    }

    // Or get JSON for Stream Load
    jsonBytes, err := t.TransformToJSON(kafkaMessage)
    if err != nil {
        log.Fatal(err)
    }

    // Send to StarRocks via Stream Load
    // ...
}
```

### Stream Load Example

```bash
curl -X PUT \
  -H "Authorization: Basic $(echo -n 'root:' | base64)" \
  -H "Content-Type: application/json" \
  -H "format: json" \
  --data-binary @transformed_records.json \
  "http://starrocks-fe:8030/api/udspm_v1/casb_file/_stream_load"
```

## Nullable Fields

Fields not present in the sample message are mapped with defaults:

| Field | Default |
|-------|---------|
| `classification_*` | `null` or `[]` |
| `content_classification_*` | `null` or `[]` |
| `geo` | `null` |
| `media_type_category` | `null` |
| `exemption_*` | `null` or `[]` |
| `access_sources_*` | `[]` |

## Special Transformations

### Exposure Field

The `exposure` field contains base64-encoded gzipped JSON:

```go
// Option 1: Store raw (recommended for performance)
exposure := unified.ExposureData.RawExposure

// Option 2: Decode and parse
decoded, _ := base64.StdEncoding.DecodeString(rawExposure)
reader, _ := gzip.NewReader(bytes.NewReader(decoded))
decompressed, _ := io.ReadAll(reader)
var exposureObj map[string]interface{}
json.Unmarshal(decompressed, &exposureObj)
```

### Size Field

The `size` field comes as a string and needs integer conversion:

```go
size, _ := strconv.ParseInt(unified.Size, 10, 64)
```

### Deleted Flag

Convert string boolean to integer:

```go
nsDeleted := 0
if msg.Deleted == "true" {
    nsDeleted = 1
}
```
