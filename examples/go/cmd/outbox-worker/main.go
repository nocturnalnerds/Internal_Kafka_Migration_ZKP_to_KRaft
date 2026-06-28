package main

import (
	"log"
	"time"

	"github.com/IBM/sarama"
	"github.com/example/kafka-zk-kraft/examples/go/internal/appconfig"
	"github.com/example/kafka-zk-kraft/examples/go/internal/outbox"
)

func main() {
	cfg := appconfig.FromEnv()

	kafkaConfig := sarama.NewConfig()
	kafkaConfig.ClientID = cfg.ClientID + "-outbox-worker"
	kafkaConfig.Producer.RequiredAcks = sarama.WaitForAll
	kafkaConfig.Producer.Idempotent = true
	kafkaConfig.Producer.Return.Successes = true
	kafkaConfig.Producer.Retry.Max = 2147483647
	kafkaConfig.Net.MaxOpenRequests = 1

	producer, err := sarama.NewSyncProducer(cfg.Brokers, kafkaConfig)
	if err != nil {
		log.Fatalf("create producer: %v", err)
	}
	defer producer.Close()

	events, err := outbox.Load(cfg.OutboxPath)
	if err != nil {
		log.Fatalf("load outbox: %v", err)
	}

	pending := outbox.Pending(events)
	if len(pending) == 0 {
		log.Printf("no pending outbox events")
		return
	}

	for _, event := range pending {
		partition, offset, err := producer.SendMessage(&sarama.ProducerMessage{
			Topic: event.Topic,
			Key:   sarama.StringEncoder(event.Key),
			Value: sarama.StringEncoder(event.Value),
			Headers: []sarama.RecordHeader{
				{Key: []byte("event-id"), Value: []byte(event.ID)},
				{Key: []byte("aggregate-type"), Value: []byte(event.AggregateType)},
			},
		})
		if err != nil {
			log.Fatalf("publish outbox event %s: %v", event.ID, err)
		}
		if err := outbox.MarkPublished(cfg.OutboxPath, event.ID, time.Now().UTC()); err != nil {
			log.Fatalf("mark outbox event %s published: %v", event.ID, err)
		}
		log.Printf("published outbox event id=%s topic=%s partition=%d offset=%d", event.ID, event.Topic, partition, offset)
	}
}
