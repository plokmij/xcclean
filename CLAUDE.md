# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Install Commands

```bash
make install          # Install to /usr/local (PREFIX customizable)
make uninstall        # Remove xcclean and completions
make test             # Run basic integration tests
```

Tests are manual shell commands that verify basic functionality (version, help, status, scan, JSON output). No testing framework is used.

## Architecture

xcclean is a pure Bash (3.2+) CLI tool for cleaning Xcode-related files. No external dependencies.

**Entry Point:** `bin/xcclean` - parses CLI arguments and routes to command handlers

**Library Modules (lib/):**
- `colors.sh` - ANSI color support with NO_COLOR compliance
- `core.sh` - Path definitions, formatting utilities, safety checks
- `scanner.sh` - Size calculation, directory enumeration, filtering by age/project
- `cleaner.sh` - Safe deletion with path validation, Xcode running check
- `tui.sh` - Interactive terminal UI with category expansion, item selection, keyboard navigation

**Command Flow:**
1. `bin/xcclean` sources all lib modules
2. Parses global options (--dry-run, --yes, --quiet, --json, --trash, etc.)
3. Routes to: interactive TUI (default), status, scan, clean, or list command
4. Scanner modules enumerate items from cleanable paths
5. Cleaner modules execute with safety validation

**Cleanable Categories:**
- `derived` - ~/Library/Developer/Xcode/DerivedData/
- `archives` - ~/Library/Developer/Xcode/Archives/
- `device-support` - iOS/watchOS/tvOS Device Support files
- `simulators` - Unavailable CoreSimulator devices
- `caches` - Xcode and build caches

## Bash Compatibility Notes

- Uses Bash 3.2 (macOS default) - no associative arrays
- Indexed arrays with pipe-delimited fields for data structures
- UTF-8 box drawing with ASCII fallback detection
