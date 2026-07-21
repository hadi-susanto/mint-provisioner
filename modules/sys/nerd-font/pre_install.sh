#!/usr/bin/env bash
set -euo pipefail

source "$LIB_DIR/installer_external.sh"
source "$LIB_DIR/state.sh"

log_info "[$CANONICAL_ID] Creating temporary download file"

if ! download_file="$(mktemp --suffix=.zip)"; then
    log_error "[$CANONICAL_ID] Failed to create temporary file"

    exit 1
fi

if [[ -n "${NERD_FONT_FAMILY:-}" ]]; then
    font_name="$NERD_FONT_FAMILY"
    log_info "[$CANONICAL_ID] Using font family from NERD_FONT_FAMILY: $font_name"
else
    font_name="Inconsolata"
    log_info "[$CANONICAL_ID] Using default font family: $font_name"
fi

regex="${font_name}\.zip$"

log_info "[$CANONICAL_ID] Resolving latest release"

if ! url="$(
    github_find_release \
        "$CANONICAL_ID" \
        ryanoasis \
        nerd-fonts \
        "$regex"
)"; then
    log_error "[$CANONICAL_ID] Failed to resolve latest release"
    log_error "[$CANONICAL_ID] No release asset matched regex: $regex"
    log_error "[$CANONICAL_ID] Please check all available fonts at https://www.nerdfonts.com/font-downloads"
    log_error "[$CANONICAL_ID] You can change the font selection by setting NERD_FONT_FAMILY"
    rm -f "$download_file"

    exit 2
fi

if ! download_file "$CANONICAL_ID" "$url" "$download_file"; then
    log_error "[$CANONICAL_ID] Download failed"
    rm -f "$download_file"

    exit 3
fi

set_state "DOWNLOAD_FILE" "$download_file"
set_state "FONT_NAME" "$font_name"
save_states "$CANONICAL_ID" || exit 4

log_info "[$CANONICAL_ID] Download completed successfully"
