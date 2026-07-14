#!/usr/bin/env bash

source "${LIB_DIR}/common.sh"
source "$LIB_DIR/state.sh"

load_states "$CANONICAL_ID" || log_warn "[$CANONICAL_ID] Failed to load states. Falling back to default values."

for binary in \
    mkvextract \
    mkvinfo \
    mkvmerge \
    mkvpropedit
do
    command -v "$binary" >/dev/null 2>&1 || exit 1
done

if [[ "$(get_state "MKVTOOLNIX_GUI_ENABLED" "false")" == "true" ]]; then
    command -v "mkvtoolnix-gui" >/dev/null 2>&1 || exit 1
fi

exit 0
