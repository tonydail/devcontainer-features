#!/usr/bin/env bash
#
# Installs Chromium browser and ChromeDriver for automated testing
#

set -euo pipefail

# Configuration
readonly VERSION="${VERSION:-"latest"}"
# Normalize version string
normalize_version() {
	local version="$1"
	case "${version,,}" in
	"stable" | "latest" | "")
		echo "latest"
		;;
	*)
		echo "$version"
		;;
	esac
}

# Logging functions
log_info() {
	echo "[INFO] $*" >&2
}

log_error() {
	echo "[ERROR] $*" >&2
}

log_warning() {
	echo "[WARNING] $*" >&2
}

# Creates or updates a symlink, handling existing files safely
ensure_symlink() {
	local -r source_file="$1"
	local -r target_symlink="$2"

	# Validate parameters
	if [[ -z "$source_file" || -z "$target_symlink" ]]; then
		log_error "ensure_symlink requires both source and target parameters"
		return 1
	fi

	if [[ ! -e "$source_file" ]]; then
		log_error "Source file does not exist: $source_file"
		return 1
	fi

	# Handle existing symlink
	if [[ -L "$target_symlink" ]]; then
		if [[ "$(readlink -f "$target_symlink")" == "$source_file" ]]; then
			log_info "Symlink already exists and is correct: $target_symlink"
			return 0
		fi
		log_info "Removing incorrect symlink: $target_symlink"
		rm -f "$target_symlink"
	elif [[ -e "$target_symlink" ]]; then
		# Backup existing file
		local -r backup_file="${target_symlink}.bak.$(date +%s)"
		log_warning "Backing up existing file: $target_symlink -> $backup_file"
		mv "$target_symlink" "$backup_file"
	fi

	# Create symlink
	ln -s "$source_file" "$target_symlink"
	log_info "Created symlink: $target_symlink -> $source_file"
}

# Validates environment and requirements
check_prerequisites() {
	if [[ "$EUID" -ne 0 ]]; then
		log_error "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile."
		exit 1
	fi
}

# Ensures login shells get the correct PATH
setup_environment() {
	log_info "Setting up environment PATH"
	rm -f /etc/profile.d/00-restore-env.sh
	echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" >/etc/profile.d/00-restore-env.sh
	chmod +x /etc/profile.d/00-restore-env.sh
}

# Updates package lists if needed
update_packages() {
	if [[ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" -eq 0 ]]; then
		log_info "Updating package lists..."
		apt-get update -y
	fi
}

# Gets available Chromium versions from apt
get_available_versions() {
	apt-cache madison chromium 2>/dev/null | awk '{print $3}' | head -10
}

# Validates if a specific version is available
validate_version() {
	local requested_version="$1"
	local available_versions

	if [[ "$requested_version" == "latest" ]]; then
		return 0
	fi

	available_versions=$(get_available_versions)
	if echo "$available_versions" | grep -q "^${requested_version}$"; then
		return 0
	else
		log_error "Version '$requested_version' not found in available versions:"
		echo "$available_versions" | head -5 | sed 's/^/  /' >&2
		return 1
	fi
}


# Finds Chromium executable path
find_chromium() {
	local chromium_path

	for cmd in chromium chromium-browser; do
		if chromium_path=$(command -v "$cmd" 2>/dev/null); then
			echo "$chromium_path"
			return 0
		fi
	done

	log_error "Chromium not found in PATH"
	return 1
}

# Creates chrome symlink for compatibility
setup_chrome_symlink() {
	local chromium_path
	if chromium_path=$(find_chromium); then
		log_info "Found Chromium at: $chromium_path"
		ensure_symlink "$chromium_path" "/usr/local/bin/chrome"
	else
		exit 1
	fi
}

# # Displays installed version information
# show_version_info() {
# 	local chromium_version
# 	local driver_version

# 	if chromium_version=$(chrome --version 2>/dev/null); then
# 		log_info "Installed Chromium: $chromium_version"
# 	else
# 		log_warning "Could not determine Chromium version"
# 	fi

# 	if driver_version=$(chromedriver --version 2>/dev/null); then
# 		log_info "Installed ChromeDriver: $driver_version"
# 	else
# 		log_warning "Could not determine ChromeDriver version"
# 	fi
# }

# Cleans up package cache
cleanup() {
	log_info "Cleaning up package cache..."
	rm -rf /var/lib/apt/lists/*
}

