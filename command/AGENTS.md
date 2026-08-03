# Command Development Guidelines

This directory contains executable Bash command implementations used by Mint Provisioner.

Each command should provide a clear command-line interface, separate argument parsing from validation, and keep its main execution flow easy to follow.

## Script Header

Every command script must include a Bash shebang:

```bash
#!/usr/bin/env bash
```

Unlike library files, command scripts are executable entry points or dedicated command handlers.

Every command script must enable strict shell options immediately after the shebang. Any sourced library must remain compatible with those options.

## Command Structure

Command scripts should follow this general structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

source ...

__parse_args() {
    ...
}

__validate_options() {
    ...
}

main() {
    local -A options=()
    local -a args=()

    __parse_args options args "$@" || return $?
    __validate_options options || return $?

    # Main command logic.
}

main "$@"
```

The normal execution order is:

1. Source required libraries.
2. Define private command functions.
3. Parse command-line arguments.
4. Validate parsed options and arguments.
5. Execute the command logic.
6. Call `main "$@"`.

## Argument Parsing

Each command that accepts options or positional arguments should define a private `__parse_args` function.

The parser should receive output variables by name:

```bash
__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=()
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -f | --force)
                options_ref[FORCE]=1
                shift
                ;;

            -h | --help)
                options_ref[HELP]=1
                shift
                ;;

            --)
                shift
                args_ref+=("$@")
                break
                ;;

            -*)
                log_error "Unknown option: $1"

                return 2
                ;;

            *)
                args_ref+=("$1")
                shift
                ;;
        esac
    done
}
```

Initialize option defaults explicitly when needed:

```bash
options_ref[FORCE]=0
options_ref[HELP]=0
```

Argument parsing should be limited to:

* Recognizing options.
* Reading option values.
* Collecting positional arguments.
* Reporting malformed or unknown options.
* Populating the provided output arrays.

Argument parsing should not:

* Install packages.
* Modify files.
* Resolve modules from the filesystem unless required to parse an option value.
* Perform the main command operation.
* Mix validation rules with command execution.

## Option Validation

Each command should define a private `__validate_options` function when validation is required.

Validation must happen after parsing and before performing the command operation.

Example:

```bash
__validate_options() {
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    if (( ${options_ref[ALL]} && ${#args_ref[@]} > 0 )); then
        log_error "The --all option cannot be combined with module names"

        return 2
    fi
}
```

Validation should handle rules such as:

* Mutually exclusive options.
* Missing option values.
* Unsupported option combinations.
* Required positional arguments.
* Maximum or minimum positional argument counts.
* Invalid enum-like values.
* Invalid local or global installation scope.
* Commands that cannot operate on `all` and named targets simultaneously.

The validator should not perform the main operation.

Validation failures should return a consistent non-zero status, normally the command's usage-error status.

## Main Function

Every command script must define and invoke `main`.

```bash
main() {
    local -A options=()
    local -a args=()

    __parse_args options args "$@" || return $?
    __validate_options options args || return $?

    ...
}

main "$@"
```

Always pass `"$@"` to `__parse_args`.

Associative and indexed arrays should be initialized explicitly:

```bash
local -A options=()
local -a args=()
```

Use guard clauses to keep the command flow shallow:

```bash
if (( options[HELP] )); then
    print_help

    return 0
fi
```

Propagate failures intentionally:

```bash
execute_command "${args[@]}" || return $?
```

Do not rely on the incidental status of the final command unless it represents the intended command result.

## Dedicated Command Scripts

A dedicated command script such as `install.sh`, `uninstall.sh`, `list.sh`, or `status.sh` may contain multiple helper functions.

A script does not need to contain only one operation internally.

For example, `list.sh` may:

* List every available module.
* List only modules named by the user.
* Group modules by category.
* Render a detailed or compact view depending on options.

The behavior should still belong to the same command responsibility.

Example:

```bash
__list_all_modules() {
    ...
}

__list_selected_modules() {
    ...
}

main() {
    local -A options=()
    local -a args=()

    __parse_args options args "$@" || return $?
    __validate_options options args || return $?

    if (( ${#args[@]} == 0 )); then
        __list_all_modules options || return $?

        return 0
    fi

    __list_selected_modules options args
}
```

## Command Routers

A command router such as `main.sh` should delegate to dedicated command scripts using `exec`.

Using `exec` replaces the router process with the selected command process. This preserves signals and exit codes without leaving an unnecessary parent shell process.

Example:

```bash
__run_command() {
    local command="$1"
    shift

    case "$command" in
        install | uninstall | list | status)
            exec bash "$COMMAND_DIR/$command.sh" "$@"
            ;;

        help | -h | --help)
            print_help
            ;;

        *)
            log_error "Unsupported command: $command"

            return 2
            ;;
    esac
}
```

Supported commands must be declared explicitly through `case` branches.

Do not automatically execute an arbitrary script solely because its filename matches user input. Explicit routing prevents accidental command exposure and makes the supported command API clear.

Prefer:

```bash
case "$command" in
    install)
        exec bash "$COMMAND_DIR/install.sh" "$@"
        ;;

    uninstall)
        exec bash "$COMMAND_DIR/uninstall.sh" "$@"
        ;;

    list)
        exec bash "$COMMAND_DIR/list.sh" "$@"
        ;;

    *)
        log_error "Unsupported command: $command"

        return 2
        ;;
