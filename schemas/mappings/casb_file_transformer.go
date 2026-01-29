package transformer

import (
	"encoding/json"
	"strconv"
	"time"
)

// KafkaMessage represents the raw Kafka message for casb_file
type KafkaMessage struct {
	TsMs            int64  `json:"__ts_ms"`
	Deleted         string `json:"__deleted"`
	Op              string `json:"__op"`
	ID              string `json:"id"`
	CreatedAt       string `json:"created_at"`
	Modified        string `json:"modified"`
	Updated         string `json:"updated"`
	InventoryFields string `json:"inventory_fields"` // JSON string
	UnifiedData     string `json:"unified_data"`     // JSON string
}

// InventoryFields represents parsed inventory_fields JSON
type InventoryFields struct {
	AppCategory string `json:"app_category"`
	AppInstance string `json:"app_instance"`
	AppName     string `json:"app_name"`
	AppSuite    string `json:"app_suite"`
	NsTenantID  int    `json:"ns_tenant_id"`
}

// UnifiedData represents parsed unified_data JSON
type UnifiedData struct {
	ID                    string       `json:"id"`
	IDType                string       `json:"idType"`
	Name                  string       `json:"name"`
	MimeType              string       `json:"mimeType"`
	Created               string       `json:"created"`
	Modified              string       `json:"modified"`
	ParentID              string       `json:"parentId"`
	ParentType            string       `json:"parentType"`
	Path                  string       `json:"path"`
	Size                  string       `json:"size"` // String in source, convert to int
	ContentHash           string       `json:"contentHash"`
	URL                   string       `json:"url"`
	MetadataHash          string       `json:"metadataHash"`
	AccessInheritanceType string       `json:"accessInheritanceType"`
	IDs                   []string     `json:"ids"`
	Creator               UserRef      `json:"creator"`
	Owner                 UserRef      `json:"owner"`
	LastModifier          UserRef      `json:"lastModifier"`
	ExposureData          ExposureData `json:"exposureData"`
	Root                  RootRef      `json:"root"`
}

// UserRef represents a user reference
type UserRef struct {
	ID          string `json:"id"`
	Username    string `json:"username"`
	DisplayName string `json:"displayName"`
	Email       string `json:"email"`
}

// ExposureData represents exposure information
type ExposureData struct {
	RawExposure string `json:"rawExposure"` // Base64 encoded gzipped JSON
	UpdatedAt   string `json:"updatedAt"`
}

// RootRef represents the root file/folder reference
type RootRef struct {
	ID   string `json:"id"`
	Type string `json:"type"`
}

// CASBFileRecord represents the StarRocks target record
type CASBFileRecord struct {
	// Primary Key
	NsTenantID int    `json:"ns_tenant_id"`
	Instance   string `json:"instance"`
	App        string `json:"app"`
	ID         string `json:"id"`

	// Timestamps
	NsInsertionEpochTimestamp string `json:"ns_insertion_epoch_timestamp"`
	Created                   string `json:"created"`
	Timestamp                 string `json:"timestamp"`
	LastScanned               string `json:"last_scanned,omitempty"`
	NsUpdated                 string `json:"ns_updated"`
	NsCdcTimestamp            string `json:"ns_cdc_timestamp"`

	// Application metadata
	AppCategory string `json:"appcategory"`
	AppSuite    string `json:"appsuite"`

	// Classification fields
	ClassificationLabel               string   `json:"classification_label,omitempty"`
	ClassificationLabels              string   `json:"classification_labels,omitempty"`
	ClassificationObjectLabels        []string `json:"classification_object_labels"`
	ClassificationObjectValueIDs      []string `json:"classification_object_value_ids"`
	ClassificationObjectValueTexts    []string `json:"classification_object_value_texts"`
	ClassificationObjectVendorApps    []string `json:"classification_object_vendor_apps"`
	ClassificationObjectVendorInstances []string `json:"classification_object_vendor_instances"`
	ClassificationVendor              string   `json:"classification_vendor,omitempty"`

	// File metadata
	ContentHash       string `json:"content_hash"`
	MimeType          string `json:"mime_type"`
	ParentID          string `json:"parent_id"`
	ParentType        string `json:"parent_type"`
	URL               string `json:"url"`
	Path              string `json:"path"`
	Name              string `json:"name"`
	Size              int64  `json:"size"`
	Geo               string `json:"geo,omitempty"`
	Exposure          string `json:"exposure,omitempty"`
	MediaTypeCategory string `json:"media_type_category,omitempty"`

	// Owner information
	OwnerID          string `json:"owner_id"`
	OwnerEmail       string `json:"owner_email"`
	OwnerDisplayName string `json:"owner_display_name"`
	LastModifierID   string `json:"last_modifier_id"`
	LastModifierEmail string `json:"last_modifier_email"`

	// Content classification / DLP
	ContentClassificationDLPRule                  []string `json:"content_classification_dlp_rule"`
	ContentClassificationDLPHitCount              []int64  `json:"content_classification_dlp_hitCount"`
	ContentClassificationDLPSeverity              []string `json:"content_classification_dlp_severity"`
	ContentClassificationDLPProfiles              any      `json:"content_classification_dlp_profiles,omitempty"`
	ContentClassificationEntityDataTypes          any      `json:"content_classification_entity_data_types,omitempty"`
	ContentClassificationEntitySensitivityLevels  any      `json:"content_classification_entity_sensitivity_levels,omitempty"`
	ContentClassificationEntityCounts             any      `json:"content_classification_entity_counts,omitempty"`
	ContentClassificationStatus                   string   `json:"content_classification_status,omitempty"`
	ContentClassificationHash                     string   `json:"content_classification_hash,omitempty"`

	// File hierarchy
	FileRootID            string   `json:"file_root_id"`
	FileRootType          string   `json:"file_root_type"`
	AccessInheritanceType string   `json:"access_inheritance_type"`
	LegacyID              string   `json:"legacy_id,omitempty"`
	AccessSourcesID       []string `json:"access_sources_id"`
	AccessSourcesType     []string `json:"access_sources_type"`

	// Exemptions
	ExemptionPolicies []string `json:"exemption_policies"`
	ExemptionEnd      string   `json:"exemption_end,omitempty"`

	// Internal fields
	NsDeleted int `json:"ns_deleted"`
	NsMeta    int `json:"ns_meta"`
}

