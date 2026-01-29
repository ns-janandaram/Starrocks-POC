package filter

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestTenantFilter_IsAllowed(t *testing.T) {
	// Create temp whitelist file
	tmpDir := t.TempDir()
	whitelistPath := filepath.Join(tmpDir, "tenant-whitelist.txt")

	content := `# Allowed tenants
18988
12345
67890
`
	if err := os.WriteFile(whitelistPath, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}

	tf := NewTenantFilter(TenantFilterConfig{
		WhitelistPath:   whitelistPath,
		RefreshInterval: 1 * time.Second,
		Enabled:         true,
	})

	if err := tf.Start(); err != nil {
		t.Fatal(err)
	}
	defer tf.Stop()

	// Test allowed tenants
	if !tf.IsAllowed(18988) {
		t.Error("tenant 18988 should be allowed")
	}
	if !tf.IsAllowed(12345) {
		t.Error("tenant 12345 should be allowed")
	}

	// Test disallowed tenant
	if tf.IsAllowed(99999) {
		t.Error("tenant 99999 should not be allowed")
	}
}

func TestTenantFilter_Disabled(t *testing.T) {
	tf := NewTenantFilter(TenantFilterConfig{
		Enabled: false,
	})

	if err := tf.Start(); err != nil {
		t.Fatal(err)
	}
	defer tf.Stop()

	// All tenants should be allowed when disabled
	if !tf.IsAllowed(12345) {
		t.Error("all tenants should be allowed when filter is disabled")
	}
	if !tf.IsAllowed(99999) {
		t.Error("all tenants should be allowed when filter is disabled")
	}
}

func TestTenantFilter_Refresh(t *testing.T) {
	tmpDir := t.TempDir()
	whitelistPath := filepath.Join(tmpDir, "tenant-whitelist.txt")

	// Initial whitelist
	if err := os.WriteFile(whitelistPath, []byte("18988\n"), 0644); err != nil {
		t.Fatal(err)
	}

	tf := NewTenantFilter(TenantFilterConfig{
		WhitelistPath:   whitelistPath,
		RefreshInterval: 100 * time.Millisecond,
		Enabled:         true,
	})

	if err := tf.Start(); err != nil {
		t.Fatal(err)
	}
	defer tf.Stop()

	// Verify initial state
	if !tf.IsAllowed(18988) {
		t.Error("tenant 18988 should be allowed initially")
	}
	if tf.IsAllowed(12345) {
		t.Error("tenant 12345 should not be allowed initially")
	}

	// Update whitelist
	if err := os.WriteFile(whitelistPath, []byte("18988\n12345\n"), 0644); err != nil {
		t.Fatal(err)
	}

	// Wait for refresh
	time.Sleep(200 * time.Millisecond)

	// Verify updated state
	if !tf.IsAllowed(12345) {
		t.Error("tenant 12345 should be allowed after refresh")
	}
}

func TestTenantFilter_GetAllowedTenants(t *testing.T) {
	tmpDir := t.TempDir()
	whitelistPath := filepath.Join(tmpDir, "tenant-whitelist.txt")

	content := "18988\n12345\n67890\n"
	if err := os.WriteFile(whitelistPath, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}

	tf := NewTenantFilter(TenantFilterConfig{
		WhitelistPath:   whitelistPath,
		RefreshInterval: 1 * time.Second,
		Enabled:         true,
	})

	if err := tf.Start(); err != nil {
		t.Fatal(err)
	}
	defer tf.Stop()

	tenants := tf.GetAllowedTenants()
	if len(tenants) != 3 {
		t.Errorf("expected 3 tenants, got %d", len(tenants))
	}
}
