#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/debconf.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"
source "$LIB_INSTALLER/prompt.sh"

tag="interactive:$CANONICAL_ID"

ensure_no_distro_mysql_server "$CANONICAL_ID" || exit $?

selected_index="$(
    choose_option \
        "Which MySQL Server series do you want to install?" \
        "MySQL 9.7 LTS (default)" \
        "MySQL 8.4 LTS" \
        "MySQL Innovation"
)" || exit $?

case "$selected_index" in
    0)
        resolve_mysql_series "mysql-9.7-lts"
        ;;
    1)
        resolve_mysql_series "mysql-8.4-lts"
        ;;
    2)
        resolve_mysql_series "mysql-innovation"
        ;;
    *)
        tlog_error "$tag" \
            "Unexpected MySQL series selection index: %s" "$selected_index"

        exit 1
        ;;
esac

if mysql_data_dir_exists; then
    tlog_warn "$tag" "Existing /var/lib/mysql found; its root credentials are kept"
    set_state "MYSQL_ROOT_LOGIN" "existing"
    save_states "$CANONICAL_ID"

    exit $?
fi

while true; do
    root_password="$(
        ask_password "MySQL root password (leave empty to log in as root with 'sudo mysql')"
    )" || exit $?

    if validate_mysql_root_password "$root_password"; then
        break
    fi
done

# A non-empty password is preseeded here so it is never written to the state
# file; an empty one is preseeded in pre-install, after sudo is cached.
if [[ -z "$root_password" ]]; then
    set_state "MYSQL_ROOT_LOGIN" "socket"
else
    preseed_mysql_root_password "$CANONICAL_ID" "$root_password" || exit $?
    set_state "MYSQL_ROOT_LOGIN" "password"
fi

save_states "$CANONICAL_ID"
