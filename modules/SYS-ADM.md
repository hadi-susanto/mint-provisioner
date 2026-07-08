# ⚙️ System Administration (`sys-adm`)

System Administration modules provide tools for monitoring, analyzing, and managing Linux systems. They help inspect resource usage, analyze disk consumption, optimize package management, and improve day-to-day system administration tasks. Several modules also integrate with the provisioner by installing shell completions or configurable installation options.

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

## Bottom (`bottom`)

Bottom is a modern terminal-based system monitor that provides real-time visualization of CPU, memory, disk, network, and process information through a highly customizable user interface.

### Installation Method

**GitHub latest release (.deb)**

The installer locates the latest AMD64 Debian package from the official GitHub releases page and installs it using APT.

### Supported ENV

- `BOTTOM_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `bottom-musl_.*_amd64\.deb`

### Official Website

https://github.com/ClementTsang/bottom

---

## Du Analyzer (`du-analyzer`)

Du Analyzer (dua-cli) is a fast disk usage analyzer designed for exploring directory sizes interactively. It helps quickly identify files and directories consuming the most storage.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 MUSL archive from the official GitHub releases page, extracts it, and creates a symbolic link for the executable.

### Supported ENV

- `DU_ANALYZER_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `dua-.*-x86_64-unknown-linux-musl\.tar\.gz$`

- `DU_ANALYZER_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/du-analyzer`

### Official Website

https://github.com/Byron/dua-cli

---

## Du Rust (`du-rust`)

Du Rust (Dust) is a modern replacement for the traditional `du` command. It presents directory sizes using an intuitive tree view with proportional bars, making it easier to identify storage hotspots.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 MUSL archive from the official GitHub releases page, extracts it, and creates a symbolic link for the executable.

### Supported ENV

- `DU_RUST_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `dust-.*-x86_64-unknown-linux-musl\.tar\.gz$`

- `DU_RUST_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/du-rust`

### Official Website

https://github.com/bootandy/dust

---

## Duf (`duf`)

Duf is a modern replacement for the traditional `df` command. It presents mounted filesystems, storage utilization, free space, and device information in a clean, colorful, and easy-to-read table.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 archive from the official GitHub releases page, extracts it, and creates a symbolic link for the executable.

### Supported ENV

- `DUF_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `duf_.*_linux_amd64\.tar\.gz$`

- `DUF_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/duf`

### Official Website

https://github.com/muesli/duf

---

## Nerd Fonts (`nerd-font`)

Nerd Fonts provides patched developer fonts containing thousands of additional glyphs used by modern terminal prompts, CLI applications, editors, and programming tools.

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

## Procs (`procs`)

Procs is a modern replacement for the classic `ps` command. It provides colored output, process tree visualization, improved searching, additional metadata, and a more user-friendly interface for inspecting running processes.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 archive from the official GitHub releases page, extracts it, and creates a symbolic link for the executable.

### Supported ENV

- `PROCS_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `procs-.*-x86_64-linux\.zip$`

- `PROCS_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/procs`

### Official Website

https://github.com/dalance/procs

---

## System Config (`sys-config`)

System Config applies the opinionated Linux Mint configuration used by this provisioner. Rather than installing a standalone application, this module configures the operating system to provide a consistent and productive desktop environment.

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
