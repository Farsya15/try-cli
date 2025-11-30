# try

> A fast, interactive CLI tool for managing ephemeral development workspaces

`try` is a command-line tool that helps you quickly navigate between development projects using an interactive fuzzy finder. It automatically organizes your projects in dated directories and provides instant switching between workspaces.

![Demo](https://raw.githubusercontent.com/tobi/try/main/demo.gif)

## Features

- **Interactive fuzzy search** - Type to instantly filter through your projects
- **Automatic organization** - Projects are stored in dated directories (`~/src/tries/YYYY-MM-DD-project-name`)
- **Shell integration** - Seamlessly changes your current directory
- **Cross-platform** - Works on Linux, macOS, and other Unix-like systems
- **Fast and lightweight** - Written in C with minimal dependencies
- **Git-aware** - Clone repositories directly into dated workspaces

## Installation

### Pre-built binaries

Download the latest release from [GitHub Releases](https://github.com/tobi/try-c/releases) for your platform:

```bash
# Linux x86_64
curl -L https://github.com/tobi/try-c/releases/latest/download/try-linux-x86_64.tar.gz | tar xz
sudo mv try /usr/local/bin/

# macOS (Intel)
curl -L https://github.com/tobi/try-c/releases/latest/download/try-darwin-x86_64.tar.gz | tar xz
sudo mv try /usr/local/bin/

# macOS (Apple Silicon)
curl -L https://github.com/tobi/try-c/releases/latest/download/try-darwin-aarch64.tar.gz | tar xz
sudo mv try /usr/local/bin/
```

### Build from source

#### Prerequisites

- C11 compiler (GCC, Clang)
- Make
- POSIX-compliant system

#### Build

```bash
git clone https://github.com/tobi/try-c.git
cd try-c
make
sudo make install
```

#### Nix (Flakes)

If you use Nix with flakes enabled:

```bash
nix profile install github:tobi/try-c
```

Or run directly:

```bash
nix run github:tobi/try-c
```

## Quick Start

1. **Initialize shell integration**:
   ```bash
   try init >> ~/.bashrc  # or ~/.zshrc
   source ~/.bashrc
   ```

2. **Clone a repository**:
   ```bash
   try clone https://github.com/user/project
   # Creates: ~/src/tries/2025-01-15-project/
   ```

3. **Navigate to a project**:
   ```bash
   try cd
   # Interactive fuzzy finder opens
   ```

4. **Create a new workspace**:
   ```bash
   try cd
   # Type "my-new-project" and press Enter
   # Creates: ~/src/tries/YYYY-MM-DD-my-new-project/
   ```

## Usage

### Commands

```bash
try init                    # Print shell integration code
try cd [query]              # Interactive directory selector with optional initial filter
try clone <url> [name]      # Clone repository into dated directory
try --help                  # Show help
try --version               # Show version
```

### Shell Integration

Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
# try shell integration
try() {
  if [ "$1" = "init" ]; then
    /usr/local/bin/try "$@"
    return
  fi
  tmp=$(mktemp)
  /usr/local/bin/try "$@" > "$tmp"
  ret=$?
  if [ $ret -eq 0 ]; then
    . "$tmp"
  fi
  rm -f "$tmp"
  return $ret
}
```

### Key Bindings

| Key | Action |
|-----|--------|
| `↑/↓` or `j/k` | Navigate up/down |
| `Enter` | Select current item |
| `Esc` | Cancel selection |
| `Type to filter` | Fuzzy search through directories |

## Configuration

### Default Paths

- **Tries directory**: `~/src/tries/`
- **Binary location**: `/usr/local/bin/try`

### Environment Variables

- `TRY_PATH`: Override the tries directory (default: `~/src/tries`)

## Examples

### Basic Navigation

```bash
# Open interactive selector
try cd

# Filter for projects containing "web"
try cd web

# Filter for React projects
try cd react
```

### Repository Cloning

```bash
# Clone with automatic naming
try clone https://github.com/facebook/react

# Clone with custom name
try clone https://github.com/microsoft/vscode vscode-project
```

### Directory Structure

```
~/src/tries/
├── 2025-01-15-facebook-react/
├── 2025-01-16-microsoft-vscode/
├── 2025-01-20-my-experiment/
└── 2025-01-22-web-app/
```

## Development

### Building

```bash
make clean && make
```

### Testing

```bash
make test
```

### Project Structure

```
├── src/           # C source files
│   ├── main.c     # Entry point and argument parsing
│   ├── tui.c      # Terminal user interface
│   ├── fuzzy.c    # Fuzzy matching algorithm
│   ├── commands.c # Command implementations
│   ├── terminal.c # Terminal control functions
│   └── utils.c    # Utility functions
├── libs/          # External libraries (zstr, zvec)
├── test/          # Test scripts and fixtures
├── docs/          # Documentation
└── Makefile       # Build configuration
```

### Architecture

`try` uses a unique shell integration pattern:

1. User runs `try cd`
2. C binary executes and prints shell commands to stdout
3. Shell wrapper sources the output, executing commands in the current shell
4. This allows changing the current directory (impossible for subprocesses)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Run `make test`
6. Submit a pull request

### Development Setup

```bash
git clone https://github.com/tobi/try-c.git
cd try-c
make
./try --help  # Test basic functionality
```

## Related Projects

- [try (Ruby)](https://github.com/tobi/try) - Original Ruby implementation
- [z-libs](https://github.com/z-libs) - C libraries used in this project

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- Original concept and Ruby implementation by [Tobias Lütke](https://github.com/tobi)
- C port and additional features by contributors</content>
<parameter name="filePath">README.md