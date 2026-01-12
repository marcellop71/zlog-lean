# zlog-lean

Lean 4 wrapper for the [zlog](https://github.com/HardySimpson/zlog) C logging library.

> ⚠️ **Warning**: this is work in progress, it is still incomplete and it ~~may~~ will contain errors

## AI Assistance Disclosure

Parts of this repository were created with assistance from AI-powered coding tools, specifically Claude by Anthropic. Not all generated code may have been reviewed. Generated code may have been adapted by the author. Design choices, architectural decisions, and final validation were performed independently by the author.

## Features

- **High Performance**: Native zlog performance (~250,000 logs/second)
- **Thread Safe**: Full thread and process safety
- **Categories**: Organize logs by component/module
- **Levels**: DEBUG, INFO, NOTICE, WARN, ERROR, FATAL
- **MDC**: Mapped Diagnostic Context for thread-local context
- **LoggerT**: Monad transformer for structured logging
- **Flexible Configuration**: Runtime configuration via config files

## Prerequisites

### Option 1: Using Nix (Recommended)

The easiest way to build and use zlog-lean is with [Nix](https://nixos.org/). Nix provides:
- ✅ Automatic dependency management (zlog, Lean 4, build tools)
- ✅ Reproducible builds across machines
- ✅ No system-wide installations needed
- ✅ Isolated build environments

**Install Nix:**
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Build the project:**
```bash
nix build
```

That's it! Everything is handled automatically.

### Option 2: Manual Setup

If not using Nix, install zlog on your system:

```bash
# Ubuntu/Debian
sudo apt-get install libzlog-dev

# Or build from source
git clone https://github.com/HardySimpson/zlog.git
cd zlog
make
sudo make install
sudo ldconfig
```

## Building with Nix

### Build the Package

```bash
# Build the package (creates ./result symlink)
nix build

# Check what was built
ls -la result/
# result/lib/lean/    - Compiled Lean modules
# result/share/lean/  - Build artifacts
```

### Development Environment

```bash
# Enter development shell with all dependencies
nix develop

# Now you can use lake, lean, etc.
lake build
lake test
```

### Using as a Flake Dependency

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zlog-lean.url = "github:marcellop71/zlog-lean";
  };

  outputs = { self, nixpkgs, zlog-lean }:
    # ... in your derivation:
    let
      zlogDeps = zlog-lean.lib.${system};
    in {
      # Use zlog C library
      buildInputs = [ zlogDeps.zlog ];

      # Use zlog-lean package
      buildInputs = [ zlogDeps.zlogLeanPackage ];

      # Access in LEAN_PATH
      configurePhase = ''
        export LEAN_PATH="${zlogDeps.zlogLeanPackage}/lib/lean:$LEAN_PATH"
      '';
    };
}
```

### CI/CD with Nix

The project includes GitHub Actions CI that uses Nix:

```yaml
- uses: DeterminateSystems/nix-installer-action@v12
- uses: DeterminateSystems/magic-nix-cache-action@v8
- run: nix build
```

Releases are automatically built and published on version tags (`v*.*.*`).

## Installation (Lake)

Add to your `lakefile.lean`:

```lean
require zlogLean from git
  "git@github.com:marcellop71/zlog-lean.git" @ "main"
```

## Quick Start

```lean
import ZlogLean

def main : IO Unit := do
  -- Initialize with a config file
  let ok ← Zlog.init "zlog.conf"
  if !ok then
    IO.eprintln "Failed to initialize zlog"
    return

  -- Simple logging
  Zlog.debug "Debug message"
  Zlog.info "Info message"
  Zlog.warn "Warning message"
  Zlog.error "Error message"

  -- Category-based logging
  let cat := Zlog.Category.get! "my_app"
  cat.info "Application started"
  cat.debug "Processing..."

  -- Cleanup
  Zlog.fini
```

## Configuration

Create a `zlog.conf` file:

```ini
[global]
strict init = true

[formats]
simple = "%d %V [%c] %m%n"

[rules]
*.DEBUG >stdout; simple
```

See [zlog documentation](https://hardysimpson.github.io/zlog/UsersGuide-EN.html) for full configuration options.

## API Reference

### Initialization

```lean
-- Initialize from config file
Zlog.init (configPath : String) : IO Bool

-- Initialize from config string
Zlog.initFromString (configString : String) : IO Bool

-- Reload configuration
Zlog.reload (configPath : String) : IO Bool

-- Finalize and cleanup
Zlog.fini : IO Unit
```

### Simple Logging

```lean
Zlog.debug (msg : String) : IO Unit
Zlog.info (msg : String) : IO Unit
Zlog.notice (msg : String) : IO Unit
Zlog.warn (msg : String) : IO Unit
Zlog.error (msg : String) : IO Unit
Zlog.fatal (msg : String) : IO Unit
```

### Category-based Logging

```lean
-- Get a category
let cat := Zlog.Category.get! "category_name"

-- Log with category
cat.debug "message"
cat.info "message"
cat.warn "message"
cat.error "message"

-- Check if level is enabled
cat.levelEnabled .debug
```

### LoggerT Monad

```lean
open Zlog

def myApp : LoggerT IO Unit := do
  logInfo "Starting"
  logDebug "Processing"
  logInfo "Done"

def main : IO Unit := do
  Zlog.init "zlog.conf"
  let cat := Category.get! "my_app"
  LoggerT.run { category := cat } myApp
  Zlog.fini
```

### Mapped Diagnostic Context (MDC)

```lean
-- Set context value
MDC.put "user_id" "12345"

-- Get context value
let userId ← MDC.get "user_id"

-- Remove context value
MDC.remove "user_id"

-- Clear all context
MDC.clean
```

## Log Levels

| Level  | Value | Description |
|--------|-------|-------------|
| DEBUG  | 20    | Debug information |
| INFO   | 40    | General information |
| NOTICE | 60    | Normal but significant |
| WARN   | 80    | Warning conditions |
| ERROR  | 100   | Error conditions |
| FATAL  | 120   | Fatal conditions |

## Troubleshooting

### Nix: LD_LIBRARY_PATH Conflicts

If you have `LD_LIBRARY_PATH` set in your shell, it can interfere with Nix builds. Add this to your `.zshrc` or `.bashrc`:

```bash
nix() {
  case "$1" in
    build|develop|shell|run|flake)
      LD_LIBRARY_PATH="" command nix "$@"
      ;;
    *)
      command nix "$@"
      ;;
  esac
}
```

### Build Fails: Cannot Find zlog

If using manual setup (not Nix), ensure zlog is installed:

```bash
# Check if zlog is installed
ldconfig -p | grep zlog

# Check library path
pkg-config --libs zlog
```

### Lake Cannot Find Dependencies

If using as a Lake dependency, ensure you have the FFI libraries installed:

```bash
# With Nix
nix develop

# Without Nix
sudo apt-get install libzlog-dev
```

## License

[Your License Here]

## Contributing

Contributions welcome! Please ensure:
- Code passes `nix build`
- Tests pass in CI
- Documentation is updated

