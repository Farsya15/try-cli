# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`try` is a CLI tool for managing ephemeral development workspaces (called "tries"). It provides an interactive directory selector with fuzzy search and integrates with the shell to quickly navigate between project directories. The tool tracks recently accessed tries and allows cloning repositories into dated directories.

## Reference Implementation

A Ruby reference implementation exists at `docs/try.reference.rb` which demonstrates the full feature set and UI behavior. Use this as the source of truth for expected functionality when implementing features in C.

## Build System

Build the project:
```bash
make
```

Clean build artifacts:
```bash
make clean
```

Install to `/usr/local/bin/try`:
```bash
make install
```

The binary is built to `dist/try` from C source files in `src/`. Object files are placed in `obj/`.

## Architecture

### Shell Integration Pattern

The tool uses a unique architecture where it emits shell commands that are sourced by the parent shell:

1. User runs `try cd` or similar command
2. The C binary executes and prints shell commands to stdout
3. A shell wrapper function sources the output, executing it in the current shell context
4. This allows the tool to change the current directory (impossible for normal subprocesses)

Commands are emitted via `emit_task()` in `src/commands.c`, which prints shell snippets chained with `&&`. Each command chain ends with `true\n`.

### Core Components

**Command Layer** (`src/commands.c`, `src/commands.h`):
- `cmd_init()`: Prints shell function definition for integration
- `cmd_clone()`: Generates shell commands to clone repo into dated directory
- `cmd_cd()`: Launches interactive selector, emits cd command
- `cmd_worktree()`: Placeholder (not implemented)

**Interactive TUI** (`src/tui.c`, `src/tui.h`):
- `run_selector()`: Main interactive loop using raw terminal mode
- Scans directories in tries path (default: `~/src/tries`)
- Returns `SelectionResult` with action type and path
- Supports fuzzy filtering and keyboard navigation

**Fuzzy Matching** (`src/fuzzy.c`, `src/fuzzy.h`):
- `fuzzy_match()`: Updates TryEntry score and rendered output in-place
- `calculate_score()`: Combines fuzzy match score with recency (mtime)
- `highlight_matches()`: Inserts `{highlight}` tokens around matched characters
- Algorithm favors consecutive character matches and recent access times
- **Documentation**: See `spec/fuzzy_matching.md` for complete algorithm specification

**Terminal Management** (`src/terminal.c`, `src/terminal.h`):
- Raw mode terminal control (disables canonical mode, echo)
- Escape sequence parsing for arrow keys, special keys
- Window size detection
- Cursor visibility control

**Token System** (`src/tokens.rl`, `src/tokens.c`, `src/tokens.h`):
- Ragel-based state machine for token expansion
- Stack-based style nesting with `{/}` pop operation
- Full color palette support (standard, bright, 256-color)
- Control sequences for cursor and screen management

**Utilities** (`src/utils.c`, `src/utils.h`):
- Path utilities: `join_path()`, `mkdir_p()`, directory existence checks
- Time formatting: `format_relative_time()` for human-readable timestamps
- `AUTO_FREE` macro: Cleanup helper for raw pointers using `Z_CLEANUP()`

**Data Structures** (`src/libs/zstr.h`, `src/libs/zvec.h`, `src/libs/zlist.h`):
- Custom string library (`zstr`) with SSO (Small String Optimization)
- Generic vector implementation (`zvec`) used for TryEntry collections
- Generic list implementation (`zlist`) available but rarely needed
- All libs support RAII-style cleanup with `Z_CLEANUP()` attribute
- **Always use zstr and zvec for all string management and arrays**

### Memory Management

The codebase uses GCC/Clang's `__attribute__((cleanup))` for automatic resource cleanup:

```c
Z_CLEANUP(zstr_free) zstr path = zstr_init();
// path automatically freed when leaving scope
```

Manual cleanup still required in some cases:
- Vector elements must be freed before freeing the vector
- `TryEntry` structs contain zstr fields that need individual `zstr_free()` calls

### Data Flow

1. User invokes `try cd [query]`
2. `main()` parses `--path` flag or uses default tries directory
3. `cmd_cd()` calls `run_selector()` with optional initial filter
4. `run_selector()` scans directories with `scan_tries()`
5. Interactive loop: user types to filter, arrows to navigate
6. On Enter: returns `SelectionResult` with action and path
7. `cmd_cd()` emits shell commands to cd to selected path
8. Shell wrapper sources output, executing the cd command

