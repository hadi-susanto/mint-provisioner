#!/usr/bin/env bash
set -euo pipefail

source "$LIB_INSTALLER/detection.sh"
source "$LIB_WORKFLOW/$CANONICAL_ID/resolver.sh"

mysql_tools_connector="${MYSQL_TOOLS_CONNECTOR:-}"
tag="interactive:$CANONICAL_ID"

if [[ -n "$mysql_tools_connector" ]]; then
    if resolve_mysql_tools_connector "$mysql_tools_connector"; then
        save_states "$CANONICAL_ID" || exit $?

        exit 0
    fi

    tlog_warn "$tag" "Fallback to interactive session: invalid MYSQL_TOOLS_CONNECTOR value."
fi

source "$LIB_INSTALLER/prompt.sh"

connectors=(java python odbc cpp)
packages=(mysql-connector-j mysql-connector-python-py3 mysql-connector-odbc libmysqlcppconn-dev)
labels=(
    "Connector/J (Java)"
    "Connector/Python"
    "Connector/ODBC"
    "Connector/C++"
)

# Mark connectors that are already installed; choosing one again reinstalls it.
for index in "${!packages[@]}"; do
    if package_installed "$CANONICAL_ID" "${packages[$index]}"; then
        labels[$index]+=" (installed)"
    fi
done

selected_index="$(
    choose_option "Which MySQL connector do you want to install?" "${labels[@]}"
)" || exit $?

if [[ ! "$selected_index" =~ ^[0-3]$ ]]; then
    tlog_error "$tag" "Unexpected MySQL connector selection index: %s" "$selected_index"

    exit 1
fi

resolve_mysql_tools_connector "${connectors[$selected_index]}" || exit $?
save_states "$CANONICAL_ID"
