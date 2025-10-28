#!/usr/bin/env bash
#
# Installs Chromium browser and ChromeDriver on Debian for automated testing
#

if [ -f install_common.sh ]; then
  source install_common.sh
else
  source "$(dirname "$0")/install_common.sh"
fi

# Installs Chromium and ChromeDriver
install_chromium() {
	local normalized_version
	normalized_version=$(normalize_version "$VERSION")
	log_info "Installing Chromium and ChromeDriver on Debian (version: $normalized_version)..."
	# Install base dependencies first
    apt-get install -y --no-install-recommends dbus dbus-x11
	dbus-uuidgen > /var/lib/dbus/machine-id

	if [[ "$normalized_version" == "latest" ]]; then
		log_info "Installing latest version of Chromium..."
		apt-get install -y --no-install-recommends chromium chromium-driver
	else
		log_info "Validating requested version: $normalized_version"
		if validate_version "$normalized_version"; then
			log_info "Installing Chromium version: $normalized_version"
			apt-get install -y --no-install-recommends \
				"chromium=${normalized_version}" \
				"chromium-driver=${normalized_version}"
		else
			log_error "Failed to install specific version. Falling back to latest..."
			apt-get install -y --no-install-recommends chromium chromium-driver
		fi
	fi
}



# Displays installed version information
show_version_info() {
	local chromium_version
	local driver_version

	if chromium_version=$(chromium --version 2>/dev/null); then
		log_info "Installed Chromium: $chromium_version"
	else
		log_warning "Could not determine Chromium version"
	fi

	if driver_version=$(chromedriver --version 2>/dev/null); then
		log_info "Installed ChromeDriver: $driver_version"
	else
		log_warning "Could not determine ChromeDriver version"
	fi
}


# Main installation flow
main() {
	local normalized_version
	normalized_version=$(normalize_version "$VERSION")

	log_info "Installing Chromium and ChromeDriver feature (version: $normalized_version)..."

	check_prerequisites
	setup_environment
	update_packages
	install_chromium
	setup_chrome_symlink
	show_version_info
	cleanup

	log_info "Installation completed successfully!"
}

 main "$@"
