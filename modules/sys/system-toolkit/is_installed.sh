#!/usr/bin/env bash
set -euo pipefail

commands=(
    syskit-bash
    syskit-bin
    syskit-cfg
    syskit-zsh
)

for command_name in "${commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        exit 1
    fi
done

exit 0
