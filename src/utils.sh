#!/bin/bash

function get_branch_name {
	local organization=$1
	local template_repository_name=$2
	local latest_template_commit
	local branch_name

	latest_template_commit=$(gh api repos/"$organization"/"$template_repository_name"/commits --jq '.[0].sha[:8]')
	branch_name="syncing-template-until-$latest_template_commit"

	echo "$branch_name"
}

function find_children_repositories {
	local organization=$1
	local template_repository_name=$2

	gh repo list "$organization" \
		--json name,templateRepository \
		--jq '.[] | select(.templateRepository.name == "'"$template_repository_name"'") | .name'
}

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

function get_git_complete_name {
	local organization=$1
	local repository_name=$2
	echo "$organization/$repository_name"
}

function get_template_repository_path {
	local organization=$1
	local template_repository_name=$2

	local template_repository_complete_name
	template_repository_complete_name=$(get_git_complete_name "$organization" "$template_repository_name")
	echo "https://github.com/$template_repository_complete_name.git"
}

function check_if_git_branch_exists {
	local branch_name=$1
	git show-ref --verify --quiet "refs/remotes/origin/$branch_name"
}

function has_staged_changes {
	! git diff --quiet --cached
}

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
