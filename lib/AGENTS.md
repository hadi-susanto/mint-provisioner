# Library Development Guidelines

This directory contains reusable Bash libraries shared by Mint Provisioner commands and modules.

Libraries should expose coherent, narrowly scoped functions and must remain safe when sourced by command scripts running with strict shell options.

## Script Header

Every library file must include a Bash shebang:

```bash
#!/usr/bin/env bash
```

The shebang is required for consistency and editor or tooling detection, even though library files are intended to be sourced rather than executed directly.

Library files must not enable strict mode:

```bash
set -euo pipefail
```

Do not add `set -e`, `set -u`, `set -o pipefail`, or equivalent strict-mode declarations to a library.

The calling script owns the shell execution mode.

## Strict-Mode Compatibility

Although libraries do not enable `set -euo pipefail`, their functions must be compatible with callers that do.

Any command that may legitimately return a non-zero status must be handled explicitly.

Use conditional commands:

```bash
if command_that_may_fail; then
    ...
fi
```

Use an explicit fallback:

```bash
command_that_may_fail || return $?
```

Capture an expected failure safely:

```bash
local status

if output="$(command_that_may_fail)"; then
    :
else
    status=$?
    log_error "Command failed"

    return "$status"
fi
```

Do not leave potentially failing commands unguarded when their failure is expected, recoverable, or should be propagated intentionally.

Be especially careful with:

* `grep`
* `read`
* `command -v`
* command substitutions
* pipelines
* file tests implemented through external commands
* commands used only to inspect whether something exists
* arithmetic expressions whose result may produce a non-zero status

Functions should return statuses intentionally rather than relying on incidental exit statuses from their final command.

## Double-Sourcing Guard

Every library must include a guard that prevents it from being initialized more than once.

Place the guard immediately after the shebang and before sourcing another library.

Example:

```bash
#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_EXTERNAL_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_EXTERNAL_INSTALLER_LOADED=1
```

The guard variable must:

* Be unique to the library.
* Use a project-specific prefix.
* Be safe when `set -u` is enabled.
* Be defined before another library is sourced.

Do not use `exit` in a sourcing guard. A library must return control to its caller.

## Library Dependencies

A library may source another library when needed.

Dependencies must be sourced after the double-sourcing guard.

This is commonly used to import foundational libraries such as common utilities or logging functions.

Example:

```bash
#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_EXTERNAL_INSTALLER_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_EXTERNAL_INSTALLER_LOADED=1

source "$LIB_DIR/common.sh"
source "$LIB_DIR/log.sh"
```

Avoid unnecessary dependencies and circular imports.

A lower-level library should not depend on a higher-level library that already depends on it.

## Library Cohesion

Each library must have one clear responsibility.

Functions in the same file should belong to the same functional area.

For example, an external installer library should contain only functions related to installing software from external vendors, such as:

* Adding external package repositories.
* Installing vendor signing keys.
* Downloading vendor-provided artifacts.
* Resolving external release URLs.
* Installing packages unavailable from the standard repository.

It should not contain unrelated functions for:

* Rendering menus.
* Managing module state.
* Parsing command arguments.
* Formatting generic tables.
* Configuring desktop applications.

When a library begins serving multiple unrelated purposes, split it into smaller libraries.

Prefer names that communicate the library responsibility clearly:

```text
external-installer.sh
package-manager.sh
module-state.sh
download.sh
logging.sh
```

## Public and Private Functions

Functions intended for use by other scripts are public functions.

Internal implementation functions must use the `__` prefix:

```bash
__resolve_download_url() {
    ...
}
```

Public functions should use descriptive names without the private prefix:

```bash
install_external_deb() {
    ...
}
```

Keep the public API small. Extract private helpers when they make the implementation easier to understand, test, or reuse internally.

## Public Function Documentation

Every public function must be documented immediately before its declaration.

Use the following format:

```bash
##
# function_name
#
# Short description.
#
# Parameters:
#   package_name - Name of the package to install.
#   repository_url - URL of the package repository.
#
# Output:
#   Description of standard output produced by the function.
#
# Return:
#   0 - Description of the successful result.
#   1 - Description of a known failure condition.
#
function_name() {
    local package_name="$1"
    local repository_url="$2"

    ...
}
```

