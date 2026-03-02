# Portable Linux Toolkit — Static Binaries for Any Linux

Pre-built **statically linked binaries** of essential development tools for Linux `x86_64` and `aarch64` (ARM64). No glibc dependency, no installation required, no root needed. Just copy and run.

## Tools

| Tool | Version | x86_64 | aarch64 | Size |
|------|---------|--------|---------|------|
| **tmux** | 3.5a | `tmux.x86_64` | `tmux.aarch64` | ~1.3 MB |
| **ripgrep** | 14.1.1 | `rg.x86_64` | `rg.aarch64` | ~5-6 MB |
| **Neovim** | 0.11.4 | `nvim-0.11.4-x86_64.appimage` | `nvim-0.11.4-aarch64.appimage` | ~10 MB |

All ELF binaries are **stripped** for minimal size. tmux and ripgrep are statically linked — they have **zero runtime dependencies**.

## Usage

### Option 1: Activate everything with one command

```bash
# zsh — auto-detects the toolkit directory
source /path/to/portable/activate.zsh

# tcsh/csh
source /path/to/portable/activate.csh
```

This sets up shell aliases for `nvim`, `vim`, `vi`, `rg`, and `tmux` pointing to the portable binaries. Your system PATH is never modified.

### Option 2: Use individual binaries directly

```bash
# Run tmux directly
./tmux.x86_64

# Search with ripgrep
./rg.x86_64 "TODO" ./src/

# Run neovim AppImage (requires FUSE, or use --appimage-extract)
./nvim-0.11.4-x86_64.appimage
```

## Design Principles

- **Zero footprint**: No files written to `$HOME`. All temp files (history, caches) go to `/tmp/portable-$USER/`.
- **Alias-only activation**: Tools are accessed via shell aliases. The system PATH is never modified.
- **Architecture-aware**: Binaries named with arch suffix, auto-detected at activation time via `uname -m`.
- **FUSE-aware**: Neovim AppImage runs directly with FUSE; auto-extracts to `/tmp` without it.
- **Instant deactivation**: Run `unalias tmux` (or any tool) to restore system defaults.

## Use Cases

- SSH into **customer or production servers** without install permissions
- Work on **old Linux distros** (RHEL 6/7, CentOS 6/7, Ubuntu 14.04+) with outdated tools
- Use inside **Docker containers** or minimal images without package managers
- Bring your tools to **air-gapped** or **restricted environments**
- Keep your workflow consistent across any Linux machine

## Included Configs

| File | Description |
|------|-------------|
| `activate.zsh` | Zsh activation script (~117 lines): tool aliases, vi keybindings, minimal prompt |
| `activate.csh` | Tcsh activation script (~115 lines): same features for tcsh/csh |
| `vim.vimrc` | Bare essentials vim/nvim config (10 lines): syntax, numbers, indent |
| `tmux.conf` | tmux config: vi-style navigation, bell monitoring, window management |

## Verification

```bash
# Check that binaries are statically linked
file tmux.x86_64
# → ELF 64-bit LSB executable, x86-64, statically linked, stripped

file rg.x86_64
# → ELF 64-bit LSB pie executable, x86-64, static-pie linked, stripped

# Check they have no dynamic library dependencies
ldd tmux.x86_64
# → not a dynamic executable
```

## Building

The tmux static binary is built using Alpine Linux (musl libc) in Docker. See the build scripts or build your own:

```bash
# Example: build static tmux using Alpine Docker
docker run --rm -v "$PWD:/out" alpine:latest sh -c '
  apk add --no-cache build-base libevent-dev libevent-static ncurses-dev ncurses-static
  # ... compile with LDFLAGS=-static
'
```

Ripgrep binaries are from the [official releases](https://github.com/BurntSushi/ripgrep/releases) (musl target).
Neovim AppImages are from the [official releases](https://github.com/neovim/neovim/releases).
