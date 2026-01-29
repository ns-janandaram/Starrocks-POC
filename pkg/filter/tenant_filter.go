package filter

import (
	"bufio"
	"context"
	"log"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

// TenantFilter filters messages based on a whitelist of tenant IDs.
// The whitelist is refreshed periodically from a file (ConfigMap in K8s).
type TenantFilter struct {
	mu              sync.RWMutex
	allowedTenants  map[int]struct{}
	whitelistPath   string
	refreshInterval time.Duration
	lastModTime     time.Time
	enabled         bool
	ctx             context.Context
	cancel          context.CancelFunc
}

// TenantFilterConfig holds configuration for the tenant filter
type TenantFilterConfig struct {
	// WhitelistPath is the path to the tenant whitelist file
	// In K8s, this is typically mounted from a ConfigMap
	// e.g., /etc/config/tenant-whitelist.txt
	WhitelistPath string

	// RefreshInterval is how often to check for whitelist updates
	// Default: 2 minutes
	RefreshInterval time.Duration

	// Enabled controls whether filtering is active
	// If false, all tenants are allowed
	Enabled bool
}

// NewTenantFilter creates a new tenant filter
func NewTenantFilter(cfg TenantFilterConfig) *TenantFilter {
	if cfg.RefreshInterval == 0 {
		cfg.RefreshInterval = 2 * time.Minute
	}

	ctx, cancel := context.WithCancel(context.Background())

	tf := &TenantFilter{
		allowedTenants:  make(map[int]struct{}),
		whitelistPath:   cfg.WhitelistPath,
		refreshInterval: cfg.RefreshInterval,
		enabled:         cfg.Enabled,
		ctx:             ctx,
		cancel:          cancel,
	}

	return tf
}

// Start begins the background refresh loop
func (tf *TenantFilter) Start() error {
	if !tf.enabled {
		log.Println("Tenant filter is disabled, all tenants will be processed")
		return nil
	}

	// Initial load
	if err := tf.loadWhitelist(); err != nil {
		return err
	}

	// Start background refresh
	go tf.refreshLoop()

	log.Printf("Tenant filter started, refreshing every %v from %s", tf.refreshInterval, tf.whitelistPath)
	return nil
}

// Stop stops the background refresh loop
func (tf *TenantFilter) Stop() {
	tf.cancel()
}

// IsAllowed checks if a tenant ID is in the whitelist
func (tf *TenantFilter) IsAllowed(tenantID int) bool {
	if !tf.enabled {
		return true
	}

	tf.mu.RLock()
	defer tf.mu.RUnlock()

	_, allowed := tf.allowedTenants[tenantID]
	return allowed
}

// GetAllowedTenants returns a copy of the current allowed tenant IDs
func (tf *TenantFilter) GetAllowedTenants() []int {
	tf.mu.RLock()
	defer tf.mu.RUnlock()

	tenants := make([]int, 0, len(tf.allowedTenants))
	for id := range tf.allowedTenants {
		tenants = append(tenants, id)
	}
	return tenants
}

// refreshLoop periodically reloads the whitelist
func (tf *TenantFilter) refreshLoop() {
	ticker := time.NewTicker(tf.refreshInterval)
	defer ticker.Stop()

	for {
		select {
		case <-tf.ctx.Done():
			log.Println("Tenant filter refresh loop stopped")
			return
		case <-ticker.C:
			if err := tf.loadWhitelistIfChanged(); err != nil {
				log.Printf("Error refreshing tenant whitelist: %v", err)
			}
		}
	}
}

// loadWhitelistIfChanged reloads the whitelist only if the file has changed
func (tf *TenantFilter) loadWhitelistIfChanged() error {
	info, err := os.Stat(tf.whitelistPath)
	if err != nil {
		return err
	}

	if info.ModTime().After(tf.lastModTime) {
		return tf.loadWhitelist()
	}

	return nil
}

// loadWhitelist reads the whitelist file and updates the allowed tenants
func (tf *TenantFilter) loadWhitelist() error {
	file, err := os.Open(tf.whitelistPath)
	if err != nil {
		return err
	}
	defer file.Close()

	newAllowed := make(map[int]struct{})
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Skip empty lines and comments
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		tenantID, err := strconv.Atoi(line)
		if err != nil {
			log.Printf("Warning: invalid tenant ID in whitelist: %s", line)
			continue
		}

		newAllowed[tenantID] = struct{}{}
	}

	if err := scanner.Err(); err != nil {
		return err
	}

	// Update the whitelist atomically
	tf.mu.Lock()
	oldCount := len(tf.allowedTenants)
	tf.allowedTenants = newAllowed
	tf.lastModTime = time.Now()
	tf.mu.Unlock()

	log.Printf("Tenant whitelist reloaded: %d tenants (was %d)", len(newAllowed), oldCount)

	return nil
}

// Reload forces an immediate reload of the whitelist
func (tf *TenantFilter) Reload() error {
	return tf.loadWhitelist()
}
