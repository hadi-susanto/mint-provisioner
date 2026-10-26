# `mp outdated --async`: Worker Pool

`mp outdated` normally inspects modules one at a time. Most of the time goes to network lookups (GitHub releases,
vendor `latest.sh` scripts, `git ls-remote`), so a long module list spends most of its run waiting. With
`--async` (alias `--batch`), a pool of background workers shares one queue of modules, and the lookups overlap.

```bash
mp outdated --async            # 6 workers (default)
mp outdated --async 3          # 3 workers
mp outdated --batch=9 cli/bat  # 9 is the maximum
```

The worker count must be 1–9. It is capped at the number of modules, so selecting 3 modules starts at most 3 workers.
A non-numeric word after the flag is treated as a module (`--async consul` uses 6 workers to inspect `consul`).

The table, summary, and exit code are the same as in sequential mode. Only the progress display and the order
of log messages differ.

## Overview

```
                     ┌──────────────────────────── work dir (mktemp -d) ─────────────────────────────┐
                     │  next         queue counter (index of the next module)                        │
 main process        │  queue.lock   flock: one worker at a time reads and bumps "next"              │
 ─────────────       │  draw.lock    flock: one worker at a time draws on the terminal               │
 1. create work dir  │  result.<i>   one result line per module (status, versions, state, note)      │
 2. start N workers ─┼─► worker-1 ┐                                                                  │
 3. wait             │   worker-2 ├─ loop: dequeue i → draw line → inspect → write result.<i>, log.<i>│
 4. clear status     │   worker-N ┘                                                                  │
 5. read results in  │  log.<i>      stderr of that module's inspection                              │
    queue order      └───────────────────────────────────────────────────────────────────────────────┘
 6. print table
```

Workers are subshells (`( … ) &`), so variables they set never reach the main process. Files in the work dir
carry the results back; the main process loads them into the same `__SHOWN_IDS` / `__VERSION_*` globals that
sequential mode fills, and `__print_versions` does not know which mode produced them.

## Functions

| Function                   | Runs in | Role                                                                    |
|----------------------------|---------|-------------------------------------------------------------------------|
| `__inspect_modules_async`  | main    | Sets up the work dir and traps, starts workers, waits, collects results |
| `__run_worker`             | worker  | Takes modules from the queue until it is empty                          |
| `__dequeue`                | worker  | Takes the next queue index under `queue.lock`                           |
| `__draw_worker_line`       | worker  | Redraws the worker's own status line under `draw.lock`                  |
| `__inspect_module`         | worker  | Inspects one module; shared with sequential mode                        |
| `__store_versions`         | main    | Stores one row in the globals; shared with sequential mode              |
| `__stop_workers`           | main    | Kills the workers on Ctrl-C or TERM                                     |

## Step by Step

### 1. Work directory and traps

`__inspect_modules_async` creates a private temp directory in `__WORK_DIR` and writes `0` to `next`.
`__WORK_DIR` and `__WORKER_PIDS` are file-scope globals because the traps run outside the function.

```bash
trap '[[ -z "$__WORK_DIR" ]] || rm -rf -- "$__WORK_DIR"' EXIT
trap '__stop_workers; exit 130' INT
trap '__stop_workers; exit 143' TERM
```

- `EXIT` removes the work dir however the command ends.
- `INT`/`TERM` kill the workers explicitly. Without job control (any script), Bash starts background jobs with
  SIGINT **ignored**, so Ctrl-C alone would leave the workers running against a deleted work dir.

### 2. Reserving the status block

When stderr is a terminal, the main process prints one empty line per worker, leaving the cursor below the block:

```
[INFO] [worker-1] [3/42] inspecting module dev/mise     ← 3 lines up
[INFO] [worker-2] [4/42] inspecting module cli/rclone   ← 2 lines up
[INFO] [worker-3] [5/42] inspecting module cli/bat      ← 1 line up
█                                                       ← cursor rests here
```

