#!/usr/bin/env bash
#
# 08_system_tuning.sh — 系统调优
#
# 包含: locale, sysctl, 文件描述符限制, SSH 基础加固。
# 可独立运行: bash bootstrap/scripts/08_system_tuning.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "系统调优"

# ═══════════════════════════════════════════════════════════════════════════════
# Locale
# ═══════════════════════════════════════════════════════════════════════════════

step "配置 Locale (en_US.UTF-8)"
DESIRED_LOCALE="en_US.UTF-8"
info "检查 locale 是否可用..."
if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
    ok "Locale $DESIRED_LOCALE 已可用"
else
    run_cmd "生成 locale" $SUDO locale-gen "$DESIRED_LOCALE"
    run_cmd "设置系统 locale" $SUDO update-locale LANG="$DESIRED_LOCALE"
fi

info "当前 locale 设置:"
locale 2>/dev/null | head -5

# ═══════════════════════════════════════════════════════════════════════════════
# Sysctl 调优
# ═══════════════════════════════════════════════════════════════════════════════

step "Sysctl 内核参数调优"
SYSCTL_CONF="/etc/sysctl.d/99-bootstrap.conf"
if [[ -f "$SYSCTL_CONF" ]]; then
    ok "sysctl 配置已存在: $SYSCTL_CONF"
    info "当前内容:"
    $SUDO cat "$SYSCTL_CONF"
else
    SYSCTL_CONTENT='# bootstrap — system tuning

# inotify: IDE 和文件监控需要更大的 watcher 数量
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# 文件描述符上限
fs.file-max = 2097152

# 网络性能
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000

# 减少 swap 使用，优先使用内存
vm.swappiness = 10

# 减少缓存压力
vm.vfs_cache_pressure = 50'

    info "将写入以下配置到 $SYSCTL_CONF:"
    echo "$SYSCTL_CONTENT"
    echo ""

    echo "$SYSCTL_CONTENT" | $SUDO tee "$SYSCTL_CONF" > /dev/null
    run_cmd "应用 sysctl 配置" $SUDO sysctl --system
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 文件描述符限制
# ═══════════════════════════════════════════════════════════════════════════════

step "文件描述符限制 (ulimit)"
LIMITS_CONF="/etc/security/limits.d/99-bootstrap.conf"
if [[ -f "$LIMITS_CONF" ]]; then
    ok "limits 配置已存在: $LIMITS_CONF"
    info "当前内容:"
    $SUDO cat "$LIMITS_CONF"
else
    LIMITS_CONTENT="# bootstrap — increase limits for $TARGET_USER
$TARGET_USER  soft  nofile  65536
$TARGET_USER  hard  nofile  131072
$TARGET_USER  soft  nproc   65536
$TARGET_USER  hard  nproc   131072"

    info "将写入以下配置到 $LIMITS_CONF:"
    echo "$LIMITS_CONTENT"
    echo ""

    echo "$LIMITS_CONTENT" | $SUDO tee "$LIMITS_CONF" > /dev/null
    ok "文件描述符限制已配置"
fi

info "当前 ulimit 值:"
echo "  nofile (soft): $(ulimit -Sn)"
echo "  nofile (hard): $(ulimit -Hn)"

# ═══════════════════════════════════════════════════════════════════════════════
# SSH 基础加固
# ═══════════════════════════════════════════════════════════════════════════════

step "SSH 基础加固"
SSHD_CONF="/etc/ssh/sshd_config.d/99-bootstrap.conf"
if [[ -f "$SSHD_CONF" ]]; then
    ok "SSH 加固配置已存在: $SSHD_CONF"
    info "当前内容:"
    $SUDO cat "$SSHD_CONF"
else
    SSHD_CONTENT='# bootstrap — SSH hardening
PermitRootLogin no
PasswordAuthentication yes
MaxAuthTries 5
LoginGraceTime 60'

    info "将写入以下配置到 $SSHD_CONF:"
    echo "$SSHD_CONTENT"
    echo ""

    echo "$SSHD_CONTENT" | $SUDO tee "$SSHD_CONF" > /dev/null
    ok "SSH 加固配置已写入"

    # 某些系统服务名为 sshd，某些为 ssh
    if $SUDO systemctl reload sshd 2>/dev/null; then
        ok "sshd 服务已重载"
    elif $SUDO systemctl reload ssh 2>/dev/null; then
        ok "ssh 服务已重载"
    else
        warn "无法重载 SSH 服务 (服务可能未运行)"
    fi
fi

footer
