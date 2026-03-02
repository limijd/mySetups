#!/usr/bin/env bash
#
# bootstrap/debian_ubuntu.sh — Idempotent post-install setup for Debian/Ubuntu
#
# Usage:
#   curl -fsSL <raw-url> | bash
#   # or
#   bash bootstrap/debian_ubuntu.sh
#
# Safe to re-run: skips already-installed components.

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# Colors & helpers
# ═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()      { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()     { printf "${RED}[ERR]${NC}   %s\n" "$*"; }
section() { printf "\n${CYAN}══════ %s ══════${NC}\n\n" "$*"; }

# Track results for final summary
declare -a INSTALLED=()
declare -a SKIPPED=()
declare -a FAILED=()

track_installed() { INSTALLED+=("$1"); }
track_skipped()   { SKIPPED+=("$1"); }
track_failed()    { FAILED+=("$1"); }

# ═══════════════════════════════════════════════════════════════════════════════
# Section 0: Pre-checks
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 0: Pre-checks"

# OS detection
if [[ ! -f /etc/os-release ]]; then
    err "Cannot detect OS. /etc/os-release not found."
    exit 1
fi

source /etc/os-release

if [[ "$ID" != "ubuntu" && "$ID" != "debian" && "$ID_LIKE" != *"debian"* && "$ID_LIKE" != *"ubuntu"* ]]; then
    err "This script is for Debian/Ubuntu only. Detected: $PRETTY_NAME"
    exit 1
fi

ok "Detected OS: $PRETTY_NAME ($VERSION_CODENAME)"
ok "Architecture: $(uname -m)"

# sudo check
if [[ $EUID -eq 0 ]]; then
    SUDO=""
    warn "Running as root. Prefer running as normal user with sudo."
else
    if ! command -v sudo &>/dev/null; then
        err "sudo not found. Please install sudo or run as root."
        exit 1
    fi
    SUDO="sudo"
    # Warm up sudo cache
    info "Requesting sudo access..."
    $SUDO true
    ok "sudo access confirmed"
fi

# Determine the target user (the real user, even if running via sudo)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

ok "Target user: $TARGET_USER (home: $TARGET_HOME)"

# Repo paths
SETUP_REPO_DIR="$TARGET_HOME/sandbox/github/mySetups"
NVIM_REPO_DIR="$TARGET_HOME/sandbox/github/nvim-pro-kit"
DOTFILES_BACKUP="$TARGET_HOME/.dotfiles.bak"

# ═══════════════════════════════════════════════════════════════════════════════
# Section 1: System packages (apt)
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 1: System packages (apt)"

info "Updating package index..."
$SUDO apt-get update -qq

# All packages in one array, grouped by category
APT_PACKAGES=(
    # ── Shells ──
    zsh
    tcsh

    # ── Editors ──
    vim
    vim-gtk3           # vim with clipboard (+clipboard, +xterm_clipboard)

    # ── Terminal multiplexer ──
    tmux
    screen

    # ── Compilers & build tools ──
    gcc
    g++
    clang
    llvm
    build-essential    # make, libc-dev, dpkg-dev, etc.
    cmake
    ninja-build
    pkg-config
    autoconf
    automake
    libtool
    ccache             # compiler cache
    bear               # generate compile_commands.json

    # ── C/C++ development tools ──
    clang-format
    clang-tools        # clangd, clang-check, etc.
    valgrind
    gdb
    strace

    # ── Development libraries ──
    libssl-dev
    libffi-dev
    zlib1g-dev
    libreadline-dev

    # ── Version control ──
    git
    git-lfs

    # ── Python (system base) ──
    python3
    python3-venv
    python3-pip

    # ── Modern CLI replacements ──
    ripgrep            # rg — faster grep
    fd-find            # fd — faster find
    fzf                # fuzzy finder
    bat                # better cat with syntax highlighting
    eza                # modern ls (maintained exa fork)
    zoxide             # smart cd
    git-delta          # better git diff
    tldr               # simplified man pages

    # ── System monitoring ──
    htop
    btop               # resource monitor (better htop)
    ncdu               # interactive disk usage
    duf                # better df
    iotop              # I/O monitor
    sysstat            # sar, iostat, mpstat
    lsof               # list open files
    linux-tools-common # perf

    # ── Network tools ──
    curl
    wget
    net-tools          # ifconfig, netstat
    dnsutils           # dig, nslookup
    traceroute
    mtr                # traceroute + ping
    openssh-server
    nmap
    tcpdump
    socat
    iperf3

    # ── Code navigation ──
    universal-ctags
    cscope

    # ── Shell / text tools ──
    direnv
    shellcheck         # shell script linter
    jq                 # JSON processor
    tree
    unzip
    zip
    pv                 # pipe viewer (progress)
    xclip              # clipboard from CLI
    zstd               # modern compression
    indent             # C code formatter
    lm-sensors         # CPU temperature

    # ── System essentials ──
    ca-certificates
    gnupg
    software-properties-common
    man-db
    locales
)

