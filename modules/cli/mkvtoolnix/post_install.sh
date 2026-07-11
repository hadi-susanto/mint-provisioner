#!/usr/bin/env bash

#
# Mkvtoolnix post-installation tasks
#

source "${LIB_DIR}/installer_common.sh"

MODULE="mkvtoolnix"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ "${MKVTOOLNIX_SKIP_CONFIGURATION:-${SKIP_CONFIGURATION:-false}}" == "true" ]]; then
    log_warn "[$MODULE] MKVTOOLNIX_SKIP_CONFIGURATION is set to true, skipping configuration"

    return 0
fi

if [[ -z "${MKVTOOLNIX_FORCE_CONFIGURATION:-}" ]]; then
    MKVTOOLNIX_FORCE_CONFIGURATION="${FORCE_CONFIGURATION:-false}"
fi

#
# Copy payloads
#
for file in "$PAYLOAD_DIR"/*; do
    copy_to_config_dir "$MODULE" "$file" "MKVTOOLNIX_FORCE_CONFIGURATION"
done

#
# Since mkvtoolnix will have lots helper, we will create single loader
#
LOADER_FILE="$(get_config_dir)/mkvtoolnix-loader.sh"
CONFIG_DIR="$(get_config_dir)"

__write_loader() {
    cat > "$LOADER_FILE" <<'EOF'
# This is a generated file.
# Please don't modify this file manually.
# Any changes will be overwritten when the mkvtoolnix configuration is run again.

EOF

    for file in "$PAYLOAD_DIR"/*; do
        [[ -f "$file" ]] || continue

        printf '[[ -f %q ]] && source %q\n' \
            "$CONFIG_DIR/$(basename "$file")" \
            "$CONFIG_DIR/$(basename "$file")" \
            >> "$LOADER_FILE"
    done
}

if [[ -f "$LOADER_FILE" ]]; then
    if [[ "$MKVTOOLNIX_FORCE_CONFIGURATION" != true ]]; then
        log_warn "[$MODULE] $LOADER_FILE already exists, to overwrite please pass MKVTOOLNIX_FORCE_CONFIGURATION=true"
    else
        log_warn "[$MODULE] overwrite $LOADER_FILE because of MKVTOOLNIX_FORCE_CONFIGURATION=true"

        __write_loader
    fi
else
    __write_loader
fi

add_bash_source "$MODULE" "$(get_config_dir)/mkvtoolnix-loader.sh"
add_zsh_source "$MODULE" "$(get_config_dir)/mkvtoolnix-loader.sh"

log_info "[$MODULE] MKVToolNix configuration completed"
