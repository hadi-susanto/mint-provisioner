# ⚙️ DevOps Tools (`ops`)

Containers, GitOps, cloud, secrets, and infrastructure tooling. Modules in this category help run, deploy, and operate
services from a development machine.

## Contents

- [Argo CD CLI](#argo-cd-cli-argocd)
- [cloudflared](#cloudflared-cloudflared)
- [Consul](#consul-consul)
- [Docker](#docker-docker)
- [Google Cloud CLI](#google-cloud-cli-gcloud)
- [K9s](#k9s-k9s)
- [kubectl](#kubectl-kubectl)
- [mkcert](#mkcert-mkcert)
- [Vault](#vault-vault)

---

## Argo CD CLI (`argocd`)

The Argo CD CLI is the command-line client for Argo CD, the declarative GitOps continuous delivery tool for Kubernetes.
It manages applications, projects, clusters, repositories, and sync operations from the terminal.

### Installation Method

**GitHub latest release (precompiled binary)**

The installer downloads the latest `argocd-linux-amd64` binary from the official GitHub releases page, verifies its
SHA-256 digest, and creates a symbolic link for the executable.

### Supported ENV

- `ARGOCD_INSTALL_DIR`
    - Installation directory.
    - Default: `${INSTALL_DIR}/argocd`
    - Must be writable by the current user; the resolved path is recorded in the module registry after installation.

### Official Website

https://argo-cd.readthedocs.io/en/stable/cli_installation/

---

## cloudflared (`cloudflared`)

cloudflared is the Cloudflare Tunnel connector. It creates outbound-only tunnels that expose local services and private
networks through Cloudflare without opening inbound ports.

### Installation Method

**GitHub latest release (`.deb` package)**

The installer downloads the latest Linux amd64 `.deb` (not the FIPS build) from the official GitHub releases page,
verifies its SHA-256 digest, and installs it with APT.

### Supported ENV

None.

### Post-install Guide

The module does not log in, create tunnels, or install the service. After installation, authenticate with:

```bash
cloudflared tunnel login
```

### Official Website

https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/

---

## Consul (`consul`)

Consul is HashiCorp's tool for service discovery, service mesh, and distributed key-value storage.

### Installation Method

**Official website (precompiled archive)**

Resolves the latest release through HashiCorp's version API, downloads `consul_<version>_linux_amd64.zip` from
`releases.hashicorp.com`, and installs it for on-demand use. No service, APT repository, or system configuration is
created. Only AMD64 is supported.

### Supported ENV

- `CONSUL_INSTALL_DIR`
    - Directory holding the binary, configuration, and wrapper scripts.
    - Default: `${INSTALL_DIR}/consul`
- `CONSUL_DATA_DIR`
    - Directory used to store Consul data.
    - Default: `${CONSUL_INSTALL_DIR}/data`

Both must be absolute paths containing only letters, digits, and `. _ / @ + -` because they are written into the
generated scripts and configuration.

### Installation Layout

```
${CONSUL_INSTALL_DIR}/
├── bin/consul   # real binary, not on PATH
├── agent.json   # configuration, regenerated on every install
├── consul       # wrapper, symlinked into /usr/local/bin
└── data         # data directory (default location)
```

The `consul` wrapper runs the real binary and adds `-config-file=<dir>/agent.json` automatically for the `agent` subcommand unless
you pass your own; every other subcommand is passed through unchanged.

Start a single-node server with `consul agent`. The UI is available at http://127.0.0.1:8500.

Install and reinstall overwrite the binary, configuration, and wrappers, so local edits to `agent.json` / `server.json` are lost on reinstall; pass your own `-config-file` / `-config`
instead.
`mp remove` deletes everything except the data directory; `mp purge` deletes that too.

### Official Website

https://developer.hashicorp.com/consul

---

## Docker (`docker`)

Docker Engine is a container runtime and development platform for building, running, and managing containerized
applications. The module also installs Docker Compose and Docker Buildx.

### Installation Method

**Official Docker APT repository**

Adds Docker's vendor-managed Ubuntu repository and signing key, then installs:

- `docker-ce`
- `docker-ce-cli`
- `containerd.io`
- `docker-buildx-plugin`
- `docker-compose-plugin`

The module requires `rsync` before installation because existing Docker data is migrated to the configured library
directory. The pre-installation phase fails when `rsync` is unavailable.

### Supported ENV

- `DOCKER_LIB_INSTALL_DIR`
    - Directory used to store Docker images, containers, volumes, and other daemon data.
    - Must be an absolute path.
    - Must be writable by the current user before installation begins.
    - Must not be `/`, `/var/lib/docker`, a parent of `/var/lib/docker`, or a directory inside it.
    - Default: `${INSTALL_DIR}/docker-lib`

### Installation Configuration

During installation, the module:

- Installs Docker Engine, Docker Compose, and Docker Buildx.
- Checks whether `/var/lib/docker` was created by Docker.
- Skips data migration and displays a warning when `/var/lib/docker` does not exist.
- Stops the Docker service and socket before migrating existing data.
- Copies `/var/lib/docker` into `DOCKER_LIB_INSTALL_DIR` using `rsync`.
- Preserves numeric user and group IDs during migration.
- Records the resolved data destination in the module registry after a successful migration.
- Configures Docker's `data-root` in `/etc/docker/daemon.json`.
- Preserves an existing `daemon.json` and asks the user to verify it manually.
- Restarts Docker after migration.
- Adds the current non-root user to the `docker` group when the group exists.
- Displays manual instructions when the `docker` group does not exist.
- Preserves the original `/var/lib/docker` contents for manual verification and removal.

The saved installation state is removed by `cleanup.sh` after installation completes.

After being added to the `docker` group, log out and sign in again before running Docker commands without `sudo`.

### Official Website

https://www.docker.com/

### Documentation

https://docs.docker.com/engine/

---

## Google Cloud CLI (`gcloud`)

Google Cloud CLI (`gcloud`) is Google's official command-line interface for managing Google Cloud
resources and services. It provides commands for authentication, project and configuration
management, resource administration, application deployment, and interaction with Google Cloud APIs.

### Installation Method

**Official APT repository**

Installs the Google Cloud CLI from Google's official APT package repository.

### Official Website

https://cloud.google.com/sdk

---

## K9s (`k9s`)

K9s is a terminal UI for navigating, observing, and managing Kubernetes clusters. It reads the same kubeconfig as
`kubectl`.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads `k9s_Linux_amd64.tar.gz` from the latest derailed/k9s GitHub release, verifies its SHA-256 digest, and
installs the binary for the current user. Only AMD64 is supported.

### Supported ENV

* `K9S_INSTALL_DIR`

  * Installation directory.
  * Default: `${INSTALL_DIR}/k9s`
  * Must be writable by the current user; the resolved path is recorded in the
    module registry after installation.

### Official Website

https://k9scli.io/

### GitHub Repository

https://github.com/derailed/k9s

---

## kubectl (`kubectl`)

kubectl is the Kubernetes command-line tool for running commands against clusters.

### Installation Method

**Official website (precompiled binary)**

Resolves the latest stable release from `dl.k8s.io/release/stable.txt`, downloads the `linux/amd64` binary, and
verifies it against the SHA-256 published beside it. No APT repository is configured. Only AMD64 is supported.

### Supported ENV

* `KUBECTL_INSTALL_DIR`

  * Installation directory.
  * Default: `${INSTALL_DIR}/kubectl`
  * Must be writable by the current user; the resolved path is recorded in the
    module registry after installation.

### Removal

`mp purge` also deletes `~/.kube` (kubeconfig and cache).

### Official Website

https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

---

## mkcert (`mkcert`)

mkcert is a simple command-line tool for creating locally trusted development
TLS certificates. It automatically creates a local CA and installs it into
supported system and browser trust stores.

### Installation Method

**GitHub latest release (precompiled archive)**

Downloads the latest precompiled mkcert binary directly from the project's
GitHub releases.

### Supported ENV

* `MKCERT_INSTALL_DIR`

  * Installation directory.
  * Default: `${INSTALL_DIR}/mkcert`
  * Must be writable by the current user; the resolved path is recorded in the
    module registry after installation.

### Official Website

https://github.com/FiloSottile/mkcert

---

## Vault (`vault`)

Vault is HashiCorp's tool for secrets management, encryption as a service, and privileged access management.

### Installation Method

**Official website (precompiled archive)**

Resolves the latest release through HashiCorp's version API, downloads `vault_<version>_linux_amd64.zip` from
`releases.hashicorp.com`, and installs it for on-demand use. No service, APT repository, or system configuration is
created. Only AMD64 is supported.

### Supported ENV

- `VAULT_INSTALL_DIR`
    - Directory holding the binary, configuration, and wrapper scripts.
    - Default: `${INSTALL_DIR}/vault`
- `VAULT_DATA_DIR`
    - Directory used to store Vault data.
    - Default: `${VAULT_INSTALL_DIR}/data`

Both must be absolute paths containing only letters, digits, and `. _ / @ + -` because they are written into the
generated scripts and configuration.

### Installation Layout

```
${VAULT_INSTALL_DIR}/
├── bin/vault    # real binary, not on PATH
├── server.json  # configuration, regenerated on every install
├── vault        # wrapper, symlinked into /usr/local/bin
├── vault-init   # `vault operator init` with one key share, symlinked into /usr/local/bin
├── vault-unseal # `vault operator unseal`, uses VAULT_UNSEAL_TOKEN if set, symlinked into /usr/local/bin
└── data         # data directory (default location)
```

The `vault` wrapper runs the real binary and adds `-config=<dir>/server.json` automatically for the `server` subcommand unless you
pass your own; every other subcommand is passed through unchanged.

Start the server with `vault server` (UI at http://127.0.0.1:8200; `VAULT_ADDR` defaults to it in the wrapper).
Initialize once with `vault-init`, which runs `vault operator init -key-shares=1 -key-threshold=1`, so a single unseal key
is required. The key count is fixed at initialization, so it cannot be set in `server.json`. Unseal with
`vault-unseal`, a wrapper for `vault operator unseal`: with no arguments and `VAULT_UNSEAL_TOKEN` set it unseals with that
key (convenient for local development; the key is visible in the process list while the command runs). Otherwise
arguments are passed through, or the key is typed at Vault's hidden prompt. The listener binds to `127.0.0.1` only. Vault locks its memory, which an unprivileged process may only do with
`CAP_IPC_LOCK`, so the installer runs `sudo setcap cap_ipc_lock=+ep` on `bin/vault` (requires `setcap` from
`libcap2-bin`). The capability is lost when the binary is replaced, so it is granted on every install.

Install and reinstall overwrite the binary, configuration, and wrappers, so local edits to `agent.json` / `server.json` are lost on reinstall; pass your own `-config-file` / `-config`
instead.
`mp remove` deletes everything except the data directory; `mp purge` deletes that too.

### Official Website

https://developer.hashicorp.com/vault
