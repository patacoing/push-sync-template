#!/bin/bash

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
REQUEST_REVIEW_FROM_COPILOT=${REQUEST_REVIEW_FROM_COPILOT:-false}

validate_inputs "$ORGANIZATION" "$TEMPLATE_REPOSITORY_NAME" "$GITHUB_PAT" || exit 1
check_required_tools || exit 1

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
