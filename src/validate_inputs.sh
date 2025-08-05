#!/bin/bash

function validate_input {
	local input_name=$1
	local input_value=$2

	if [ -z "$input_value" ]; then
		echo "Error: $input_name is not set. Please provide a valid value."
		return 1
	fi
}

function validate_inputs {
	local organization=$1
	local template_repository_name=$2
	local github_pat=$3

	validate_input "ORGANIZATION" "$organization" || return 1
	validate_input "TEMPLATE_REPOSITORY_NAME" "$template_repository_name" || return 1
	validate_input "GITHUB_PAT" "$github_pat" || return 1
}
