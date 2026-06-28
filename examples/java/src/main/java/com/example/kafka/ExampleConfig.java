package com.example.kafka;

import java.time.Duration;
import java.util.List;

public record ExampleConfig(
    List<String> brokers,
    String inputTopic,
    String outputTopic,
    String groupId,
    String transactionalIdPrefix,
    Duration pollTimeout
) {
  public static ExampleConfig fromEnv() {
    return new ExampleConfig(
        split(env("KAFKA_BROKERS", "localhost:19092,localhost:19093,localhost:19094")),
        env("KAFKA_INPUT_TOPIC", "orders"),
        env("KAFKA_OUTPUT_TOPIC", "payments"),
        env("KAFKA_GROUP_ID", "orders-eos-processor"),
        env("KAFKA_TRANSACTIONAL_ID_PREFIX", "orders-eos"),
        Duration.ofMillis(Long.parseLong(env("KAFKA_POLL_TIMEOUT_MS", "1000")))
    );
  }

  private static String env(String key, String fallback) {
    String value = System.getenv(key);
    return value == null || value.isBlank() ? fallback : value;
  }

  private static List<String> split(String csv) {
    return List.of(csv.split(",")).stream().map(String::trim).filter(s -> !s.isEmpty()).toList();
  }

  public String bootstrapServers() {
    return String.join(",", brokers);
  }
}

