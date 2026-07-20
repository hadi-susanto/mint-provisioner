#!/usr/bin/env bash

packages=(
    "brave-browser"
    "brave-browser-beta"
    "brave-browser-nightly"
)

for package in "${packages[@]}"; do
    status="$(
        dpkg-query \
            --show \
            --showformat='${Status}' \
            "$package" 2>/dev/null
    )" || continue

    if [[ "$status" == "install ok installed" ]]; then
        exit 0
    fi
done

exit 1
