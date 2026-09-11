# `>_` Terminal (`term`)

Terminal emulators, shells, prompts, themes, and tools that enhance the terminal experience. This category includes software such as **Kitty**, **Ghostty**, **Alacritty**, **Terminator**, **Zsh**, **Starship**, **Oh My Posh**, and **Powerlevel10k**.

## Contents

- [Alacritty](#alacritty-alacritty)
- [Ghostty](#ghostty-ghostty)
- [Kitty](#kitty-kitty)
- [Oh My Posh](#oh-my-posh-oh-my-posh-alias-omp)
- [Powerlevel10k](#powerlevel10k-power-level-10k-alias-plvl10k)
- [Starship](#starship-starship)
- [Terminator](#terminator-terminator)
- [Zsh](#zsh-zsh)

---

## Alacritty (`alacritty`)

Alacritty is a GPU-accelerated terminal emulator focused on simplicity and performance. It provides a fast and
lightweight terminal experience while remaining highly configurable.

### Installation Method

**APT package (Linux Mint / Ubuntu repository)**

Installs Alacritty directly from the distribution package repository.

### Supported ENV

None.

### Official Website

https://alacritty.org/

---

## Ghostty (`ghostty`)

Ghostty is a modern GPU-accelerated terminal emulator designed for performance, usability, and native platform
integration. It provides advanced terminal features while maintaining a clean user experience.

### Installation Method

**Launchpad PPA**

### Supported ENV

- `GHOSTTY_USE_APT_ADD_REPOSITORY`
    - Controls whether the Launchpad repository is added using `add-apt-repository`.
    - Default: `${USE_APT_ADD_REPOSITORY}`

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

### Official Website

https://ghostty.org/

---

## Kitty (`kitty`)

Kitty is a fast, feature-rich, GPU-based terminal emulator. It supports split layouts, keyboard-driven navigation,
graphical terminal features, and extensive customization.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Kitty `.txz` archive from the official GitHub release page, extracts it into the configured
installation directory, creates symbolic links for `kitty` and `kitten`, installs desktop launcher files, and registers
Kitty as an available terminal emulator.

### Supported ENV

- `KITTY_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/kitty`

- `KITTY_INSTALL_OPEN_HANDLER`
    - Install `kitty-open.desktop`, allowing Kitty to be registered as an application for opening files.
    - Default:
      `false`

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

### Official Website

https://sw.kovidgoyal.net/kitty/

---

## Oh My Posh (`oh-my-posh`) [alias: `omp`]

Oh My Posh is a highly customizable prompt theme engine for shells. It provides rich, contextual prompts with support
for Git status, runtime information, icons, and many other prompt segments.

### Installation Method

**Official website (precompiled binary and archive)**

Downloads the latest Oh My Posh binary from the official CDN using the configured platform suffix, downloads the latest
themes archive, installs the binary into the configured installation directory, extracts themes, and creates a symbolic
link in `/usr/local/bin`.

### Supported ENV

- `OH_MY_POSH_SUFFIX`
    - Platform suffix used when downloading the Oh My Posh binary.
    - Default:
      `linux-amd64`

- `OH_MY_POSH_INSTALL_DIR`
    - Installation directory for the Oh My Posh binary.
    - Default:
      `${INSTALL_DIR}/oh-my-posh`

- `OH_MY_POSH_THEMES_INSTALL_DIR`
    - Installation directory for Oh My Posh themes.
    - Default:
      `${OH_MY_POSH_INSTALL_DIR}/themes`

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

Without System Toolkit, configure Oh My Posh manually using the
[official prompt integration guide](https://ohmyposh.dev/docs/installation/prompt).

### Official Website

https://ohmyposh.dev/

---

## Powerlevel10k (`power-level-10k`) [alias: `plvl10k`]

Powerlevel10k is a high-performance Zsh theme with a powerful configuration wizard. It provides a fast and highly
customizable prompt for interactive Zsh usage.

### Installation Method

**GitHub repository clone**

Clones the official Powerlevel10k GitHub repository into the configured installation directory using a shallow clone.

### Supported ENV

- `POWERLEVEL10K_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/power-level-10k`

### Installation Detection and Registry

Powerlevel10k is detected by verifying `powerlevel10k.zsh-theme` in the configured, registered, or default installation
directory. After installation, Mint Provisioner stores the checkout path and Git revision when it can be resolved. A
stale registry does not make a missing theme appear installed.

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

Provide the Powerlevel10k installation directory when running the interactive configuration module:

```bash
POWERLEVEL10K_INSTALL_DIR="/path/to/installed/power-level-10k" syskit-cfg install term/power-level-10k
```

Without System Toolkit, source the installed theme from your Zsh configuration:

```zsh
source "/path/to/installed/power-level-10k/powerlevel10k.zsh-theme"
```

### Official Website

https://github.com/romkatv/powerlevel10k

---

## Starship (`starship`)

Starship is a minimal, fast, and highly customizable cross-shell prompt. It provides a consistent prompt experience
across shells with support for Git status, language runtimes, package versions, and many other contextual indicators.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest Linux x86_64 MUSL TAR.GZ archive from the official GitHub release page, extracts the `starship`
binary into the configured installation directory, makes it executable, and creates a symbolic link.

### Supported ENV

- `STARSHIP_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/starship`

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

Without System Toolkit, follow the **Add the init script to your shell's config file** section in the
[official Starship installation guide](https://starship.rs/).

### Official Website

https://starship.rs/

---

## Terminator (`terminator`)

Terminator is a feature-rich terminal emulator designed for users who frequently work with multiple terminal sessions.
It provides split panes, tabbed terminals, broadcast input, and extensive layout customization.

### Installation Method

**Launchpad PPA**

Configures the `ppa:mattrose/terminator` Launchpad PPA and installs the `terminator` package.

### Supported ENV

- `TERMINATOR_USE_APT_ADD_REPOSITORY`
    - Use `add-apt-repository` instead of explicit key and source-file configuration.
    - Default: `${USE_APT_ADD_REPOSITORY}`

#### Keyboard Shortcuts

| Shortcut        | Action                       |
|-----------------|------------------------------|
| `Ctrl+Shift+E`  | Split terminal vertically.   |
| `Ctrl+Shift+O`  | Split terminal horizontally. |
| `Ctrl+PageUp`   | Switch to the previous tab.  |
| `Ctrl+PageDown` | Switch to the next tab.      |
| `Ctrl+Shift+T`  | Open a new tab.              |
| `Ctrl+Shift+W`  | Close the current terminal.  |

### Official Website

https://gnome-terminator.org/

---

## Zsh (`zsh`)

Zsh is an advanced Unix shell that extends the Bourne shell with powerful scripting capabilities, intelligent tab
completion, programmable prompts, command history improvements, and extensive customization.

Zsh serves as the foundation for many shell integrations managed by System Toolkit.

### Installation Method

**APT package (Linux Mint / Ubuntu repository)**

Installs Zsh from the distribution package repository.

### System Toolkit Integration

This module has additional features that can be enabled by running SysKit. See the
[System Toolkit payload catalog](https://github.com/hadi-susanto/system-toolkit/tree/main/payload).

### Official Website

https://www.zsh.org/
