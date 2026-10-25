#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/stateful-apt-install.sh"

stateful_apt_install "$CANONICAL_ID" "MYSQL_TOOLS_PACKAGE"
