package main

import (
	"log"

	"github.com/IBM/sarama"
	"github.com/example/kafka-zk-kraft/examples/go/internal/appconfig"
)

func main() {
	cfg := appconfig.FromEnv()

	kafkaConfig := sarama.NewConfig()
	kafkaConfig.ClientID = cfg.ClientID + "-idempotent"
	kafkaConfig.Producer.RequiredAcks = sarama.WaitForAll
	kafkaConfig.Producer.Idempotent = true
	kafkaConfig.Producer.Return.Successes = true
	kafkaConfig.Producer.Retry.Max = 2147483647
	kafkaConfig.Net.MaxOpenRequests = 1

	producer, err := sarama.NewSyncProducer(cfg.Brokers, kafkaConfig)
	if err != nil {
		log.Fatalf("create idempotent producer: %v", err)
	}
	defer producer.Close()

	partition, offset, err := producer.SendMessage(&sarama.ProducerMessage{
		Topic: cfg.Topic,
		Key:   sarama.StringEncoder(cfg.MessageKey),
		Value: sarama.StringEncoder(cfg.MessageValue),
	})
	if err != nil {
		log.Fatalf("send idempotent message: %v", err)
	}

	log.Printf("idempotent send topic=%s partition=%d offset=%d", cfg.Topic, partition, offset)
}