### Description

Provide a concise explanation of what the function does.

```bash
##
# install_external_package
#
# Installs a package from an external vendor repository.
#
install_external_package() {
    ...
}
```

### Parameters

Parameter names must be human-readable and should match the corresponding local variable names used by the function.

Do not document parameters as `$1`, `$2`, or other positional references.

Prefer:

```bash
# Parameters:
#   package_name - Name of the package to install.
#   repository_url - URL of the external repository.
```

Instead of:

```bash
# Parameters:
#   $1 - Name of the package to install.
#   $2 - URL of the external repository.
```

When the function accepts the name of a variable used as a nameref, describe both the parameter and the expected variable type:

```bash
# Parameters:
#   options_name - Name of the associative array containing command options.
#   modules_name - Name of the indexed array that receives resolved modules.
```

The documented names should correspond to the function implementation:

```bash
resolve_modules() {
    local options_name="$1"
    local modules_name="$2"
    local -n options_ref="$options_name"
    local -n modules_ref="$modules_name"

    ...
}
```

Do not include a `Parameters` section when the function accepts no arguments.

### Output

Document meaningful standard output produced for callers.

```bash
# Output:
#   Prints the resolved package version to standard output.
```

Messages written through logging functions generally do not need to be documented as function output unless logging is the primary purpose of the function.

Do not include an `Output` section when the function produces no meaningful standard output.

### Return

Document meaningful return codes and their conditions.

```bash
# Return:
#   0 - The package is installed.
#   1 - The package is not installed.
#   2 - The installation state could not be determined.
```

When the function only returns `0` and has no meaningful failure status, omit the `Return` section.

Do not document a non-zero return code unless the function can intentionally return it.

## Function Return Behavior

Functions must use explicit return behavior where the result matters.

Example:

```bash
package_installed() {
    local package="$1"

    dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
        grep -Fqx 'install ok installed'
}
```

When a pipeline may run under `pipefail`, handle it intentionally when appropriate:

```bash
package_installed() {
    local package="$1"
    local status

    if ! status="$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null)"; then
        return 1
    fi

    [[ "$status" == "install ok installed" ]]
}
```

Use `return $?` when preserving the exact status is meaningful:

```bash
perform_installation || return $?
```

Use a specific status when translating an implementation failure into a documented API result:

```bash
if ! resolve_package_url package_url; then
    log_error "Unable to resolve package URL"

    return 2
fi
```

## Sourcing Versus Execution

Library files are intended to be sourced.

They must not:

* Call `main`.
* Parse command-line arguments at file scope.
* Perform installations at file scope.
* Modify user files merely because the library was sourced.
* Call `exit`.
* Assume they are running in a separate process.

Initialization at file scope should be limited to:

* Double-sourcing guards.
* Sourcing required dependencies.
* Declaring constants.
* Defining functions.

## Variable Scope

Variables used inside functions should normally be local:

```bash
resolve_package() {
    local package="$1"
    local version
}
```

Use `readonly` for library-level constants where appropriate.

Avoid modifying global variables unless the library API explicitly exists to do so.

When receiving arrays by name, use namerefs:

```bash
resolve_packages() {
    local output_name="$1"
    local -n output_ref="$output_name"

    output_ref=()
}
```

## File Template

Use this structure for new library files:

```bash
#!/usr/bin/env bash

if [[ -n "${__MINT_PROVISIONER_EXAMPLE_LIBRARY_LOADED:-}" ]]; then
    return 0
fi

readonly __MINT_PROVISIONER_EXAMPLE_LIBRARY_LOADED=1

source "$LIB_DIR/common.sh"

##
# example_public_function
#
# Performs one coherent library operation.
#
# Parameters:
#   $1 - Description of the input.
#
# Output:
#   Prints the resolved value to standard output.
#
# Return:
#   1 - The value could not be resolved.
#
example_public_function() {
    local input="$1"
    local result

    if result="$(__example_private_function "$input")"; then
        :
    else
        return $?
    fi

    printf '%s\n' "$result"
}

__example_private_function() {
    local input="$1"

    ...
}
```

