#!/usr/bin/env bash

if [[ -n "${__MP_MODULES_JETBRAINS_INSTALL_LOADED:-}" ]]; then
    return 0
fi

readonly __MP_MODULES_JETBRAINS_INSTALL_LOADED=1

source "$LIB_WORKFLOW/stateful-extract-install.sh"

__install_desktop_entry() {
    local canonical_id="$1"
    local name="$2"
    local install_path="$3"
    local display_name="$4"
    local keyword="$5"
    local tag="integration:$canonical_id"
    local launcher_link="$(symlink_location)/${name}"
    local icon_source="${install_path}/bin/${name}.svg"
    local icon_theme_dir="/usr/share/icons/hicolor"
    local icon_path="${icon_theme_dir}/scalable/apps/${name}.svg"
    local application_dir="/usr/share/applications"
    local desktop_file="${application_dir}/${name}.desktop"

    tlog_info "$tag" "Begin desktop integration for %s" "$display_name"

    if [[ ! -f "$icon_source" ]]; then
        tlog_error "$tag" "JetBrains application icon not found: %s" "$icon_source"

        return 1
    fi

    if ! sudo install -Dm0644 "$icon_source" "$icon_path"; then
        tlog_error "$tag" "Failed to install the application icon: %s" "$icon_path"

        return 1
    fi

    if ! sudo mkdir -p "$application_dir"; then
        tlog_error "$tag" "Failed to create desktop application directory: %s" "$application_dir"

        return 1
    fi

    if ! sudo tee "$desktop_file" >/dev/null <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=$display_name
Comment=Develop software with $display_name
Exec=$launcher_link %f
Icon=$name
Terminal=false
StartupNotify=true
Categories=Development;IDE;
Keywords=Development;IDE;Editor;JetBrains;$keyword;
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
        if ! sudo gtk-update-icon-cache -f -t "$icon_theme_dir"; then
            tlog_warn "$tag" "Failed to refresh the icon cache"
        fi
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        if ! sudo update-desktop-database "$application_dir"; then
            tlog_warn "$tag" "Failed to refresh the desktop application database"
        fi
    fi

    tlog_info "$tag" "%s desktop integration done" "$display_name"
}

main() {
    local canonical_id="$1"
    local raw_install_path="$2"
    local product_name="$3"
    local product_keyword="$4"
    local tag="install:$canonical_id"
    local module_id="${canonical_id##*/}"
    local install_path

    load_states "$canonical_id" || return $?
    tlog_info "$tag" "Begin %s installation" "$product_name"
    install_path="$(expand_path "$raw_install_path")" || return $?

    stateful_extract_install \
        "$canonical_id" \
        "JETBRAINS_ARCHIVE_FILE" \
        "tar.gz" \
        "$install_path" \
        "bin/$module_id" \
        "$module_id" \
        -- \
        "--strip-components=1" || return $?

    __install_desktop_entry \
        "$canonical_id" \
        "$module_id" \
        "$install_path" \
        "$product_name" \
        "$product_keyword"
}
