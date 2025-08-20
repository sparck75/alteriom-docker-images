# ESP Platform Build Tests

This directory contains test projects to validate that the Docker images can successfully build firmware for ESP32, ESP32-S3, ESP32-C3, and ESP8266 platforms.

## Test Projects

### ESP32 Test (`esp32-test/`)
- **Platform**: espressif32
- **Board**: esp32dev
- **Framework**: Arduino
- **Environment**: esp32dev

Simple test program that initializes serial communication, displays chip information, and blinks the built-in LED.

### ESP32-S3 Test (`esp32s3-test/`)
- **Platform**: espressif32
- **Board**: esp32-s3-devkitc-1
- **Framework**: Arduino
- **Environment**: esp32-s3-devkitc-1

Test program specifically for ESP32-S3 with USB CDC support and PSRAM detection.

### ESP32-C3 Test (`esp32c3-test/`)
- **Platform**: espressif32
- **Board**: esp32-c3-devkitm-1
- **Framework**: Arduino
- **Environment**: esp32-c3-devkitm-1

Test program specifically for ESP32-C3 with USB CDC support and chip information display.

### ESP8266 Test (`esp8266-test/`)
- **Platform**: espressif8266
- **Board**: nodemcuv2
- **Framework**: Arduino
- **Environment**: nodemcuv2

Test program for ESP8266 with NodeMCU LED blinking (inverted logic).

## Running Tests

### Automated Testing
Use the test script to run all tests:

```bash
# Test with default images (builder:latest and dev:latest)
./scripts/test-esp-builds.sh

# Test with specific image
./scripts/test-esp-builds.sh ghcr.io/sparck75/alteriom-docker-images/builder:latest

# Test with multiple images
./scripts/test-esp-builds.sh builder:latest dev:latest
```

### Manual Testing
You can also test individual projects manually:

```bash
# ESP32 build
cd tests/esp32-test
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32dev

# ESP32-S3 build
cd tests/esp32s3-test
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32-s3-devkitc-1

# ESP32-C3 build
cd tests/esp32c3-test
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e esp32-c3-devkitm-1

# ESP8266 build
cd tests/esp8266-test
docker run --rm -v ${PWD}:/workspace ghcr.io/sparck75/alteriom-docker-images/builder:latest run -e nodemcuv2
```

## Test Validation

The tests validate:
1. **Docker Image Availability**: Images can be pulled and are accessible
2. **PlatformIO Functionality**: PlatformIO runs correctly in the container
3. **Platform Installation**: ESP platforms are properly installed or can be downloaded
4. **Compilation Success**: Firmware compiles successfully for each target platform
5. **Arduino Framework**: Arduino framework works with all tested platforms

## Expected Output

Successful tests will show:
- Platform downloads (first run may take longer)
- Successful compilation with memory usage statistics
- Generated firmware files (.bin, .elf)

Example successful output:
```
[INFO] Testing esp32 build with ghcr.io/sparck75/alteriom-docker-images/builder:latest
[INFO] Project: esp32-test, Environment: esp32dev
...
RAM:   [=         ]  12.4% (used 40644 bytes from 327680 bytes)
Flash: [===       ]  25.1% (used 328165 bytes from 1310720 bytes)
[SUCCESS] esp32 build completed successfully
```

## Integration with CI/CD

These tests are integrated into the GitHub Actions workflow and run automatically when:
- Docker images are built and published
- Pull requests are created or updated
- Manual workflow dispatch is triggered

The tests ensure that published Docker images are fully functional for ESP development.