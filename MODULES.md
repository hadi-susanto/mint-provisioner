# Available Modules

This document describes the modules available in Mint Provisioner and their supported environment variables for
customizing the installation flow.

## 📦 Module List

| Module            | Source    | Description                                                                                                                                   | Supported ENV Variables                                                                                                                   |
|:------------------|:----------|:----------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------|
| `alacritty`       | Native    | A cross-platform, GPU-accelerated terminal emulator.                                                                                          | -                                                                                                                                         |
| `apt-fast`        | LaunchPad | A shell script wrapper for apt that can drastically improve apt download speeds by downloading packages from multiple mirrors simultaneously. | `APT_FAST_USE_APT_ADD_REPOSITORY`,`APT_FAST_SKIP_CONFIGURE`, `APT_FAST_FORCE_CONFIGURE`                                                   |
| `eza`             | PPA       | A modern replacement for `ls`.                                                                                                                | `EZA_SKIP_CONFIGURE`, `EZA_FORCE_CONFIGURE`                                                                                               |
| `flameshot`       | GitHub    | Powerful yet simple-to-use screenshot software.                                                                                               | `FLAMESHOT_REGEX`                                                                                                                         |
| `ghostty`         | LaunchPad | A fast, feature-rich, GPU-accelerated terminal emulator.                                                                                      | `GHOSTTY_USE_APT_ADD_REPOSITORY`, `GHOSTTY_SKIP_CONFIGURE`, `GHOSTTY_FORCE_CONFIGURE`                                                     |
| `git`             | Native    | Distributed version control system.                                                                                                           | `GIT_SKIP_CONFIGURE`, `GIT_FORCE_CONFIGURE`                                                                                               |
| `kitty`           | GitHub    | A fast, feature-rich, GPU-based terminal emulator.                                                                                            | `KITTY_REGEX`, `KITTY_INSTALL_DIR`, `KITTY_SKIP_CONFIGURE`, `KITTY_FORCE_CONFIGURE`, `KITTY_INSTALL_OPEN_HANDLER`                         |
| `nerd-font`       | GitHub    | Iconic font aggregator, collection, & patcher.                                                                                                | `NERD_FONT_FAMILY`                                                                                                                        |
| `oh-my-posh`      | External  | A prompt theme engine for any shell.                                                                                                          | `OH_MY_POSH_SUFFIX`, `OH_MY_POSH_INSTALL_DIR`, `OH_MY_POSH_THEMES_INSTALL_DIR`, `OH_MY_POSH_SKIP_CONFIGURE`, `OH_MY_POSH_FORCE_CONFIGURE` |
| `power-level-10k` | GitHub    | A theme for Zsh that emphasizes speed, flexibility and out-of-the-box experience.                                                             | `POWERLEVEL10K_INSTALL_DIR`, `POWERLEVEL10K_SKIP_CONFIGURE`, `POWERLEVEL10K_FORCE_CONFIGURE`                                              |
| `starship`        | GitHub    | The minimal, blazing-fast, and infinitely customizable prompt for any shell!                                                                  | `STARSHIP_REGEX`, `STARSHIP_INSTALL_DIR`, `STARSHIP_SKIP_CONFIGURE`, `STARSHIP_FORCE_CONFIGURE`                                           |
| `sys-config`      | Native    | Special module to confiure existing Linux Mint installation, it **don't install anything** so please use `configure.sh` to initiate it.       | -                                                                                                                                         |
| `terminator`      | LaunchPad | Multiple terminals in one window.                                                                                                             | `TERMINATOR_USE_APT_ADD_REPOSITORY`                                                                                                       |
| `zsh`             | Native    | The Z shell (zsh) is a Unix shell that can be used as an interactive login shell and as a powerful command interpreter for shell scripting.   | `ZSH_SKIP_CONFIGURE`, `ZSH_FORCE_CONFIGURE`                                                                                               |

## 🛠️ Configuration Details

### `*_USE_APT_ADD_REPOSITORY`

Used to determine whether to use `apt-add-repository` to add repositories. Our script is designed to work with
`apt-add-repository` but sometime it might not work because of network issues or other reasons. Hence, I decided to
manually add the repositories and the GPG keys via `fetch_and_install_asc_key` instead. In rare cases, you can enable
the `apt-add-repository` method by setting this variable to `true`.

* **`USE_APT_ADD_REPOSITORY`**: If set to `true`, all modules will use `apt-add-repository` to add repositories.
* **Supported by**: `pt-fast`, `terminator`.

### `*_REGEX`

Used usually by GitHub-type modules to dynamically change the regex pattern used to identify and download the correct
asset from releases.

* **`FLAMESHOT_REGEX`**: Default: `ubuntu-<version>.*\.deb$` (auto-generated based on Ubuntu version).
* **`KITTY_REGEX`**: Default: `x86_64\.txz$`.
* **`STARSHIP_REGEX`**: Default: `starship-x86_64-unknown-linux-musl\.tar\.gz$`.

### `*_SUFFIX`

Used by modules that download assets with a specific platform/architecture suffix in the filename.

* **`OH_MY_POSH_SUFFIX`**: Default: `linux-amd64`.

### `*_INSTALL_DIR`

Used to change the installation directory for modules that perform "manual" installation instead of using packaged
software (like DEB or PPA). By default, it uses an `INSTALL_DIR` that shares the same base root as the
`mint-provisioner` repository.

* **Supported by**: `kitty`, `oh-my-posh`, `power-level-10k`, `starship`.

### `OH_MY_POSH_THEMES_INSTALL_DIR`

Used to change the installation directory for the themes of the `oh-my-posh` module. By default, it uses a `themes`
folder inside the `OH_MY_POSH_INSTALL_DIR`.

### `*_SKIP_CONFIGURE`

Used mostly in modules that have a `post_install` phase to skip the automatic configuration of the installed software.

* **`SKIP_CONFIGURE`**: If set to `true`, all modules will skip their configuration phase.
* **Supported by**: `apt-fast`, `eza`, `git`, `ghostty`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`, `zsh`.

### `*_FORCE_CONFIGURE`

Used during the `post_install` phase to forcefully overwrite existing configuration files with the default ones provided
by the module.

* **`FORCE_CONFIGURE`**: If set to `true`, all modules will overwrite their configurations. This is used by the
  `reconfigure.sh` script.
* **Supported by**: `apt-fast`, `eza`, `ghostty`, `git`, `kitty`, `oh-my-posh`, `power-level-10k`, `starship`, `zsh`.

### Others ENV

Environment variables that are specific to certain modules and not covered by the categories above.

* **`NERD_FONT_FAMILY`**: Specifies the font family to install for the `nerd-font` module.
* **`KITTY_INSTALL_OPEN_HANDLER`**: If set to `true`, the `kitty-open.desktop` file will be installed. (default:
  `false`)
