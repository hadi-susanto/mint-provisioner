# 🖥️ Desktop Applications (`gui`)

Graphical applications for productivity, file management, security, and everyday desktop workflows.

## Contents

- [avda](#avda-avda)
- [Cryptomator](#cryptomator-cryptomator)
- [DeaDBeeF](#deadbeef-deadbeef)
- [deskOTP](#deskotp-desk-otp)
- [Double Commander](#double-commander-double-commander-alias-db-cmd)
- [Flameshot](#flameshot-flameshot)
- [fman](#fman-fman)
- [Insync](#insync-insync)
- [KeePassXC](#keepassxc-keepass-xc-alias-keepass-alias-keepassxc)
- [Lapce](#lapce-lapce)
- [Meld](#meld-meld)
- [Mu Commander](#mu-commander-mu-commander-alias-mu-cmd)
- [onedriver](#onedriver-onedriver)
- [OTPClient](#otpclient-otpclient)
- [Sunflower](#sunflower-sunflower)
- [TLP UI](#tlp-ui-tlp-ui)

---

## avda (`avda`)

avda is a desktop app for generating and viewing one-time passwords from Aegis Authenticator backups. Open an Aegis
vault export and avda shows the live codes for its entries.

### Installation Method

**GitHub latest release (ZIP)**

Downloads the latest `avda_linux.zip` and the application icon (from the release tag) from the official GitHub
repository, extracts the `avda` binary into the installation directory, links it into the `bin` directory, and creates
a desktop entry.

### Supported ENV

- `AVDA_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/avda`

### Cleanup

- Removes the downloaded archive and icon files.
- Removes the module state file.

### Official Website

https://github.com/Sammy-T/avda

---

## Cryptomator (`cryptomator`)

Cryptomator is an easy-to-use encryption utility for protecting files stored locally or in cloud storage. It creates encrypted vaults that can be transparently mounted when unlocked, making it useful for securely storing sensitive files while remaining compatible with services such as OneDrive, Google Drive, and Dropbox.

### Installation Method

**Launchpad PPA**

Configures the official Cryptomator Launchpad PPA, then installs Cryptomator using APT.

### Supported ENV

- `CRYPTOMATOR_USE_APT_ADD_REPOSITORY`
    - Controls whether the Launchpad repository is added using `add-apt-repository`.
    - Default:
      `${USE_APT_ADD_REPOSITORY}`

### Official Website

https://cryptomator.org/

---

## DeaDBeeF (`deadbeef`)

DeaDBeeF is a lightweight and highly customizable audio player. It supports numerous audio formats, playlists, internet
radio, metadata editing, gapless playback, equalization, and an extensible plugin system.

### Installation Method

**Official website (precompiled archive)**

Locates and downloads the latest Linux x86_64 TAR.BZ2 release from the official DeaDBeeF download page. The module
extracts the standalone application into the configured installation directory and creates a symbolic link for the main
`deadbeef` executable.

### Supported ENV

- `DEADBEEF_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/deadbeef`

### Desktop Integration

- Installs `deadbeef.desktop` into `/usr/share/applications`.
- Registers DeaDBeeF as an audio player for supported audio files, playlists, cue sheets, and directories.
- Adds desktop actions for playing, pausing, stopping, and navigating tracks.
- Uses the bundled DeaDBeeF icon (`deadbeef.png`) from the installation directory.

### Cleanup

- Removes the downloaded TAR.BZ2 archive.
- Removes the module state file.

### Official Website

https://deadbeef.sourceforge.io/

---

## deskOTP (`desk-otp`)

deskOTP is a desktop authenticator for TOTP, HOTP, and Steam Guard codes. It can import tokens from Aegis, 2FAS, andOTP,
Authy, Google Authenticator, and other apps.

### Installation Method

**GitHub latest release (.deb)**

Downloads the latest `deskotp_*_amd64.deb` package from the official GitHub releases page, stores the downloaded package path in a module state file, then installs the package using APT.

### Cleanup

- Removes the downloaded `.deb` package.
- Removes the module state file.

### Official Website

https://github.com/extricator/deskOTP

---

## Double Commander (`double-commander`) [alias: `db-cmd`]

Double Commander is a cross-platform dual-pane file manager inspired by Total Commander. It includes built-in archive support, batch renaming, advanced search, internal viewers, and extensive keyboard shortcuts for efficient file management.

### Installation Method

**External APT repository**

Configures the Double Commander repository from the openSUSE Build Service, then installs the selected Double Commander GUI package using APT.

### Supported ENV

- `DOUBLE_COMMANDER_UI_TOOLKIT`
    - Double Commander GUI package variant to install.
    - Supported values: `auto`, `gtk`, `qt` (will be treated as `qt5`), `qt5`, `qt6`
    - Default:
      `auto`

### Official Website

https://doublecmd.sourceforge.io/

---

## Flameshot (`flameshot`)

Flameshot is a powerful screenshot application featuring an interactive annotation interface. It allows users to capture, edit, annotate, blur sensitive information, and save screenshots without requiring a separate image editor.

### Installation Method

**GitHub latest release (.deb)**

Downloads the latest Ubuntu-specific AMD64 release asset from the official GitHub releases page. If the matched asset is a ZIP file, the installer extracts the `.deb` package from it, then installs the package using APT.

### Cleanup

- Removes the downloaded `.deb` package.
- Removes the module state file.

### Official Website

https://flameshot.org/

---

## fman (`fman`)

fman is an open-source, cross-platform dual-pane file manager designed for efficient keyboard-driven workflows. It
provides fast directory navigation, a Commander-style interface, and extensibility through plugins.

### Installation Method

**GitHub latest release (.deb)**

Locates and downloads the latest Ubuntu x64 Debian package from the official GitHub releases page, stores the downloaded
package path in a module state file, then installs the package using APT.

### Cleanup

- Removes the downloaded `.deb` package.
- Removes the module state file.

### External Source

https://github.com/mherrmann/fman

### Official Website

https://fman.io/

---

## Insync (`insync`)

Insync is a desktop cloud storage client for synchronizing Google Drive, OneDrive, and Dropbox with the local filesystem.
It normally runs in the background after the initial account and synchronization configuration is completed through its
graphical interface.

Insync is commercial software and may require a license after its trial period.

### Installation Method

**Official Insync APT repository**

Adds the vendor-managed Insync repository and signing key for the current Linux Mint release, then installs the `insync`
package using APT.

The module supports AMD64 systems.

### File Manager Integration

Insync provides optional integration packages that display synchronization badges and additional actions in supported
file managers:

| File manager | Package            |
|--------------|--------------------|
| Caja         | `insync-caja`      |
| Dolphin      | `insync-dolphin`   |
| Nautilus     | `insync-nautilus`  |
| Nemo         | `insync-nemo`      |
| Thunar       | `insync-thunar`    |

Linux Mint Cinnamon users will normally want the `insync-nemo` package.

These packages are not installed automatically because the required integration depends on the user's desktop
environment and file manager.

### Official Website

https://www.insynchq.com/

---

## KeePassXC (`keepass-xc`) [alias: `keepass`] [alias: `keepassxc`]

KeePassXC is a modern, cross-platform password manager compatible with the KeePass database format. It securely stores passwords, passkeys, SSH keys, TOTP secrets, and other sensitive information in an encrypted database while providing browser integration and automatic credential filling.

### Installation Method

**Launchpad PPA**

Configures the official KeePassXC Launchpad PPA, then installs KeePassXC using APT.

### Supported ENV

- `KEEPASS_XC_USE_APT_ADD_REPOSITORY`
    - Controls whether the Launchpad repository is added using `add-apt-repository`.
    - Default:
      `${USE_APT_ADD_REPOSITORY}`

### Official Website

https://keepassxc.org/

---

## Lapce (`lapce`)

Lapce is a lightning-fast, open-source code editor written in Rust with a native GPU-rendered UI, built-in LSP
support, remote development, and tree-sitter syntax highlighting.

### Installation Method

**GitHub latest release (.deb)**

Downloads the `.deb` built for the system's Ubuntu base release (for example `noble` on Linux Mint 22, `jammy` on
Linux Mint 21) from the official `lapce/lapce` releases and installs it using APT. Only `x86_64` is supported.

**Tree-sitter grammars and queries**

Lapce normally downloads these on first launch. The module pre-fetches the latest `grammars-linux-x86_64.tar.zst` and
`queries.tar.zst` from `lapce/tree-sitter-grammars` so syntax highlighting works immediately. `zstd` is required.

### Installed Configuration

- Extracts grammars to `~/.local/share/lapce-stable/grammars`.
- Extracts queries to `~/.config/lapce-stable/queries`.

### Desktop Integration

- The `.deb` installs the desktop entry and icon; the module does not create one.

### Official Website

https://lapce.dev/

---

## Meld (`meld`)

Meld is a visual diff and merge tool for developers. It compares two or three files or directories side by side,
supports interactive merging, and integrates with Git and other version control systems.

### Installation Method

**GNOME GitLab repository (source installation, `meld-3-24` branch)**

Performs a shallow clone of the `meld-3-24` branch of the official Meld repository and runs Meld directly from the
clone without a Meson build. The installer precompiles its GResource bundle, GSettings schema, and translations.

`meld-3-24` is the last stable GTK 3 branch. The `main` branch targets GTK 4 and requires libadwaita 1.6, which Linux
Mint 22 (Ubuntu 24.04) does not provide.

The module requires:

- Python 3
- Git

The following runtime packages are installed using APT:

- `python3-gi`, `python3-gi-cairo`, `python3-cairo`
- `gir1.2-gtk-3.0`, `gir1.2-gtksource-4`
- `gsettings-desktop-schemas`
- `libglib2.0-bin`, `libglib2.0-dev-bin` (`glib-compile-schemas`, `glib-compile-resources`)
- `gettext` (`msgfmt` for translations)

### Supported ENV

- `MELD_INSTALL_DIR`
    - Directory where the Meld Git repository is cloned.
    - Default: `${INSTALL_DIR}/meld`

### Installed Configuration

- Creates a symbolic link for `bin/meld` named `meld`.

### Desktop Integration

- Installs `meld.desktop` into `/usr/share/applications`.
- Installs the bundled icon into `/usr/share/icons/hicolor/scalable/apps/meld.svg`.
- Accepts files and directories (`%F`) and registers Meld under the development category.

### Official Website

https://meldmerge.org/

---

## Mu Commander (`mu-commander`) [alias: `mu-cmd`]

Mu Commander is a lightweight, cross-platform dual-pane file manager. It provides a Commander-style interface for file management with support for common file operations, keyboard-driven workflows, archive handling, and multiple storage locations.

### Installation Method

**GitHub latest release (.deb)**

Downloads the latest x86_64 Debian package from the official GitHub releases page, stores the downloaded package path in a module state file, then installs the package using APT.

### Official Website

https://www.mucommander.com/

---

## onedriver (`onedriver`)

onedriver is a native Linux filesystem for Microsoft OneDrive. It mounts your OneDrive as a regular folder and downloads
files on demand, so nothing is stored locally until it is opened. It includes a GTK launcher for managing mounts.

### Installation Method

**External APT repository**

Configures the onedriver repository from the openSUSE Build Service (`home:jstaf`), then installs the `onedriver`
package using APT. The repository path is derived from the detected Ubuntu version, so installation fails if the
repository has no build for that version.

### Supported ENV

None.

### Usage

After installation, start `onedriver-launcher` from the application menu, click `+`, and sign in with your Microsoft
account through the browser.

### Official Website

https://github.com/jstaf/onedriver

---

## OTPClient (`otpclient`)

OTPClient is a GTK desktop application for generating TOTP and HOTP codes. It can import and export Aegis Authenticator
backups, which makes it a convenient desktop companion for tokens kept in Aegis on Android.

### Installation Method

**External APT repository**

Configures the OTPClient repository from the openSUSE Build Service (`home:polslinux:otpclient`), then installs the
`otpclient` package using APT. The repository path is derived from the detected Ubuntu version, so installation fails if
the repository has no build for that version.

### Supported ENV

None.

### Official Website

https://github.com/paolostivanin/OTPClient

---

## Sunflower (`sunflower`)

Sunflower is a highly customizable twin-panel file manager for Linux. It provides a dual-pane interface with plugin support and a workflow focused on efficient desktop file management.

### Installation Method

**GitHub latest release (.deb)**

Downloads the latest Debian package from the official GitHub releases page, stores the downloaded package path in a module state file, then installs the package using APT.

### Official Website

https://github.com/MeanEYE/Sunflower

---

## TLP UI (`tlp-ui`)

TLP UI is a GTK-based graphical interface for viewing and editing TLP power-management configuration. It provides an
easier way to inspect available TLP settings, modify configuration values, and view TLP status information.

### Installation Method

**GitHub repository (source installation)**

Installs the required Python and GTK runtime packages, then performs a shallow clone of the official TLPUI GitHub
repository.

The module requires:

- Python 3.10 or newer
- Git
- An existing TLP installation

The following runtime packages are installed using APT:

- `python3-gi`
- `python3-yaml`
- `python3-toml`
- `gir1.2-gtk-3.0`

### Supported ENV

- `TLP_UI_INSTALL_DIR`
    - Directory where the TLPUI Git repository is cloned.
    - Default: `${INSTALL_DIR}/tlp-ui`

### Installed Configuration

- Creates `/usr/local/bin/tlp-ui`.
- The launcher changes to the TLPUI installation directory and executes:

```bash
python3 -m tlpui
```

### Desktop Integration

- Installs `tlp-ui.desktop` into `/usr/share/applications`.
- Installs the application icon into `/usr/share/icons/hicolor/512x512/apps/tlp-ui.png`.
- Registers TLP UI under the system settings and hardware settings categories.
- Refreshes the desktop application database and icon cache when the required utilities are available.

### Official Website

https://github.com/d4nj1/TLPUI
