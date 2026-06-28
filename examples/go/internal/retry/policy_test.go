package retry

import (
	"testing"
	"time"
)

func TestDecideRetryTopic(t *testing.T) {
	now := time.Date(2026, 7, 6, 0, 0, 0, 0, time.UTC)
	policy := Policy{
		BaseTopic:   "orders",
		MaxAttempts: 2,
		Backoff:     5 * time.Second,
		Now:         func() time.Time { return now },
	}

	decision := policy.Decide(0)
	if decision.Topic != "orders.retry.0" {
		t.Fatalf("topic = %q", decision.Topic)
	}
	if decision.SendToDLQ {
		t.Fatal("expected retry decision")
	}
	if decision.AvailableAt != now.Add(5*time.Second) {
		t.Fatalf("available at = %s", decision.AvailableAt)
	}
}

func TestDecideDLQ(t *testing.T) {
	now := time.Date(2026, 7, 6, 0, 0, 0, 0, time.UTC)
	policy := Policy{
		BaseTopic:   "orders",
		MaxAttempts: 2,
		Backoff:     5 * time.Second,
		Now:         func() time.Time { return now },
	}

	decision := policy.Decide(2)
	if decision.Topic != "orders.dlq" {
		t.Fatalf("topic = %q", decision.Topic)
	}
	if !decision.SendToDLQ {
		t.Fatal("expected DLQ decision")
	}
}
