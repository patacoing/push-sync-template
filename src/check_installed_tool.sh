#!/bin/bash

#######################################
# Check if a specific command/tool is installed on the system.
# Globals:
#   None
# Arguments:
#   command_name: The name of the command/tool to check for installation
# Outputs:
#   Writes error message to stdout if tool is not found
# Returns:
#   0 if tool is installed and available, 1 otherwise
#######################################
function check_tool_is_installed {
	local command_name=$1

	if ! command -v "$command_name" &>/dev/null; then
		echo "$command_name is not installed. Please install it to use this script."
		return 1
	fi
}

#######################################
# Check if all required tools are installed on the system.
# Validates the presence of essential tools (git, gh) needed for the script
# to function properly. Exits early if any tool is missing.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes error messages to stdout for any missing tools
# Returns:
#   0 if all required tools are available, 1 otherwise
#######################################
function check_required_tools {
	local tools=("git" "gh")

	for tool in "${tools[@]}"; do
		check_tool_is_installed "$tool" || return 1
	done
}
