#!/usr/bin/env bash
set -euo pipefail

source "${MODULES_DIR}/ide/jetbrains.sh"
source "${LIB_DIR}/state.sh"

declare -A product=()
declare -A metadata=()
declare -A artifacts=()

jetbrains_load_product "$CANONICAL_ID" product || exit $?
load_states "$CANONICAL_ID" || exit $?

auto_install_jq="$(get_state "JETBRAINS_AUTO_INSTALL_JQ" "false")" || exit $?
auto_install_aria2="$(get_state "JETBRAINS_AUTO_INSTALL_ARIA2" "false")" || exit $?

jetbrains_auto_install_jq "$CANONICAL_ID" "$auto_install_jq" || exit $?
jetbrains_auto_install_aria2 "$CANONICAL_ID" "$auto_install_aria2" || exit $?

jetbrains_extract_metadata \
    "$CANONICAL_ID" \
    "${product[RELEASE_CODE]}" \
    metadata || exit $?

jetbrains_download_artifacts \
    "$CANONICAL_ID" \
    "${metadata[DOWNLOAD_URL]}" \
    "${metadata[CHECKSUM_URL]}" \
    artifacts || exit $?

if ! set_state "JETBRAINS_ARCHIVE_FILE" "${artifacts[ARCHIVE_FILE]}" || \
    ! set_state "JETBRAINS_VERSION" "${metadata[VERSION]}"; then
    jetbrains_cleanup "$CANONICAL_ID" "${artifacts[ARCHIVE_FILE]}"

    exit 1
fi

if ! save_states "$CANONICAL_ID"; then
    jetbrains_cleanup "$CANONICAL_ID" "${artifacts[ARCHIVE_FILE]}"

    exit 1
fi
