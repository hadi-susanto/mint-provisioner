---
sessionId: session-260702-161722-16n4
---

# Requirements

### Overview & Goals
Introduce category folders under `modules/` using the user-defined category map, with runtime auto-detection of category from folder name and support for both `module` and `category/module` selectors.

### Scope
#### In Scope
- Big-bang move from flat `modules/<module>/` into `modules/<category>/<module>/`.
- Implement the exact category grouping provided by user.
- Keep `category/module` as canonical selector and allow flat `module` when unique.
- Make `lib/metadata_parser.sh` recognize categories automatically from directory path (no new metadata key).
- Update `README.md`, `MODULES.md`, and `.junie/guidelines.md` to the categorized structure.

#### Out of Scope
- Any module lifecycle contract changes.
- Rewriting module internals unrelated to path/discovery.

### Functional Requirements
- Category folder names must be lowercase kebab-case (`lowercase-with-hyphen`) and must not use spaces.
- Category assignment must follow this mapping:
  - `software-engineering`: `git`, `git-ui`, `lazy-git`, `delta`, `apache-maven`, `sdkman`, `adb`
  - `terminal-experience`: `alacritty`, `ghostty`, `kitty`, `terminator`, `zsh`, `starship`, `oh-my-posh`, `power-level-10k`, `eza`, `bat`, `zellij`
  - `system-administration`: `bottom`, `procs`, `duf`, `du-analyzer`, `du-rust`, `nerd-font`, `apt-fast`, `sys-config`
  - `desktop-utilities`: `double-commander`, `mu-commander`, `sunflower`, `flameshot`, `cryptomator`, `keepass-xc`
- `install.sh` / `configure.sh` must accept `category/module` directly.
- Flat `module` input must resolve only when unique; ambiguous names must return candidate `category/module` values.
- `parse_config` must accept only canonical `category/module` identifiers.
- Resolving flat `module` selectors is caller responsibility; callers must skip `parse_config` when resolution fails.
- Module listing must output category-qualified identities for copy-paste usage.

# Technical Design

### Current Implementation
- `install.sh` and `configure.sh` validate modules via `[[ -d "$MODULES_DIR/$module" ]]` (flat-only).
- `lib/metadata_parser.sh:list_available_modules()` scans `modules/*` with `find ... -maxdepth 1`.
- `lib/module_installer.sh` and `lib/module_configurer.sh` build paths as `"$MODULES_DIR/$module"`.
- Current repo layout is flat (`modules/<module>/...`).

### Key Decisions
- **Canonical ID remains `category/module`**; compatibility flat names stay supported when unique.
- **Category source of truth is folder name**; no category field added to `metadata.conf` for now.
- **Big-bang migration** to keep repo consistent in one change.

### Proposed Changes
1. **Metadata/discovery layer (`lib/metadata_parser.sh`)**
   - Discover module dirs at depth 2.
   - Expose canonical IDs as `category/module`.
   - Add selector resolver for both input forms with ambiguity handling.
   - Derive category from path segment under `modules/`.
2. **Metadata contract update (`lib/metadata_parser.sh:parse_config`)**
   - Change `parse_config` contract to accept only canonical `category/module` IDs.
   - Build module path strictly from canonical ID before reading `metadata.conf`.
   - Return failure for non-canonical input; do not perform selector resolution inside `parse_config`.
3. **Entrypoints (`install.sh`, `configure.sh`)**
   - Replace direct directory checks with resolver-based normalization.
   - Resolve all user-provided selectors to canonical IDs before runtime execution.
   - Skip downstream `parse_config` calls for selectors that failed resolution (not found/ambiguous), and abort with clear aggregated errors.
4. **Execution layer (`lib/module_installer.sh`, `lib/module_configurer.sh`)**
   - Assume module arguments are already canonical IDs.
   - Keep `parse_config` invocations canonical-only and keep human-readable metadata display via canonical-keyed lookups.
5. **Repository/module move**
   - Relocate each current module directory into one of the four category directories above.
6. **Docs alignment**
   - Update `README.md` structure and usage examples.
   - Update `MODULES.md` to reflect categorized locations/identifiers.
   - Update `.junie/guidelines.md` module pattern to categorized convention.

