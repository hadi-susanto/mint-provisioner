#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"

MODULE="power-level-10k"

if ! command -v git >/dev/null 2>&1; then
    log_error "[$MODULE] git is required but not installed."

    exit 1
fi
