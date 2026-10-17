#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"

apt_install \
    "$CANONICAL_ID" \
    mysql-connector-j \
    mysql-connector-python-py3 \
    mysql-connector-odbc \
    libmysqlcppconn-dev
