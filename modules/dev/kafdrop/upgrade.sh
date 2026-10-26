#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_WORKFLOW/dev/kafdrop/installer.sh"
source "$LIB_WORKFLOW/version-registry.sh"

tag="upgrade:$CANONICAL_ID"
old_version=""

load_states "$CANONICAL_ID" || exit 1
new_version="$(get_state "KAFDROP_VERSION")" || exit $?

if ! load_registry "$CANONICAL_ID" || ! install_path="$(get_registry "INSTALL_PATH")"; then
    tlog_error "$tag" "Installation path is not recorded in the registry"

    exit 1
fi

if has_registry "KAFDROP_VERSION"; then
    old_version="$(get_registry "KAFDROP_VERSION")" || exit $?
fi

kafdrop_install_jar "$CANONICAL_ID" "$install_path" || exit $?

# The wrapper expects exactly one jar, so drop the previous release first.
old_jar="$install_path/kafdrop-${old_version}.jar"
if [[ -n "$old_version" && "$old_version" != "$new_version" && -f "$old_jar" ]]; then
    rm -f -- "$old_jar" || exit $?
fi

kafdrop_write_wrapper "$CANONICAL_ID" "$install_path" || exit $?

save_registry "$CANONICAL_ID" || exit $?
record_version_registry "$CANONICAL_ID"
