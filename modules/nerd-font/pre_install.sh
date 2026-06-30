#!/usr/bin/env bash

#
# Pre-install phase for Nerd Font.
#
# Actions:
#   1. Create a temporary file to hold the zip archive.
#   2. Resolve the latest release from GitHub (ryanoasis/nerd-fonts).
#   3. Persist the temporary file path into the module state file.
#   4. Download the package into the temporary file.
#
# Environment:
#   NERD_FONT_FAMILY
#       Optional font family name to install.
#       Defaults to Inconsolata.
#
# State:
#   Writes the download path to:
#       ${STATE_DIR}/nerd-font.path
#   Writes the font name to:
#       ${STATE_DIR}/nerd-font.name
#

source "$LIB_DIR/installer_external.sh"

MODULE="nerd-font"
STATE_FILE="$STATE_DIR/nerd-font.path"

log_info "[$MODULE] Creating temporary download file"

if ! download_file="$(mktemp --suffix=.zip)"; then
    log_error "[$MODULE] Failed to create temporary file"

    exit 1
fi

if [[ -n "${NERD_FONT_FAMILY:-}" ]]; then
    font_name="$NERD_FONT_FAMILY"
    log_info "[$MODULE] Using font family from NERD_FONT_FAMILY: $font_name"
else
    font_name="Inconsolata"
    log_info "[$MODULE] Using default font family: $font_name"
fi

regex="${font_name}\.zip$"

log_info "[$MODULE] Resolving latest release"

if ! url="$(
    github_find_release \
        "$MODULE" \
        ryanoasis \
        nerd-fonts \
        "$regex"
)"; then
    log_error "[$MODULE] Failed to resolve latest release"
    log_error "[$MODULE] No release asset matched regex: $regex"
    log_error "[$MODULE] Please check all available fonts at https://www.nerdfonts.com/font-downloads"
    log_error "[$MODULE] You can change the font selection by setting NERD_FONT_FAMILY"
    rm -f "$download_file"

    exit 2
fi

log_info "[$MODULE] Creating state file: $STATE_FILE"

if ! printf '%s\n' "$download_file" > "$STATE_FILE"; then
    log_error "[$MODULE] Failed to create state file"
    rm -f "$download_file"

    exit 3
fi

if ! download_file "$MODULE" "$url" "$download_file"; then
    log_error "[$MODULE] Download failed"
    rm -f "$STATE_FILE"
    rm -f "$download_file"

    exit 4
fi

log_info "[$MODULE] Writing font name to state file: $font_name"
echo "$font_name" > "${STATE_DIR}/nerd-font.name"

log_info "[$MODULE] Download completed successfully"