### Data Models / Contracts
- Canonical module identifier: `category/module`.
- Category is runtime-derived from module path (`modules/<category>/<module>`).
- `parse_config <canonical_id> <result_array_name>` contract:
  - Input must be canonical `category/module`.
  - Non-canonical input is invalid and must fail immediately.
  - Function parses only after canonical path validation.
- Resolution rules (outside `parse_config`):
  - Selector with `/`: validate as canonical path.
  - Selector without `/`: match by basename across all categories.
  - Match count `0/1/>1` => not found / resolve / ambiguity error.
  - Only successfully resolved canonical IDs are passed to `parse_config`.

### File Structure
- **Framework files**: `install.sh`, `configure.sh`, `lib/metadata_parser.sh`, `lib/module_installer.sh`, `lib/module_configurer.sh`.
- **Docs**: `README.md`, `MODULES.md`, `.junie/guidelines.md`.
- **Modules tree**: migrate from flat `modules/<module>` to `modules/<category>/<module>` using the user-specified category map.

### Risks
- Existing code keys metadata by basename (`parse_config` uses `basename`), which can clash with canonical IDs; adapt `parse_config` and consumers to use canonical-aware keys safely.
- Partial relocation could break lookup; migration must be atomic in one commit.
- Documentation drift risk if selector examples are not updated everywhere.

# Testing

### Validation Approach
Validate categorized discovery, selector resolution, and install/configure execution paths using syntax and smoke checks.

### Key Scenarios
- `./install.sh software-engineering/git` works.
- `./install.sh git` resolves when unique.
- Ambiguous flat selector returns explicit candidate list.
- `./configure.sh` behaves consistently with the same resolver.
- `./install.sh` (no args) lists category-qualified IDs.

### Edge Cases
- Unknown category path (`foo/bar`) returns clear not-found.
- Missing `metadata.conf` in nested module is skipped/fails with existing parser behavior.
- Mixed selector forms in one command are normalized consistently.
- Direct `parse_config` calls with non-canonical IDs fail fast with clear error logs.
- Callers do not invoke `parse_config` for unresolved or ambiguous selectors.

### Test Changes
- Run `bash -n` on touched framework scripts.
- Run smoke checks for listing and argument resolution after relocation.

# Delivery Steps

### ✓ Step 1: Implement nested module discovery and selector resolver
Framework resolves inputs into canonical `category/module` identifiers from `modules/<category>/<module>`.
- Update `lib/metadata_parser.sh` to scan depth-2 module directories.
- Add canonical/flat selector normalization with ambiguity handling.
- Ensure category is derived from folder name only.

### ✓ Step 2: Make `parse_config` canonical-only
`parse_config` validates and parses only canonical `category/module` IDs.
- Update `lib/metadata_parser.sh` so `parse_config` accepts only canonical IDs.
- Reject non-canonical input in `parse_config` without attempting resolution.
- Keep metadata keying and path handling consistent with canonical IDs.

### ✓ Step 3: Resolve in callers and guard `parse_config` invocation
Entrypoints and lifecycle runners call `parse_config` only after successful selector normalization.
- Update `install.sh` and `configure.sh` to resolve selectors before execution.
- Adjust `lib/module_installer.sh` and `lib/module_configurer.sh` to operate on canonical IDs only.
- Ensure unresolved/ambiguous selectors are reported and skipped from `parse_config` calls.

### ✓ Step 4: Perform big-bang relocation using the approved category map
All current module directories are moved into the four target categories.
- Create category folders under `modules/` and relocate each module to its assigned category.
- Verify category assignments match the provided table exactly.
- Ensure lifecycle scripts remain intact after move.

### ✓ Step 5: Align documentation and run migration smoke validation
Documentation and runtime behavior are consistent with categorized layout.
- Update `README.md`, `MODULES.md`, and `.junie/guidelines.md` examples/patterns.
- Validate listing, canonical selectors, flat selectors, and ambiguity errors.
- Run syntax checks (`bash -n`) for modified framework scripts.