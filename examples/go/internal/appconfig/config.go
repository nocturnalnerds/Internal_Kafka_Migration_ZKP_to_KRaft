package appconfig

import (
	"os"
	"strconv"
	"strings"
	"time"
)

type KafkaConfig struct {
	Brokers       []string
	Topic         string
	GroupID       string
	ClientID      string
	MessageKey    string
	MessageValue  string
	OutboxPath    string
	RetryBackoff  time.Duration
	RetryAttempts int
}

func FromEnv() KafkaConfig {
	return KafkaConfig{
		Brokers:       csvEnv("KAFKA_BROKERS", "localhost:19092,localhost:19093,localhost:19094"),
		Topic:         env("KAFKA_TOPIC", "orders"),
		GroupID:       env("KAFKA_GROUP_ID", "orders-consumer"),
		ClientID:      env("KAFKA_CLIENT_ID", "go-example"),
		MessageKey:    env("KAFKA_MESSAGE_KEY", "order-1"),
		MessageValue:  env("KAFKA_MESSAGE_VALUE", `{"order_id":"order-1","status":"created"}`),
		OutboxPath:    env("OUTBOX_PATH", "outbox.jsonl"),
		RetryBackoff:  durationEnv("RETRY_BACKOFF", 5*time.Second),
		RetryAttempts: intEnv("RETRY_ATTEMPTS", 2),
	}
}

func env(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func csvEnv(key string, fallback string) []string {
	raw := env(key, fallback)
	parts := strings.Split(raw, ",")
	values := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			values = append(values, trimmed)
		}
	}
	return values
}

func intEnv(key string, fallback int) int {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return value
}

func durationEnv(key string, fallback time.Duration) time.Duration {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback
	}
	value, err := time.ParseDuration(raw)
	if err != nil {
		return fallback
	}
	return value
}
