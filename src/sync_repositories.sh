#!/bin/bash

#######################################
# Template Repository Synchronization Script
#
# This script synchronizes changes from a template repository to all
# repositories that were created from that template within a GitHub organization.
# It creates pull requests with the template updates for each child repository.
#
# Required Environment Variables:
#   ORGANIZATION: GitHub organization name
#   TEMPLATE_REPOSITORY_NAME: Name of the template repository
#   GITHUB_PAT: GitHub Personal Access Token
#
# Optional Environment Variables:
#   COMMIT_MESSAGE: Custom commit message (default: auto-generated)
#   PR_TITLE: Custom PR title (default: auto-generated)
#   PR_BODY: Custom PR body (default: auto-generated)
#   DEFAULT_REVIEWERS: Comma-separated list of reviewers
#   REQUEST_REVIEW_FROM_COPILOT: Request Copilot review (default: false)
#
# Globals:
#   ORGANIZATION, TEMPLATE_REPOSITORY_NAME, COMMIT_MESSAGE, PR_TITLE,
#   PR_BODY, DEFAULT_REVIEWERS, GITHUB_PAT, REQUEST_REVIEW_FROM_COPILOT
# Arguments:
#   None
# Outputs:
#   Progress messages and sync results to stdout
# Returns:
#   0 on success, 1 on validation failure
#######################################

source "$(dirname "$0")/utils.sh"
source "$(dirname "$0")/check_installed_tool.sh"
source "$(dirname "$0")/validate_inputs.sh"

# shellcheck disable=SC2269
ORGANIZATION=${ORGANIZATION}
# shellcheck disable=SC2269
TEMPLATE_REPOSITORY_NAME=${TEMPLATE_REPOSITORY_NAME}
COMMIT_MESSAGE=${COMMIT_MESSAGE:-"Sync template $TEMPLATE_REPOSITORY_NAME with latest changes"}
PR_TITLE=${PR_TITLE:-"Sync template $TEMPLATE_REPOSITORY_NAME"}
PR_BODY=${PR_BODY:-"This PR syncs the template repository '$TEMPLATE_REPOSITORY_NAME' with the latest changes."}
DEFAULT_REVIEWERS=${DEFAULT_REVIEWERS:-""}
# shellcheck disable=SC2269
GITHUB_PAT=${GITHUB_PAT}
GIT_USER_NAME=${GITHUB_ACTOR}
GIT_USER_EMAIL="github-action@push-sync-template.noreply.github.com"
REQUEST_REVIEW_FROM_COPILOT=${REQUEST_REVIEW_FROM_COPILOT:-false}

validate_inputs "$ORGANIZATION" "$TEMPLATE_REPOSITORY_NAME" "$GITHUB_PAT" || exit 1
check_required_tools || exit 1

github_login "$GITHUB_PAT" || exit 1

git_config "$GITHUB_PAT" "$GIT_USER_NAME" "$GIT_USER_EMAIL" || exit 1

TEMPLATE_REPOSITORY_PATH=$(get_template_repository_path "$ORGANIZATION" "$TEMPLATE_REPOSITORY_NAME")
BRANCH_NAME=$(get_branch_name "$ORGANIZATION" "$TEMPLATE_REPOSITORY_NAME")

sync_repositories \
	"$ORGANIZATION" \
	"$TEMPLATE_REPOSITORY_NAME" \
	"$BRANCH_NAME" \
	"$COMMIT_MESSAGE" \
	"$TEMPLATE_REPOSITORY_PATH" \
	"$PR_TITLE" \
	"$PR_BODY" \
	"$DEFAULT_REVIEWERS" \
	"$REQUEST_REVIEW_FROM_COPILOT"
