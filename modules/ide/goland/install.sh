#!/usr/bin/env bash
set -euo pipefail

source "${MODULES_DIR}/ide/jetbrains.sh"
source "${LIB_DIR}/state.sh"

declare -A product=()

jetbrains_load_product "$CANONICAL_ID" product || exit $?

install_dir="${GOLAND_INSTALL_DIR:-${INSTALL_DIR}/${product[NAME]}}"

load_states "$CANONICAL_ID" || exit $?
archive_file="$(get_state "JETBRAINS_ARCHIVE_FILE")" || exit $?

jetbrains_extract_archive \
    "$CANONICAL_ID" \
    "$install_dir" \
    "$archive_file" || exit $?

jetbrains_integrate_cli \
    "$CANONICAL_ID" \
    "$install_dir" \
    "${product[NAME]}" || exit $?

jetbrains_integrate_desktop \
    "$CANONICAL_ID" \
    "${product[NAME]}" \
    "${product[DISPLAY_NAME]}" \
    "$install_dir" \
    "${product[KEYWORD]}"
