# mySetups

Personal dotfiles, bootstrap scripts, and a **portable toolkit** with statically linked Linux binaries that run on any Linux distribution — no dependencies, no root, no package manager needed.

## Portable Toolkit — Static Linux Binaries

Pre-built **statically linked binaries** for `x86_64` and `aarch64` (ARM64), ready to use on any Linux system — including old distros, minimal containers, and locked-down servers where you can't install packages.

### Included Tools

| Tool | Version | x86_64 | aarch64 | Linking |
|------|---------|--------|---------|---------|
| [tmux](https://github.com/tmux/tmux) | 3.5a | 1.3 MB | 1.4 MB | Statically linked (musl) |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | 14.1.1 | 6.3 MB | 5.0 MB | Static-pie |
| [Neovim](https://github.com/neovim/neovim) | 0.11.4 | 9.4 MB | 11 MB | AppImage (self-contained) |

### Quick Start

```bash
# Clone or copy the portable/ directory to any Linux machine
git clone https://github.com/limijd/mySetups.git
cd mySetups/portable

# Activate all tools (zsh)
source activate.zsh

# Activate all tools (tcsh/csh)
source activate.csh

# Or use individual binaries directly
./tmux.x86_64
./rg.x86_64 "pattern" /path/to/search
```

### Why?

If you've ever SSH'd into a machine and found yourself stuck with no `tmux`, ancient `grep`, or no decent editor — this is for you. Common scenarios:

- **Customer/production servers** where you can't install packages
- **Old Linux distros** (RHEL 6/7, CentOS, old Ubuntu) with outdated tools
- **Containers and minimal images** without package managers
- **Restricted environments** where you have no root/sudo access
- **Air-gapped systems** with no internet access

One `source` command gives you modern tmux, ripgrep, and neovim with zero system footprint. Everything lives in the toolkit directory and `/tmp`. Run `unalias <tool>` to deactivate instantly.

See [`portable/README.md`](portable/README.md) for full details.

## Other Components

| Directory | Description |
|-----------|-------------|
| [`bootstrap/`](bootstrap/) | Automated Debian/Ubuntu setup scripts for fresh machines |
| `zsh/` | Full-featured zsh config (personal daily-use) |
| `tcsh/` | tcsh config (personal daily-use) |
| `vim/` | Vim config with plugins (personal daily-use) |
| `tmux/` | tmux config (personal daily-use) |
| `nvim/` | Neovim binaries (AppImages) |
| `iterm2/` | iTerm2 color themes |

## License

These are personal configs. The portable binaries are built from their respective open-source projects — see each project for its license.
