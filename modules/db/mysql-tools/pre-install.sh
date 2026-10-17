#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/db/mysql/repository.sh"

add_mysql_repository_component "$CANONICAL_ID" "mysql-tools"
