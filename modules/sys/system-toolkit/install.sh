#!/usr/bin/env bash
set -euo pipefail

source "${LIB_COMMON}/common.sh"
source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/registry.sh"
source "${LIB_INSTALLER}/symlink.sh"

SYSTEM_TOOLKIT_INSTALL_DIR="${SYSTEM_TOOLKIT_INSTALL_DIR:-$INSTALL_DIR/system-toolkit}"
REPO_URL="https://github.com/hadi-susanto/system-toolkit.git"

sudo_cmd=()
if ! can_write "$SYSTEM_TOOLKIT_INSTALL_DIR"; then
    sudo_cmd=(sudo)
fi

if [[ -e "$SYSTEM_TOOLKIT_INSTALL_DIR" && ! -d "$SYSTEM_TOOLKIT_INSTALL_DIR/.git" ]]; then
    tlog_error "install:$CANONICAL_ID" \
        "Target exists but is not a System Toolkit checkout: $SYSTEM_TOOLKIT_INSTALL_DIR"

    exit 1
fi

if [[ -d "$SYSTEM_TOOLKIT_INSTALL_DIR/.git" ]]; then
    tlog_warn "install:$CANONICAL_ID" \
        "Target already contains System Toolkit, skipping clone: $SYSTEM_TOOLKIT_INSTALL_DIR"
else
    install_parent_dir="$(dirname -- "$SYSTEM_TOOLKIT_INSTALL_DIR")"

    if ! "${sudo_cmd[@]}" mkdir -p "$install_parent_dir"; then
        tlog_error "install:$CANONICAL_ID" "Failed to create install directory: $install_parent_dir"

        exit 2
    fi

    tlog_info "install:$CANONICAL_ID" "Cloning System Toolkit to $SYSTEM_TOOLKIT_INSTALL_DIR"

    if ! "${sudo_cmd[@]}" git clone --depth 1 "$REPO_URL" "$SYSTEM_TOOLKIT_INSTALL_DIR"; then
        tlog_error "install:$CANONICAL_ID" "Failed to clone repository: $REPO_URL"

        exit 3
    fi
fi

entrypoints=("$SYSTEM_TOOLKIT_INSTALL_DIR"/syskit-*)

if [[ ! -e "${entrypoints[0]}" ]]; then
    tlog_error "install:$CANONICAL_ID" "No syskit-* entrypoints found in $SYSTEM_TOOLKIT_INSTALL_DIR"

    exit 4
fi

for entrypoint in "${entrypoints[@]}"; do
    if [[ ! -f "$entrypoint" ]]; then
        tlog_error "install:$CANONICAL_ID" "Entrypoint is not a regular file: $entrypoint"

        exit 5
    fi

    if ! "${sudo_cmd[@]}" chmod +x "$entrypoint"; then
        tlog_error "install:$CANONICAL_ID" "Failed to make entrypoint executable: $entrypoint"

        exit 6
    fi

    symlink_binary "$CANONICAL_ID" "$entrypoint" || exit $?
done

set_registry "INSTALL_PATH" "$SYSTEM_TOOLKIT_INSTALL_DIR" || exit 7
save_registry "$CANONICAL_ID" || exit 7

tlog_info "install:$CANONICAL_ID" "Installation completed successfully"
