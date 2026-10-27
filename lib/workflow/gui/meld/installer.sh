#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_MELD_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_MELD_INSTALLER_LOADED=1

source "$LIB_COMMON/common.sh"

##
# meld_compile_runtime_data <canonical_id> <install_path>
#
# Compiles the GResource bundle, GSettings schema, and translations that Meld otherwise builds
# on first launch when it runs from its source directory. Used by install and upgrade.
#
# Parameters:
#   canonical_id - Canonical module ID used for tagged logging.
#   install_path - Meld clone directory.
#
# Return:
#   1 - The GResource bundle or GSettings schema cannot be compiled.
#
meld_compile_runtime_data() {
    local canonical_id="$1"
    local install_path="$2"
    local tag="install:$canonical_id"
    local po_file
    local language
    local mo_dir

    tlog_info "$tag" "Compiling Meld resources and settings schema"
    if ! glib-compile-resources \
        --target="$install_path/data/org.gnome.Meld.gresource" \
        --sourcedir="$install_path/meld/resources" \
        --sourcedir="$install_path/data/icons/hicolor" \
        "$install_path/meld/resources/meld.gresource.xml"; then
        tlog_error "$tag" "Failed to compile Meld resources"

        return 1
    fi

    if ! glib-compile-schemas "$install_path/data"; then
        tlog_error "$tag" "Failed to compile Meld settings schema"

        return 1
    fi

    tlog_info "$tag" "Compiling Meld translations"
    for po_file in "$install_path"/po/*.po; do
        [[ -f "$po_file" ]] || continue

        language="$(basename -- "$po_file" .po)"
        mo_dir="$install_path/build/mo/$language/LC_MESSAGES"
        if ! mkdir -p "$mo_dir" || ! msgfmt -o "$mo_dir/meld.mo" "$po_file"; then
            tlog_warn "$tag" "Failed to compile translation: %s" "$language"
        fi
    done
}
