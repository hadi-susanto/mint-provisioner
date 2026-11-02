#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/desktop-integration.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/symlink.sh"
source "$LIB_WORKFLOW/dev/kafka/installer.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"
source "$LIB_WORKFLOW/version-registry.sh"

tag="install:$CANONICAL_ID"
install_path="$(expand_path "${KAFKA_INSTALL_DIR:-$INSTALL_DIR/kafka}")" || exit $?

stateful_extract \
    "$CANONICAL_ID" \
    "ARCHIVE_FILE" \
    "tar" \
    "$install_path" \
    "--strip-components=1" || exit $?

kafka_configure_log_dirs "$CANONICAL_ID" "$install_path" || exit $?
kafka_install_wrappers "$CANONICAL_ID" "$install_path" || exit $?
symlink_binary "$CANONICAL_ID" "$install_path/kafka-server" || exit $?
symlink_binary "$CANONICAL_ID" "$install_path/kafka-initialize" || exit $?
install_desktop_entry "$CANONICAL_ID" "kafka" "Apache Kafka" "$install_path/kafka-server" \
    --exec-args "--gui" \
    --try-exec "$install_path/kafka-server" \
    --terminal 1 \
    --comment "Run a local Apache Kafka broker" \
    --icon-file "$MP_MODULES/$CANONICAL_ID/payload/kafka.png" \
    --icon-size "512x512" \
    --categories "Development;" \
    --keywords "Kafka;Broker;KRaft;Streaming;" \
    --action "Stop|Stop Kafka|--gui --stop" \
    --action "Initialize|Re-initialize Storage|--gui --initialize" || exit $?
add_to_path "$CANONICAL_ID" "$install_path/bin" || exit $?
set_registry "INSTALL_PATH" "$install_path" || exit $?
save_registry "$CANONICAL_ID" || exit $?
record_version_registry "$CANONICAL_ID"

if command -v java >/dev/null 2>&1; then
    tlog_info "$tag" "Formatting Kafka storage"
    "$install_path/kafka-initialize" --yes || exit $?
else
    message="Java 17+ is required to run Apache Kafka; the storage is formatted on the first 'kafka-server' run"
    tlog_warn "$tag" "%s" "$message"
    add_message "$CANONICAL_ID" warn "$message"
fi

message="Apache Kafka was installed.

Bootstrap server:  localhost:9092
Data:              $install_path/kraft-combined-logs

Start it with:     kafka-server (or kafka-server --daemon / --stop)
Reset the data:    kafka-initialize"
add_message "$CANONICAL_ID" info "$message"
