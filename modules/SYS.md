# ⚙️ System (`sys`)

System utilities, machine setup, performance tools, fonts, and operating system configuration. Modules in this category help configure, maintain, and optimize the operating system, including tools such as **apt-fast**, **Nerd Fonts**, and your opinionated **OOBE** configuration.

## Contents

- [Apt Fast](#apt-fast-apt-fast)
- [Dconf Editor](#dconf-editor-dconf-editor)
- [DNSCrypt Proxy](#dnscrypt-proxy-dnscrypt-proxy-alias-dnscrypt)
- [Nerd Fonts](#nerd-fonts-nerd-font)
- [Out of the Box Experience](#out-of-the-box-experience-oobe)

---

## Apt Fast (`apt-fast`)

Apt Fast is a wrapper around APT that accelerates package downloads by utilizing multiple concurrent connections. It is particularly useful when installing or upgrading a large number of packages.

### Installation Method

**Launchpad PPA**

The installer configures the official Apt Fast Launchpad PPA before installing the package using APT.

### Supported ENV

- `APT_FAST_PACKAGE_MANAGER`
    - Package manager used by apt-fast.
    - Supported values: `apt-get`, `apt`, and `aptitude`.
    - Default: `apt-get`

- `APT_FAST_MAX_CONNECTION`
    - Maximum number of simultaneous download connections.
    - Supported values: integers from `1` to `10`.
    - Default: `5`

- `APT_FAST_SUPPRESS_CONFIRM_DIALOG`
    - Controls whether apt-fast's confirmation dialog is suppressed.
    - Supported values: `true` and `false`.
    - Default: `false`

- `APT_FAST_NON_INTERACTIVE`
    - Disables apt-fast configuration prompts.
    - Falls back to the global `NON_INTERACTIVE` value.
    - Missing configuration values use their documented defaults.
    - Default: `${NON_INTERACTIVE}`

- `APT_FAST_USE_APT_ADD_REPOSITORY`
    - Controls whether the Launchpad repository is added using `add-apt-repository`.
    - Default: `${USE_APT_ADD_REPOSITORY}`

- `APT_FAST_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `APT_FAST_FORCE_CONFIGURATION`
    - Overwrite existing shell completion files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Shell Completion

The following shell completions are installed automatically:

- Bash completion (`/etc/bash_completion.d/apt-fast`)
- Zsh completion (`/usr/share/zsh/functions/Completion/Debian/_apt-fast`)

Existing completion files are preserved unless `APT_FAST_FORCE_CONFIGURATION=true` is specified.

### Official Website

https://github.com/ilikenwf/apt-fast

---

## Dconf Editor (`dconf-editor`)

Dconf Editor is a graphical tool for viewing and modifying low-level desktop environment settings stored in the dconf
configuration database.

> **Warning:** Dconf Editor exposes settings that may not be available through the regular system settings interface.
> Invalid changes can cause unexpected desktop behavior.

### Installation Method

**Native distribution package**

Installs the `dconf-editor` package from the Linux Mint or Ubuntu distribution repository using APT.

After installation, the provisioner displays a reminder that Linux Mint battery settings are available under:

```text
/org/cinnamon/settings-daemon/plugins/power/
```

### Official Website

https://apps.gnome.org/DconfEditor/

---

## DNSCrypt Proxy (`dnscrypt-proxy`) [alias: `dnscrypt`]

DNSCrypt Proxy is a local DNS proxy supporting encrypted DNS protocols, including DNSCrypt and DNS-over-HTTPS. It can
protect DNS queries from interception and use DNS providers that offer filtering or system-wide domain blocking.

### Installation Method

**Native distribution package**

Installs the `dnscrypt-proxy` package from the Linux Mint or Ubuntu distribution repository using APT.

### Supported ENV

- `DNSCRYPT_PROXY_SKIP_CONFIGURATION`
    - Skip post-install service adjustments and summary guidance.
    - Default: `${SKIP_CONFIGURATION}`

### Post-install Configuration

If `dnscrypt-proxy-resolvconf.service` cannot start because `/sbin/resolvconf` is unavailable, the module disables that
service. DNSCrypt Proxy can still operate through its systemd socket.

After installation, check the socket configuration with:

```bash
systemctl cat dnscrypt-proxy.socket
```

Use the address specified by ListenStream and ListenDatagram as the DNS server in the system network configuration.
This is commonly 127.0.0.1 or 127.0.2.1.

The main DNSCrypt Proxy configuration is located at:

```bash
/etc/dnscrypt-proxy/dnscrypt-proxy.toml
```

The `server_names` setting can be changed to select a preferred DNS or ad-blocking provider.

---

## Nerd Fonts (`nerd-font`)

Nerd Fonts provides patched developer fonts containing thousands of additional glyphs used by modern terminal prompts, CLI applications, editors, and programming tools.

**IMPORTANT:** This module does not support `INSTALL_DIR` environment variable, it will install the fonts into the system font directory.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads selected font archives from the official Nerd Fonts project, extracts the fonts into the system font directory (`/usr/local/share/fonts`), and refreshes the font cache.
The installer will create folder for each font family, eg: `/usr/local/share/fonts/nerd-font/Inconsolata`, the folder name is the font family name.

### Supported ENV

- `NERD_FONT_FAMILY`
    - Font family to install.
    - Default: `Inconsolata`.

### Post-install Configuration

#### Installed Configuration

- Installs the selected fonts into `/usr/local/share/fonts/nerd-font/<family>`.
- Refreshes the font cache automatically using `fc-cache`.

### Official Website

https://www.nerdfonts.com/

---

## Out of the Box Experience (`oobe`)

OOBE applies the opinionated Linux Mint configuration used by this provisioner. Rather than installing a standalone application, this module configures the operating system to provide a consistent and productive desktop environment.

It's recommended to run this module after fresh installation of Linux Mint via `configure.sh`.

### Installation Method

**Internal module**

This module is part of the provisioner itself and does not download or install software from an external source.

### Supported ENV

- `OOBE_SKIP_CONFIGURATION`
    - Skip all OOBE post-install configuration payloads.
    - Default: `${SKIP_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

The module applies the provisioner's recommended Linux Mint configuration, including desktop preferences, system settings, and other operating system customizations.

### Official Website

This module is maintained as part of the Linux Mint Provisioner project.
