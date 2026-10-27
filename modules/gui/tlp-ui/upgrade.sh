#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/git-pull-upgrade.sh"

git_pull_upgrade "$CANONICAL_ID"
