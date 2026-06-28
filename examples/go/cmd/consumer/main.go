package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/IBM/sarama"
	"github.com/example/kafka-zk-kraft/examples/go/internal/appconfig"
)

type handler struct{}

func (handler) Setup(sarama.ConsumerGroupSession) error {
	return nil
}

func (handler) Cleanup(sarama.ConsumerGroupSession) error {
	return nil
}

func (handler) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for message := range claim.Messages() {
		log.Printf("consumed topic=%s partition=%d offset=%d key=%s value=%s",
			message.Topic,
			message.Partition,
			message.Offset,
			string(message.Key),
			string(message.Value),
		)
		session.MarkMessage(message, "")
	}
	return nil
}

func main() {
	cfg := appconfig.FromEnv()

	kafkaConfig := sarama.NewConfig()
	kafkaConfig.ClientID = cfg.ClientID + "-consumer"
	kafkaConfig.Consumer.Offsets.Initial = sarama.OffsetOldest
	kafkaConfig.Consumer.Group.Rebalance.GroupStrategies = []sarama.BalanceStrategy{
		sarama.NewBalanceStrategyRange(),
	}

	group, err := sarama.NewConsumerGroup(cfg.Brokers, cfg.GroupID, kafkaConfig)
	if err != nil {
		log.Fatalf("create consumer group: %v", err)
	}
	defer group.Close()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	for ctx.Err() == nil {
		if err := group.Consume(ctx, []string{cfg.Topic}, handler{}); err != nil {
			log.Printf("consume failed: %v", err)
		}
	}
}
