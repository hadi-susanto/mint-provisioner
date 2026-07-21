#!/usr/bin/env bash
set -euo pipefail

# Check whether the font directory exists for the specified NERD_FONT_FAMILY
font_family="${NERD_FONT_FAMILY:-Inconsolata}"
font_dir="/usr/local/share/fonts/nerd-font/${font_family}"

if [[ -d "$font_dir" ]]; then
    exit 0
fi

exit 1