info "Installing ${#APT_PACKAGES[@]} packages..."
# Use DEBIAN_FRONTEND=noninteractive to avoid prompts
if $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${APT_PACKAGES[@]}"; then
    ok "All apt packages installed"
    track_installed "apt-packages (${#APT_PACKAGES[@]} packages)"
else
    warn "Some apt packages may have failed. Check output above."
    track_failed "apt-packages (partial)"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Section 2: Shell configuration
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 2: Shell configuration (zsh)"

ZSH_PATH=$(command -v zsh)
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)

if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    ok "Default shell is already zsh"
    track_skipped "chsh (already zsh)"
else
    info "Changing default shell to zsh for $TARGET_USER..."
    $SUDO chsh -s "$ZSH_PATH" "$TARGET_USER"
    ok "Default shell changed to zsh"
    track_installed "chsh → zsh"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Section 3: Clone repos & symlink dotfiles
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 3: Repos & dotfiles"

# Helper: clone or pull a repo
clone_or_pull() {
    local repo_url="$1"
    local target_dir="$2"

    if [[ -d "$target_dir/.git" ]]; then
        ok "Repo already exists: $target_dir"
        info "Pulling latest..."
        sudo -u "$TARGET_USER" git -C "$target_dir" pull --ff-only 2>/dev/null || \
            warn "Pull failed (dirty tree?). Skipping."
        track_skipped "clone $repo_url (exists)"
    else
        info "Cloning $repo_url → $target_dir"
        sudo -u "$TARGET_USER" mkdir -p "$(dirname "$target_dir")"
        sudo -u "$TARGET_USER" git clone "$repo_url" "$target_dir"
        ok "Cloned $repo_url"
        track_installed "clone $repo_url"
    fi
}

clone_or_pull "https://github.com/limijd/mySetups.git"    "$SETUP_REPO_DIR"
clone_or_pull "https://github.com/limijd/nvim-pro-kit.git" "$NVIM_REPO_DIR"

# Helper: create symlink with backup
safe_symlink() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        warn "Source does not exist: $source — skipping"
        track_failed "symlink $target (source missing)"
        return
    fi

    # Already correctly linked
    if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
        ok "Symlink OK: $target → $source"
        track_skipped "symlink $(basename "$target")"
        return
    fi

    # Backup existing file/link
    if [[ -e "$target" || -L "$target" ]]; then
        sudo -u "$TARGET_USER" mkdir -p "$DOTFILES_BACKUP"
        local backup_name
        backup_name="$(basename "$target").$(date +%Y%m%d%H%M%S)"
        sudo -u "$TARGET_USER" mv "$target" "$DOTFILES_BACKUP/$backup_name"
        warn "Backed up: $target → $DOTFILES_BACKUP/$backup_name"
    fi

    # Create parent dir if needed
    sudo -u "$TARGET_USER" mkdir -p "$(dirname "$target")"

    sudo -u "$TARGET_USER" ln -s "$source" "$target"
    ok "Linked: $target → $source"
    track_installed "symlink $(basename "$target")"
}

# Run symlinks as target user
info "Creating dotfile symlinks..."
safe_symlink "$SETUP_REPO_DIR/zsh/202511.zshrc"   "$TARGET_HOME/.zshrc"
safe_symlink "$SETUP_REPO_DIR/zsh/.zshenv"         "$TARGET_HOME/.zshenv"
safe_symlink "$SETUP_REPO_DIR/vim/dot.vimrc"       "$TARGET_HOME/.vimrc"
safe_symlink "$SETUP_REPO_DIR/tcsh/tcsh.cshrc"     "$TARGET_HOME/.cshrc"
safe_symlink "$SETUP_REPO_DIR/tmux/tmux.conf"      "$TARGET_HOME/.tmux.conf"

# Neovim config — link nvim-pro-kit if it has an init.lua or init.vim
NVIM_CONFIG_DIR="$TARGET_HOME/.config/nvim"
if [[ -f "$NVIM_REPO_DIR/init.lua" || -f "$NVIM_REPO_DIR/init.vim" ]]; then
    safe_symlink "$NVIM_REPO_DIR" "$NVIM_CONFIG_DIR"
else
    info "nvim-pro-kit has no init.lua/init.vim at top level — skipping nvim config symlink"
    info "You may need to symlink manually after checking the repo structure"
fi

