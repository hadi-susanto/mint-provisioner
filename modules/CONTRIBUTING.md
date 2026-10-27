# Contributing Modules

Use this guide when adding a new Mint Provisioner category or module. The module lifecycle and metadata reference live
in [README.md](README.md).

## Add a Category

1. Choose a short, lowercase, hyphenated category ID that does not overlap an existing category.
2. Create `modules/<category>/metadata.conf`:

   ```ini
   NAME="Category Display Name"
   DESCRIPTION="One concise sentence describing the category."
   ```

3. Add an uppercase category page, such as `modules/EXAMPLE.md`, documenting the category's modules.
4. Add the category and its modules to the catalog table in [README.md](README.md).

Category metadata requires `NAME` and `DESCRIPTION`. Category-specific shared helpers may live directly under the
category directory when several modules need them.

## Add a Module

1. Create `modules/<category>/<module>/` using a lowercase, hyphenated module ID.
2. Add `metadata.conf` with the required metadata:

   ```ini
   NAME="Example App"
   DESCRIPTION="A concise explanation of what the module installs."
   SOURCE="github"
   ```

   `SOURCE` must be one of `native`, `ppa`, `apt`, `github`, `sourceforge`, or `external`.

   Source values mean:
   - `native`: Supported directly by operating-system package sources without extra setup.
   - `ppa`: Uses a Launchpad PPA repository.
   - `apt`: Uses a third-party APT repository outside Launchpad PPA.
   - `github`: Downloads an artifact from GitHub or installs from a GitHub repository.
   - `sourceforge`: Downloads an artifact from SourceForge.
   - `external`: Downloads an artifact from a third-party vendor source.

3. Add `CLI` only when default command detection needs an executable name other than the module ID or needs multiple
   commands:

   ```ini
   CLI="example,example-helper"
   ```

   Every comma-separated command must be non-empty and resolve on `PATH`. Omit `CLI` when the module ID basename is
   sufficient.

4. Set `UPDATE_MODE` so `mp outdated` can report the module's versions (see "Version Tracking" below):

   ```ini
   UPDATE_MODE="github"
   UPDATE_REPOSITORY="example/example-app"
   ```

5. Implement the required `install.sh` with a shebang and `set -euo pipefail` immediately after it.
6. Add optional lifecycle scripts only when needed:
    - `installed.sh` for an installed-state check more accurate than command detection.
    - `latest.sh` to print the latest available version; required by `UPDATE_MODE="external"`.
    - `interactive.sh` for choices or validation that must complete before any selected module is installed.
    - `non-interactive.sh` for the no-prompt equivalent of `interactive.sh`. It is valid only when `interactive.sh`
      exists; without it, the module does not support non-interactive installation.
    - `pre-install.sh` for prerequisites, repositories, keys, downloads, and temporary setup.
    - `post-install.sh` for installation-adjacent adjustments after successful installation.
    - `cleanup.sh` for temporary state, downloads, and intermediate files.
    - `pre-upgrade.sh` and `upgrade.sh` so `mp upgrade` can upgrade an `UPDATE_MODE="github"`, `"external"`, or `"git"` module: download the
      new release, then replace the installed files with `stateful_deb_upgrade`, `stateful_extract_upgrade`, or
      `stateful_binary_upgrade` (see "Upgrade Phases" in `modules/AGENTS.md`).
    - `remove.sh` to support `mp remove`, `mp uninstall`, and `mp purge`. Undo exactly what the install phases created
      with the helpers in `lib/remover/`; user configuration and data are removed only through the helpers that honor
      `PURGE`. Every module in the catalog ships one, so new modules should too.
7. Add `helper.sh` and `resources/` when the module needs local reusable functions or payloads.
8. Document the module in its category page with its installation method, supported environment variables, relevant
   registry behavior, integrations, and official project link.

## Installed-State Detection

The framework checks, in order:

1. `installed.sh`, when present.
2. Every command in `CLI` metadata.
3. The module ID basename.

Keep `installed.sh` free of side effects. Return `0` when installed, `1` when not installed, and another non-zero status
when detection itself fails. Use this script when validating package variants, files, registry data, or several related
artifacts.

## Version Tracking

Choose the `UPDATE_MODE` that matches how the module installs:

- `apt`: packages from APT. Set `UPDATE_PACKAGE` to the main package, or to comma-separated candidates without spaces
  when the package depends on an installation choice (the first installed one is checked).
- `github`: release assets found with `github_find_release_asset`. Set `UPDATE_REPOSITORY="owner/repo"` and pass
  `"${asset[VERSION]}"` as the last argument of `stateful_download` for the main download.
- `external`: vendor downloads. Add a read-only `latest.sh` that prints the latest version, resolve the version in
  `pre-install.sh` with `module_latest_version` (`lib/workflow/latest-version.sh`), build the download URL from it,
  and pass it to `stateful_download`.
- `git`: git clones. Save the clone directory as registry `INSTALL_PATH` (`git_clone_install` does this), and ship an
  `upgrade.sh` that calls `git_pull_upgrade` (see "Upgrade Phases" in `modules/AGENTS.md`).
- `none`: modules without one meaningful version.

For `github` and `external`, `stateful_deb_install`, `stateful_extract_install`, and `stateful_binary_install` record
the version as registry `VERSION`. A custom `install.sh` must call `record_version_registry "$CANONICAL_ID"`
(`lib/workflow/version-registry.sh`). The full rules are in [AGENTS.md](AGENTS.md).

## Interactive and Non-Interactive Behavior

`interactive.sh` runs for every module queued by a normal `mp install` before any installation phase begins. It should
store decisions that later phases need through the state library.

Do not ask users to set global `NON_INTERACTIVE`. The public interface is:

```bash
mp install --non-interactive <module>
mp install --unattended <module>
```

In either mode, the framework runs `non-interactive.sh` instead of `interactive.sh` for modules that provide interactive
setup. The non-interactive phase must not prompt; it should use explicitly supplied values, detection, or documented
defaults. Do not add a module-specific non-interactive environment-variable override.

Use `mp install --force <module>` to requeue a module that installed-state detection reports as already installed. Force
does not skip selector resolution, metadata validation, installed-state detection, or the interactive session.

## Registry and Cleanup

Use the registry library for facts that must survive ordinary cleanup, such as an installation path, installed version,
or module-managed component list. Save registry values only after successful required installation work:

```bash
source "$LIB_INSTALLER/registry.sh"

set_registry "INSTALL_PATH" "$install_path"
save_registry "$CANONICAL_ID"
```

Registry files are stored under `$HOME/.local/state/mint-provisioner/registry/<category>/<module>.registry`.
`installed.sh` may load and verify the registry, but its presence alone must not be treated as proof of installation. Do
not remove durable registry data in ordinary `cleanup.sh`; removal belongs to `remove.sh`: the framework
deletes the registry after `remove.sh` succeeds, and `remove.sh` reads it first with `remove_install_dir` or
`remove_registry_data_dir`. When `remove_registry_data_dir` keeps the directory (no purge), it marks the registry
`DATA_RETAINED=1` and the framework keeps the registry for a later `mp purge`.

Use the state library for temporary values shared between phases, and ensure `cleanup.sh` removes temporary files that
cannot be discovered from saved state.

## Shared Installation Workflows

Prefer helpers from `lib/workflow` when a module uses a common installation sequence. The workflow library provides
shared target resolution, stateful download and installation steps, cleanup, and reusable product-specific resolvers.
Source the smallest applicable helper from `$LIB_WORKFLOW` rather than duplicating a common sequence in a module phase.
