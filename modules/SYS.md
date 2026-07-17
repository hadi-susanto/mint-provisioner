# ⚙️ System (`sys`)

System utilities, machine setup, performance tools, fonts, and operating system configuration. Modules in this category help configure, maintain, and optimize the operating system, including tools such as **apt-fast**, **Nerd Fonts**, and your opinionated **OOBE** configuration.

---

## Apt Fast (`apt-fast`)

Apt Fast is a wrapper around APT that accelerates package downloads by utilizing multiple concurrent connections. It is particularly useful when installing or upgrading a large number of packages.

### Installation Method

**Launchpad PPA**

The installer configures the official Apt Fast Launchpad PPA before installing the package using APT.

### Supported ENV

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

## Nerd Fonts (`nerd-font`)

Nerd Fonts provides patched developer fonts containing thousands of additional glyphs used by modern terminal prompts, CLI applications, editors, and programming tools.

**IMPORTANT:** This module does not support `INSTALL_DIR` environment variable, it will install the fonts into the system font directory.

### Installation Method

**Official website (precompiled archive)**

The installer downloads selected font archives from the official Nerd Fonts project, extracts the fonts into the system font directory (`/usr/local/share/fonts`), and refreshes the font cache.
The installer will create folder for each font family, eg: `/usr/local/share/fonts/nerd-font/Inconsolata`, the folder name is the font family name.

### Supported ENV

- `NERD_FONT_FAMILY`
    - Font family to install.
    - Default: `Inconsolata`.

### Post-install Configuration

#### Installed Configuration

- Installs the selected fonts into the user's local font directory.
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

None.

### Post-install Configuration

#### Installed Configuration

The module applies the provisioner's recommended Linux Mint configuration, including desktop preferences, system settings, and other operating system customizations.

### Official Website

This module is maintained as part of the Linux Mint Provisioner project.
