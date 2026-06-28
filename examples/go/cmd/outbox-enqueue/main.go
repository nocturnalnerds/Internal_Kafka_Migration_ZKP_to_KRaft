package main

import (
	"fmt"
	"log"
	"time"

	"github.com/example/kafka-zk-kraft/examples/go/internal/appconfig"
	"github.com/example/kafka-zk-kraft/examples/go/internal/outbox"
)

func main() {
	cfg := appconfig.FromEnv()
	eventID := fmt.Sprintf("%s-%d", cfg.MessageKey, time.Now().UTC().UnixNano())
	event := outbox.Event{
		ID:            eventID,
		AggregateType: "order",
		AggregateID:   cfg.MessageKey,
		Topic:         "orders.outbox",
		Key:           cfg.MessageKey,
		Value:         cfg.MessageValue,
		CreatedAt:     time.Now().UTC(),
	}

	if err := outbox.Append(cfg.OutboxPath, event); err != nil {
		log.Fatalf("append outbox event: %v", err)
	}
	log.Printf("queued outbox event id=%s path=%s", event.ID, cfg.OutboxPath)
}
