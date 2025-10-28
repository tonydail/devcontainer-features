#!/bin/bash

# Enable error handling for background execution
set -e

WORKING_FOLDER=
# Define session parameters
if [ -z "$1" ]; then
	WORKING_FOLDER=$(pwd)
	echo "No working folder argument provided. Using current directory: $WORKING_FOLDER"
else
	WORKING_FOLDER="$1"
	echo "Using provided working folder: $WORKING_FOLDER"
fi

devcontainer_path="$WORKING_FOLDER/.devcontainer"
SERVICE_NAME=$(basename "$WORKING_FOLDER")
export SERVICE_NAME

docker_compose_file="$devcontainer_path/docker-compose.yaml"
if [ -f "$docker_compose_file" ]; then
	echo "Reading service/container name from $docker_compose_file"
	CONTAINER_NAME=$(envsubst <"$docker_compose_file" | yq '.services.code_sync.container_name')
	echo "Using service/container name: $CONTAINER_NAME"
else
	echo "Docker Compose file not found at $docker_compose_file. Unable to continue."
	exit 1
fi


SESSION_NAME="${SERVICE_NAME}-mutagen-session"
LOCAL_PATH="$WORKING_FOLDER"
REMOTE_PATH="docker://${CONTAINER_NAME}/${SERVICE_NAME}"
BETA_OWNER="1000" # Replace with the desired username for the beta endpoint
BETA_GROUP="1000"

is_running() {
	docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null | grep -q "running"
}

echo "Waiting for container '$CONTAINER_NAME' to become available..."

# Loop until the container is started with timeout for background mode
TIMEOUT=300 # 5 minutes timeout
ELAPSED=0
while ! is_running; do
	sleep 1
	ELAPSED=$((ELAPSED + 1))

	# Echo "Still waiting..." every 10 seconds
	if [ $((ELAPSED % 10)) -eq 0 ]; then
		echo "Still waiting..."
	fi

	# Add timeout for background execution
	if [ $ELAPSED -ge $TIMEOUT ]; then
		echo "ERROR: Timeout waiting for container '$CONTAINER_NAME' after ${TIMEOUT} seconds"
		exit 1
	fi
done

echo "Container '$CONTAINER_NAME' is ready!"

# Load environment variables from .env file
ENV_FILE="$devcontainer_path/.env"
if [ -f "$ENV_FILE" ]; then
	echo "Loading environment variables from $ENV_FILE"
	set -a # Automatically export all variables
	# shellcheck source=.env
	source "$ENV_FILE"
	set +a # Disable automatic export
else
	echo "Warning: .env file not found at $ENV_FILE"
fi

# Define ignore patterns from SYNC_EXCLUDES or use defaults
if [ -n "$SYNC_EXCLUDES" ]; then
	echo "Using ignore patterns from SYNC_EXCLUDES: $SYNC_EXCLUDES"
	# Convert space-separated string to array
	read -a IGNORE_PATTERNS <<<"$SYNC_EXCLUDES"
else
	echo "SYNC_EXCLUDES not found, no ignore patterns will be used"
	IGNORE_PATTERNS=()
fi

# Check if a session with this name already exists and terminate it if so
if mutagen sync list --long | grep -q "Name: $SESSION_NAME"; then
	echo "Terminating existing Mutagen session: $SESSION_NAME"
	mutagen sync terminate "$SESSION_NAME"
	sleep 2 # Give Mutagen a moment to terminate
fi

echo "Creating new Mutagen sync session: $SESSION_NAME"

# Build the ignore arguments as an array
IGNORE_ARGS=()
for pattern in "${IGNORE_PATTERNS[@]}"; do
	IGNORE_ARGS+=("--ignore" "$pattern")
done

# Create the Mutagen sync session
# The --default-owner-beta flag sets ownership specifically for the beta endpoint
mutagen sync create \
	--name "$SESSION_NAME" \
	--mode two-way-resolved \
	"${IGNORE_ARGS[@]}" \
	"$LOCAL_PATH" \
	"$REMOTE_PATH" \
	--default-owner-beta=id:"$BETA_OWNER" \
	--default-group-beta=id:"$BETA_GROUP" \
	--default-file-mode=0644 \
	--default-directory-mode=0755

echo "Mutagen sync session '$SESSION_NAME' created."

# Check if running in background (nohup or no terminal)
if [ -t 0 ]; then
	# Interactive mode - ask user what they want to do
	echo "Choose an option:"
	echo "1) Monitor session interactively (Press Ctrl+C to exit)"
	echo "2) Run in background without monitoring"
	echo "3) Exit after session creation"
	read -p "Enter choice (1-3): " choice

	case $choice in
	1)
		echo "Starting interactive monitoring..."
		mutagen sync monitor "$SESSION_NAME"
		;;
	2 | 3 | *)
		echo "Session created and running in background."
		echo "Use 'mutagen sync list' to check status"
		echo "Use 'mutagen sync monitor $SESSION_NAME' to monitor later"
		;;
	esac
else
	# Background mode (nohup) - just confirm and exit
	echo "Session created and running in background."
	echo "Use 'mutagen sync list' to check status"
	echo "Use 'mutagen sync monitor $SESSION_NAME' to monitor later"

	# Optional: Log session status for background runs
	echo "Session status at $(date):"
	mutagen sync list --long
fi
