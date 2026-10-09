# 🌐 Web (`web`)

Web-related applications for browsing, communicating, and working online.

## Contents

- [Brave Browser](#brave-browser-brave-browser-alias-brave)
- [Brave Origin](#brave-origin-brave-origin-alias-origin)
- [Google Chrome](#google-chrome-google-chrome-alias-chrome)
- [LibreWolf](#librewolf-librewolf)
- [Microsoft Edge](#microsoft-edge-microsoft-edge-alias-edge)

---

## Brave Browser (`brave-browser`) [alias: `brave`]

Brave is a privacy-focused Chromium browser with built-in ad and tracker blocking.

### Installation Method

**Official Brave APT repositories**

Supports Release, Beta, and Nightly channels.

### Supported ENV

- `BRAVE_BROWSER_CHANNEL`
    - Supported values: `release`, `stable`, `beta`, `nightly`.
    - Default: `release`

Multiple channels can be installed side by side. Use `--force` when another Brave Browser channel is already installed.

### Official Website

https://brave.com/

---

## Brave Origin (`brave-origin`) [alias: `origin`]

Brave Origin is a streamlined Brave browser with optional features disabled by default. It is available for free on Linux.

### Installation Method

**Official Brave APT repositories**

Supports Release, Beta, and Nightly channels.

### Supported ENV

- `BRAVE_ORIGIN_CHANNEL`
    - Supported values: `release`, `stable`, `beta`, `nightly`.
    - Default: `release`

Multiple channels can be installed side by side. Use `--force` when another Brave Origin channel is already installed.

### Official Website

https://brave.com/origin/

---

## Google Chrome (`google-chrome`) [alias: `chrome`]

Google Chrome is Google's Chromium-based web browser. The module supports Stable, Beta, Unstable, and Canary channels.

### Installation Method

**Official Google Chrome APT repository**

Configures Google's Chrome repository and installs the selected package:

| Channel  | Package                  |
|----------|--------------------------|
| Stable   | `google-chrome-stable`   |
| Beta     | `google-chrome-beta`     |
| Unstable | `google-chrome-unstable` |
| Canary   | `google-chrome-canary`   |

Multiple Chrome channels can be installed side by side. Use `GOOGLE_CHROME_CHANNEL` to select a channel directly. If a
Chrome channel is already installed, add `--force` to run the module again and install another channel.

Example without prompts:

```bash
GOOGLE_CHROME_CHANNEL=beta mp install --non-interactive web/google-chrome
```

### Supported ENV

- `GOOGLE_CHROME_CHANNEL`
    - Supported values: `stable`, `beta`, `unstable`, `canary`.
    - Default: `stable` in non-interactive mode.

### Repository

Uses Google's APT repository (`https://dl.google.com/linux/chrome-stable/deb/`, suite `stable`, component `main`),
signed with the key from `https://dl.google.com/linux/linux_signing_key.pub`. The source file is named
`google-chrome.sources`, the same name the Chrome package uses, so the package updates it instead of adding a duplicate.

### Official Website

https://www.google.com/chrome/

---

## LibreWolf (`librewolf`)

### Installation Method

**Official LibreWolf repository**

Mint Provisioner uses the official LibreWolf repository and configures it independently without relying on `extrepo`.

### Official Website

https://librewolf.net/

---

## Microsoft Edge (`microsoft-edge`) [alias: `edge`]

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

Example without prompts:

```bash
MICROSOFT_EDGE_CHANNEL=dev mp install --non-interactive web/microsoft-edge
```

To select a channel interactively when Edge is already installed:

```bash
mp install --force web/microsoft-edge
```

### Supported ENV

- `MICROSOFT_EDGE_CHANNEL`
    - Supported values: `stable`, `beta`, `dev`, `canary`.
    - Default: `stable` in non-interactive mode.

### Post-install Configuration

Disables Edge's repository updater that may conflict with the repository managed by Mint Provisioner. This adjustment runs as part of `mp install`; use `mp install --force web/microsoft-edge` to run the module again.

### Official Website

https://www.microsoft.com/edge/download

---