### Token System

The UI uses a stack-based token formatting system implemented with [Ragel](https://www.colm.net/open-source/ragel/). Tokens are placeholder strings embedded in text that get expanded to ANSI escape codes via `zstr_expand_tokens()`. This allows formatting to be defined declaratively without hardcoding ANSI sequences throughout the codebase.

**Implementation**: `src/tokens.rl` (Ragel source) generates `src/tokens.c`

**Documentation**: See `spec/token_system.md` for complete token specifications and usage patterns.

**Stack Semantics**: Each style token pushes its previous state onto a stack. `{/}` pops one level, restoring the previous state. This enables proper nesting of styles.

**Key Features:**
- **Deferred Emission**: ANSI codes only emit when an actual character is printed
- **Redundancy Avoidance**: Repeated identical styles don't emit duplicate codes
- **Auto-Reset at Newlines**: All styles automatically reset before each newline

**Available Tokens:**

| Category | Tokens |
|----------|--------|
| **Semantic** | `{b}` (bold), `{highlight}` (bold+yellow), `{h1}` (bold+orange), `{h2}` (bold+blue), `{dim}` (gray), `{section}` (bold), `{danger}` (red bg) |
| **Attributes** | `{bold}` `{B}`, `{italic}` `{I}`, `{underline}` `{U}`, `{reverse}`, `{strikethrough}`, `{strike}` |
| **Colors** | `{red}`, `{green}`, `{blue}`, `{yellow}`, `{cyan}`, `{magenta}`, `{white}`, `{black}`, `{gray}`/`{grey}` |
| **Bright Colors** | `{bright:red}`, `{bright:green}`, etc. |
| **256-Color** | `{fg:N}`, `{bg:N}` where N is 0-255 |
| **Background** | `{bg:red}`, `{bg:green}`, etc. |
| **Reset/Pop** | `{/}` (pop), `{/name}` (e.g., `{/highlight}`), `{reset}` (full reset), `{/fg}`, `{/bg}` |
| **Control** | `{clr}` (clear line), `{cls}` (clear screen), `{home}`, `{hide}`, `{show}` |
| **Special** | `{cursor}` (cursor position tracking) |

**Usage Pattern:**
```c
// Simple formatting
Z_CLEANUP(zstr_free) zstr result = zstr_expand_tokens("Status: {b}OK{/}");

// Nested styles (stack-based)
Z_CLEANUP(zstr_free) zstr result = zstr_expand_tokens("{bold}Bold {red}and red{/} just bold{/} normal");

// 256-color support
Z_CLEANUP(zstr_free) zstr result = zstr_expand_tokens("{fg:214}Orange text{/}");
```

**In Fuzzy Matching:**
The fuzzy matching system in `src/fuzzy.c` inserts `{highlight}` tokens around matched characters. These tokens are preserved through the rendering pipeline and expanded to ANSI codes when displayed:

```c
// Input: "2025-11-29-test", query: "te"
// Output: "2025-11-29-{highlight}te{/}st"
// Displayed: "2025-11-29-[bold yellow]te[reset]st"
```

**Regenerating Token Parser:**
```bash
ragel -C -G2 src/tokens.rl -o src/tokens.c
```

## Configuration

Constants defined in `src/config.h`:
- `TRY_VERSION`: Current version string
- `DEFAULT_TRIES_PATH_SUFFIX`: Default path relative to HOME (`src/tries`)

The tries path can be overridden with `--path` or `--path=` flag.

## Testing Workflow

Automated tests are available via `make test`. Manual testing approach:

1. Build with `make`
2. Run `./dist/try init` to get shell function definition
3. Source the output or manually test commands
4. Test interactive selector: `./dist/try cd`
5. Test with filter: `./dist/try cd <query>`
6. Test cloning: `./dist/try clone <url> [name]`

Reference the Ruby implementation in `docs/try.reference.rb` for expected behavior.

## Common Patterns

**Creating a new zstr from string literal:**
```c
Z_CLEANUP(zstr_free) zstr s = zstr_from("text");
```

**Building paths:**
```c
Z_CLEANUP(zstr_free) zstr path = join_path("/base", "subdir");
```

**Working with vectors:**
```c
vec_TryEntry entries = {0};  // Zero-initialize
TryEntry entry = {/* ... */};
vec_push(&entries, entry);
vec_free_TryEntry(&entries);  // Free vector (not contents!)
```

**Emitting shell commands:**
```c
emit_task("cd", "/some/path", NULL);
printf("true\n");  // End command chain
```

**Token expansion for UI text:**
```c
Z_CLEANUP(zstr_free) zstr formatted = zstr_from("{dim}Path:{/fg} {b}");
zstr_cat(&formatted, some_path);
zstr_cat(&formatted, "{/b}");
Z_CLEANUP(zstr_free) zstr expanded = zstr_expand_tokens(zstr_cstr(&formatted));
// Use expanded for output
```

## String and Array Management

**Critical:** Always use `zstr` for strings and `zvec` for arrays. Never use raw C strings or arrays except:
- When interfacing with system APIs that require `char*` (use `zstr_cstr()` to convert)
- For small stack-allocated buffers in performance-critical paths

`zlist` is available for linked list use cases but is rarely needed.

## Dependencies

External dependencies are minimal:
- Standard C library (POSIX)
- Math library (`-lm` for fuzzy scoring)
- Ragel (`ragel`) - only needed if modifying `src/tokens.rl`

The `src/libs/` directory contains bundled single-header libraries (zstr, zvec, zlist) that are self-contained.

Note: The generated `src/tokens.c` is checked into the repository, so Ragel is only required when modifying the token system.

## Directory Structure

- `src/` - C source and header files
- `src/libs/` - Bundled single-header libraries (z-libs: zstr, zvec, zlist)
- `spec/` - Try specifications (CLI structure, fuzzy matching, token system, TUI)
- `docs/` - Reference implementation and z-libs documentation
- `test/` - Test suite (test.sh)
- `obj/` - Object files (created by make, gitignored)
- `dist/` - Build output directory (created by make, gitignored)
- `dist/try` - Output binary
- `.github/workflows/` - CI/CD configuration

## Key Files

- `src/main.c` - Entry point, argument parsing
- `src/tui.c` - Interactive selector implementation
- `src/fuzzy.c` - Scoring and highlighting logic
- `src/tokens.rl` - Token system (Ragel source)
- `src/tokens.c` - Token system (generated, do not edit)
- `src/utils.c` - Shared utilities
- `src/commands.c` - Command implementations, shell emission
- `Makefile` - Build configuration
- `docs/try.reference.rb` - Ruby reference implementation (source of truth for features)

## Documentation Maintenance

**IMPORTANT**: When making changes to certain subsystems, their corresponding documentation files must be updated:

- **Token system** (`src/tokens.rl`):
  - Update `spec/token_system.md` with any new tokens or changed ANSI codes
  - Update the token table in this file (CLAUDE.md)
  - Update `src/tokens.h` header documentation
  - Regenerate C code: `ragel -C -G2 src/tokens.rl -o src/tokens.c`

- **Fuzzy matching algorithm** (`src/fuzzy.c`, `fuzzy_match()`):
  - Update `spec/fuzzy_matching.md` with algorithm changes
  - Update scoring examples if formulas change
  - Document any new bonuses, multipliers, or scoring components

These documentation files serve as specifications and must remain synchronized with the implementation.

## Release Process

The `VERSION` file is the single source of truth for version numbers. It is read by:
- **Makefile**: Passes `-DTRY_VERSION` to the compiler
- **flake.nix**: Uses `builtins.readFile ./VERSION`
- **PKGBUILD/.SRCINFO**: Updated via `make update-pkg`

### Release Steps

1. Update the `VERSION` file with the new version number
2. Run `make update-pkg` to sync PKGBUILD and .SRCINFO
3. Commit with excellent release notes in the commit message body:
   - Summarize all significant changes since the last release
   - Group changes by category (Features, Bug Fixes, Improvements)
   - Credit contributors where applicable
   - Be concise but comprehensive
4. Create and push tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z" && git push origin master && git push origin vX.Y.Z`
5. GitHub Actions will automatically:
   - Build binaries for all platforms (Linux x86_64/aarch64, macOS x86_64/aarch64)
   - Create a GitHub release with binaries attached
   - Use commit messages to generate release notes

### Versioning Scheme

Follow semantic versioning (semver):
- **Major (X.0.0)**: Breaking changes to CLI interface or behavior
- **Minor (0.X.0)**: New features, non-breaking changes
- **Patch (0.0.X)**: Bug fixes, documentation updates
