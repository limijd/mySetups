# Debian/Ubuntu Bootstrap Script Design

## Summary

`bootstrap/debian_ubuntu.sh` — idempotent post-install script for fresh Debian/Ubuntu machines.
Installs all preferred packages, dev toolchains, dotfiles, and security hardening.

## Decisions

| Topic | Decision |
|-------|----------|
| Default shell | Zsh |
| Dotfile strategy | Symlink from ~ to repo |
| Python | System python3 + uv |
| Rust | rustup (user-level) |
| Node | nvm + latest LTS |
| Run mode | Idempotent (safe to re-run) |
| Tailscale / Chromium | Not included (manual install) |

## Script Structure

```
Section 0: Pre-checks (OS detect, sudo, idempotent guards)
Section 1: System packages (apt)
Section 2: Shell configuration (chsh → zsh)
Section 3: Clone repos + symlink dotfiles
Section 4: Dev toolchains (rustup, uv, nvm)
Section 5: Security hardening (ufw, fail2ban)
Section 6: System tuning (locale, sysctl, limits)
Section 7: Summary report
```

## APT Package List

### Shells
zsh, tcsh

### Editors
vim, vim-gtk3 (clipboard support)

### Terminal
tmux, screen

### Compilers & Build
gcc, g++, clang, llvm, build-essential, cmake, ninja-build, pkg-config,
autoconf, automake, libtool, ccache, bear

### C/C++ Tools
clang-format, clang-tools, valgrind, gdb, strace

### Dev Libraries
libssl-dev, libffi-dev, zlib1g-dev, libreadline-dev

### VCS
git, git-lfs

### Python (system base)
python3, python3-venv, python3-pip

### Modern CLI
ripgrep, fd-find, fzf, bat, eza, zoxide, delta (git-delta), tldr

### System Monitoring
htop, btop, ncdu, duf, iotop, sysstat, lsof, linux-tools-common

### Network
curl, wget, net-tools, dnsutils, traceroute, mtr, openssh-server,
nmap, tcpdump, socat, iperf3

### Code Navigation
universal-ctags, cscope

### Shell Tools
direnv, shellcheck, jq, tree, unzip, zip, pv, xclip, zstd, lm-sensors

### System
ca-certificates, gnupg, software-properties-common, man-db, locales

## Dotfile Symlinks

| Source (repo) | Target (~) |
|---------------|------------|
| zsh/202511.zshrc | ~/.zshrc |
| zsh/.zshenv | ~/.zshenv |
| vim/dot.vimrc | ~/.vimrc |
| tcsh/tcsh.cshrc | ~/.cshrc |
| tmux/tmux.conf | ~/.tmux.conf |

Before symlinking, backup existing files to `~/.dotfiles.bak/`.

## Repos to Clone

- `github.com/limijd/mySetups` → `~/sandbox/github/mySetups`
- `github.com/limijd/nvim-pro-kit` → `~/sandbox/github/nvim-pro-kit`

## Security

- ufw: enable, default deny incoming, allow SSH (22)
- fail2ban: install, enable, default jail for sshd
