package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"kafka-starrocks-loader/pkg/consumer"
)

func main() {
	log.Println("Starting Kafka-StarRocks Loader...")

	// Parse configuration from environment
	cfg := consumer.Config{
		KafkaBrokers:          getEnv("KAFKA_BROKERS", "localhost:9092"),
		KafkaTopic:            getEnv("KAFKA_TOPIC", "file_phx"),
		KafkaGroupID:          getEnv("KAFKA_GROUP_ID", "starrocks-loader"),
		TenantFilterEnabled:   getEnvBool("TENANT_FILTER_ENABLED", true),
		TenantWhitelistPath:   getEnv("TENANT_WHITELIST_PATH", "/etc/config/tenant-whitelist.txt"),
		TenantRefreshInterval: getEnvDuration("TENANT_REFRESH_INTERVAL", 2*time.Minute),
		BatchSize:             getEnvInt("BATCH_SIZE", 5000),
		FlushInterval:         getEnvDuration("FLUSH_INTERVAL_MS", 1000*time.Millisecond),
	}

	// Create consumer
	c, err := consumer.NewConsumer(cfg)
	if err != nil {
		log.Fatalf("Failed to create consumer: %v", err)
	}

	// Start HTTP server for health checks
	go startHTTPServer(c)

	// Start consumer in background
	go func() {
		if err := c.Start(); err != nil {
			log.Printf("Consumer error: %v", err)
		}
	}()

	// Wait for shutdown signal
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	<-sigCh

	log.Println("Shutting down...")
	c.Stop()
	log.Println("Shutdown complete")
}

func startHTTPServer(c *consumer.Consumer) {
	mux := http.NewServeMux()

	// Health check endpoint
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Readiness check endpoint
	mux.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Ready"))
	})

	// Tenant list endpoint
	mux.HandleFunc("/tenants", func(w http.ResponseWriter, r *http.Request) {
		tenants := c.GetFilteredTenants()
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"allowed_tenants": tenants,
			"count":           len(tenants),
		})
	})

	// Reload tenants endpoint
	mux.HandleFunc("/reload-tenants", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		if err := c.ReloadTenantFilter(); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Tenant whitelist reloaded"))
	})

	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	log.Println("HTTP server listening on :8080")
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Printf("HTTP server error: %v", err)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		parsed, err := strconv.ParseBool(value)
		if err != nil {
			return defaultValue
		}
		return parsed
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		parsed, err := strconv.Atoi(value)
		if err != nil {
			return defaultValue
		}
		return parsed
	}
	return defaultValue
}

func getEnvDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		parsed, err := time.ParseDuration(value)
		if err != nil {
			return defaultValue
		}
		return parsed
	}
	return defaultValue
}
