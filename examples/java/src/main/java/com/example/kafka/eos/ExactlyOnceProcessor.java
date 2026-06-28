package com.example.kafka.eos;

import com.example.kafka.ExampleConfig;
import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.OffsetAndMetadata;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;

public final class ExactlyOnceProcessor {
  private ExactlyOnceProcessor() {}

  public static void main(String[] args) {
    ExampleConfig config = ExampleConfig.fromEnv();
    String transactionalId = config.transactionalIdPrefix() + "-processor-" + UUID.randomUUID();

    try (
        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(consumerProps(config));
        KafkaProducer<String, String> producer = new KafkaProducer<>(producerProps(config, transactionalId))
    ) {
      producer.initTransactions();
      consumer.subscribe(List.of(config.inputTopic()));

      while (true) {
        ConsumerRecords<String, String> records = consumer.poll(config.pollTimeout());
        if (records.isEmpty()) {
          continue;
        }

        producer.beginTransaction();
        Map<TopicPartition, OffsetAndMetadata> offsets = new HashMap<>();

        for (ConsumerRecord<String, String> record : records) {
          String value = transform(record.value());
          producer.send(new ProducerRecord<>(config.outputTopic(), record.key(), value));
          offsets.put(
              new TopicPartition(record.topic(), record.partition()),
              new OffsetAndMetadata(record.offset() + 1)
          );
        }

        producer.sendOffsetsToTransaction(offsets, consumer.groupMetadata());
        producer.commitTransaction();
        System.out.printf("Committed %d record(s) and offsets transactionally%n", records.count());
      }
    }
  }

  public static String transform(String input) {
    return "{\"processed\":true,\"source\":" + quote(input) + "}";
  }

  private static String quote(String input) {
    return "\"" + input.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
  }

  private static Properties consumerProps(ExampleConfig config) {
    Properties props = new Properties();
    props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, config.bootstrapServers());
    props.put(ConsumerConfig.GROUP_ID_CONFIG, config.groupId());
    props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");
    props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
    props.put(ConsumerConfig.ISOLATION_LEVEL_CONFIG, "read_committed");
    props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
    props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
    return props;
  }

  private static Properties producerProps(ExampleConfig config, String transactionalId) {
    Properties props = new Properties();
    props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, config.bootstrapServers());
    props.put(ProducerConfig.CLIENT_ID_CONFIG, "java-eos-processor");
    props.put(ProducerConfig.ACKS_CONFIG, "all");
    props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");
    props.put(ProducerConfig.TRANSACTIONAL_ID_CONFIG, transactionalId);
    props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
    props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
    return props;
  }
}
