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
