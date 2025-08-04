#!/bin/bash

source "$(dirname "$0")/utils.sh"

ORGANIZATION=$1
TEMPLATE_REPOSITORY_NAME=$2
COMMIT_MESSAGE=${3:-"Sync template $TEMPLATE_REPOSITORY_NAME with latest changes"}
PR_TITLE=${4:-"Sync template $TEMPLATE_REPOSITORY_NAME"}
PR_BODY=${5:-"This PR syncs the template repository '$TEMPLATE_REPOSITORY_NAME' with the latest changes."}
DEFAULT_REVIEWERS=${6}
REQUEST_REVIEW_FROM_COPILOT=${7:-false}

if [ -z "$ORGANIZATION" ]; then
	echo "Usage: $0 <organization> <template-repository-name>"
	exit 1
fi

if [ -z "$TEMPLATE_REPOSITORY_NAME" ]; then
	echo "Usage: $0 <organization> <template-repository-name>"
	exit 1
fi

TEMPLATE_REPOSITORY_COMPLETE_NAME=$(get_git_complete_name "$ORGANIZATION" "$TEMPLATE_REPOSITORY_NAME")
TEMPLATE_REPOSITORY_PATH="https://github.com/$TEMPLATE_REPOSITORY_COMPLETE_NAME.git"
BRANCH_NAME=$(get_branch_name)

sync_repositories "$ORGANIZATION" "$TEMPLATE_REPOSITORY_NAME" "$BRANCH_NAME" "$COMMIT_MESSAGE" "$TEMPLATE_REPOSITORY_PATH" "$PR_TITLE" "$PR_BODY" "$DEFAULT_REVIEWERS" "$REQUEST_REVIEW_FROM_COPILOT"
