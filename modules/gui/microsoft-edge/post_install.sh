#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/messages.sh"

updater_scripts=(
    "/opt/microsoft/msedge/cron/microsoft-edge"
    "/opt/microsoft/msedge-beta/cron/microsoft-edge-beta"
    "/opt/microsoft/msedge-dev/cron/microsoft-edge-dev"
    "/opt/microsoft/msedge-canary/cron/microsoft-edge-canary"
)

for updater_script in "${updater_scripts[@]}"; do
    [[ -e "$updater_script" ]] || continue

    log_info \
        "[$CANONICAL_ID] Disabling Microsoft Edge repository updater: $updater_script"

    if ! sudo chmod -x "$updater_script"; then
        log_error \
            "[$CANONICAL_ID] Failed to disable updater: $updater_script"

        exit 1
    fi
done

message="Microsoft Edge's repository updater has been disabled because it may
replace the APT source configuration managed by Mint Provisioner.

A future Microsoft Edge package upgrade may make its updater executable again.
Reapply the configuration when necessary with:

    ./configure.sh gui/microsoft-edge"

add_message "$CANONICAL_ID" "warn" "$message"
