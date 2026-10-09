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
