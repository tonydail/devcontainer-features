#!/bin/bash

# Mutagen Session Termination Script
# This script reads the mutagen.log file to extract session information
# and terminates the sync session based on the session ID

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
MUTAGEN_LOG="$LOG_DIR/mutagen.log"
PID_LOG="$LOG_DIR/mutagen_pid.log"
SESSION_INFO_LOG="$LOG_DIR/mutagen_session_info.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

setup_working_environment() {
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	SERVICE_NAME="$(basename "$(pwd)")"
	#check if we have a logs directory in the user log path
	LOG_DIR="$HOME/Library/Logs/$(basename "$SERVICE_NAME")"

	MUTAGEN_LOG="$LOG_DIR/mutagen.log"
	PID_LOG="$LOG_DIR/mutagen_pid.log"
	SESSION_INFO_LOG="$LOG_DIR/mutagen_session_info.log"
}

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to extract session ID from mutagen.log
extract_session_id() {
    if [[ ! -f "$MUTAGEN_LOG" ]]; then
        print_status $RED "Error: Mutagen log file not found at $MUTAGEN_LOG"
        return 1
    fi
    
    # Extract session ID from the log (format: "Created session sync_...")
    local session_id=$(grep -o "Created session sync_[A-Za-z0-9]*" "$MUTAGEN_LOG" | tail -1 | awk '{print $3}')
    
    if [[ -z "$session_id" ]]; then
        print_status $RED "Error: No session ID found in mutagen log"
        return 1
    fi
    
    echo "$session_id"
    return 0
}

# Function to extract session name from mutagen.log
extract_session_name() {
    if [[ ! -f "$MUTAGEN_LOG" ]]; then
        return 1
    fi
    
    # Extract session name (format: "Mutagen sync session 'name' created.")
    local session_name=$(grep "Mutagen sync session.*created" "$MUTAGEN_LOG" | tail -1 | sed "s/.*'\(.*\)' created.*/\1/")
    
    if [[ -z "$session_name" ]]; then
        return 1
    fi
    
    echo "$session_name"
    return 0
}

# Function to get process PID
get_process_pid() {
    if [[ ! -f "$PID_LOG" ]]; then
        return 1
    fi
    
    local pid=$(grep "Process PID:" "$PID_LOG" | tail -1 | awk '{print $3}')
    echo "$pid"
    return 0
}

# Function to check if mutagen is available
check_mutagen() {
	if ! command -v mutagen &>/dev/null; then
        print_status $RED "Error: mutagen command not found in PATH"
        print_status $YELLOW "This script requires mutagen to be installed and available"
        return 1
    fi
    return 0
}

# Function to terminate session by ID
terminate_by_id() {
    local session_id=$1
    
    print_status $YELLOW "Attempting to terminate session ID: $session_id"
    
    if mutagen sync terminate "$session_id"; then
        print_status $GREEN "✓ Successfully terminated session: $session_id"
        log_termination "ID" "$session_id"
        return 0
    else
        print_status $RED "✗ Failed to terminate session: $session_id"
        return 1
    fi
}

# Function to terminate session by name
terminate_by_name() {
    local session_name=$1
    
    print_status $YELLOW "Attempting to terminate session name: $session_name"
    
    if mutagen sync terminate "$session_name"; then
        print_status $GREEN "✓ Successfully terminated session: $session_name"
        log_termination "NAME" "$session_name"
        return 0
    else
        print_status $RED "✗ Failed to terminate session: $session_name"
        return 1
    fi
}

# Function to kill process by PID
kill_process() {
    local pid=$1
    
    if [[ -z "$pid" ]]; then
        return 1
    fi
    
    # Check if process is running
	if ps -p "$pid" >/dev/null 2>&1; then
        print_status $YELLOW "Killing process PID: $pid"
        if kill "$pid"; then
            print_status $GREEN "✓ Successfully killed process: $pid"
            log_termination "PID" "$pid"
            return 0
        else
            print_status $RED "✗ Failed to kill process: $pid"
            return 1
        fi
    else
        print_status $YELLOW "Process $pid is not running"
        return 1
    fi
}

# Function to log termination
log_termination() {
    local method=$1
    local identifier=$2
    local timestamp=$(date)
    
	echo "" >>"$SESSION_INFO_LOG"
	echo "=== TERMINATION LOG ===" >>"$SESSION_INFO_LOG"
	echo "Terminated on: $timestamp" >>"$SESSION_INFO_LOG"
	echo "Method: $method" >>"$SESSION_INFO_LOG"
	echo "Identifier: $identifier" >>"$SESSION_INFO_LOG"
	echo "======================" >>"$SESSION_INFO_LOG"
}

