#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"

# Installed only when every connector is present; a single distro package
# (e.g. Ubuntu's libmysqlcppconn-dev) must not count.
for package in \
    "mysql-connector-j" \
    "mysql-connector-python-py3" \
    "mysql-connector-odbc" \
    "libmysqlcppconn-dev"; do
    package_installed "$CANONICAL_ID" "$package" || exit $?
done
