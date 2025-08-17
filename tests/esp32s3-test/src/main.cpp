#include <Arduino.h>

// Simple ESP32-S3 test program
// This validates that the Docker images can successfully build ESP32-S3 firmware

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  
  // Initialize built-in LED
  pinMode(LED_BUILTIN, OUTPUT);
  
  Serial.println("ESP32-S3 Test Program Started");
  Serial.printf("ESP32-S3 Chip ID: %012llX\n", ESP.getEfuseMac());
  Serial.printf("ESP32-S3 Chip Model: %s\n", ESP.getChipModel());
  Serial.printf("ESP32-S3 Chip Revision: %d\n", ESP.getChipRevision());
  Serial.printf("ESP32-S3 CPU Frequency: %d MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("Free Heap: %d bytes\n", ESP.getFreeHeap());
  Serial.printf("PSRAM Size: %d bytes\n", ESP.getPsramSize());
}

void loop() {
  // Blink LED to show the program is running
  digitalWrite(LED_BUILTIN, HIGH);
  delay(500);
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
  
  Serial.println("ESP32-S3 is alive and blinking!");
}