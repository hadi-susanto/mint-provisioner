#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-binary-upgrade.sh"

stateful_binary_upgrade "$CANONICAL_ID" "BINARY_FILE" "argocd"
