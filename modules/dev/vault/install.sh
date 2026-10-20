#!/usr/bin/env bash
set -euo pipefail

source "$LIB_COMMON/common.sh"
source "$LIB_INSTALLER/messages.sh"
source "$LIB_INSTALLER/path.sh"
source "$LIB_INSTALLER/registry.sh"
source "$LIB_INSTALLER/symlink.sh"
source "$LIB_WORKFLOW/stateful-extractor.sh"

install_path="$(expand_path "${VAULT_INSTALL_DIR:-$INSTALL_DIR/vault}")" || exit $?
data_path="$(expand_path "${VAULT_DATA_DIR:-$install_path/data}")" || exit $?
binary="$install_path/bin/vault"
config_file="$install_path/server.json"
__tag="install:$CANONICAL_ID"

if ! mkdir -p -- "$install_path/bin" "$data_path"; then
    tlog_error "$__tag" "Failed to create the installation or data directory"

    exit 1
fi

stateful_extract "$CANONICAL_ID" "ARCHIVE_FILE" "zip" "$install_path/bin" || exit $?

if ! chmod +x "$binary"; then
    tlog_error "$__tag" "Failed to make Vault executable: %s" "$binary"

    exit 1
fi

# Vault locks its memory (mlockall); an unprivileged process needs CAP_IPC_LOCK for that. The capability is lost
# whenever the binary is replaced, so it is granted on every install.
tlog_info "$__tag" "Granting cap_ipc_lock to %s" "$binary"

if ! sudo setcap cap_ipc_lock=+ep "$binary"; then
    tlog_error "$__tag" "Failed to grant cap_ipc_lock to %s" "$binary"

    exit 1
fi

# Generated files are overwritten on every install and reinstall.
cat >"$config_file" <<CONFIG
{
  "storage": {
    "file": {
      "path": "${data_path}"
    }
  },
  "listener": [
    {
      "tcp": {
        "address": "127.0.0.1:8200",
        "tls_disable": true
      }
    }
  ],
  "api_addr": "http://127.0.0.1:8200",
  "default_lease_ttl": "168h",
  "max_lease_ttl": "720h",
  "ui": true
}
CONFIG

content="$(cat <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

binary="@BINARY@"
config_file="@CONFIG@"

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

if [[ "${1:-}" == "server" ]]; then
    shift

    for argument in "$@"; do
        case "$argument" in
            -config | -config=* | --config | --config=* | -dev | --dev)
                exec "$binary" server "$@"
                ;;
        esac
    done

    exec "$binary" server -config="$config_file" "$@"
fi

exec "$binary" "$@"
WRAPPER
)"
content="${content//@BINARY@/$binary}"
content="${content//@CONFIG@/$config_file}"
printf '%s\n' "$content" >"$install_path/vault"
chmod 755 "$install_path/vault"
symlink_binary "$CANONICAL_ID" "$install_path/vault" "vault" || exit $?

content="$(cat <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

# A single unseal key is enough: the share count and threshold are fixed when Vault is initialized.
export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

exec "@BINARY@" operator init -key-shares=1 -key-threshold=1 "$@"
WRAPPER
)"
content="${content//@BINARY@/$binary}"
printf '%s\n' "$content" >"$install_path/vault-init"
chmod 755 "$install_path/vault-init"
symlink_binary "$CANONICAL_ID" "$install_path/vault-init" "vault-init" || exit $?

content="$(cat <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

# Local development helper: with no arguments and VAULT_UNSEAL_TOKEN set, unseals with that key.
# The key then appears in the process list; any arguments passed are used as is, and without either the
# key is typed at Vault's hidden prompt.
export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"

if (( $# == 0 )) && [[ -n "${VAULT_UNSEAL_TOKEN:-}" ]]; then
    exec "@BINARY@" operator unseal "$VAULT_UNSEAL_TOKEN"
fi

exec "@BINARY@" operator unseal "$@"
WRAPPER
)"
content="${content//@BINARY@/$binary}"
printf '%s\n' "$content" >"$install_path/vault-unseal"
chmod 755 "$install_path/vault-unseal"
symlink_binary "$CANONICAL_ID" "$install_path/vault-unseal" "vault-unseal" || exit $?

set_registry "INSTALL_PATH" "$install_path" || exit $?
set_registry "DATA_PATH" "$data_path" || exit $?
save_registry "$CANONICAL_ID" || exit $?

message="Vault was installed.

Binary:  $binary
Config:  $config_file
Data:    $data_path

Start:   vault server
Init:    vault-init (once, one unseal key)
Unseal:  vault-unseal (uses VAULT_UNSEAL_TOKEN if set)
UI:      http://127.0.0.1:8200"
add_message "$CANONICAL_ID" "info" "$message"
