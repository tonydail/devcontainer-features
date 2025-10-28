#!/usr/bin/env bash
#
# Installs Chromium browser and ChromeDriver for automated testing
#

set -euo pipefail

# Determine the operating system
# Read the OS ID from /etc/os-release
# Don't source it directly to avoid polluting the environment
if [ -f /etc/os-release ]; then
  ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
else
  echo "Cannot determine operating system. /etc/os-release not found."
  exit 1
fi

case "${ID,,}" in
  debian)
    echo "Detected Debian OS. Proceeding with Debian installation script."
    source "$(dirname "$0")/install_debian.sh"
    ;;
  *)
    echo "Unsupported operating system: $ID"
    exit 1
    ;;
esac