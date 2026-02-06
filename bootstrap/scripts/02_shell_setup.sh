#!/usr/bin/env bash
#
# 02_shell_setup.sh — 设置默认 shell 为 zsh
#
# 可独立运行: bash bootstrap/scripts/02_shell_setup.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "设置默认 Shell (zsh)"

step "检查 zsh 是否已安装"
if ! check_cmd zsh; then
    err "zsh 未安装，请先运行 01_apt_packages.sh"
    exit 1
fi
ZSH_PATH=$(command -v zsh)
ok "zsh 路径: $ZSH_PATH"
run_cmd "查看 zsh 版本" zsh --version

step "检查当前默认 shell"
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)
info "当前默认 shell: $CURRENT_SHELL"

if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
    ok "默认 shell 已经是 zsh，无需修改"
else
    step "切换默认 shell 为 zsh"
    run_cmd "chsh -s $ZSH_PATH $TARGET_USER" $SUDO chsh -s "$ZSH_PATH" "$TARGET_USER"

    # 验证
    NEW_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)
    if [[ "$NEW_SHELL" == "$ZSH_PATH" ]]; then
        ok "默认 shell 已切换为: $NEW_SHELL"
    else
        err "切换失败，当前仍为: $NEW_SHELL"
    fi
fi

footer
