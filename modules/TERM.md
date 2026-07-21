# `>_` Terminal (`term`)

Terminal emulators, shells, prompts, themes, and tools that enhance the terminal experience. This category includes software such as **Kitty**, **Ghostty**, **Alacritty**, **Terminator**, **Zsh**, **Starship**, **Oh My Posh**, and **Powerlevel10k**.

## Contents

- [Alacritty](#alacritty-alacritty)
- [Ghostty](#ghostty-ghostty)
- [Kitty](#kitty-kitty)
- [Oh My Posh](#oh-my-posh-oh-my-posh)
- [Powerlevel10k](#powerlevel10k-power-level-10k)
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

- `GHOSTTY_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default: `${SKIP_CONFIGURATION}`

- `GHOSTTY_FORCE_CONFIGURATION`
    - Overwrite existing configuration.
    - Default: `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Creates the Ghostty configuration directory if it does not already exist.
- Installs the bundled `mint-provisioner.ghostty` configuration file.
- Automatically includes `mint-provisioner.ghostty` from `~/.config/ghostty/config.ghostty` if the include directive is
  not already present.

The bundled configuration includes:

- GitHub Dark theme.
- Disable restoring previous windows, tabs, and splits.
- Split pane shortcuts.
- Split navigation shortcuts.
- Split zoom shortcut.

#### Keyboard Shortcuts

| Shortcut           | Action                                   |
|--------------------|------------------------------------------|
| `Ctrl+Shift+E`     | Split pane to the right.                 |
| `Ctrl+Shift+O`     | Split pane downward.                     |
| `Ctrl+Shift+Enter` | Automatically determine split direction. |
| `Ctrl+←`           | Focus left split.                        |
| `Ctrl+→`           | Focus right split.                       |
| `Ctrl+↑`           | Focus upper split.                       |
| `Ctrl+↓`           | Focus lower split.                       |
| `Ctrl+Shift+X`     | Toggle split zoom.                       |

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

- `KITTY_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `x86_64\.txz$`

- `KITTY_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/kitty`

- `KITTY_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default:
      `${SKIP_CONFIGURATION}`

- `KITTY_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default:
      `${FORCE_CONFIGURATION}`

- `KITTY_INSTALL_OPEN_HANDLER`
    - Install `kitty-open.desktop`, allowing Kitty to be registered as an application for opening files.
    - Default:
      `false`

### Post-install Configuration

#### Installed Configuration

- Creates `~/.config/kitty` if it does not already exist.
- Copies `mint-provisioner.kitty` into `~/.config/kitty`.
- Copies `mint-provisioner.session` into `~/.config/kitty`.
- Creates `~/.config/kitty/kitty.conf` if it does not already exist.
- Adds `include mint-provisioner.kitty` into `kitty.conf` if the include line does not already exist.

The bundled Kitty configuration:

- Enables only the split and stack layouts.
- Disables remembered window size and window position.
- Sets the initial window size to `120c` by `30c`.
- Removes window margins.
- Enables minimal borders.
- Starts Kitty using `mint-provisioner.session`.

#### Keyboard Shortcuts

| Shortcut           | Action                                                                                |
|--------------------|---------------------------------------------------------------------------------------|
| `Ctrl+Shift+X`     | Switch to the next layout, mimicking maximize/minimize behavior for the current pane. |
| `F5`               | Create a horizontal split.                                                            |
| `Ctrl+Shift+O`     | Create a horizontal split.                                                            |
| `F6`               | Create a vertical split.                                                              |
| `Ctrl+Shift+E`     | Create a vertical split.                                                              |
| `F4`               | Create an automatic split.                                                            |
| `Ctrl+Shift+Enter` | Create an automatic split.                                                            |
| `F7`               | Rotate the current split layout.                                                      |
| `Shift+Up`         | Move the active window up.                                                            |
| `Shift+Left`       | Move the active window left.                                                          |
| `Shift+Right`      | Move the active window right.                                                         |
| `Shift+Down`       | Move the active window down.                                                          |
| `Ctrl+Shift+Up`    | Move the active window to the top screen edge.                                        |
| `Ctrl+Shift+Left`  | Move the active window to the left screen edge.                                       |
| `Ctrl+Shift+Right` | Move the active window to the right screen edge.                                      |
| `Ctrl+Shift+Down`  | Move the active window to the bottom screen edge.                                     |
| `Ctrl+Left`        | Focus the neighboring window on the left.                                             |
| `Ctrl+Right`       | Focus the neighboring window on the right.                                            |
| `Ctrl+Up`          | Focus the neighboring window above.                                                   |
| `Ctrl+Down`        | Focus the neighboring window below.                                                   |
| `Ctrl+.`           | Set split bias to 80%.                                                                |
| `Ctrl+Shift+W`     | Maximize the active window horizontally.                                              |
| `Ctrl+Shift+H`     | Maximize the active window vertically.                                                |

### Official Website

https://sw.kovidgoyal.net/kitty/

---

## Oh My Posh (`oh-my-posh`)

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

- `OH_MY_POSH_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default:
      `${SKIP_CONFIGURATION}`

- `OH_MY_POSH_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default:
      `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `oh-my-posh.sh` into the provisioner's configuration directory.
- Copies `oh-my-posh.zsh` into the provisioner's configuration directory.

#### Shell Integration

- Registers Oh My Posh initialization for **Bash**.
- Registers Oh My Posh initialization for **Zsh**.

### Official Website

https://ohmyposh.dev/

---

## Powerlevel10k (`power-level-10k`)

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

- `POWERLEVEL10K_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default:
      `${SKIP_CONFIGURATION}`

- `POWERLEVEL10K_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default:
      `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Shell Integration

- Registers the installed `powerlevel10k.zsh-theme` file for **Zsh**.
- Skips configuration when Zsh is not installed.

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

- `STARSHIP_REGEX`
    - Regular expression used to locate the GitHub release asset.
    - Default:
      `starship-x86_64-unknown-linux-musl\.tar\.gz$`

- `STARSHIP_INSTALL_DIR`
    - Installation directory.
    - Default:
      `${INSTALL_DIR}/starship`

- `STARSHIP_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default:
      `${SKIP_CONFIGURATION}`

- `STARSHIP_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default:
      `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Copies `starship.sh` into the provisioner's configuration directory.
- Copies `starship.zsh` into the provisioner's configuration directory.
- Creates `~/.config/starship.toml` from the bundled payload if it does not exist.
- If `~/.config/starship.toml` already exists and does not contain `add_newline`, prepends the provisioner's Starship
  newline configuration.
- If `~/.config/starship.toml` already contains `add_newline`, leaves the file unchanged and prints a manual update
  message.

#### Shell Integration

- Registers Starship initialization for **Bash**.
- Registers Starship initialization for **Zsh**.

#### Shell Functions

| Function             | Description                                                                    |
|----------------------|--------------------------------------------------------------------------------|
| `__starship_newline` | Bash helper that adds a blank line before each prompt except the first prompt. |
| `starship_newline`   | Zsh helper that adds a blank line before each prompt except the first prompt.  |

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

Within the provisioner, Zsh serves as the foundation for many shell integrations installed by other modules.

### Installation Method

**APT package (Linux Mint / Ubuntu repository)**

Installs Zsh from the distribution package repository and configures it as the default interactive shell for the current
user.

### Supported ENV

- `ZSH_SKIP_CONFIGURATION`
    - Skip post-install configuration.
    - Default:
      `${SKIP_CONFIGURATION}`

- `ZSH_FORCE_CONFIGURATION`
    - Overwrite existing configuration files.
    - Default:
      `${FORCE_CONFIGURATION}`

### Post-install Configuration

#### Installed Configuration

- Creates the provisioner's Zsh configuration directory.
- Installs the bundled `.zshrc`.
- Installs the module loader.
- Installs helper functions used by other provisioner modules.
- Configures automatic loading of provisioner-managed shell integrations.
- Preserves existing configuration unless `ZSH_FORCE_CONFIGURATION=true`.

#### Shell Integration

The provisioner automatically loads shell integrations installed by other modules from the generated loader file,
allowing modules to contribute aliases, functions, completions, and environment variables without modifying `.zshrc`.

### Official Website

https://www.zsh.org/