# Function to show session information
show_session_info() {
    print_status $BLUE "=== Current Session Information ==="
    
    local session_id=$(extract_session_id)
    local session_name=$(extract_session_name)
    local pid=$(get_process_pid)
    
    if [[ -n "$session_id" ]]; then
        print_status $GREEN "Session ID: $session_id"
    else
        print_status $RED "Session ID: Not found"
    fi
    
    if [[ -n "$session_name" ]]; then
        print_status $GREEN "Session Name: $session_name"
    else
        print_status $RED "Session Name: Not found"
    fi
    
    if [[ -n "$pid" ]]; then
		if ps -p "$pid" >/dev/null 2>&1; then
            print_status $GREEN "Process PID: $pid (running)"
        else
            print_status $YELLOW "Process PID: $pid (not running)"
        fi
    else
        print_status $RED "Process PID: Not found"
    fi
    
    print_status $BLUE "=================================="
}

# Main function
main() {
	local should_exit=false
	setup_working_environment
	if [[ ! -d "$LOG_DIR" ]]; then
		print_status $RED "Error: Log directory not found at $LOG_DIR"
		print_status $RED "Unable to proceed with mutagen sync termination."
		exit 1
	else
		print_status $GREEN "Using log directory: $LOG_DIR"
	fi


    print_status $BLUE "Mutagen Session Termination Script"
    print_status $BLUE "=================================="
    
    # Show current session information
    show_session_info
    
    # Parse command line arguments
    case "${1:-auto}" in
	"info" | "--info" | "-i")
            print_status $BLUE "Session information displayed above"
            exit 0
            ;;
	"id" | "--id")
            if ! check_mutagen; then
                exit 1
            fi
            session_id=$(extract_session_id)
            if [[ -n "$session_id" ]]; then
                terminate_by_id "$session_id"
            else
                print_status $RED "No session ID found to terminate"
                exit 1
            fi
            ;;
	"name" | "--name")
            if ! check_mutagen; then
                exit 1
            fi
            session_name=$(extract_session_name)
            if [[ -n "$session_name" ]]; then
                terminate_by_name "$session_name"
            else
                print_status $RED "No session name found to terminate"
                exit 1
            fi
            ;;
	"pid" | "--pid")
            pid=$(get_process_pid)
            if [[ -n "$pid" ]]; then
                kill_process "$pid"
            else
                print_status $RED "No process PID found to kill"
                exit 1
            fi
            ;;
	"auto" | "--auto" | "")
            # Try different termination methods in order
            success=false
            
            # First try mutagen termination if available
            if check_mutagen; then
                # Try by session name first
                session_name=$(extract_session_name)
                if [[ -n "$session_name" ]] && terminate_by_name "$session_name"; then
                    success=true
                else
                    # Try by session ID
                    session_id=$(extract_session_id)
                    if [[ -n "$session_id" ]] && terminate_by_id "$session_id"; then
                        success=true
                    fi
                fi
            fi
            
            # If mutagen termination failed, try killing the process
            if [[ "$success" != "true" ]]; then
                pid=$(get_process_pid)
                if [[ -n "$pid" ]] && kill_process "$pid"; then
                    success=true
                fi
            fi
            
            if [[ "$success" != "true" ]]; then
                print_status $RED "All termination methods failed"
                exit 1
		else
			print_status $GREEN "Mutagen session terminated successfully"
			print_status $BLUE "Cleaning up log directory: $LOG_DIR"
			rm -rfv "$LOG_DIR"
            fi
            ;;
	"help" | "--help" | "-h")
            print_status $BLUE "Usage: $0 [METHOD]"
            print_status $BLUE ""
            print_status $BLUE "Methods:"
            print_status $BLUE "  auto     - Try all methods (default)"
            print_status $BLUE "  id       - Terminate by session ID"
            print_status $BLUE "  name     - Terminate by session name"
            print_status $BLUE "  pid      - Kill by process PID"
            print_status $BLUE "  info     - Show session information only"
            print_status $BLUE "  help     - Show this help"
            exit 0
            ;;
        *)
            print_status $RED "Unknown method: $1"
            print_status $YELLOW "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
