#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/pipx-package.sh"

pypi_latest_version "$CANONICAL_ID" "openconnect-saml"
