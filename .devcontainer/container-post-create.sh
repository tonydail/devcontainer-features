#!/bin/bash

# Bash strict mode for better error handling
set -euo pipefail

# ==============================================================================
# Container Post-Create Script - Common Components
# ==============================================================================
# This file is included at the beginning of container-post-create.sh in all containers.
# It contains commands that are common to all development containers.
#
# Dependencies: 
#   - Environment variables: SERVICE_NAME, HOME
#   - Directory structure: .devcontainer/ in workspace root
# ==============================================================================

# Configuration constants
SCRIPT_NAME="$(basename "$0")"
readonly DEVCONTAINER_DIR=".devcontainer"
readonly VSCODE_DIR=".vscode"
readonly BASH_ALIASES_FILE=".bash_aliases"
readonly VSCODE_SETTINGS_FILE="vsc_extension_workspace_settings.json"
readonly VSCODE_SETTINGS_LINK="settings.json"

# ==============================================================================
# Logging and utility functions
# ==============================================================================

# Log an informational message
log_info() {
    local message="$1"
    echo "[$SCRIPT_NAME] INFO: $message" >&2
}

# Log an error message  
log_error() {
    local message="$1"
    echo "[$SCRIPT_NAME] ERROR: $message" >&2
}

# Log a success message
log_success() {
    local message="$1"
    echo "[$SCRIPT_NAME] SUCCESS: $message" >&2
}

# Log a warning message
log_warning() {
    local message="$1"
    echo "[$SCRIPT_NAME] WARNING: $message" >&2
}


# ==============================================================================
# Validation functions
# ==============================================================================

# Check if running on supported OS
validate_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS version - /etc/os-release not found"
        return 1
    fi
    
    local os_id
    os_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
    
    case "$os_id" in
        ubuntu|debian)
            log_info "Detected supported OS: $os_id"
            return 0
            ;;
        *)
            log_error "Unsupported OS: $os_id (only Ubuntu/Debian supported)"
            return 1
            ;;
    esac
}

# Check if we have sudo access
validate_sudo_access() {
    if ! sudo -n true 2>/dev/null; then
        log_error "Sudo access is not available"
        return 1
    fi
    
    log_info "Sudo access confirmed"
    return 0
}

# Check if required commands are available
validate_dependencies() {
    local missing_commands=()
    local required_commands=("$@")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    log_info "All required dependencies found"
    return 0
}


# Validate that required environment variables are set
validate_environment_variables() {
    local missing_vars=()
	local required_env_vars=("$@")
    
    for var in "${required_env_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi

    if [[ -z "${HOME:-}" ]]; then
        missing_vars+=("HOME")
    fi
    
    log_info "Environment validation successful"
    return 0
}

verify_command_installation() {
	local command="$1"
	local name="$2"
	local message=
    log_info "Verifying command installation..."
    
	if [[ -z "$command" ]]; then
		log_error "verify_command_installation requires a command to check"
		return 1
	fi

    if [[ -z "$name" ]]; then
		message="$command"
	fi

    if command -v "$command" >/dev/null 2>&1; then
        local version
        version=$($command --version 2>/dev/null | head -n1 || echo "unknown")
        log_success "$message verification successful - $version"
    else
        log_error "$message verification failed - $command command not found"
        return 1
    fi
}

# Create a symlink safely with proper error handling	
# Args: source_file target_symlink
ensure_symlink() {
    local source_file="$1"
    local target_symlink="$2"
    
    # Validate input parameters
    if [[ -z "$source_file" || -z "$target_symlink" ]]; then
        log_error "ensure_symlink requires both source and target parameters"
        return 1
    fi
    
    # Check if source file exists
    if [[ ! -e "$source_file" ]]; then
        log_error "Source file does not exist: $source_file"
        return 1
    fi
    
    # Check if symlink already points to the correct target
    if [[ -L "$target_symlink" ]]; then
        local current_target
        current_target=$(readlink -f "$target_symlink")
        
        if [[ "$current_target" == "$source_file" ]]; then
            log_info "Symlink already correct: $target_symlink -> $source_file"
            return 0
        else
            log_info "Removing incorrect symlink: $target_symlink -> $current_target"
            rm -f "$target_symlink"
        fi
    elif [[ -e "$target_symlink" ]]; then
        # Target exists but is not a symlink - back it up
        local backup_file
        backup_file="${target_symlink}.bak.$(date +%s)"
        log_info "Backing up existing file: $target_symlink -> $backup_file"
        mv "$target_symlink" "$backup_file"
    fi
    
    # Create the symlink
    if sudo ln -s "$source_file" "$target_symlink"; then
        log_success "Created symlink: $target_symlink -> $source_file"
        return 0
    else
        log_error "Failed to create symlink: $target_symlink -> $source_file"
        return 1
    fi
}

update_package_lists() {
    log_info "Updating package lists..."
    
    if sudo apt-get update -y >/dev/null 2>&1; then
        log_success "Package lists updated successfully"
    else
        log_error "Failed to update package lists"
        return 1
    fi
}

# Install required packages for MongoDB repository setup
install_packages() {
    local packages=("$@") # Accept packages as parameters

	if [[ ${#packages[@]} -eq 0 ]]; then
		log_error "No packages specified for installation"
		return 1
	fi

	log_info "Installing packages: ${packages[*]}"
    sudo apt-get install -y "${packages[@]}"
    
    if [ $? -eq 0 ]; then
        log_success "Packages installed successfully"
    else
        log_error "Failed to install packages: ${packages[*]}"
        return 1
    fi
}


# ==============================================================================
# Main setup functions
# ==============================================================================

# Setup bash aliases symlink
setup_bash_aliases() {
    log_info "Setting up bash aliases symlink"
    
    local source_file="/$SERVICE_NAME/$DEVCONTAINER_DIR/$BASH_ALIASES_FILE"
    local target_link="$HOME/$BASH_ALIASES_FILE"
    
    if [[ -f "$source_file" ]]; then
        ensure_symlink "$source_file" "$target_link"
    else
        log_info "Bash aliases file not found, skipping: $source_file"
    fi
}

# Setup VSCode workspace settings
setup_vscode_settings() {
    log_info "Setting up VSCode workspace settings"
    
    local vscode_dir="/$SERVICE_NAME/$VSCODE_DIR"
    local source_file="/$SERVICE_NAME/$DEVCONTAINER_DIR/$VSCODE_SETTINGS_FILE"
    local target_link="$vscode_dir/$VSCODE_SETTINGS_LINK"
    
    # Ensure .vscode directory exists
    if [[ ! -d "$vscode_dir" ]]; then
        if mkdir -p "$vscode_dir"; then
            log_success "Created directory: $vscode_dir"
        else
            log_error "Failed to create directory: $vscode_dir"
            return 1
        fi
    fi
    
    # Create symlink for settings if source exists
    if [[ -f "$source_file" ]]; then
        ensure_symlink "$source_file" "$target_link"
    else
        log_info "VSCode settings file not found, skipping: $source_file"
    fi
}

# ==============================================================================
# Main execution
# ==============================================================================

common_main() {
    log_info "Starting common container post-create setup..."
	validate_os || exit 1
	validate_environment_variables "SERVICE_NAME" || exit 1
    validate_dependencies "sudo" "curl" "apt-get" || exit 1
    validate_sudo_access || exit 1
    
    # Run setup functions
    setup_bash_aliases
    #setup_vscode_settings
}

# Only run main function if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    common_main "$@"
fi

# END Common scripts