// CASBFileTransformer transforms Kafka messages to StarRocks records
type CASBFileTransformer struct{}

// NewCASBFileTransformer creates a new transformer
func NewCASBFileTransformer() *CASBFileTransformer {
	return &CASBFileTransformer{}
}

// Transform converts a Kafka message to a StarRocks record
func (t *CASBFileTransformer) Transform(data []byte) (*CASBFileRecord, error) {
	var msg KafkaMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, err
	}

	// Parse nested JSON fields
	var inventory InventoryFields
	if err := json.Unmarshal([]byte(msg.InventoryFields), &inventory); err != nil {
		return nil, err
	}

	var unified UnifiedData
	if err := json.Unmarshal([]byte(msg.UnifiedData), &unified); err != nil {
		return nil, err
	}

	// Convert timestamps
	cdcTimestamp := time.UnixMilli(msg.TsMs).UTC().Format("2006-01-02 15:04:05")

	// Parse size from string to int64
	size, _ := strconv.ParseInt(unified.Size, 10, 64)

	// Convert __deleted string to int
	nsDeleted := 0
	if msg.Deleted == "true" {
		nsDeleted = 1
	}

	// Extract legacy_id from ids array (second element if exists)
	legacyID := ""
	if len(unified.IDs) > 1 {
		legacyID = unified.IDs[1]
	}

	record := &CASBFileRecord{
		// Primary Key
		NsTenantID: inventory.NsTenantID,
		Instance:   inventory.AppInstance,
		App:        inventory.AppName,
		ID:         unified.ID, // Use unified_data.id instead of top-level id

		// Timestamps
		NsInsertionEpochTimestamp: cdcTimestamp,
		Created:                   formatTimestamp(unified.Created),
		Timestamp:                 formatTimestamp(msg.Modified),
		LastScanned:               formatTimestamp(unified.ExposureData.UpdatedAt),
		NsUpdated:                 formatTimestamp(msg.Updated),
		NsCdcTimestamp:            cdcTimestamp,

		// Application metadata
		AppCategory: inventory.AppCategory,
		AppSuite:    inventory.AppSuite,

		// Classification fields (empty arrays for nullable)
		ClassificationObjectLabels:          []string{},
		ClassificationObjectValueIDs:        []string{},
		ClassificationObjectValueTexts:      []string{},
		ClassificationObjectVendorApps:      []string{},
		ClassificationObjectVendorInstances: []string{},

		// File metadata
		ContentHash: unified.ContentHash,
		MimeType:    unified.MimeType,
		ParentID:    unified.ParentID,
		ParentType:  unified.ParentType,
		URL:         unified.URL,
		Path:        unified.Path,
		Name:        unified.Name,
		Size:        size,
		Exposure:    unified.ExposureData.RawExposure, // Store raw, decode in query if needed

		// Owner information
		OwnerID:           unified.Owner.ID,
		OwnerEmail:        unified.Owner.Email,
		OwnerDisplayName:  unified.Owner.DisplayName,
		LastModifierID:    unified.LastModifier.ID,
		LastModifierEmail: unified.LastModifier.Email,

		// Content classification / DLP (empty arrays for nullable)
		ContentClassificationDLPRule:     []string{},
		ContentClassificationDLPHitCount: []int64{},
		ContentClassificationDLPSeverity: []string{},
		ContentClassificationHash:        unified.MetadataHash,

		// File hierarchy
		FileRootID:            unified.Root.ID,
		FileRootType:          unified.Root.Type,
		AccessInheritanceType: unified.AccessInheritanceType,
		LegacyID:              legacyID,
		AccessSourcesID:       []string{},
		AccessSourcesType:     []string{},

		// Exemptions
		ExemptionPolicies: []string{},

		// Internal fields
		NsDeleted: nsDeleted,
		NsMeta:    0,
	}

	return record, nil
}

// TransformToJSON converts a Kafka message to JSON for Stream Load
func (t *CASBFileTransformer) TransformToJSON(data []byte) ([]byte, error) {
	record, err := t.Transform(data)
	if err != nil {
		return nil, err
	}
	return json.Marshal(record)
}

// formatTimestamp converts ISO8601 to StarRocks DATETIME format
func formatTimestamp(ts string) string {
	if ts == "" {
		return ""
	}

	// Try parsing various ISO8601 formats
	formats := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05.000Z",
	}

	for _, format := range formats {
		if t, err := time.Parse(format, ts); err == nil {
			return t.UTC().Format("2006-01-02 15:04:05")
		}
	}

	return ts // Return as-is if parsing fails
}
