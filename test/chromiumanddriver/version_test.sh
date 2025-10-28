#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Test version-specific functionality
echo "Testing Chromium version information..."

# Check that version commands work
check "chromium version output contains 'Chromium'" chromium --version | grep -i chromium
check "chromedriver version output contains version number" chromedriver --version | grep -E '[0-9]+\.[0-9]+\.[0-9]+'

# Test that both executables are the same major version (they should be compatible)
CHROMIUM_VERSION=$(chromium --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
CHROMEDRIVER_VERSION=$(chromedriver --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

echo "Chromium version: $CHROMIUM_VERSION"
echo "ChromeDriver version: $CHROMEDRIVER_VERSION"

# Extract major version numbers
CHROMIUM_MAJOR=$(echo "$CHROMIUM_VERSION" | cut -d. -f1)
CHROMEDRIVER_MAJOR=$(echo "$CHROMEDRIVER_VERSION" | cut -d. -f1)

check "chromium and chromedriver major versions match" test "$CHROMIUM_MAJOR" = "$CHROMEDRIVER_MAJOR"

# Test that the installation respects system architecture
check "chromium binary is executable" test -x "$(command -v chromium)"
check "chromedriver binary is executable" test -x "$(command -v chromedriver)"

# Verify package installation
check "chromium package is installed" dpkg -l | grep -q "^ii.*chromium "
check "chromium-driver package is installed" dpkg -l | grep -q "^ii.*chromium-driver "

# Report result
reportResults