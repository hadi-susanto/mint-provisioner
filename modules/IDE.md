# IDE (`ide`)

Integrated development environments and source-code editors for software development,
ranging from lightweight editors to full-featured IDEs. This vendor-neutral category can include products such as
Visual Studio Code, Geany, and CudaText alongside the JetBrains products currently documented below.

## Contents

- [CudaText](#cudatext-cudatext)
- [Geany](#geany-geany)
- [Visual Studio Code](#visual-studio-code-vscode)
- [VSCodium](#vscodium-vscodium)
- [IntelliJ IDEA](#intellij-idea-idea)
- [PyCharm](#pycharm-pycharm)
- [GoLand](#goland-goland)
- [PhpStorm](#phpstorm-phpstorm)
- [WebStorm](#webstorm-webstorm)
- [CLion](#clion-clion)
- [Rider](#rider-rider)
- [RubyMine](#rubymine-rubymine)
- [RustRover](#rustrover-rustrover)
- [DataGrip](#datagrip-datagrip)

---

## CudaText (`cudatext`)

CudaText is a cross-platform text and code editor with a Python plugin system.

### Installation Method

**Latest SourceForge `.deb` release** for the selected GTK or Qt toolkit.

### Supported ENV

- `CUDATEXT_UI_TOOLKIT`
    - Selects the CudaText package variant.
    - Supported values: `auto`, `gtk2`, `gtk3`, `qt5`, and `qt6`.
- `CUDATEXT_NON_INTERACTIVE`
    - Disables the toolkit selection prompt and uses automatic detection when `CUDATEXT_UI_TOOLKIT` is unset.
    - Falls back to `${NON_INTERACTIVE}`.

### Official Website

https://cudatext.github.io/

---

## Geany (`geany`)

Geany is a fast, lightweight IDE with a small footprint and support for many programming languages.

### Installation Method

**Geany Developers Launchpad PPA** (`ppa:geany-dev/ppa`), using the `geany` package.

By default, Mint Provisioner configures the PPA explicitly with signing-key fingerprint
`DE52D7C0594C5BDBF940922B361331969CA95183`. It can use `add-apt-repository` instead when requested.

### Supported ENV

- `GEANY_USE_APT_ADD_REPOSITORY`
    - Controls whether the Launchpad repository is added using `add-apt-repository`.
    - Falls back to `${USE_APT_ADD_REPOSITORY}`.

### Official Website

https://www.geany.org/

---

## Shared JetBrains module behavior

The JetBrains modules in this category query the official JetBrains release metadata service for the latest stable
release. Each module downloads the Linux x86_64 archive and its official SHA-256 checksum, then verifies the archive
before installation. When `aria2c` is available, the installation archive uses four concurrent connections; otherwise
it uses the standard framework downloader. ARM archives are not currently supported.

`jq` is required to process the release metadata. When `jq` is missing, interactive installations ask whether Mint
Provisioner may install it. Non-interactive installations do not grant that permission implicitly.

`aria2` is an optional download accelerator. When `aria2c` is missing, interactive installations ask whether Mint
Provisioner may install `aria2`. Non-interactive installations default to the standard downloader unless automatic
installation was explicitly authorized.

Each JetBrains IDE is extracted into its configured installation directory. Its bundled native launcher is linked under
`/usr/local/bin` using the launcher's filename, such as `idea` or `goland`. Each module also installs a system-wide
desktop entry and application icon. The JetBrains Runtime bundled with each IDE is used.

### Shared JetBrains supported ENV

- `JETBRAINS_AUTO_INSTALL_JQ`
    - Controls whether Mint Provisioner may install `jq` when it is unavailable.
    - Supported values: `true` and `false`.
    - When unset in interactive mode and `jq` is missing, the module asks for permission.
    - When unset in non-interactive mode, defaults to `false`.

- `JETBRAINS_AUTO_INSTALL_ARIA2`
    - Controls whether Mint Provisioner may install `aria2` when `aria2c` is unavailable.
    - Supported values: `true` and `false`.
    - When unset in interactive mode and `aria2c` is missing, the module asks for permission.
    - When unset in non-interactive mode, defaults to `false` and uses the standard downloader.

- `JETBRAINS_NON_INTERACTIVE`
    - Disables the shared JetBrains dependency prompt.
    - Falls back to `${NON_INTERACTIVE}`.
    - A product-specific `*_NON_INTERACTIVE` variable takes precedence.

---

## IntelliJ IDEA (`idea`)

IntelliJ IDEA is JetBrains' unified IDE for JVM and full-stack development. Core functionality is available without a
subscription, while advanced framework, database, and enterprise features require an appropriate license.

### Installation Method

**Official JetBrains release archive** using product identifier `IIU`.

### Supported ENV

- `IDEA_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/idea`
- `IDEA_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/idea/

---

## PyCharm (`pycharm`)

PyCharm is JetBrains' unified IDE for Python development, data science, notebooks, and web applications.

### Installation Method

**Official JetBrains release archive** using product identifier `PCP`.

### Supported ENV

- `PYCHARM_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/pycharm`
- `PYCHARM_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/pycharm/

---

## GoLand (`goland`)

GoLand is JetBrains' IDE for Go development, with integrated code analysis, refactoring, testing, and debugging.

### Installation Method

**Official JetBrains release archive** using product identifier `GO`.

### Supported ENV

- `GOLAND_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/goland`
- `GOLAND_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/go/

---

## PhpStorm (`phpstorm`)

PhpStorm is JetBrains' IDE for PHP and web development, with framework support, database tools, and debugging.

### Installation Method

**Official JetBrains release archive** using product identifier `PS`.

### Supported ENV

- `PHPSTORM_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/phpstorm`
- `PHPSTORM_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/phpstorm/

---

## WebStorm (`webstorm`)

WebStorm is JetBrains' IDE for JavaScript, TypeScript, and modern web application development.

### Installation Method

**Official JetBrains release archive** using product identifier `WS`.

### Supported ENV

- `WEBSTORM_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/webstorm`
- `WEBSTORM_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/webstorm/

---

## CLion (`clion`)

CLion is JetBrains' IDE for C and C++ development, with code analysis, CMake, debugging, and embedded tooling.

### Installation Method

**Official JetBrains release archive** using product identifier `CL`.

### Supported ENV

- `CLION_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/clion`
- `CLION_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/clion/

---

## Rider (`rider`)

Rider is JetBrains' cross-platform IDE for .NET, C#, ASP.NET, Unity, and related development workflows.

### Installation Method

**Official JetBrains release archive** using product identifier `RD`.

### Supported ENV

- `RIDER_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/rider`
- `RIDER_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/rider/

---

## RubyMine (`rubymine`)

RubyMine is JetBrains' IDE for Ruby and Rails development, with code intelligence, testing, and debugging.

### Installation Method

**Official JetBrains release archive** using product identifier `RM`.

### Supported ENV

- `RUBYMINE_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/rubymine`
- `RUBYMINE_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/ruby/

---

## RustRover (`rustrover`)

RustRover is JetBrains' IDE for Rust development, with Cargo integration, code analysis, testing, and debugging.

### Installation Method

**Official JetBrains release archive** using product identifier `RR`.

### Supported ENV

- `RUSTROVER_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/rustrover`
- `RUSTROVER_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/rust/

---

## DataGrip (`datagrip`)

DataGrip is JetBrains' database IDE for querying, developing, and managing multiple database systems.

### Installation Method

**Official JetBrains release archive** using product identifier `DG`.

### Supported ENV

- `DATAGRIP_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/datagrip`
- `DATAGRIP_NON_INTERACTIVE`
    - Product-specific override for JetBrains non-interactive configuration.

### Official Website

https://www.jetbrains.com/datagrip/
