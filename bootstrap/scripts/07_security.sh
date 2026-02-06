#!/usr/bin/env bash
#
# 07_security.sh — 防火墙 (ufw) + fail2ban
#
# 配置基础安全: UFW 防火墙 + fail2ban 暴力破解防护。
# 可独立运行: bash bootstrap/scripts/07_security.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "安全加固 (ufw + fail2ban)"

# ═══════════════════════════════════════════════════════════════════════════════
# UFW 防火墙
# ═══════════════════════════════════════════════════════════════════════════════

step "检查 ufw 是否已安装"
if ! check_cmd ufw; then
    run_cmd "安装 ufw" $SUDO apt-get install -y ufw
fi
ok "ufw 已就绪"

step "查看当前防火墙状态"
$SUDO ufw status verbose

step "配置 ufw 规则"
UFW_STATUS=$($SUDO ufw status | head -1)
if [[ "$UFW_STATUS" == *"active"* ]]; then
    ok "ufw 已激活，跳过配置"
else
    info "配置: 默认拒绝入站，允许出站，放行 SSH"
    run_cmd "设置默认拒绝入站" $SUDO ufw default deny incoming
    run_cmd "设置默认允许出站" $SUDO ufw default allow outgoing
    run_cmd "允许 SSH 连接"    $SUDO ufw allow ssh
    run_cmd "启用 ufw"        $SUDO ufw --force enable
fi

step "显示最终 ufw 规则"
$SUDO ufw status numbered

# ═══════════════════════════════════════════════════════════════════════════════
# fail2ban
# ═══════════════════════════════════════════════════════════════════════════════

step "检查 fail2ban 是否已安装"
if ! check_cmd fail2ban-client; then
    run_cmd "安装 fail2ban" $SUDO apt-get install -y fail2ban
else
    ok "fail2ban 已安装"
    run_cmd "fail2ban 版本" fail2ban-client --version
fi

step "配置 fail2ban jail.local"
F2B_LOCAL="/etc/fail2ban/jail.local"
if [[ -f "$F2B_LOCAL" ]]; then
    ok "jail.local 已存在，跳过"
    info "当前内容:"
    $SUDO cat "$F2B_LOCAL"
else
    info "创建 $F2B_LOCAL"
    info "内容如下:"

    F2B_CONTENT='[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ssh
backend = systemd'

    echo "$F2B_CONTENT"
    echo "$F2B_CONTENT" | $SUDO tee "$F2B_LOCAL" > /dev/null
    ok "jail.local 已创建"
fi

step "启动 fail2ban 服务"
run_cmd_allow_fail "启用 fail2ban 自启动" $SUDO systemctl enable fail2ban
run_cmd_allow_fail "重启 fail2ban"       $SUDO systemctl restart fail2ban

step "查看 fail2ban 状态"
run_cmd_allow_fail "fail2ban 服务状态" $SUDO fail2ban-client status

footer
