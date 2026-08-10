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

4. Implement the required `install.sh` with a shebang and `set -euo pipefail` immediately after it.
5. Add optional lifecycle scripts only when needed:
    - `installed.sh` for an installed-state check more accurate than command detection.
    - `interactive.sh` for choices or validation that must complete before any selected module is installed.
    - `pre_install.sh` for prerequisites, repositories, keys, downloads, and temporary setup.
    - `post_install.sh` for installation-adjacent adjustments after successful installation.
    - `cleanup.sh` for temporary state, downloads, and intermediate files.
6. Add `helper.sh` and `resources/` when the module needs local reusable functions or payloads.
7. Document the module in its category page with its installation method, supported environment variables, relevant
   registry behavior, integrations, and official project link.

## Installed-State Detection

The framework checks, in order:

1. `installed.sh`, when present.
2. Every command in `CLI` metadata.
3. The module ID basename.

Keep `installed.sh` free of side effects. Return `0` when installed, `1` when not installed, and another non-zero status
when detection itself fails. Use this script when validating package variants, files, registry data, or several related
artifacts.

## Interactive and Non-Interactive Behavior

`interactive.sh` runs for every module queued by `mp install` before any installation phase begins. It should store
decisions that later phases need through the state library.

Do not ask users to set global `NON_INTERACTIVE`. The public interface is:

```bash
mp install --non-interactive <module>
mp install --unattended <module>
```

In either mode, the framework runs `interactive.sh` with `NON_INTERACTIVE=true` in that script's environment. The script
must not prompt; it should use explicitly supplied values, detection, or documented defaults. A module may expose a
documented `*_NON_INTERACTIVE` override when its behavior needs a module-specific control.

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
not remove durable registry data in ordinary `cleanup.sh`; reserve removal for a future explicit uninstall or
registry-management workflow.

Use the state library for temporary values shared between phases, and ensure `cleanup.sh` removes temporary files that
cannot be discovered from saved state.
