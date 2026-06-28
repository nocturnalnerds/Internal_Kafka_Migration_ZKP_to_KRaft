package com.example.kafka.tx;

import com.example.kafka.ExampleConfig;
import java.time.Instant;
import java.util.Properties;
import java.util.UUID;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;

public final class TransactionalProducer {
  private TransactionalProducer() {}

  public static void main(String[] args) {
    ExampleConfig config = ExampleConfig.fromEnv();
    String transactionalId = config.transactionalIdPrefix() + "-producer-" + UUID.randomUUID();

    Properties props = new Properties();
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, config.bootstrapServers());
    props.put(ProducerConfig.CLIENT_ID_CONFIG, "java-transactional-producer");
    props.put(ProducerConfig.ACKS_CONFIG, "all");
    props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
    props.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, transactionalId);
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

    try (KafkaProducer<String, String> producer = new KafkaProducer<>(props)) {
      producer.initTransactions();
      producer.beginTransaction();
      producer.send(new ProducerRecord<>(
          config.outputTopic(),
          "transactional-order",
          "{\"event\":\"transactional-producer\",\"created_at\":\"" + Instant.now() + "\"}"
      ));
      producer.commitTransaction();
      System.out.printf("Committed transactional write to topic %s%n", config.outputTopic());
    }
  }
}

