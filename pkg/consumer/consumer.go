package consumer

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"github.com/segmentio/kafka-go"

	"kafka-starrocks-loader/pkg/filter"
)

// Config holds consumer configuration
type Config struct {
	// Kafka settings
	KafkaBrokers string
	KafkaTopic   string
	KafkaGroupID string

	// Tenant filter settings
	TenantFilterEnabled   bool
	TenantWhitelistPath   string
	TenantRefreshInterval time.Duration

	// Processing settings
	BatchSize     int
	FlushInterval time.Duration
}

// Consumer processes Kafka messages with tenant filtering
type Consumer struct {
	cfg          Config
	reader       *kafka.Reader
	tenantFilter *filter.TenantFilter
	ctx          context.Context
	cancel       context.CancelFunc
}

// MessageEnvelope represents the outer Kafka message structure
// Used to extract tenant_id before full parsing
type MessageEnvelope struct {
	InventoryFields string `json:"inventory_fields"`
}

// InventoryFields contains tenant identification
type InventoryFields struct {
	NsTenantID int `json:"ns_tenant_id"`
}

// NewConsumer creates a new consumer with tenant filtering
func NewConsumer(cfg Config) (*Consumer, error) {
	ctx, cancel := context.WithCancel(context.Background())

	// Initialize Kafka reader
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:        []string{cfg.KafkaBrokers},
		Topic:          cfg.KafkaTopic,
		GroupID:        cfg.KafkaGroupID,
		MinBytes:       1e6,  // 1MB
		MaxBytes:       10e6, // 10MB
		CommitInterval: time.Second,
	})

	// Initialize tenant filter
	tenantFilter := filter.NewTenantFilter(filter.TenantFilterConfig{
		WhitelistPath:   cfg.TenantWhitelistPath,
		RefreshInterval: cfg.TenantRefreshInterval,
		Enabled:         cfg.TenantFilterEnabled,
	})

	return &Consumer{
		cfg:          cfg,
		reader:       reader,
		tenantFilter: tenantFilter,
		ctx:          ctx,
		cancel:       cancel,
	}, nil
}

// Start begins consuming messages
func (c *Consumer) Start() error {
	// Start tenant filter
	if err := c.tenantFilter.Start(); err != nil {
		return err
	}

	log.Printf("Consumer started for topic %s", c.cfg.KafkaTopic)

	// Metrics
	var processed, filtered, errors int64

	for {
		select {
		case <-c.ctx.Done():
			log.Printf("Consumer stopped. Processed: %d, Filtered: %d, Errors: %d",
				processed, filtered, errors)
			return nil
		default:
			msg, err := c.reader.ReadMessage(c.ctx)
			if err != nil {
				if c.ctx.Err() != nil {
					return nil // Context cancelled
				}
				log.Printf("Error reading message: %v", err)
				errors++
				continue
			}

			// Extract tenant ID for filtering
			tenantID, err := c.extractTenantID(msg.Value)
			if err != nil {
				log.Printf("Error extracting tenant ID: %v", err)
				errors++
				continue
			}

			// Check if tenant is allowed
			if !c.tenantFilter.IsAllowed(tenantID) {
				filtered++
				if filtered%10000 == 0 {
					log.Printf("Filtered %d messages (tenant not in whitelist)", filtered)
				}
				continue
			}

			// Process the message
			if err := c.processMessage(msg.Value, tenantID); err != nil {
				log.Printf("Error processing message: %v", err)
				errors++
				continue
			}

			processed++
			if processed%10000 == 0 {
				log.Printf("Processed %d messages, filtered %d", processed, filtered)
			}
		}
	}
}

// Stop stops the consumer
func (c *Consumer) Stop() {
	c.cancel()
	c.tenantFilter.Stop()
	c.reader.Close()
}

// extractTenantID extracts the tenant ID from the message without full parsing
func (c *Consumer) extractTenantID(data []byte) (int, error) {
	var envelope MessageEnvelope
	if err := json.Unmarshal(data, &envelope); err != nil {
		return 0, err
	}

	var inv InventoryFields
	if err := json.Unmarshal([]byte(envelope.InventoryFields), &inv); err != nil {
		return 0, err
	}

	return inv.NsTenantID, nil
}

// processMessage handles a single message (implement your logic here)
func (c *Consumer) processMessage(data []byte, tenantID int) error {
	// TODO: Implement your transformation and loading logic
	// This is where you would:
	// 1. Transform the message using CASBFileTransformer
	// 2. Batch the records
	// 3. Send to StarRocks via Stream Load

	return nil
}

// GetFilteredTenants returns the current list of allowed tenants
func (c *Consumer) GetFilteredTenants() []int {
	return c.tenantFilter.GetAllowedTenants()
}

// ReloadTenantFilter forces a reload of the tenant whitelist
func (c *Consumer) ReloadTenantFilter() error {
	return c.tenantFilter.Reload()
}
