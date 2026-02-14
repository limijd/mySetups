# mySetups Architecture

Personal dotfiles and environment setup tools organized by component.

## Directory Structure

```
mySetups/
  bootstrap/        # Automated Debian/Ubuntu setup scripts
  iterm2/           # iTerm2 color themes
  nvim/             # Neovim binaries (AppImages)
  portable/         # Self-contained toolkit for customer environments
  tcsh/             # tcsh config (personal daily-use)
  tmux/             # tmux config (personal daily-use)
  vim/              # Vim config with plugins (personal daily-use)
  zsh/              # zsh config (personal daily-use)
  docs/plans/       # Design docs and implementation plans
```

## Portable Toolkit (`portable/`)

A self-contained toolkit for customer work environments. Source one file to activate personal tools (nvim, rg, tmux) with zero footprint.

### Usage

```bash
# zsh
source /path/to/portable/zsh.zshrc

# tcsh
setenv PORTABLE_DIR /path/to/portable; source /path/to/portable/tcsh.cshrc
```

### Design Principles

- **Alias-only activation**: Tools are accessed via shell aliases, never PATH modifications. Customer's PATH remains unchanged.
- **Zero footprint on $HOME**: All temp files (history, completion cache, extracted AppImages) go to `/tmp/portable-$USER/`.
- **FUSE-aware AppImage handling**: nvim AppImage runs directly if FUSE is available; otherwise lazy-extracts to `/tmp` on first use.
- **Architecture-aware**: Binaries are named with arch suffix (`rg.x86_64`, `rg.aarch64`), auto-detected at source time.
- **Non-interfering**: `unalias <tool>` restores system defaults at any time.

### Files

| File | Purpose |
|------|---------|
| `zsh.zshrc` | Minimal zsh config (~100 lines) with auto-detect dir, tool aliases, ultra-minimal prompt |
| `tcsh.cshrc` | Minimal tcsh config (~100 lines) with PORTABLE_DIR env var, tool aliases |
| `vim.vimrc` | Bare essentials vim config (~10 lines) loaded via `-u` flag |
| `tmux.conf` | tmux config loaded via `-f` flag |
| `nvim-*.appimage` | Neovim AppImages for aarch64 and x86_64 |
| `rg.*` | Ripgrep static binaries for aarch64 and x86_64 |
| `tmux.*` | tmux static binaries |

## Bootstrap (`bootstrap/`)

Automated setup scripts for fresh Debian/Ubuntu machines. See `bootstrap/README.md`.

## Personal Configs

The `zsh/`, `tcsh/`, `vim/`, `tmux/` directories contain full-featured personal configs for daily use on owned machines. These are **not** the same as the stripped-down portable versions.
