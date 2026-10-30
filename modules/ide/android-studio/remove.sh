#!/usr/bin/env bash
set -euo pipefail

source "$LIB_REMOVER/binary.sh"
source "$LIB_REMOVER/desktop.sh"
source "$LIB_REMOVER/home.sh"

remove_desktop_entry "$CANONICAL_ID" "android-studio" || exit $?
remove_symlink "$CANONICAL_ID" "android-studio" || exit $?
remove_install_dir "$CANONICAL_ID" || exit $?

# Per-version directories such as AndroidStudio2026.2; the SDK and shared Google dirs stay.
declare -A version_dirs=()

for root in "$HOME/.config/Google" "$HOME/.cache/Google" "$HOME/.local/share/Google"; do
    for dir in "$root"/AndroidStudio*; do
        if [[ -d "$dir" ]]; then
            version_dirs["Google/${dir##*/}"]=1
        fi
    done
done

if (( ${#version_dirs[@]} > 0 )); then
    purge_home_paths "$CANONICAL_ID" "${!version_dirs[@]}"
fi