esac
```

The grouped form is acceptable when every supported command maps directly to a script with the same name:

```bash
case "$command" in
    install | uninstall | list | status)
        exec bash "$COMMAND_DIR/$command.sh" "$@"
        ;;

    *)
        log_error "Unsupported command: $command"

        return 2
        ;;
esac
```

Use `exec bash` rather than executing the script directly:

```bash
exec bash "$COMMAND_DIR/install.sh" "$@"
```

This allows command scripts to remain non-executable while still requiring a Bash shebang for consistency and tooling support.

Code after a successful `exec` call is unreachable. Therefore, do not write:

```bash
exec bash "$COMMAND_DIR/install.sh" "$@" || return $?
```

If `exec` fails, the shell continues and `exec` returns a non-zero status. Handle that failure explicitly when a custom error message is needed:

```bash
local status

if exec bash "$COMMAND_DIR/install.sh" "$@"; then
    :
else
    status=$?
    log_error "Unable to execute install command"

    return "$status"
fi
```

In most cases, a direct `exec` is sufficient:

```bash
exec bash "$COMMAND_DIR/install.sh" "$@"
```

A command router may still use private helper functions to:

* Parse global options.
* Resolve command aliases.
* Print top-level help.
* Validate the requested subcommand.
* Determine the dedicated command script path.

The router should not duplicate logic already owned by the dedicated command script.

## Private Functions

Command-specific helper functions must use the `__` prefix:

```bash
__parse_args() {
    ...
}

__validate_options() {
    ...
}

__install_module() {
    ...
}
```

Functions intended to be shared across multiple commands should generally be moved into an appropriate library instead of being duplicated.

Keep command-private helpers in the command file when they exist only to organize that command's implementation.

## Help Handling

Help should be processed before normal validation when the user must be able to request help without supplying otherwise required arguments.

Example:

```bash
main() {
    local -A options=()
    local -a args=()

    __parse_args options args "$@" || return $?

    if (( options[HELP] )); then
        print_help

        return 0
    fi

    __validate_options options args || return $?

    ...
}
```

Alternatively, validation may explicitly bypass normal requirements when help is enabled.

Help output should not perform command operations.

## Return Codes

Commands should return statuses intentionally.

A recommended convention is:

* `0`: Command completed successfully.
* `1`: Command operation failed.
* `2`: Invalid command usage or arguments.

Preserve a called function's status when the distinction is meaningful:

```bash
install_module "$module" || return $?
```

Translate statuses only when the command API intentionally defines a different result:

```bash
if ! resolve_module "$module"; then
    log_error "Unknown module: $module"

    return 2
fi
```

Do not call `exit` from helper functions. Return the status to `main`.

The final `main "$@"` call allows the script status to become the status of `main` naturally.

## Command and Library Boundaries

Command scripts should coordinate operations.

Libraries should implement reusable operations.

A command script may:

* Parse user input.
* Validate options.
* Select modules.
* Decide which operation to run.
* Render command-specific output.
* Coordinate multiple library calls.

A library should handle reusable concerns such as:

* Package installation.
* External repository configuration.
* Module discovery.
* Logging.
* State persistence.
* Filesystem operations.
* Downloading artifacts.

Avoid placing general reusable logic directly in a command script.

Avoid placing command-specific argument parsing in a shared library unless the library is specifically designed as a reusable argument parser.

## File Template

Use this structure for new dedicated commands:

```bash
#!/usr/bin/env bash

source "$LIB_DIR/common.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/module.sh"

__parse_args() {
    local options_name="$1"
    local args_name="$2"
    shift 2

    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    options_ref=(
        [ALL]=0
        [FORCE]=0
        [HELP]=0
    )
    args_ref=()

    while (( $# > 0 )); do
        case "$1" in
            -a | --all)
                options_ref[ALL]=1
                shift
                ;;

            -f | --force)
                options_ref[FORCE]=1
                shift
                ;;

            -h | --help)
                options_ref[HELP]=1
                shift
                ;;

            --)
                shift
                args_ref+=("$@")
                break
                ;;

            -*)
                log_error "Unknown option: $1"

                return 2
                ;;

            *)
                args_ref+=("$1")
                shift
                ;;
        esac
    done
}

__validate_options() {
    local options_name="$1"
    local args_name="$2"
    local -n options_ref="$options_name"
    local -n args_ref="$args_name"

    if (( options_ref[ALL] && ${#args_ref[@]} > 0 )); then
        log_error "The --all option cannot be combined with module names"

        return 2
    fi

    if (( ! options_ref[ALL] && ${#args_ref[@]} == 0 )); then
        log_error "Specify at least one module or use --all"

        return 2
    fi
}

__execute_for_module() {
    local options_name="$1"
    local module="$2"
    local -n options_ref="$options_name"

    if ! module_exists "$module"; then
        log_error "Unknown module: $module"

        return 1
    fi

    install_module "$module" "${options_ref[FORCE]}" || return $?
}

main() {
    local -A options=()
    local -a args=()
    local module

    __parse_args options args "$@" || return $?

    if (( options[HELP] )); then
        print_help

        return 0
    fi

    __validate_options options args || return $?

    if (( options[ALL] )); then
        install_all_modules options || return $?

        return 0
    fi

    for module in "${args[@]}"; do
        __execute_for_module options "$module" || return $?
    done
}

main "$@"
```

