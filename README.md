# Push Sync Template

A GitHub Action that automatically syncs updates from a template repository to all repositories that were created from it. Instead of requiring each repository to periodically pull changes, this action uses a **push model** where updates are proactively distributed to all child repositories.

## 🚀 What it does

This action:

1. **Discovers child repositories** - Finds all repositories in your organization that were created from a specific template
2. **Creates sync branches** - For each child repository, creates a new branch with the latest template changes
3. **Merges template updates** - Applies template changes using `git merge --squash` with conflict resolution favoring template changes
4. **Opens pull requests** - Automatically creates PRs in each child repository with the synced changes
5. **Assigns reviewers** - Optionally assigns default reviewers and/or GitHub Copilot for review

## 🔄 Push Model vs Pull Model

This action implements a **push model** for template synchronization:

- **❌ Pull Model**: Each repository periodically checks for and pulls template updates (requires setup in every repo, can be forgotten)
- **✅ Push Model**: Template repository pushes updates to all child repositories automatically (centralized, proactive, ensures no repository is left behind)

The push model ensures that:
- All repositories receive updates consistently
- No manual intervention is required in child repositories
- Updates are distributed immediately when the template changes
- You have full visibility and control over the sync process
- You don't need to manage PAT in every children repositories

## 📋 Inputs

| Input                         | Description                                                  | Required | Default                                                                              |
| ----------------------------- | ------------------------------------------------------------ | -------- | ------------------------------------------------------------------------------------ |
| `organization`                | GitHub organization name                                     | ✅ Yes    | -                                                                                    |
| `template_repository_name`    | Name of the template repository                              | ✅ Yes    | -                                                                                    |
| `commit_message`              | Commit message for the sync operation                        | ❌ No     | `"Sync template {template_name} with latest changes"`                                |
| `pr_title`                    | Pull request title                                           | ❌ No     | `"Sync template {template_name}"`                                                    |
| `pr_body`                     | Pull request body                                            | ❌ No     | `"This PR syncs the template repository '{template_name}' with the latest changes."` |
| `default_reviewers`           | Default reviewers for PRs (comma-separated GitHub usernames) | ❌ No     | -                                                                                    |
| `request_review_from_copilot` | Request review from GitHub Copilot                           | ❌ No     | `false`                                                                              |
| `github_pat`                  | Github PAT to open PRs on children repositories              | ✅ Yes    | -                                                                                    |


## 🛠️ Usage

```yaml
name: Sync Template
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Sync template to child repositories
        uses: patacoing/push-sync-template@vmain
        with:
          organization: "my-org"
          template_repository_name: "my-template"
          github_pat: ${{ secrets.GITHUB_PAT }}
```

## 🚧 Current Limitations

- Template sync ignore files are not yet implemented (TODO in the code)
- PR labels are not yet added automatically (TODO in the code)