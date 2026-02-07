# xcclean

A pure shell script CLI tool for cleaning Xcode-related files on macOS.

Inspired by [Mole](https://github.com/tw93/Mole).

## Features

- **Storage Overview** - See Mac disk usage at a glance
- **Derived Data** - Clean build artifacts with per-project breakdown
- **Archives** - Remove old .xcarchive bundles
- **Device Support** - Clean iOS/watchOS/tvOS device support files
- **Simulators** - Remove unavailable simulator devices
- **Caches** - Clean Xcode and build caches
- **Interactive TUI** - Terminal UI for easy navigation
- **JSON Output** - Script-friendly output format

## Installation

### Homebrew (Recommended)

```bash
brew install your-username/tap/xcclean
```

### Manual Installation

```bash
git clone https://github.com/your-username/xcclean.git
cd xcclean
make install
```

### Curl Installer

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/xcclean/main/install.sh | bash
```

## Usage

### Interactive Mode

```bash
xcclean
```

Launches an interactive TUI where you can:
- View storage by category
- Select categories to clean
- Toggle individual items
- Preview before deletion

### Commands

```bash
xcclean status              # Show storage overview
xcclean scan                # Scan and show all cleanable paths
xcclean clean <category>    # Clean specified category
xcclean list <category>     # List items in category
```

### Categories

| Category | Description |
|----------|-------------|
| `derived` | Xcode DerivedData |
| `archives` | Xcode Archives (.xcarchive) |
| `device-support` | iOS/watchOS/tvOS Device Support |
| `simulators` | Unavailable Simulator devices |
| `caches` | Xcode and build caches |
| `all` | All categories |

### Options

```bash
-n, --dry-run           Preview without deleting
-y, --yes               Skip confirmation prompts
-q, --quiet             Minimal output (for scripts)
-v, --verbose           Verbose output
--no-color              Disable colored output
--json                  Output in JSON format
--trash                 Move to Trash instead of delete
--older-than <days>     Only items older than N days
--keep-latest <n>       Keep N most recent items
--project <name>        Filter by project name
```

### Examples

```bash
# Preview what would be cleaned
xcclean clean derived --dry-run

# Clean old derived data (>30 days)
xcclean clean derived --older-than 30

# Keep latest 3 device support versions
xcclean clean device-support --keep-latest 3

# Clean everything without prompts
xcclean clean all --yes

# List archives as JSON
xcclean list archives --json

# Move to Trash instead of permanent delete
xcclean clean caches --trash

# Automation/CI usage
xcclean clean all --yes --quiet
```

## Cleanable Paths

| Category | Path | Typical Size |
|----------|------|--------------|
| Derived Data | `~/Library/Developer/Xcode/DerivedData/` | 5-50GB+ |
| Archives | `~/Library/Developer/Xcode/Archives/` | 500MB-10GB+ |
| iOS DeviceSupport | `~/Library/Developer/Xcode/iOS DeviceSupport/` | 10-30GB+ |
| watchOS DeviceSupport | `~/Library/Developer/Xcode/watchOS DeviceSupport/` | 2-10GB |
| tvOS DeviceSupport | `~/Library/Developer/Xcode/tvOS DeviceSupport/` | 2-10GB |
| Simulators | `~/Library/Developer/CoreSimulator/Devices/` | 5-20GB+ |
| Simulator Caches | `~/Library/Developer/CoreSimulator/Caches/` | 0-500MB |
| Build Caches | `~/Library/Caches/com.apple.dt.xcodebuild/` | 0-2GB |
| Xcode Cache | `~/Library/Caches/com.apple.dt.Xcode/` | 0-1GB |
| Documentation | `~/Library/Developer/Xcode/DocumentationCache/` | 50-500MB |

## Safety Features

- **Dry-run mode** - Preview changes before deleting with `--dry-run`
- **Trash option** - Move to Trash instead of permanent delete with `--trash`
- **Path validation** - Only deletes from known Xcode cache directories
- **Xcode running check** - Warns if Xcode is currently open
- **Confirmation prompts** - Requires confirmation unless `--yes` is specified

## Requirements

- macOS 10.15+ (Catalina and later)
- Bash 3.2+ (ships with macOS)
- No external dependencies

## Shell Completions

Completions are installed automatically for bash, zsh, and fish.

### Manual Setup

**Bash** (add to `~/.bashrc`):
```bash
source /usr/local/etc/bash_completion.d/xcclean
```

**Zsh** (add to `~/.zshrc`):
```bash
fpath=(/usr/local/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit
```

**Fish**:
```bash
# Completions are loaded automatically
```

## Uninstall

```bash
make uninstall
```

Or:

```bash
./uninstall.sh
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
