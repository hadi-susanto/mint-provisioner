#!/usr/bin/env bash
set -euo pipefail

source "${LIB_INSTALLER}/apt.sh"
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

        exit 1
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

__install_desktop_entry() {
    local canonical_id="$1"
    local tag="desktop:$canonical_id"
    local icon_source="$MP_MODULES/$CANONICAL_ID/payload/tlp-ui.png"
    local icon_theme_dir="/usr/share/icons/hicolor"
    local icon_path="$icon_theme_dir/512x512/apps/tlp-ui.png"
    local application_dir="/usr/share/applications"
    local desktop_file="$application_dir/tlp-ui.desktop"

    tlog_info "$tag" "Installing TLP UI .desktop file"
    if [[ ! -f "$icon_source" ]]; then
        tlog_error "$tag" "Missing TLP UI Icon resources: %s" "$icon_source"

        return 1
    fi

    if ! sudo install -Dm0644 "$icon_source" "$icon_path"; then
        tlog_error "$tag" "Failed to install application icon: %s" "$icon_path"

        return 1
    fi

    if ! sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=TLP UI
GenericName=Power Management
Comment=Configure TLP power management
Exec=tlp-ui
TryExec=tlp-ui
Icon=tlp-ui
Terminal=false
Categories=Settings;HardwareSettings;GTK;
Keywords=Battery;Power;Laptop;TLP;
StartupWMClass=Tlp-UI
EOF
    then
        tlog_error "$tag" "Failed to install desktop file: %s" "$desktop_file"

        return 1
    fi

    if ! sudo chmod 0644 "$desktop_file"; then
        tlog_error "$tag" "Failed to set desktop file permissions: %s" "$desktop_file"

        return 1
    fi

    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        tlog_info "$tag" "Refreshing icon cache"

        if ! sudo gtk-update-icon-cache -f -t "$icon_theme_dir"; then
            tlog_warn "$tag" "Failed to refresh the icon cache"
        fi
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        tlog_info "$tag" "Refreshing desktop application database"

        if ! sudo update-desktop-database "$application_dir"; then
            tlog_warn "$tag" "Failed to refresh the desktop application database"
        fi
    fi
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local install_path

    install_path="$(expand_path "$raw_install_path")" || return $?
    __ensure_python_dependencies "$canonical_id" || return $?
    __clone_tlpui_repository "$canonical_id" "$install_path" || return $?
    __install_cli_entry "$canonical_id" "$install_path" || return $?
    __install_desktop_entry "$canonical_id" "$install_path" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id"
}

main "$CANONICAL_ID" "${TLP_UI_INSTALL_DIR:-$INSTALL_DIR/tlp-ui}"
