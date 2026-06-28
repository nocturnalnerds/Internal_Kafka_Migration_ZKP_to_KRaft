package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/IBM/sarama"
	"github.com/example/kafka-zk-kraft/examples/go/internal/appconfig"
	retrypolicy "github.com/example/kafka-zk-kraft/examples/go/internal/retry"
)

type retryHandler struct {
	producer sarama.SyncProducer
	policy   retrypolicy.Policy
}

func (retryHandler) Setup(sarama.ConsumerGroupSession) error {
	return nil
}

func (retryHandler) Cleanup(sarama.ConsumerGroupSession) error {
	return nil
}

func (h retryHandler) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for message := range claim.Messages() {
		if err := process(message); err == nil {
			session.MarkMessage(message, "")
			continue
		}

		attempt := retryAttempt(message.Headers)
		decision := h.policy.Decide(attempt)
		headers := []sarama.RecordHeader{
			{Key: []byte("x-original-topic"), Value: []byte(message.Topic)},
			{Key: []byte("x-retry-attempt"), Value: []byte(strconv.Itoa(decision.Attempt))},
			{Key: []byte("x-available-at"), Value: []byte(decision.AvailableAt.Format(time.RFC3339Nano))},
		}

		_, _, err := h.producer.SendMessage(&sarama.ProducerMessage{
			Topic:   decision.Topic,
			Key:     sarama.ByteEncoder(message.Key),
			Value:   sarama.ByteEncoder(message.Value),
			Headers: headers,
		})
		if err != nil {
			return err
		}
		log.Printf("routed failed message offset=%d to topic=%s dlq=%t", message.Offset, decision.Topic, decision.SendToDLQ)
		session.MarkMessage(message, "")
	}
	return nil
}

func main() {
	cfg := appconfig.FromEnv()

	producerConfig := sarama.NewConfig()
	producerConfig.ClientID = cfg.ClientID + "-retry-producer"
	producerConfig.Producer.RequiredAcks = sarama.WaitForAll
	producerConfig.Producer.Idempotent = true
	producerConfig.Producer.Return.Successes = true
	producerConfig.Net.MaxOpenRequests = 1

	producer, err := sarama.NewSyncProducer(cfg.Brokers, producerConfig)
	if err != nil {
		log.Fatalf("create retry producer: %v", err)
	}
	defer producer.Close()

	consumerConfig := sarama.NewConfig()
	consumerConfig.ClientID = cfg.ClientID + "-retry-consumer"
	consumerConfig.Consumer.Offsets.Initial = sarama.OffsetOldest
	consumerConfig.Consumer.Group.Rebalance.GroupStrategies = []sarama.BalanceStrategy{
		sarama.NewBalanceStrategyRange(),
	}

	group, err := sarama.NewConsumerGroup(cfg.Brokers, cfg.GroupID, consumerConfig)
	if err != nil {
		log.Fatalf("create consumer group: %v", err)
	}
	defer group.Close()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	handler := retryHandler{
		producer: producer,
		policy: retrypolicy.Policy{
			BaseTopic:   cfg.Topic,
			MaxAttempts: cfg.RetryAttempts,
			Backoff:     cfg.RetryBackoff,
		},
	}
	topics := []string{cfg.Topic, cfg.Topic + ".retry.0", cfg.Topic + ".retry.1"}
	for ctx.Err() == nil {
		if err := group.Consume(ctx, topics, handler); err != nil {
			log.Printf("consume failed: %v", err)
		}
	}
}

func process(message *sarama.ConsumerMessage) error {
	if string(message.Value) == "fail" {
		return errRetryable
	}
	log.Printf("processed topic=%s partition=%d offset=%d", message.Topic, message.Partition, message.Offset)
	return nil
}

var errRetryable = retryableError("retryable failure requested by message payload")

type retryableError string

func (e retryableError) Error() string {
	return string(e)
}

func retryAttempt(headers []*sarama.RecordHeader) int {
	for _, header := range headers {
		if string(header.Key) != "x-retry-attempt" {
			continue
		}
		attempt, err := strconv.Atoi(string(header.Value))
		if err == nil {
			return attempt
		}
	}
	return 0
}
