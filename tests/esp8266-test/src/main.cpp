#include <Arduino.h>

// Simple ESP8266 test program
// This validates that the Docker images can successfully build ESP8266 firmware

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  
  // Initialize built-in LED
  pinMode(LED_BUILTIN, OUTPUT);
  
  Serial.println("ESP8266 Test Program Started");
  Serial.printf("ESP8266 Chip ID: %08X\n", ESP.getChipId());
  Serial.printf("ESP8266 CPU Frequency: %d MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("Free Heap: %d bytes\n", ESP.getFreeHeap());
  Serial.printf("Flash Chip Size: %d bytes\n", ESP.getFlashChipSize());
}

void loop() {
  // Blink LED to show the program is running (inverted logic for NodeMCU)
  digitalWrite(LED_BUILTIN, LOW);   // Turn LED on (LOW is on for NodeMCU)
  delay(750);
  digitalWrite(LED_BUILTIN, HIGH);  // Turn LED off (HIGH is off for NodeMCU)
  delay(750);
  
  Serial.println("ESP8266 is alive and blinking!");
}