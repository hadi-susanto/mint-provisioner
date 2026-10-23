#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/github.sh"
source "$LIB_WORKFLOW/install-target.sh"
source "$LIB_WORKFLOW/stateful-downloader.sh"

regex="kafdrop-.*[.]jar$"
install_dir="${KAFDROP_INSTALL_DIR:-$INSTALL_DIR/kafdrop}"

valid_install_target "$CANONICAL_ID" "$install_dir" "KAFDROP_INSTALL_DIR" || exit $?
declare -A asset=()
github_find_release_asset "$CANONICAL_ID" "obsidiandynamics" "kafdrop" "$regex" asset || exit $?
version="${asset[URL]##*kafdrop-}"
version="${version%.jar}"

set_state "KAFDROP_VERSION" "$version"
stateful_download "$CANONICAL_ID" "BINARY_FILE" "${asset[URL]}" ".jar" 1 "${asset[SHA256]}"