When stderr is not a terminal (piped or redirected), nothing is drawn.

### 3. Starting the workers

```bash
(
    trap - EXIT INT TERM
    __run_worker "$worker" "$workers" "$__WORK_DIR" "$draw" "$@"
) &
__WORKER_PIDS+=("$!")
```

Each worker resets the inherited traps first; otherwise the first worker to finish would delete the work dir
while the others still use it. The module list is passed as arguments and is the same for every worker; the
queue position is the only shared, changing state.

### 4. The worker loop

```
while index = __dequeue:
    draw "[INFO] [worker-K] [index+1/total] inspecting module <id>"
    __inspect_module <id> 2> log.<index>
    write result.<index>.tmp, then mv to result.<index>
clear own status line
```

- **Dequeue.** `__dequeue` holds `flock` on `queue.lock` while it reads `next` and writes `next + 1`, so no two
  workers ever take the same module. It returns non-zero when the queue is empty, which ends the loop. A fast
  worker simply takes more modules.
- **Drawing.** `__draw_worker_line` writes one sequence under `draw.lock`: move up `N − K + 1` lines, clear the
  line, print, move down the same distance. The cursor ends where it started, so concurrent workers never knock each
  other's positions out of step, and each worker only ever touches its own line.
- **Logs.** The module's stderr (`tlog_error`, `tlog_warn`, …) goes to `log.<index>` so messages cannot break the
  status block.
- **Results.** One line, fields separated by `\x1f`:

  ```
  <status>␟<INSTALLED>␟<LATEST>␟<STATE>␟<NOTE>
  ```

  The file is written as `.tmp` and renamed, so `result.<index>` either exists complete or not at all.

`<status>` is the return code of `__inspect_module`: `0` success, `1` detection or version query failed (the row
is still filled), `2` module metadata could not be parsed.

### 5. Waiting and clearing

The main process `wait`s for every worker PID; a worker that exits non-zero marks the run as failed. It then
clears the status block (`\033[<N>A\r\033[J`: up N lines, column 0, clear to end of screen).

### 6. Collecting results

For each index in queue order (the order of the module list, so the table matches sequential mode):

1. Print `log.<index>` to stderr if it is not empty. Logs therefore appear grouped per module, after the progress
   display.
2. If `result.<index>` is missing, the worker died on that module: store an `error` row with the note
   `inspection failed` and mark the run as failed.
3. Otherwise read it with `IFS=$'\x1f' read -r status installed latest state note`:
   - status `2`: return 1 (same as sequential mode on a metadata error);
   - status `1`: mark the run as failed and keep the row;
   - store the row with `__store_versions`.

`\x1f` (unit separator) is used instead of a tab because tab is IFS whitespace: consecutive tabs collapse, so an
empty field would shift every later field. Non-whitespace separators keep empty fields in place.

## Failure Behavior

| Situation                            | Result                                                                |
|--------------------------------------|-----------------------------------------------------------------------|
| A version lookup fails               | Row shows `[unknown]`, its error is printed after the progress, exit 1 |
| A worker is killed                   | Other workers finish the queue; the lost module shows `inspection failed`, exit 1 |
| Module metadata cannot be parsed     | Exit 1 before the table, as in sequential mode                        |
| Ctrl-C / TERM                        | Workers are killed, work dir removed, exit 130 / 143                  |
| Work dir cannot be created           | Error logged, exit 1                                                  |

## Notes

- Each worker makes its own network calls, so more workers means more concurrent GitHub API requests. The
  unauthenticated limit is 60 requests per hour; set `GITHUB_TOKEN` when checking many modules (see `FAQ.md`).
- Workers only read system state (dpkg, the APT cache, registry files, git clones); none of them write outside
  the work dir. The optional `sudo apt-get update` offer runs in the main process before any worker starts.
- `flock` (util-linux) and `mktemp` (coreutils) are part of every Mint/Ubuntu install.
