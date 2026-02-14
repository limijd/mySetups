# Portable Toolkit for Customer Environments

**Date:** 2026-02-14
**Status:** Approved

## Goal

A self-contained portable toolkit that provides personal tools (nvim, rg, tmux) and shell config (zsh, tcsh, vim) in customer work environments. One `source` command activates everything with zero footprint on the customer machine.

## Usage

```bash
# zsh
source /path/to/portable/zsh.zshrc

# tcsh
setenv PORTABLE_DIR /path/to/portable; source /path/to/portable/tcsh.cshrc
```

## Design Decisions

### Approach: Self-contained source files

Each shell config is a standalone file. No helper scripts, no multi-step setup. Source one file and everything works.

### Directory auto-detection

- **zsh:** `${0:A:h}` — built-in, reliable
- **tcsh:** Requires `$PORTABLE_DIR` env var set before sourcing (tcsh has no `$0` equivalent). Falls back to `$_` parsing with a warning if unset.

### Tool activation via aliases only

All tools activated through aliases, never PATH modifications:
- `nvim`, `vim`, `vi` → portable nvim AppImage (or extracted binary)
- `rg` → portable ripgrep binary
- `tmux` → portable tmux with `-f $PORTABLE_DIR/tmux.conf`
- `EDITOR` set to portable nvim wrapper

If a binary doesn't exist for the current arch, that alias is silently skipped.

### AppImage FUSE handling

1. Check `fusermount --version` to detect FUSE availability
2. **With FUSE:** alias directly to the AppImage
3. **Without FUSE:** lazy-extract on first use to `/tmp/portable-$USER/nvim-squashfs/` via `--appimage-extract`. Reuse across shell sessions until reboot.

### Vim config loading

Aliases include `-u $PORTABLE_DIR/vim.vimrc` to bypass customer's vim/nvim config.

### Non-interference guarantees

- **No PATH changes** — aliases only
- **No env pollution** — only `EDITOR` is set
- **No writes to `$HOME`** — all temp files under `/tmp/portable-$USER/` (history, completion cache, nvim extraction)
- **No umask changes**
- **Prompt clearly tagged** with `[portable]` so user knows the config is active
- `unalias <tool>` restores system defaults at any time

### Prompt style

Ultra-minimal, two-line:
```
user@host /full/cwd
$
```

### What's stripped from original configs

**zsh.zshrc** (~840 lines → ~80 lines):
- Removed: platform detection, vcs_info, CPU temp, Tailscale, GeoIP, git-remote segments, all PATH blocks, proxy functions, nvm/pyenv/cargo bootstrap, compaudit, tmux hooks, load telemetry, `.zshrc.local` sourcing

**tcsh.cshrc** (~126 lines → ~60 lines):
- Removed: platform-specific PATH blocks, hostnamectl parsing, `.cshrc.local` sourcing, hard-coded path sets

**vim.vimrc** (~131 lines → ~15 lines):
- Removed: vim-plug, all plugins, Python integration, ctags, vimwiki
- Kept: nocompatible, filetype, syntax, number, expandtab/tabstop/shiftwidth, smartindent, mouse off, search highlighting

**tmux.conf:** Unchanged (already lean at ~108 lines)

## File Layout

```
portable/
  zsh.zshrc                          # rewritten (~80 lines)
  tcsh.cshrc                         # rewritten (~60 lines)
  vim.vimrc                          # rewritten (~15 lines)
  tmux.conf                          # unchanged
  nvim-0.11.4-aarch64.appimage       # existing
  nvim-0.11.4-x86_64.appimage        # existing
  rg.aarch64                         # existing
  rg.x86_64                          # existing
  tmux.x86_64                        # existing
```