# Install vim-plug for vim
VIM_PLUG="$TARGET_HOME/.vim/autoload/plug.vim"
if [[ -f "$VIM_PLUG" ]]; then
    ok "vim-plug already installed"
    track_skipped "vim-plug"
else
    info "Installing vim-plug..."
    sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.vim/autoload"
    if sudo -u "$TARGET_USER" curl -fLo "$VIM_PLUG" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 2>/dev/null; then
        ok "vim-plug installed"
        track_installed "vim-plug"
    else
        warn "Failed to download vim-plug"
        track_failed "vim-plug"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Section 4: Development toolchains
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 4: Development toolchains"

# ── 4a. Rust (rustup) ──

info "Setting up Rust..."
if sudo -u "$TARGET_USER" bash -c 'command -v rustup &>/dev/null'; then
    ok "rustup already installed"
    info "Updating rustup..."
    sudo -u "$TARGET_USER" rustup update 2>/dev/null || warn "rustup update failed"
    track_skipped "rustup"
else
    info "Installing rustup..."
    if sudo -u "$TARGET_USER" bash -c \
        'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path'; then
        ok "rustup installed"
        track_installed "rustup + stable toolchain"
    else
        warn "rustup installation failed"
        track_failed "rustup"
    fi
fi

# Ensure cargo bin is available for this script
CARGO_BIN="$TARGET_HOME/.cargo/bin"
if [[ -d "$CARGO_BIN" ]]; then
    export PATH="$CARGO_BIN:$PATH"
fi

# ── 4b. Python (uv) ──

info "Setting up Python (uv)..."
if sudo -u "$TARGET_USER" bash -c 'command -v uv &>/dev/null'; then
    ok "uv already installed"
    info "Updating uv..."
    sudo -u "$TARGET_USER" bash -c 'uv self update' 2>/dev/null || warn "uv update failed"
    track_skipped "uv"
else
    info "Installing uv..."
    if sudo -u "$TARGET_USER" bash -c \
        'curl -LsSf https://astral.sh/uv/install.sh | sh'; then
        ok "uv installed"
        track_installed "uv"
    else
        warn "uv installation failed"
        track_failed "uv"
    fi
fi

# ── 4c. Node.js (nvm) ──

info "Setting up Node.js (nvm)..."
NVM_DIR="$TARGET_HOME/.nvm"
if [[ -d "$NVM_DIR" ]]; then
    ok "nvm already installed at $NVM_DIR"
    track_skipped "nvm"
else
    info "Installing nvm..."
    # Get latest nvm version from GitHub
    NVM_LATEST=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') || NVM_LATEST="v0.40.1"

    if sudo -u "$TARGET_USER" bash -c \
        "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST/install.sh | bash"; then
        ok "nvm $NVM_LATEST installed"
        track_installed "nvm $NVM_LATEST"
    else
        warn "nvm installation failed"
        track_failed "nvm"
    fi
fi

