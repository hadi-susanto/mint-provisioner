#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/apt.sh"
source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_INSTALLER/git-clone.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/symlink.sh"
source "$LIB_WORKFLOW/gui/meld/installer.sh"

declare -r REPOSITORY="https://gitlab.gnome.org/GNOME/meld.git"
# Last stable GTK 3 branch; main targets GTK 4 and libadwaita 1.6, which Linux Mint 22 does not provide.
declare -r BRANCH="meld-3-24"

__ensure_runtime_dependencies() {
    local canonical_id="$1"
    local tag="python-dep:$canonical_id"

    if ! apt_install "$canonical_id" \
        "python3-gi" "python3-gi-cairo" "python3-cairo" "gir1.2-gtk-3.0" "gir1.2-gtksource-4" \
        "gsettings-desktop-schemas" "libglib2.0-bin" "libglib2.0-dev-bin" "gettext"; then
        tlog_error "$tag" "Failed to install Python or GTK runtime dependencies"

        return 1
    fi

    if ! python3 -c '
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkSource", "4")
gi.require_foreign("cairo")
' >/dev/null 2>&1; then
        tlog_error "$tag" "Failed to load the required Python modules: gi, cairo, Gtk 3.0 and GtkSource 4"

        return 1
    fi
}

main() {
    local canonical_id="$1"
    local install_path

    install_path="$(expand_path "$2")" || return $?
    __ensure_runtime_dependencies "$canonical_id" || return $?
    git_clone "$canonical_id" "$REPOSITORY" "$install_path" "bin/meld" "meld.doap" -- --branch "$BRANCH" || return $?
    symlink_binary "$canonical_id" "$install_path/bin/meld" "meld" || return $?
    set_registry "INSTALL_PATH" "$install_path" || return $?
    save_registry "$canonical_id" || return $?
    meld_compile_runtime_data "$canonical_id" "$install_path" || return $?
    install_desktop_entry "$canonical_id" "meld" "Meld" "meld" \
        --exec-args "%F" \
        --try-exec "meld" \
        --generic-name "Diff Viewer" \
        --comment "Compare and merge your files" \
        --icon-file "$install_path/data/icons/hicolor/scalable/apps/org.gnome.Meld.svg" \
        --startup-wm-class "org.gnome.Meld" \
        --startup-notify 1 \
        --categories "GTK;Development;" \
        --keywords "diff;merge;"
}

main "$CANONICAL_ID" "${MELD_INSTALL_DIR:-$INSTALL_DIR/meld}"
