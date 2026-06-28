package outbox

import (
	"path/filepath"
	"testing"
	"time"
)

func TestAppendLoadAndMarkPublished(t *testing.T) {
	path := filepath.Join(t.TempDir(), "outbox.jsonl")
	event := Event{
		ID:            "evt-1",
		AggregateType: "order",
		AggregateID:   "order-1",
		Topic:         "orders.outbox",
		Key:           "order-1",
		Value:         `{"order_id":"order-1"}`,
		CreatedAt:     time.Date(2026, 7, 6, 0, 0, 0, 0, time.UTC),
	}

	if err := Append(path, event); err != nil {
		t.Fatal(err)
	}

	events, err := Load(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(events) != 1 {
		t.Fatalf("events length = %d", len(events))
	}
	if got := len(Pending(events)); got != 1 {
		t.Fatalf("pending length = %d", got)
	}

	publishedAt := time.Date(2026, 7, 6, 0, 1, 0, 0, time.UTC)
	if err := MarkPublished(path, "evt-1", publishedAt); err != nil {
		t.Fatal(err)
	}

	events, err = Load(path)
	if err != nil {
		t.Fatal(err)
	}
	if got := len(Pending(events)); got != 0 {
		t.Fatalf("pending length = %d", got)
	}
}
