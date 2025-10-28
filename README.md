# Dev Container Features

[![CI - Test Features](https://github.com/tonydail/devcontainer-features/actions/workflows/test.yaml/badge.svg)](https://github.com/tonydail/devcontainer-features/actions/workflows/test.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A collection of [Dev Container Features](https://containers.dev/features) for enhancing development environments with commonly needed tools and utilities.

## 🚀 Available Features

### Chromium and Driver (`chromiumanddriver`)

Installs Chromium browser and ChromeDriver for automated testing with flexible version support and D-Bus integration.

**Features:**
- 🌐 **Browser Automation**: Ready-to-use Chromium + ChromeDriver setup
- 🔧 **Version Control**: Install latest, stable, or specific versions
- 🚀 **Chrome Compatibility**: Creates `/usr/local/bin/chrome` symlink for compatibility
- 🐧 **Multi-Distribution**: Works on Debian-based containers
- 📡 **D-Bus Support**: Includes D-Bus daemon for advanced desktop integration
- 🧪 **Testing Ready**: Optimized for headless browser testing and automation

## 📖 Usage

### Basic Usage

Add to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/tonydail/devcontainer-features/chromiumanddriver:1": {}
  }
}