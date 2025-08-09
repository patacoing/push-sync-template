#!/bin/bash

#######################################
# Interpolate the commit message template with dynamic values.
# This function replaces placeholders in the commit message template with actual values
# such as the template repository name, branch name, and latest commit hash.
# This allows for a more informative and context-aware commit message.
# The placeholders in the template should be in the format `${variable_name}`.
# Globals:
#   None
# Arguments:
#   commit_message_template: The template for the commit message
#   template_repository_name: The name of the template repository
#   branch_name: The name of the branch being created
#   latest_template_commit: The latest commit hash of the template repository
# Outputs:
#   Prints the generated commit message to stdout
# Returns:
#   0 on success
#######################################
function interpolate_commit_message {
	local commit_message_template=$1
	local template_repository_name=$2
	local branch_name=$3
	local latest_template_commit=$4

	declare -A vars
	vars["template_repository_name"]="$template_repository_name"
	vars["branch_name"]="$branch_name"
	vars["latest_template_commit"]="$latest_template_commit"

	interpolate_template "$commit_message_template" vars
}

#######################################
# Interpolate the PR title template with dynamic values.
# This function replaces placeholders in the PR title template with actual values
# such as the template repository name and branch name.
# This allows for a more informative and context-aware PR title.
# The placeholders in the template should be in the format `${variable_name}`.
# Globals:
#   None
# Arguments:
#   pr_title_template: The template for the PR title
#   template_repository_name: The name of the template repository
#   branch_name: The name of the branch being created
# Outputs:
#   Prints the generated branch name to stdout
# Returns:
#   0 on success
#######################################
function interpolate_pr_title {
	local pr_title_template=$1
	local template_repository_name=$2
	local branch_name=$3

	declare -A vars
	vars["template_repository_name"]="$template_repository_name"
	vars["branch_name"]="$branch_name"

	interpolate_template "$pr_title_template" vars
}

#######################################
# Interpolate the PR body template with dynamic values.
# This function replaces placeholders in the PR body template with actual values
# such as the template repository name, branch name, and latest commit hash.
# This allows for a more informative and context-aware PR body.
# The placeholders in the template should be in the format `${variable_name}`.
# Globals:
#   None
# Arguments:
#   pr_body_template: The template for the PR body
#   template_repository_name: The name of the template repository
#   branch_name: The name of the branch being created
#   latest_template_commit: The latest commit hash of the template repository
# Outputs:
#   Prints the generated PR body to stdout
# Returns:
#   0 on success
#######################################
function interpolate_pr_body {
	local pr_body_template=$1
	local template_repository_name=$2
	local branch_name=$3
	local latest_template_commit=$4

	declare -A vars
	vars["template_repository_name"]="$template_repository_name"
	vars["branch_name"]="$branch_name"
	vars["latest_template_commit"]="$latest_template_commit"

	interpolate_template "$pr_body_template" vars
}

#######################################
# Interpolate the branch name template with dynamic values.
# This function replaces placeholders in the branch name template with actual values
# such as the template repository name and latest commit hash.
# This allows for a more informative and context-aware branch name.
# The placeholders in the template should be in the format `${variable_name}`.
# Globals:
#   None
# Arguments:
#   branch_name_template: The template for the branch name
#   template_repository_name: The name of the template repository
#   latest_template_commit: The latest commit hash of the template repository
#
# Outputs:
#   Prints the generated branch name to stdout
# Returns:
#   0 on success
#######################################
function interpolate_branch_name {
	local branch_name_template=$1
	local template_repository_name=$2
	# shellcheck disable=SC2034
	local latest_template_commit=$3

	declare -A vars
	vars["template_repository_name"]="$template_repository_name"
	# shellcheck disable=SC2034
	vars["latest_template_commit"]="$latest_template_commit"

	interpolate_template "$branch_name_template" vars
}

#######################################
# Interpolate a template with dynamic values.
# This function replaces placeholders in a template with values from a dictionary.
# The placeholders in the template should be in the format `${variable_name}`.
# The dictionary should be passed as a reference.
# This allows for flexible and reusable template interpolation.
# Globals:
#   None
# Arguments:
#   template: The template string to be interpolated
#   dict: A reference to an associative array containing the values for interpolation
# Outputs:
#   Prints the generated branch name to stdout
# Returns:
#   0 on success
#######################################
function interpolate_template {
	local template="$1"
	declare -n dict="$2"

	local varspec=""
	local env_args=()
	for key in "${!dict[@]}"; do
		varspec="$varspec \${$key}"
		env_args+=("$key=${dict[$key]}")
	done
	varspec="${varspec# }"

	env "${env_args[@]}" envsubst "$varspec" <<<"$template"
}
