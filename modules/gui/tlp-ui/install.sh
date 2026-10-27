#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
source "${LIB_INSTALLER}/desktop-integration.sh"
source "${LIB_INSTALLER}/path.sh"
source "${LIB_INSTALLER}/registry.sh"

__ensure_python_dependencies() {
    local canonical_id="$1"
    local tag="python-dep:$canonical_id"

    if ! apt_install "$canonical_id" "python3-gi" "python3-yaml" "python3-toml" "gir1.2-gtk-3.0"; then
        tlog_error "$tag" "Fail to install Python or GTK runtime dependencies"

        return 1
    fi

    if ! python3 -c 'import gi, yaml, toml' >/dev/null 2>&1; then
        tlog_error "$tag" "Failed to load the required Python modules: gi, yaml and toml"

        return 1
    fi
}

__clone_tlpui_repository() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="install:$canonical_id"
    local repository="https://github.com/d4nj1/TLPUI.git"
    local parent_dir="$(dirname -- "$install_path")"

    if [[ -f "$install_path/tlpui/__main__.py" ]]; then
        tlog_warn "$tag" "%s directory already contains TLPUI, skipping clone" "$install_path"

        return 0
    fi
    
    if git clone --depth 1 "$repository" "$install_path"; then
        return 0
    fi

    tlog_error "$tag" "Failed to clone: directory is probably not empty: %s" "$install_path"

    return 1
}

__install_cli_entry() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="cli:$canonical_id"
    local cli_path="/usr/local/bin/tlp-ui"
    local quoted_install_path

    tlog_info "$tag" "Installing TLP UI python wrapper"
    printf -v quoted_install_path '%q' "$install_path"
    if ! sudo tee "$cli_path" >/dev/null <<EOF
#!/usr/bin/env bash

cd $quoted_install_path || exit 1
exec python3 -m tlpui "\$@"
EOF
    then
        tlog_error "$tag" "Failed to create launcher: %s" "$cli_path"

        return 1
    fi

    if ! sudo chmod 0755 "$cli_path"; then
        tlog_error "$tag" "Failed to make launcher executable: %s" "$cli_path"

        return 1
    fi

    tlog_info "$tag" "tlp-ui now available system wide"

    return 0
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local install_path

    install_path="$(expand_path "$raw_install_path")" || return $?
    __ensure_python_dependencies "$canonical_id" || return $?
    __clone_tlpui_repository "$canonical_id" "$install_path" || return $?
    __install_cli_entry "$canonical_id" "$install_path" || return $?
    install_desktop_entry "$canonical_id" "tlp-ui" "TLP UI" "tlp-ui" \
        --try-exec "tlp-ui" \
        --generic-name "Power Management" \
        --comment "Configure TLP power management" \
        --icon-file "$MP_MODULES/$canonical_id/payload/tlp-ui.png" \
        --icon-size "512x512" \
        --categories "Settings;HardwareSettings;GTK;" \
        --keywords "Battery;Power;Laptop;TLP;" \
        --startup-wm-class "Tlp-UI" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id"
}

main "$CANONICAL_ID" "${TLP_UI_INSTALL_DIR:-$INSTALL_DIR/tlp-ui}"
