#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/state.sh"
source "$LIB_INSTALLER/symlink.sh"
source "$LIB_WORKFLOW/dev/kafdrop/installer.sh"
source "$LIB_WORKFLOW/version-registry.sh"

load_states "$CANONICAL_ID" || exit 1
install_path="$(expand_path "${KAFDROP_INSTALL_DIR:-$INSTALL_DIR/kafdrop}")" || exit $?

kafdrop_install_jar "$CANONICAL_ID" "$install_path" || exit $?
kafdrop_write_wrapper "$CANONICAL_ID" "$install_path" || exit $?
symlink_binary "$CANONICAL_ID" "$install_path/kafdrop" || exit $?
install_desktop_entry "$CANONICAL_ID" "kafdrop" "Kafdrop" "$install_path/kafdrop" \
    --exec-args "--gui" \
    --try-exec "$install_path/kafdrop" \
    --terminal 1 \
    --comment "Web UI for browsing and monitoring Kafka clusters" \
    --icon-file "$MP_MODULES/$CANONICAL_ID/payload/kafdrop.svg" \
    --categories "Development;Network;" \
    --keywords "Kafka;Kafdrop;Topics;Broker;" || exit $?

save_registry "$CANONICAL_ID" || exit $?
record_version_registry "$CANONICAL_ID"

add_message "$CANONICAL_ID" "info" "The Kafdrop launcher opens a terminal and asks for the Kafka bootstrap server and port."

if ! command -v java >/dev/null 2>&1; then
    add_message "$CANONICAL_ID" "warn" "Java is required to run Kafdrop, please install one."
fi
