#!/bin/bash

set -e

if [ -f /etc/os-release ]; then
  ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
else
  echo "Cannot determine operating system. /etc/os-release not found."
  exit 1
fi

case "${ID,,}" in
  debian)
    echo "Detected Debian OS. Proceeding with Debian installation script."
    source "$(dirname "$0")/test_with_debian.sh"
    ;;
  *)
    echo "Unsupported operating system: $ID"
    exit 1
    ;;
esac
