#!/bin/bash

function check_tool_is_installed {
	local command_name=$1

	if ! command -v "$command_name" &>/dev/null; then
		echo "$command_name is not installed. Please install it to use this script."
		return 1
	fi
}

function check_required_tools {
	local tools=("git" "gh")

	for tool in "${tools[@]}"; do
		check_tool_is_installed "$tool" || return 1
	done
}
