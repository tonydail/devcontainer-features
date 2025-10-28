#!/bin/bash
working_directory=
log_file_path=

devcontainer_path=
log_path=
mutagen_log_path=
pid_log_path=
environment_file=
mutagen_script_path=

get_log_file_path() {
	local log_path=
	log_path="$HOME/Library/Logs/$(basename "$(get_working_directory)")"
	echo "$log_path"
}

get_working_directory() {
	echo "$PWD"
}

get_devcontainer_path() {
	echo "$(get_working_directory)/.devcontainer"
}

set_working_environment() {
	devcontainer_path=$(get_devcontainer_path)
	log_path=$(get_log_file_path)
	mutagen_log_path="$log_path/mutagen.log"
	pid_log_path="$log_path/mutagen_pid.log"
	environment_file="$devcontainer_path/.env"
	mutagen_script_path="$devcontainer_path/mutagen_start.sh"
}

writeEnvironmentFileEntry() {
	local var_name="$1"
	local var_value="$2"
	local env_file="$3"

	sed -I '' "/${var_name}/d" "$env_file" || die "Failed to update $var_name in $env_file"
	printf "\n%s=\"%s\"" "$var_name" "$var_value" >>"$env_file" || die "Failed to add $var_name to $env_file"
}

writeEnvironmentFile() {
	local tmp
	tmp=$(mktemp) || die "Unable to create temp file"
	cat "$environment_file" >"$tmp"

	writeEnvironmentFileEntry "SERVICE_NAME" "$(basename "$(pwd)")" "$tmp"

	mv -f "$tmp" "$environment_file"
	chmod 644 "$environment_file" || true
	echo "Wrote environment file to $environment_file" true

}

set_working_environment
writeEnvironmentFile

rm -rf $log_path
mkdir -p $log_path

if [ -f "$mutagen_script_path" ]; then
	echo "!!!!!DO NOT MODIFY THIS LOG FILE!!!!!" | tee -a $pid_log_path
	echo "It is used during the cleanup process!" | tee -a $pid_log_path
	echo "--------------------------------------" | tee -a $pid_log_path
	echo "" | tee -a $pid_log_path
	echo "Starting mutagen_sync.sh in background..." | tee -a $pid_log_path

	echo "!!!!!DO NOT MODIFY THIS LOG FILE!!!!!" | tee -a $mutagen_log_path
	echo "It is used during the cleanup process!" | tee -a $mutagen_log_path
	echo "--------------------------------------" | tee -a $mutagen_log_path
	echo "" | tee -a $mutagen_log_path

	nohup $mutagen_script_path "$PWD" >>$mutagen_log_path 2>&1 &
	nohup_pid=$!

	echo "$(date): Started mutagen_sync.sh with nohup, PID: $nohup_pid" | tee -a $pid_log_path
	echo "Process PID: $nohup_pid" | tee -a $pid_log_path
	echo "To check if running: ps -p $nohup_pid" | tee -a $pid_log_path
	echo "To kill process: kill $nohup_pid" | tee -a $pid_log_path
else
	echo "Warning: mutagen_sync.sh not found at $devcontainer_path/mutagen_sync.sh" | tee -a $pid_log_path
fi
