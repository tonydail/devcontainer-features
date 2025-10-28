#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib


# Test basic installation
check "chromium executable exists" command -v chromium
check "chromedriver executable exists" command -v chromedriver
check "chrome symlink exists" test -L /usr/local/bin/chrome
check "chrome symlink points to chromium" test "$(readlink -f /usr/local/bin/chrome)" = "$(command -v chromium)"

# Test functionality
check "chromium version check" chromium --version
check "chromedriver version check" chromedriver --version

# Test browser launch (headless mode)
dbus-daemon --session --fork
check "chromium headless test" chromium --headless --disable-gpu --no-sandbox --dump-dom about:blank
check "chromium new headless test" chromium --headless=new --disable-gpu --no-sandbox --dump-dom about:blank
# # Test that dbus is installed (required dependency)
# check "dbus installed" dpkg -l | grep -q dbus

# Report result
reportResults
