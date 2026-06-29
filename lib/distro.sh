#!/usr/bin/env bash

#
# Load distribution and upstream distribution information.
#
load_release_info() {
    if [[ -n "${__RELEASE_INFO_LOADED:-}" ]]; then
        return 0
    fi

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
    else
        printf '[ERROR] [load_release_info] /etc/os-release not found\n' >&2

        return 1
    fi
    #
    # Linux Mint-specific upstream information.
    #
    if [[ -f /etc/upstream-release/lsb-release ]]; then
        . /etc/upstream-release/lsb-release
    fi

    #
    # Fallback when upstream-release is unavailable.
    #
    if [[ -z "${DISTRIB_CODENAME:-}" ]]; then
        DISTRIB_CODENAME="${UBUNTU_CODENAME:-}"
    fi

    if [[ -z "${DISTRIB_RELEASE:-}" ]]; then
        case "${DISTRIB_CODENAME:-}" in
            resolute) DISTRIB_RELEASE="26.04" ;;
            questing) DISTRIB_RELEASE="25.10" ;;
            plucky)   DISTRIB_RELEASE="25.04" ;;
            oracular) DISTRIB_RELEASE="24.10" ;;
            noble)    DISTRIB_RELEASE="24.04" ;;
            mantic)   DISTRIB_RELEASE="23.10" ;;
            lunar)    DISTRIB_RELEASE="23.04" ;;
            kinetic)  DISTRIB_RELEASE="22.10" ;;
            jammy)    DISTRIB_RELEASE="22.04" ;;
            impish)   DISTRIB_RELEASE="21.10" ;;
            hirsute)  DISTRIB_RELEASE="21.04" ;;
            groovy)   DISTRIB_RELEASE="20.10" ;;
            focal)    DISTRIB_RELEASE="20.04" ;;
            eoan)     DISTRIB_RELEASE="19.10" ;;
            disco)    DISTRIB_RELEASE="19.04" ;;
            cosmic)   DISTRIB_RELEASE="18.10" ;;
            bionic)   DISTRIB_RELEASE="18.04" ;;
            *)
                printf '[WARN]   [load_release_info] Unknown Ubuntu codename: %s\n' \
                    "${DISTRIB_CODENAME:-<empty>}" >&2

                DISTRIB_RELEASE="00.00"
                ;;
        esac
    fi

    readonly VERSION_ID
    readonly VERSION_CODENAME
    readonly DISTRIB_RELEASE
    readonly DISTRIB_CODENAME

    __RELEASE_INFO_LOADED=1
}

#
# Returns Linux Mint version (e.g. 22.3)
#
get_mint_version() {
    load_release_info
    echo "$VERSION_ID"
}

#
# Returns Linux Mint codename (e.g. zara)
#
get_mint_codename() {
    load_release_info
    echo "$VERSION_CODENAME"
}

#
# Returns Ubuntu version (e.g. 24.04)
#
get_ubuntu_version() {
    load_release_info
    echo "$DISTRIB_RELEASE"
}

#
# Returns Ubuntu codename (e.g. noble)
#
get_ubuntu_codename() {
    load_release_info
    echo "$DISTRIB_CODENAME"
}
