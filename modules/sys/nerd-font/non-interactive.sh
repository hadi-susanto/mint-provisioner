#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

raw_families="${NERD_FONT_FAMILIES:-${NERD_FONT_FAMILY:-}}"

if [[ -z "$raw_families" ]]; then
    tlog_error "non-interactive:$CANONICAL_ID" \
        "Set NERD_FONT_FAMILIES or NERD_FONT_FAMILY to at least one font family"

    exit 1
fi

resolve_font_families "$raw_families" || exit $?

save_states "$CANONICAL_ID"
