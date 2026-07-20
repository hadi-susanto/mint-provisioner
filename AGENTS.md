# Mint Provisioner Agent Guidelines

## General Guidelines

- Use Bash with `#!/usr/bin/env bash`.
- Every executable entrypoint and module phase script must enable strict mode immediately after the shebang using `set -euo pipefail`.
- Sourced libraries, helpers, and shell-integration payloads must not change the caller's shell options. They must remain compatible with `set -euo pipefail`.
- Quote variable expansions unless word splitting or pathname expansion is intentional.
- Use guard clauses and avoid unnecessary nesting.
- Prefer small, readable validation appropriate for this framework.
- Use `NON_INTERACTIVE`, never `NONINTERACTIVE`.
- Module canonical IDs use the `<category>/<module>` format.
- Preserve unrelated user changes in the working tree.

## Safety

- Do not run `sudo` unless explicitly requested.
- Do not run installation phases that modify the operating system during validation.
- Do not install packages, add APT repositories, modify services, or write under `/etc`, `/usr`, `/opt`, or other system directories unless explicitly requested.
- Prefer syntax checks, static analysis, mocks, temporary directories, and isolated test fixtures.
- Do not commit, push, merge, or modify unrelated files unless requested.

## Function Documentation

- Document public or reusable Bash functions with a concise comment block.
- Documentation should include, when applicable:
  - A short description
  - Parameters
  - Output written to stdout
  - Non-zero return behavior
- Do not document `return 0` when success is the function's only normal return behavior.
- Functions prefixed with `__` are private helpers.
- Private helpers do not require documentation when their purpose is clear from their name and implementation.
- Document a private helper when its behavior, parameters, output, or return codes are not obvious.

Example:

```bash
##
# resolve_package <toolkit>
#
# Resolves a UI toolkit name to its corresponding package.
#
# Parameters:
#   toolkit    Supported toolkit name.
#
# Output:
#   Prints the resolved package name.
#
# Returns:
#   1 when the toolkit is unsupported.
#
resolve_package() {
    ...
}
```

## Return and Exit Statements

Place a blank line before standalone `return` and `exit` statements when they follow another statement in the same block.

Correct:

```bash
if [[ "$failed" == "true" ]]; then
    log_error "Operation failed"

    exit 1
fi
```

Incorrect:

```bash
if [[ "$failed" == "true" ]]; then
    log_error "Operation failed"
    exit 1
fi
```

Compact guard expressions are allowed when they improve clarity:

```bash
load_states "$CANONICAL_ID" || exit $?
```

## Guard Clauses

Prefer guard clauses to reduce nesting in functions, conditionals, and loops.

Example:

```bash
if [[ "${SKIP_CONFIGURATION:-false}" == "true" ]]; then
    log_warn "[$CANONICAL_ID] Skipping configuration"

    exit 0
fi

# Continue with the main logic.
```

Inside loops, use `continue` when it makes the main processing path clearer:

```bash
for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue

    process_file "$file"
done
```

## Error Handling

- Check failures from operations required for the phase to succeed.
- Log a useful error before returning or exiting with a non-zero status.
- Do not log an error and then silently report success.
- Preserve meaningful exit codes from installation-detection scripts.
- Optional maintenance operations may log a warning and continue when their failure does not invalidate the installation.

## Validation

After modifying Bash files:

- Run `bash -n` on every changed Bash script.
- Run ShellCheck when it is available.
- Use safe mocks or temporary directories for behavioral tests.
- Do not perform real package installation or system configuration as part of routine validation.
- Review the final diff for unrelated changes.
