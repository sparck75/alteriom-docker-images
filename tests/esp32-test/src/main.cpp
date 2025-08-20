#include <Arduino.h>

// Simple ESP32 test program
// This validates that the Docker images can successfully build ESP32 firmware

// Define LED pin for ESP32 (most ESP32 boards have LED on GPIO2)
#define LED_PIN 2

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  
  // Initialize LED pin
  pinMode(LED_PIN, OUTPUT);
  
  Serial.println("ESP32 Test Program Started");
  Serial.printf("ESP32 Chip ID: %012llX\n", ESP.getEfuseMac());
  Serial.printf("ESP32 Chip Model: %s\n", ESP.getChipModel());
  Serial.printf("ESP32 Chip Revision: %d\n", ESP.getChipRevision());
  Serial.printf("ESP32 CPU Frequency: %d MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("Free Heap: %d bytes\n", ESP.getFreeHeap());
}

void loop() {
  // Blink LED to show the program is running
  digitalWrite(LED_PIN, HIGH);
  delay(1000);
  digitalWrite(LED_PIN, LOW);
  delay(1000);
  
  Serial.println("ESP32 is alive and blinking!");
}