package com.example.kafka;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.example.kafka.eos.ExactlyOnceProcessor;
import org.junit.jupiter.api.Test;

class ExactlyOnceProcessorTest {
  @Test
  void transformEscapesInput() {
    assertEquals(
        "{\"processed\":true,\"source\":\"{\\\"id\\\":\\\"1\\\"}\"}",
        ExactlyOnceProcessor.transform("{\"id\":\"1\"}")
    );
  }
}

