# ❓ Frequently Asked Questions

## GitHub Module Fails with `403 Rate Limited`

### Problem

The GitHub module fails with a cURL error similar to:

```text
403 Rate Limited
```

This happens when GitHub's API rate limit for unauthenticated requests
has been exceeded.

### Solution

Create a GitHub Personal Access Token (PAT) and provide it through the
`GITHUB_TOKEN` environment variable.

The token does **not** require any permissions. A token without
permissions is sufficient for authenticated requests to public
repositories.

For example:

```bash
export GITHUB_TOKEN="github_pat_..."
```

Then run the Mint Provisioner command again:

```bash
mp install ...
```

Alternatively, provide the token for a single invocation:

```bash
GITHUB_TOKEN="github_pat_..." mp install ...
```

> **Note:** Mint Provisioner only requires the token for GitHub API
> authentication. It does not require access to private repositories.

## Interactive Prompts Look Broken or Render Oddly

### Problem

Interactive module questions are shown as `whiptail` dialogs, which may render
poorly in some terminals (for example limited terminal emulators, serial
consoles, or unusual `TERM` values).

### Solution

Set `DISABLE_WHIPTAIL=true` to force the plain-text prompts, which only need
Bash:

```bash
DISABLE_WHIPTAIL=true mp install ...
```

Mint Provisioner uses `whiptail` automatically when it is installed and
`TERM` is set to something other than `dumb`; otherwise it already falls back
to plain-text prompts. Only the exact value `true` disables `whiptail`.

## How Do I Unseal Vault Automatically?

### Problem

Vault starts sealed, so every `vault server` start needs `vault-unseal` and the unseal key typed at its hidden prompt.

### Solution

For local development only, export the unseal key as `VAULT_UNSEAL_TOKEN`. When `vault-unseal` runs with no arguments, it
unseals with that key:

```bash
export VAULT_UNSEAL_TOKEN="<unseal key printed by vault-init>"
vault server &
vault-unseal
```

The key is created by `vault-init` (one key share, threshold 1) and is only printed once, so save it first.

Arguments always win: `vault-unseal <key>` ignores `VAULT_UNSEAL_TOKEN`. With neither, Vault asks for the key at its
hidden prompt.

> **Note:** The key is passed to Vault as a command-line argument, so it is visible in the process list while the
> command runs, and wherever you export `VAULT_UNSEAL_TOKEN` (for example `~/.bashrc`) it is stored in plain text. Do not
> use this for anything but a local development Vault.

## XML Files Still Open in My Old Editor After Installing Gram

### Problem

After installing Gram and setting it as the default text editor, `.xml` files still open in another editor
(for example `xed`).

Gram's desktop entry declares only the `text/plain` MIME type. Setting a default text editor changes only that type,
while XML files use `application/xml` (also known as `text/xml`).

### Solution

Set Gram as the default for the XML types:

```bash
gio mime application/xml app.liten.Gram.desktop
gio mime text/xml app.liten.Gram.desktop
```

If `gio` refuses, use `xdg-mime` instead:

```bash
xdg-mime default app.liten.Gram.desktop application/xml text/xml
```

Both commands change only your user settings in `~/.config/mimeapps.list`. Other file types, such as `.json`, `.md`,
and `.yaml`, have their own MIME types and may need the same command.
