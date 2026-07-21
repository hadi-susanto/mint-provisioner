#!/usr/bin/env bash
set -euo pipefail

source "${LIB_DIR}/common.sh"

packages=(
    "mkvtoolnix-gui"
    "mkvtoolnix"
)

for package in "${packages[@]}"; do
    if status="$(
        dpkg-query \
            --show \
            --showformat='${Status}' \
            "$package" 2>/dev/null
    )"; then
        if [[ "$status" == "install ok installed" ]]; then
            exit 0
        fi
    else
        rc=$?
        if ((rc != 1)); then
            log_error "[$CANONICAL_ID] Failed to query package status for $package"

            exit 2
        fi
    fi
done

exit 1
