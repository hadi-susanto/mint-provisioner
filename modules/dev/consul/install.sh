#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/symlink.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"
source "$LIB_WORKFLOW/version-registry.sh"

install_path="$(expand_path "${CONSUL_INSTALL_DIR:-$INSTALL_DIR/consul}")" || exit $?
data_path="$(expand_path "${CONSUL_DATA_DIR:-$install_path/data}")" || exit $?
binary="$install_path/bin/consul"
config_file="$install_path/agent.json"
__tag="install:$CANONICAL_ID"

if ! mkdir -p -- "$install_path/bin" "$data_path"; then
    tlog_error "$__tag" "Failed to create the installation or data directory"

    exit 1
fi

stateful_extract "$CANONICAL_ID" "ARCHIVE_FILE" "zip" "$install_path/bin" || exit $?

if ! chmod +x "$binary"; then
    tlog_error "$__tag" "Failed to make Consul executable: %s" "$binary"

    exit 1
fi

# Generated files are overwritten on every install and reinstall.
cat >"$config_file" <<CONFIG
{
  "datacenter": "dc1",
  "node_name": "local-dev-node",
  "server": true,
  "bootstrap_expect": 1,
  "data_dir": "${data_path}",
  "ui_config": {
    "enabled": true
  },
  "bind_addr": "127.0.0.1"
}
CONFIG

content="$(cat <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

binary="@BINARY@"
config_file="@CONFIG@"

if [[ "${1:-}" == "agent" ]]; then
    shift

    for argument in "$@"; do
        case "$argument" in
            -config-file | -config-file=* | --config-file | --config-file=* | \
                -config-dir | -config-dir=* | --config-dir | --config-dir=*)
                exec "$binary" agent "$@"
                ;;
        esac
    done

    exec "$binary" agent -config-file="$config_file" "$@"
fi

exec "$binary" "$@"
WRAPPER
)"
content="${content//@BINARY@/$binary}"
content="${content//@CONFIG@/$config_file}"
printf '%s\n' "$content" >"$install_path/consul"
chmod 755 "$install_path/consul"
symlink_binary "$CANONICAL_ID" "$install_path/consul" "consul" || exit $?

set_registry "INSTALL_PATH" "$install_path" || exit $?
set_registry "DATA_PATH" "$data_path" || exit $?
save_registry "$CANONICAL_ID" || exit $?
record_version_registry "$CANONICAL_ID"

message="Consul was installed.

Binary:  $binary
Config:  $config_file
Data:    $data_path

Start it with:  consul agent
UI:  http://127.0.0.1:8500"
add_message "$CANONICAL_ID" "info" "$message"
