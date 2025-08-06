#!/bin/bash

#######################################
# Generate a unique branch name for template synchronization.
# Creates a branch name incorporating the latest commit hash from the
# template repository to ensure uniqueness and traceability.
# Globals:
#   None
# Arguments:
#   organization: The GitHub organization name
#   template_repository_name: The name of the template repository
# Outputs:
#   Prints the generated branch name to stdout
# Returns:
#   0 on success
#######################################
function get_branch_name {
	local organization=$1
	local template_repository_name=$2
	local latest_template_commit
	local branch_name

	latest_template_commit=$(gh api repos/"$organization"/"$template_repository_name"/commits --jq '.[0].sha[:8]')
	branch_name="syncing-template-until-$latest_template_commit"

	echo "$branch_name"
}

#######################################
# Find all repositories that use a specific template repository.
# Uses GitHub CLI to query the organization's repositories and filter
# those that were created from the specified template.
# Globals:
#   None
# Arguments:
#   organization: The GitHub organization name
#   template_repository_name: The name of the template repository
# Outputs:
#   Prints repository names to stdout, one per line
# Returns:
#   0 on success
#######################################
function find_children_repositories {
	local organization=$1
	local template_repository_name=$2

	gh repo list "$organization" \
		--json name,templateRepository \
		--jq '.[] | select(.templateRepository.name == "'"$template_repository_name"'") | .name'
}

#######################################
# Synchronize template changes to all child repositories.
# Main orchestration function that finds all repositories using the template
# and applies template updates to each one via pull requests.
# Globals:
#   None
# Arguments:
#   organization: The GitHub organization name
#   template_repository_name: The name of the template repository
#   branch_name: The branch name to use for sync commits
#   commit_message: The commit message for sync changes
#   template_repository_path: The Git URL of the template repository
#   pr_title: The title for pull requests
#   pr_body: The body text for pull requests
#   default_reviewers: Comma-separated list of default reviewers
#   request_review_from_copilot: Boolean flag to request Copilot review
# Outputs:
#   Progress messages and repository sync status to stdout
# Returns:
#   0 on success
#######################################
function sync_repositories {
	local organization=$1
	local template_repository_name=$2
	local branch_name=$3
	local commit_message=$4
	local template_repository_path=$5
	local pr_title=$6
	local pr_body=$7
	local default_reviewers=$8
	local request_review_from_copilot=$9
	local children_repositories
	local i

	children_repositories=$(find_children_repositories "$organization" "$template_repository_name")

	echo "Found repositories that use the template '$template_repository_name' in organization '$organization' :"
	i=1
	for child_repository in $children_repositories; do
		echo "$i - $child_repository"
		i=$((i + 1))
	done
	echo ""

	if [ -z "$children_repositories" ]; then
		echo "No repositories found that use the template '$template_repository_name' in organization '$organization'."
		return 0
	fi

	mkdir -p "children_repositories"
	cd "children_repositories" || exit

	for child_repository in $children_repositories; do
		echo "- Syncing repository : $child_repository"
		if sync_repository "$organization" "$child_repository" "$branch_name" "$commit_message" "$template_repository_name" "$template_repository_path" "$pr_title" "$pr_body" "$default_reviewers" "$request_review_from_copilot"; then
			echo "Successfully synced $child_repository"
		else
			echo "Failed to sync $child_repository"
		fi
		echo ""
	done

	cd ../
}

#######################################
# Create a complete Git repository name in org/repo format.
# Globals:
#   None
# Arguments:
#   organization: The GitHub organization name
#   repository_name: The repository name
# Outputs:
#   Prints the complete repository name to stdout
# Returns:
#   0 on success
#######################################
function get_git_complete_name {
	local organization=$1
	local repository_name=$2
	echo "$organization/$repository_name"
}

#######################################
# Generate the HTTPS Git URL for a template repository.
# Globals:
#   None
# Arguments:
#   organization: The GitHub organization name
#   template_repository_name: The name of the template repository
# Outputs:
#   Prints the HTTPS Git URL to stdout
# Returns:
#   0 on success
#######################################
function get_template_repository_path {
	local organization=$1
	local template_repository_name=$2

	local template_repository_complete_name
	template_repository_complete_name=$(get_git_complete_name "$organization" "$template_repository_name")
	echo "https://github.com/$template_repository_complete_name.git"
}

#######################################
# Check if a Git branch exists in the remote repository.
# Globals:
#   None
# Arguments:
#   branch_name: The name of the branch to check
# Outputs:
#   None
# Returns:
#   0 if branch exists, 1 otherwise
#######################################
function check_if_git_branch_exists {
	local branch_name=$1
	git show-ref --verify --quiet "refs/remotes/origin/$branch_name"
}

#######################################
# Check if there are staged changes in the current Git repository.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 if there are staged changes, 1 otherwise
#######################################
function has_staged_changes {
	! git diff --quiet --cached
}

