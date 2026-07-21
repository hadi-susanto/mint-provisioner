# 📟 Terminal UI (`tui`)

Interactive terminal applications that provide rich text-based user interfaces. These applications combine the
efficiency of the terminal with a visual interface, including tools such as **lazygit**, **gitui**, **bottom**, **duf**,
**du-analyzer**, and **du-rust**.

## Contents

- [Bottom](#bottom-bottom-alias-btm)
- [Du Analyzer](#du-analyzer-du-analyzer-alias-dua)
- [Du Rust](#du-rust-du-rust-alias-dust)
- [Duf](#duf-duf)
- [GitUI](#gitui-git-ui)
- [Lazygit](#lazygit-lazy-git)

---

## Bottom (`bottom`) [alias: `btm`]

Bottom is a modern terminal-based system monitor that provides real-time visualization of CPU, memory, disk, network,
and process information through a highly customizable user interface.

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

---

## Du Analyzer (`du-analyzer`) [alias: `dua`]

Du Analyzer (dua-cli) is a fast disk usage analyzer designed for exploring directory sizes interactively. It helps
quickly identify files and directories consuming the most storage.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 MUSL archive from the official GitHub releases page, extracts it, and
creates a symbolic link for the executable.

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

## Du Rust (`du-rust`) [alias: `dust`]

Du Rust (Dust) is a modern replacement for the traditional `du` command. It presents directory sizes using an intuitive
tree view with proportional bars, making it easier to identify storage hotspots.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 MUSL archive from the official GitHub releases page, extracts it, and
creates a symbolic link for the executable.

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

Duf is a modern replacement for the traditional `df` command. It presents mounted filesystems, storage utilization, free
space, and device information in a clean, colorful, and easy-to-read table.

### Installation Method

**GitHub latest release (precompiled archive)**

The installer downloads the latest Linux x86_64 archive from the official GitHub releases page, extracts it, and creates
a symbolic link for the executable.

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

## GitUI (`git-ui`)

GitUI is a fast terminal user interface for Git, providing an interactive workflow for staging changes, browsing
history, managing branches, and creating commits without leaving the terminal.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Linux x86_64 release archive from the official GitHub repository.

### Supported ENV

- `GIT_UI_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/git-ui`

- `GIT_UI_REGEX`
    - Regular expression used to locate the GitHub release asset.

- `GIT_UI_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `GIT_UI_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `git-ui-aliases.sh` into the provisioner configuration directory.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Aliases

| Alias | Description                                                                                               |
|-------|-----------------------------------------------------------------------------------------------------------|
| `gui` | **Expands to:** `gitui`<br><br>Launches the GitUI terminal user interface for interactive Git operations. |

### Official Website

https://github.com/gitui-org/gitui

---

## Lazygit (`lazy-git`)

Lazygit is a simple yet powerful terminal user interface for Git. It streamlines staging, committing, rebasing,
stashing, conflict resolution, and repository navigation through an intuitive keyboard-driven interface.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Linux x86_64 release archive from the official GitHub repository.

### Supported ENV

- `LAZY_GIT_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/lazy-git`

- `LAZY_GIT_REGEX`
    - Regular expression used to locate the GitHub release asset.

- `LAZY_GIT_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `LAZY_GIT_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `lazy-git-aliases.sh` into the provisioner configuration directory.

#### Shell Integration

- Registers the configuration for **Bash**.
- Registers the configuration for **Zsh**.

#### Shell Aliases

| Alias | Description                                                                                                   |
|-------|---------------------------------------------------------------------------------------------------------------|
| `lg`  | **Expands to:** `lazygit`<br><br>Launches the Lazygit terminal user interface for interactive Git operations. |

### Official Website

https://github.com/jesseduffield/lazygit
