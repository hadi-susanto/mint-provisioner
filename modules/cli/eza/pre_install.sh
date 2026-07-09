#!/usr/bin/env bash

source "$LIB_DIR/installer_apt.sh"

install_asc_key \
    "eza" \
    "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc" \
    "http://deb.gierens.de" \
    "stable" \
    "main"
