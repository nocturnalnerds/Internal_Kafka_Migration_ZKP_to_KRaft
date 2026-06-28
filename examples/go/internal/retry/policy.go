package retry

import (
	"fmt"
	"time"
)

type Decision struct {
	Topic       string
	Attempt     int
	SendToDLQ   bool
	AvailableAt time.Time
}

type Policy struct {
	BaseTopic   string
	MaxAttempts int
	Backoff     time.Duration
	Now         func() time.Time
}

func (p Policy) Decide(currentAttempt int) Decision {
	now := p.now()
	nextAttempt := currentAttempt + 1
	if p.MaxAttempts < 0 {
		p.MaxAttempts = 0
	}
	if nextAttempt > p.MaxAttempts {
		return Decision{
			Topic:       p.BaseTopic + ".dlq",
			Attempt:     nextAttempt,
			SendToDLQ:   true,
			AvailableAt: now,
		}
	}

	return Decision{
		Topic:       fmt.Sprintf("%s.retry.%d", p.BaseTopic, currentAttempt),
		Attempt:     nextAttempt,
		SendToDLQ:   false,
		AvailableAt: now.Add(p.Backoff * time.Duration(nextAttempt)),
	}
}

func (p Policy) now() time.Time {
	if p.Now != nil {
		return p.Now()
	}
	return time.Now().UTC()
}
