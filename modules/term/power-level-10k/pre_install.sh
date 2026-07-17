#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

if ! command -v git >/dev/null 2>&1; then
    log_error "[$CANONICAL_ID] git is required but not installed."

    exit 1
fi
