#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"

# Installed when any connector is present, matching UPDATE_PACKAGE, so mp outdated
# and mp upgrade track partial installations. Adding a connector needs --force.
package_installed "$CANONICAL_ID" \
    "mysql-connector-j" \
    "mysql-connector-python-py3" \
    "mysql-connector-odbc" \
    "libmysqlcppconn-dev"
