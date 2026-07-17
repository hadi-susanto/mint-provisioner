# 🖥️ Desktop Applications (`gui`)

Graphical applications for productivity, file management, security, and everyday desktop workflows. This category includes desktop software such as **Double Commander**, **Flameshot**, **KeePassXC**, **Cryptomator**, **Sunflower**, and **muCommander**.

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
