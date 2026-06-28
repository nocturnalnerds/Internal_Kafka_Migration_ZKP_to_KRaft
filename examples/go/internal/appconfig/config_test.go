package appconfig

import (
	"testing"
	"time"
)

func TestFromEnvDefaults(t *testing.T) {
	t.Setenv("KAFKA_BROKERS", "")
	t.Setenv("RETRY_BACKOFF", "")
	t.Setenv("RETRY_ATTEMPTS", "")

	cfg := FromEnv()
	if got, want := len(cfg.Brokers), 3; got != want {
		t.Fatalf("brokers length = %d, want %d", got, want)
	}
	if cfg.Topic != "orders" {
		t.Fatalf("topic = %q", cfg.Topic)
	}
	if cfg.RetryBackoff != 5*time.Second {
		t.Fatalf("retry backoff = %s", cfg.RetryBackoff)
	}
}

func TestFromEnvOverrides(t *testing.T) {
	t.Setenv("KAFKA_BROKERS", "a:9092,b:9092")
	t.Setenv("RETRY_BACKOFF", "2s")
	t.Setenv("RETRY_ATTEMPTS", "4")

	cfg := FromEnv()
	if got, want := len(cfg.Brokers), 2; got != want {
		t.Fatalf("brokers length = %d, want %d", got, want)
	}
	if cfg.RetryBackoff != 2*time.Second {
		t.Fatalf("retry backoff = %s", cfg.RetryBackoff)
	}
	if cfg.RetryAttempts != 4 {
		t.Fatalf("retry attempts = %d", cfg.RetryAttempts)
	}
}
