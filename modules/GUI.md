# 🖥️ Desktop Applications (`gui`)

Graphical applications for productivity, file management, security, and everyday desktop workflows. This category includes desktop software such as **Double Commander**, **Flameshot**, **KeePassXC**, **Cryptomator**, **Sunflower**, and **muCommander**.

---

## Brave Browser (`brave-browser`)

Brave is a privacy-focused Chromium browser with built-in ad and tracker blocking.

### Installation Method

**Official Brave APT repositories**

Supports Release, Beta, and Nightly channels.

### Supported ENV

- `BRAVE_BROWSER_CHANNEL`
    - Supported values: `release`, `stable`, `beta`, `nightly`.
    - Default: `release`

- `BRAVE_BROWSER_NON_INTERACTIVE`
    - Disables channel selection.
    - Default: `${NON_INTERACTIVE}`

Multiple channels can be installed side by side. Use `--force` when another Brave Browser channel is already installed.

### Official Website

https://brave.com/

---

## Brave Origin (`brave-origin`)

Brave Origin is a streamlined Brave browser with optional features disabled by default. It is available for free on Linux.

### Installation Method

**Official Brave APT repositories**

Supports Release, Beta, and Nightly channels.

### Supported ENV

- `BRAVE_ORIGIN_CHANNEL`
    - Supported values: `release`, `stable`, `beta`, `nightly`.
    - Default: `release`

- `BRAVE_ORIGIN_NON_INTERACTIVE`
    - Disables channel selection.
    - Default: `${NON_INTERACTIVE}`

Multiple channels can be installed side by side. Use `--force` when another Brave Origin channel is already installed.

### Official Website

https://brave.com/origin/

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
- Uses the bundled DeaDBeeF icon when available, with the system audio icon as a fallback.

### Cleanup

- Removes the downloaded TAR.BZ2 archive.
- Removes the module state file.

### Official Website

https://deadbeef.sourceforge.io/

---

## Double Commander (`double-commander`)

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

### Supported ENV

- `FLAMESHOT_REGEX`
    - Optional regular expression used to locate the GitHub release asset.
    - When unset, the module builds an Ubuntu-version-specific pattern automatically.

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

### Supported ENV

- `FMAN_REGEX`
    - Regular expression used to locate the Ubuntu x64 Debian package in the latest GitHub release.
    - Default:
      `fman-.*-ubuntu-x64\\.deb$`

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

## KeePassXC (`keepass-xc`)

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

---

## Microsoft Edge (`microsoft-edge`)

---

## Microsoft Edge (`microsoft-edge`)

Microsoft Edge is Microsoft's Chromium-based web browser. The module supports Stable, Beta, Dev, and Canary channels.
Canary is the daily experimental channel; there is no separate Nightly channel.

### Installation Method

**Official Microsoft Edge APT repository**

Configures Microsoft's Edge repository and installs the selected package:

| Channel | Package                         |
|---------|---------------------------------|
| Stable  | `microsoft-edge-stable`         |
| Beta    | `microsoft-edge-beta`           |
| Dev     | `microsoft-edge-dev`            |
| Canary  | `microsoft-edge-canary`         |

Multiple Microsoft Edge channels can be installed side by side. Use `MICROSOFT_EDGE_CHANNEL` to select a channel
directly. If an Edge channel is already installed, add `--force` to run the module again and install another channel.

Example for non-interactive:

```bash
MICROSOFT_EDGE_CHANNEL=dev ./install.sh gui/microsoft-edge
```

For interactive could use:

```bash
./install.sh --force gui/microsoft-edge
```

### Supported ENV

- `MICROSOFT_EDGE_CHANNEL`
    - Supported values: `stable`, `beta`, `dev`, `canary`.
    - Default: `stable` in non-interactive mode.

- `MICROSOFT_EDGE_NON_INTERACTIVE`
    - Disables the channel selection prompt.
    - Default: `${NON_INTERACTIVE}`

### Post-install Configuration

Disables Edge's repository updater and removes vendor-generated APT source files that may conflict with the repository
managed by Mint Provisioner.

Reapply the configuration with:

```bash
./configure.sh gui/microsoft-edge
```

### Official Website

https://www.microsoft.com/edge/download

---

## Mu Commander (`mu-commander`)

Mu Commander is a lightweight, cross-platform dual-pane file manager. It provides a Commander-style interface for file management with support for common file operations, keyboard-driven workflows, archive handling, and multiple storage locations.

### Installation Method

**GitHub latest release (.deb)**

Downloads the latest x86_64 Debian package from the official GitHub releases page, stores the downloaded package path in a module state file, then installs the package using APT.

### Supported ENV

- `MUCOMMANDER_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `mucommander_.*_x86_64\.deb`

### Official Website

https://www.mucommander.com/

---

## Sunflower (`sunflower`)

Sunflower is a highly customizable twin-panel file manager for Linux. It provides a dual-pane interface with plugin support and a workflow focused on efficient desktop file management.

### Installation Method

**GitHub latest release (.deb)**

Downloads the latest Debian package from the official GitHub releases page, stores the downloaded package path in a module state file, then installs the package using APT.

### Supported ENV

- `SUNFLOWER_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `sunflower-.*\.all\.deb`

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
