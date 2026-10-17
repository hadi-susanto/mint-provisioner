#!/usr/bin/env bash
set -euo pipefail

source "$LIB_WORKFLOW/$CANONICAL_ID/debconf.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"
source "$LIB_INSTALLER/prompt.sh"

tag="interactive:$CANONICAL_ID"

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

root_password="$(
    ask_password "MySQL root password (leave empty to log in as root with 'sudo mysql')"
)" || exit $?

preseed_mysql_root_password "$CANONICAL_ID" "$root_password" || exit $?

save_states "$CANONICAL_ID"