#######################################
# Synchronize a single repository with template changes.
# Clones the child repository, creates a new branch, merges template changes,
# commits the changes, and creates a pull request.
# Globals:
#   None
# Arguments:
#   organization: The GitHub organization name
#   child_repository: The name of the child repository to sync
#   branch_name: The branch name to use for sync commits
#   commit_message: The commit message for sync changes
#   template_repository_name: The name of the template repository
#   template_repository_path: The Git URL of the template repository
#   pr_title: The title for the pull request
#   pr_body: The body text for the pull request
#   default_reviewers: Comma-separated list of default reviewers
#   request_review_from_copilot: Boolean flag to request Copilot review
# Outputs:
#   Progress messages and sync status to stdout
# Returns:
#   0 on successful sync, 1 if sync was skipped or failed
#######################################
function sync_repository {
	local organization=$1
	local child_repository=$2
	local branch_name=$3
	local commit_message=$4
	local template_repository_name=$5
	local template_repository_path=$6
	local pr_title=$7
	local pr_body=$8
	local default_reviewers=$9
	local request_review_from_copilot=${10}
	local child_repository_path
	local child_repository_complete_name

	rm -rf "$child_repository"
	child_repository_complete_name=$(get_git_complete_name "$organization" "$child_repository")
	child_repository_path="https://github.com/$child_repository_complete_name.git"

	git clone -q "$child_repository_path"
	cd "$child_repository" || exit

	if check_if_git_branch_exists "$branch_name"; then
		echo "Branch '$branch_name' already exists in $child_repository. Skipping syncing for $child_repository."
		return 1
	fi

	git checkout -qb "$branch_name"

	git remote add template "$template_repository_path"
	git fetch -q template

	git merge -q --squash --allow-unrelated-histories template/main -X theirs

	if ! has_staged_changes; then
		echo "No changes to commit in $child_repository. Skipping syncing for $child_repository."
		return 1
	fi

	# TODO: handle template sync ignore files
	# TODO: add labels

	git commit -m "$commit_message"

	git push -q --set-upstream origin "$branch_name" --force

	create_pull_request "$pr_title" "$pr_body" "$template_repository_name" "$branch_name" "$child_repository_complete_name" "$default_reviewers" "$request_review_from_copilot"

	cd ../
}

#######################################
# Create a pull request with optional Copilot review.
# Creates a pull request for the synchronized changes and optionally
# requests a review from GitHub Copilot using a workaround for the CLI limitation.
# Globals:
#   None
# Arguments:
#   pr_title: The title for the pull request
#   pr_body: The body text for the pull request
#   template_repository_name: The name of the template repository
#   branch_name: The branch name containing the changes
#   child_repository_complete_name: The full name (org/repo) of the child repository
#   default_reviewers: Comma-separated list of default reviewers
#   request_review_from_copilot: Boolean flag to request Copilot review
# Outputs:
#   Pull request URL and review status messages to stdout
# Returns:
#   0 on success
#######################################
function create_pull_request {
	local pr_title=$1
	local pr_body=$2
	local template_repository_name=$3
	local branch_name=$4
	local child_repository_complete_name=$5
	local default_reviewers=$6
	local request_review_from_copilot=$7
	local base_branch="main"
	local pr_link

	pr_link=$(gh pr create \
		--title "$pr_title" \
		--body "$pr_body" \
		--base "$base_branch" \
		--head "$branch_name" \
		--repo "$child_repository_complete_name" \
		--reviewer "$default_reviewers" | grep "^https:/")

	echo "Pull request created: $pr_link"

	if [ "$request_review_from_copilot" = true ]; then
		echo "Requesting review from Copilot for $child_repository_complete_name"
		local pr_number
		pr_number=$(echo "$pr_link" | rev | cut -d'/' -f1 | rev)

		# Hack to add Copilot as a reviewer because gh CLI does not support adding Copilot as a reviewer directly
		# Found at https://github.com/cli/cli/issues/10598#issuecomment-2893526162
		gh alias set --clobber save-me-copilot "api" --method POST /repos/"$1"/pulls/"$2"/requested_reviewers -f "reviewers[]=copilot-pull-request-reviewer[bot]"
		gh save-me-copilot "$child_repository_complete_name" "$pr_number" >/dev/null

		echo "Review requested from Copilot for PR #$pr_number in $child_repository_complete_name"
	fi
}

#######################################
# Authenticate with GitHub using a Personal Access Token.
# Uses the GitHub CLI to authenticate with a provided PAT by piping
# the token to the gh auth login command with the --with-token flag.
# Globals:
#   None
# Arguments:
#   github_pat: The GitHub Personal Access Token for authentication
# Outputs:
#   Authentication status messages from gh CLI to stdout
# Returns:
#   0 on successful authentication, non-zero on failure
#######################################
function github_login {
	local github_pat=$1

	echo "$github_pat" | gh auth login --with-token
}