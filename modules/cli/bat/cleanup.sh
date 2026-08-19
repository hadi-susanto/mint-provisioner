#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/state-cleaner.sh"

auto_clean_state_files "$CANONICAL_ID"
