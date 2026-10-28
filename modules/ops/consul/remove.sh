#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/data.sh"

remove_symlink "$CANONICAL_ID" "consul" || exit $?

install_path=""
data_path=""

if load_registry "$CANONICAL_ID" silent; then
    install_path="$(get_registry INSTALL_PATH)" || install_path=""
    data_path="$(get_registry DATA_PATH)" || data_path=""
fi

# The data directory lives inside the installation directory by default. Without purge, remove everything else and
# keep the data; the registry is marked so a later mp purge can still find it.
if [[ "${PURGE:-false}" != "true" && -n "$install_path" && "$install_path" == /* &&
    "$data_path" == "$install_path/"* && -d "$data_path" ]]; then
    tlog_info "remove:$CANONICAL_ID" "Removing %s but keeping the data directory" "$install_path"

    rm -rf -- "$install_path/bin" "$install_path/agent.json" "$install_path/consul" || exit $?
    add_message "$CANONICAL_ID" info "Data directory kept: $data_path. Use 'mp purge' to delete it." || true

    if ! set_registry DATA_RETAINED 1 || ! save_registry "$CANONICAL_ID"; then
        tlog_warn "remove:$CANONICAL_ID" "Failed to mark the registry as retaining data; mp purge may not find it"
    fi

    exit 0
fi

remove_install_dir "$CANONICAL_ID" || exit $?

if [[ -n "$data_path" ]]; then
    remove_data_dir "$CANONICAL_ID" "$data_path"
fi
