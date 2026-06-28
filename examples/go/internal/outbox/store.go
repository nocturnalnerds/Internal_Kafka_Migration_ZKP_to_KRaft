package outbox

import (
	"bufio"
	"encoding/json"
	"errors"
	"os"
	"time"
)

type Event struct {
	ID            string     `json:"id"`
	AggregateType string     `json:"aggregate_type"`
	AggregateID   string     `json:"aggregate_id"`
	Topic         string     `json:"topic"`
	Key           string     `json:"key"`
	Value         string     `json:"value"`
	Attempts      int        `json:"attempts"`
	CreatedAt     time.Time  `json:"created_at"`
	PublishedAt   *time.Time `json:"published_at,omitempty"`
}

func Append(path string, event Event) error {
	if event.ID == "" {
		return errors.New("event id is required")
	}
	if event.Topic == "" {
		return errors.New("event topic is required")
	}
	if event.CreatedAt.IsZero() {
		event.CreatedAt = time.Now().UTC()
	}

	file, err := os.OpenFile(path, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	defer file.Close()

	encoded, err := json.Marshal(event)
	if err != nil {
		return err
	}
	if _, err := file.Write(append(encoded, '\n')); err != nil {
		return err
	}
	return nil
}

func Load(path string) ([]Event, error) {
	file, err := os.Open(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var events []Event
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		var event Event
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil {
			return nil, err
		}
		events = append(events, event)
	}
	return events, scanner.Err()
}

func MarkPublished(path string, id string, publishedAt time.Time) error {
	events, err := Load(path)
	if err != nil {
		return err
	}

	found := false
	for i := range events {
		if events[i].ID == id {
			events[i].PublishedAt = &publishedAt
			found = true
			break
		}
	}
	if !found {
		return errors.New("event not found")
	}

	tmpPath := path + ".tmp"
	file, err := os.OpenFile(tmpPath, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	writer := bufio.NewWriter(file)
	for _, event := range events {
		encoded, err := json.Marshal(event)
		if err != nil {
			file.Close()
			return err
		}
		if _, err := writer.Write(append(encoded, '\n')); err != nil {
			file.Close()
			return err
		}
	}
	if err := writer.Flush(); err != nil {
		file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	return os.Rename(tmpPath, path)
}

func Pending(events []Event) []Event {
	pending := make([]Event, 0, len(events))
	for _, event := range events {
		if event.PublishedAt == nil {
			pending = append(pending, event)
		}
	}
	return pending
}
