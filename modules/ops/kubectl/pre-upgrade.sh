#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/ops/kubectl/resolver.sh"

kubectl_download_binary "$CANONICAL_ID"
