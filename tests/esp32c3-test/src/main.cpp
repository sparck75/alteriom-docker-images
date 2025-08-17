#include <Arduino.h>

// Simple ESP32-C3 test program
// This validates that the Docker images can successfully build ESP32-C3 firmware

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  
  // Initialize built-in LED (GPIO8 on ESP32-C3-DevKitM-1)
  pinMode(LED_BUILTIN, OUTPUT);
  
  Serial.println("ESP32-C3 Test Program Started");
  Serial.printf("ESP32-C3 Chip ID: %012llX\n", ESP.getEfuseMac());
  Serial.printf("ESP32-C3 Chip Model: %s\n", ESP.getChipModel());
  Serial.printf("ESP32-C3 Chip Revision: %d\n", ESP.getChipRevision());
  Serial.printf("ESP32-C3 CPU Frequency: %d MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("Free Heap: %d bytes\n", ESP.getFreeHeap());
  Serial.printf("Flash Size: %d bytes\n", ESP.getFlashChipSize());
}

void loop() {
  // Blink LED to show the program is running
  digitalWrite(LED_BUILTIN, HIGH);
  delay(500);
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
  
  Serial.println("ESP32-C3 is alive and blinking!");
}