# Install latest LTS node via nvm
if [[ -d "$NVM_DIR" ]]; then
    info "Installing Node.js LTS via nvm..."
    # Source nvm in a subshell to install node
    sudo -u "$TARGET_USER" bash -c "
        export NVM_DIR='$NVM_DIR'
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
        if nvm ls --no-colors 2>/dev/null | grep -q 'lts/'; then
            echo 'Node LTS already installed'
        else
            nvm install --lts
        fi
        nvm alias default lts/*
    " && track_installed "node LTS" || track_failed "node LTS"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Section 5: Security hardening
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 5: Security hardening"

# ── 5a. UFW ──

info "Configuring firewall (ufw)..."
if ! command -v ufw &>/dev/null; then
    $SUDO apt-get install -y -qq ufw
fi

UFW_STATUS=$($SUDO ufw status | head -1)
if [[ "$UFW_STATUS" == *"active"* ]]; then
    ok "ufw is already active"
    track_skipped "ufw (already active)"
else
    info "Enabling ufw with default deny + SSH allow..."
    $SUDO ufw default deny incoming
    $SUDO ufw default allow outgoing
    $SUDO ufw allow ssh
    $SUDO ufw --force enable
    ok "ufw enabled (deny incoming, allow SSH)"
    track_installed "ufw"
fi

# Show current rules
info "Current ufw rules:"
$SUDO ufw status verbose

# ── 5b. fail2ban ──

info "Configuring fail2ban..."
if ! command -v fail2ban-client &>/dev/null; then
    $SUDO apt-get install -y -qq fail2ban
    track_installed "fail2ban"
else
    ok "fail2ban already installed"
    track_skipped "fail2ban (already installed)"
fi

# Create local jail config (won't be overwritten by package upgrades)
F2B_LOCAL="/etc/fail2ban/jail.local"
if [[ -f "$F2B_LOCAL" ]]; then
    ok "fail2ban jail.local already exists"
    track_skipped "fail2ban config"
else
    info "Creating fail2ban jail.local..."
    $SUDO tee "$F2B_LOCAL" > /dev/null <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ssh
backend = systemd
EOF
    ok "fail2ban jail.local created"
    track_installed "fail2ban config"
fi

$SUDO systemctl enable fail2ban 2>/dev/null
$SUDO systemctl restart fail2ban 2>/dev/null
ok "fail2ban enabled and running"

# ═══════════════════════════════════════════════════════════════════════════════
# Section 6: System tuning
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 6: System tuning"

# ── 6a. Locale ──

DESIRED_LOCALE="en_US.UTF-8"
if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
    ok "Locale $DESIRED_LOCALE available"
    track_skipped "locale"
else
    info "Generating locale $DESIRED_LOCALE..."
    $SUDO locale-gen "$DESIRED_LOCALE"
    $SUDO update-locale LANG="$DESIRED_LOCALE"
    ok "Locale $DESIRED_LOCALE generated"
    track_installed "locale en_US.UTF-8"
fi

# ── 6b. Sysctl tuning ──

SYSCTL_CONF="/etc/sysctl.d/99-bootstrap.conf"
if [[ -f "$SYSCTL_CONF" ]]; then
    ok "Sysctl tuning already applied"
    track_skipped "sysctl tuning"
else
    info "Applying sysctl tuning..."
    $SUDO tee "$SYSCTL_CONF" > /dev/null <<'EOF'
# bootstrap/debian_ubuntu.sh — system tuning

# Increase inotify watchers (IDEs, file watchers)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# Increase file descriptors
fs.file-max = 2097152

# Network performance
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000

# Swappiness: prefer RAM over swap
vm.swappiness = 10

# Reduce cache pressure
vm.vfs_cache_pressure = 50
EOF
    $SUDO sysctl --system > /dev/null 2>&1
    ok "Sysctl tuning applied"
    track_installed "sysctl tuning"
fi

# ── 6c. File descriptor limits ──

LIMITS_CONF="/etc/security/limits.d/99-bootstrap.conf"
if [[ -f "$LIMITS_CONF" ]]; then
    ok "File descriptor limits already configured"
    track_skipped "ulimit config"
else
    info "Setting file descriptor limits..."
    $SUDO tee "$LIMITS_CONF" > /dev/null <<EOF
# bootstrap/debian_ubuntu.sh — increase limits for $TARGET_USER
$TARGET_USER  soft  nofile  65536
$TARGET_USER  hard  nofile  131072
$TARGET_USER  soft  nproc   65536
$TARGET_USER  hard  nproc   131072
EOF
    ok "File descriptor limits configured"
    track_installed "ulimit config"
fi

# ── 6d. SSH hardening (basic) ──

SSHD_CONF="/etc/ssh/sshd_config.d/99-bootstrap.conf"
if [[ -f "$SSHD_CONF" ]]; then
    ok "SSH hardening already applied"
    track_skipped "ssh hardening"
else
    info "Applying basic SSH hardening..."
    $SUDO tee "$SSHD_CONF" > /dev/null <<'EOF'
# bootstrap/debian_ubuntu.sh — SSH hardening
PermitRootLogin no
PasswordAuthentication yes
MaxAuthTries 5
LoginGraceTime 60
EOF
    $SUDO systemctl reload sshd 2>/dev/null || $SUDO systemctl reload ssh 2>/dev/null || true
    ok "SSH hardening applied (root login disabled)"
    track_installed "ssh hardening"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Section 7: Summary
# ═══════════════════════════════════════════════════════════════════════════════

section "Section 7: Summary"

printf "${GREEN}Installed/configured:${NC}\n"
for item in "${INSTALLED[@]}"; do
    printf "  ✓ %s\n" "$item"
done

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    printf "\n${YELLOW}Skipped (already present):${NC}\n"
    for item in "${SKIPPED[@]}"; do
        printf "  ⊘ %s\n" "$item"
    done
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    printf "\n${RED}Failed:${NC}\n"
    for item in "${FAILED[@]}"; do
        printf "  ✗ %s\n" "$item"
    done
fi

printf "\n"
ok "Bootstrap complete!"
info "Restart your shell or log out/in for all changes to take effect."
info "Manual steps remaining:"
info "  - Run 'vim +PlugInstall +qall' to install vim plugins"
info "  - Set up SSH keys: ssh-keygen -t ed25519"
info "  - Optional: install Tailscale (https://tailscale.com/download/linux)"
info "  - Optional: install Chromium (sudo apt install chromium-browser)"
