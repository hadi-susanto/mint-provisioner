# Available Modules

This document describes the modules available in Mint Provisioner and their supported environment variables for
customizing the installation flow.

## 📦 Module List

| Module             | Source    | Description                                                                       | Supported ENV Variables                                                                                                                           |
|:-------------------|:----------|:----------------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------|
| `adb`              | External  | Android Debug Bridge (ADB) and Fastboot from Google's platform-tools              | `ADB_INSTALL_DIR`                                                                                                                                 |
| `alacritty`        | Native    | A cross-platform, GPU-accelerated terminal emulator.                              | -                                                                                                                                                 |
| `apt-fast`         | Launchpad | APT wrapper with parallel package downloads for faster installation.              | `APT_FAST_USE_APT_ADD_REPOSITORY`,`APT_FAST_SKIP_CONFIGURATION`, `APT_FAST_FORCE_CONFIGURATION`                                                   |
| `cryptomator`      | PPA       | Free open-source client-side encryption for your cloud files                      | `CRYPTOMATOR_USE_APT_ADD_REPOSITORY`                                                                                                              |
| `double-commander` | PPA       | A cross-platform open source dual-pane file manager inspired by Total Commander.  | `DOUBLE_COMMANDER_GUI`                                                                                                                            |
| `eza`              | PPA       | A modern, feature-rich replacement for `ls`.                                      | `EZA_SKIP_CONFIGURATION`, `EZA_FORCE_CONFIGURATION`                                                                                               |
| `flameshot`        | GitHub    | Powerful yet simple-to-use screenshot software.                                   | `FLAMESHOT_REGEX`                                                                                                                                 |
| `ghostty`          | Launchpad | A fast, feature-rich, GPU-accelerated terminal emulator.                          | `GHOSTTY_USE_APT_ADD_REPOSITORY`, `GHOSTTY_SKIP_CONFIGURATION`, `GHOSTTY_FORCE_CONFIGURATION`                                                     |
| `git`              | Native    | The ubiquitous distributed version control system.                                | `GIT_SKIP_CONFIGURATION`, `GIT_FORCE_CONFIGURATION`                                                                                               |
| `keepass-xc`       | PPA       | Cross-platform community-driven port of KeePass                                   | `KEEPASS_XC_USE_APT_ADD_REPOSITORY`                                                                                                               |
| `kitty`            | GitHub    | A fast, feature-rich, GPU-based terminal emulator.                                | `KITTY_REGEX`, `KITTY_INSTALL_DIR`, `KITTY_SKIP_CONFIGURATION`, `KITTY_FORCE_CONFIGURATION`, `KITTY_INSTALL_OPEN_HANDLER`                         |
| `mu-commander`     | GitHub    | A lightweight, cross-platform file manager with a dual-pane interface.            | `MUCOMMANDER_REGEX`                                                                                                                               |
| `nerd-font`        | GitHub    | Iconic font aggregator, collection, and patcher with many glyphs.                 | `NERD_FONT_FAMILY`                                                                                                                                |
| `oh-my-posh`       | External  | A highly customizable prompt theme engine for any shell.                          | `OH_MY_POSH_SUFFIX`, `OH_MY_POSH_INSTALL_DIR`, `OH_MY_POSH_THEMES_INSTALL_DIR`, `OH_MY_POSH_SKIP_CONFIGURATION`, `OH_MY_POSH_FORCE_CONFIGURATION` |
| `power-level-10k`  | GitHub    | A high-performance Zsh theme with an easy-to-use configuration wizard.            | `POWERLEVEL10K_INSTALL_DIR`, `POWERLEVEL10K_SKIP_CONFIGURATION`, `POWERLEVEL10K_FORCE_CONFIGURATION`                                              |
| `starship`         | GitHub    | The minimal, blazing-fast, and infinitely customizable prompt for any shell!      | `STARSHIP_REGEX`, `STARSHIP_INSTALL_DIR`, `STARSHIP_SKIP_CONFIGURATION`, `STARSHIP_FORCE_CONFIGURATION`                                           |
| `sunflower`        | GitHub    | A highly customizable twin-panel file manager for Linux with support for plugins. | `SUNFLOWER_REGEX`                                                                                                                                 |
| `sys-config`       | Native    | Configure existing Linux Mint (GRUB, sudoers, plymouth, etc.)                     | -                                                                                                                                                 |
| `terminator`       | Launchpad | Feature-rich terminal emulator that supports multiple terminals in one window.    | `TERMINATOR_USE_APT_ADD_REPOSITORY`                                                                                                               |
| `zsh`              | Native    | A powerful shell designed for interactive use and scripting.                      | `ZSH_SKIP_CONFIGURATION`, `ZSH_FORCE_CONFIGURATION`                                                                                               |

## 🛠️ Configuration Details

### `*_USE_APT_ADD_REPOSITORY`

Used to determine whether to use `apt-add-repository` to add repositories. Our script is designed to work with
`apt-add-repository` but sometime it might not work because of network issues or other reasons. Hence, I decided to
manually add the repositories and the GPG keys via `install_asc_key` instead. In rare cases, you can enable
the `apt-add-repository` method by setting this variable to `true`.

* **`USE_APT_ADD_REPOSITORY`**: If set to `true`, all modules will use `apt-add-repository` to add repositories.
* **Supported by**: `apt-fast`, `cryptomator`, `double-commander`, `ghostty`, `keepass-xc`, `terminator`.

### `copy_to_config_dir` (Internal Helper)

Used by modules during the `post_install` phase to copy payload files to the user's configuration directory
(`~/.config/mint-provisioner`). It handles directory creation and respects the `*_FORCE_CONFIGURATION` settings.

* **Functionality**:
    * Checks if the source file exists (returns 1 if not).
    * Creates the configuration directory if it doesn't exist.
    * Copies the file if it doesn't exist or if force configuration is enabled.
    * Dynamically resolves the force configuration variable name to provide better logging.

* **Arguments**:
    1. `module`: Module name.
    2. `source`: Source file path.
    3. `force_var`: Name of the environment variable for force configuration (e.g., `GIT_FORCE_CONFIGURATION`).

### `*_REGEX`

Used usually by GitHub-type modules to dynamically change the regex pattern used to identify and download the correct
asset from releases.

* **`FLAMESHOT_REGEX`**: Default: `ubuntu-<version>.?amd64\.(zip|deb)$` (auto-generated based on Ubuntu version).
* **`MUCOMMANDER_REGEX`**: Default: `mucommander_.*_x86_64\.deb`.
* **`KITTY_REGEX`**: Default: `x86_64\.txz$`.
* **`STARSHIP_REGEX`**: Default: `starship-x86_64-unknown-linux-musl\.tar\.gz$`.
* **`SUNFLOWER_REGEX`**: Default: `sunflower-.*\.all\.deb`.

### `*_SUFFIX`

Used by modules that download assets with a specific platform/architecture suffix in the filename.

* **`OH_MY_POSH_SUFFIX`**: Default: `linux-amd64`.

### `*_INSTALL_DIR`

Used to change the installation directory for modules that perform "manual" installation instead of using packaged
software (like DEB or PPA). By default, it uses an `INSTALL_DIR` that shares the same base root as the
`mint-provisioner` repository.

* **Supported by**: `adb`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`.

### `OH_MY_POSH_THEMES_INSTALL_DIR`

Used to change the installation directory for the themes of the `oh-my-posh` module. By default, it uses a `themes`
folder inside the `OH_MY_POSH_INSTALL_DIR`.

### `*_SKIP_CONFIGURATION`

Used mostly in modules that have a `post_install` phase to skip the automatic configuration of the installed software.

* **`SKIP_CONFIGURATION`**: If set to `true`, all modules will skip their configuration phase.
* **Supported by**: `apt-fast`, `eza`, `git`, `ghostty`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`, `zsh`.

### `*_FORCE_CONFIGURATION`

Used during the `post_install` phase to forcefully overwrite existing configuration files with the default ones provided
by the module.

* **`FORCE_CONFIGURATION`**: If set to `true`, all modules will overwrite their configurations. This is used by the
  `reconfigure.sh` script.
* **Supported by**: `apt-fast`, `eza`, `ghostty`, `git`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`, `zsh`.

### `DOUBLE_COMMANDER_GUI`

Used by the `double-commander` module to specify which GUI variant to install.

* **Default**: `doublecmd-gtk`
* **Allowed values**: `doublecmd-gtk`, `doublecmd-qt`, `doublecmd-qt6`.

### `NERD_FONT_FAMILY`

Specifies the font family to install for the `nerd-font` module.

* **Default**: `Inconsolata`
* **Allowed values**: Please check the [Nerd Fonts Releases](https://github.com/ryanoasis/nerd-fonts/releases/latest)
  website for a complete list of available fonts.

### `KITTY_INSTALL_OPEN_HANDLER`

Flag to install the `kitty-open.desktop` file, registering it as an application to open files with the `kitty` terminal.

* **Default**: `false`
* **Allowed values**: `true`, `false`.
