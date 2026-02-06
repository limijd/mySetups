#!/usr/bin/env bash
#
# bootstrap/lib/common.sh — 共享函数库
#
# 所有 bootstrap 脚本通过 source 加载此文件，提供：
#   - 颜色输出
#   - run_cmd: 透明执行命令（显示命令 + 输出 + 结果）
#   - step: 步骤编号
#   - bootstrap_init: OS 检测 + sudo + TARGET_USER/TARGET_HOME
#   - header/footer: 脚本头尾
#   - confirm: 交互确认
#   - check_cmd: 检查命令是否存在

# 防止重复加载
[[ -n "${_BOOTSTRAP_COMMON_LOADED:-}" ]] && return 0
_BOOTSTRAP_COMMON_LOADED=1

# ═══════════════════════════════════════════════════════════════════════════════
# 颜色定义
# ═══════════════════════════════════════════════════════════════════════════════

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    DIM='\033[2m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    DIM=''
    BOLD=''
    NC=''
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 基础打印
# ═══════════════════════════════════════════════════════════════════════════════

info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()      { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()     { printf "${RED}[ERR ]${NC}  %s\n" "$*"; }
skip()    { printf "${DIM}[SKIP]${NC}  %s\n" "$*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# run_cmd — 透明执行命令
#
# 用法: run_cmd "描述" command arg1 arg2 ...
#
# 效果:
#   → 描述
#     $ command arg1 arg2 ...
#     (命令的实际输出)
#     ✓ 成功
# ═══════════════════════════════════════════════════════════════════════════════

run_cmd() {
    local description="$1"
    shift
    printf "\n${CYAN}  → %s${NC}\n" "$description"
    printf "${DIM}    \$ %s${NC}\n" "$*"
    if "$@"; then
        printf "${GREEN}    ✓ 成功${NC}\n"
        return 0
    else
        local rc=$?
        printf "${RED}    ✗ 失败 (exit code: %d)${NC}\n" "$rc"
        return $rc
    fi
}

# run_cmd_allow_fail — 同 run_cmd，但失败不退出（用于可选操作）
run_cmd_allow_fail() {
    local description="$1"
    shift
    printf "\n${CYAN}  → %s${NC}\n" "$description"
    printf "${DIM}    \$ %s${NC}\n" "$*"
    if "$@"; then
        printf "${GREEN}    ✓ 成功${NC}\n"
    else
        local rc=$?
        printf "${YELLOW}    ⚠ 失败 (exit code: %d)，继续...${NC}\n" "$rc"
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# step — 步骤编号
# ═══════════════════════════════════════════════════════════════════════════════

STEP_NUM=0

step() {
    ((STEP_NUM++))
    printf "\n${BOLD}${BLUE}━━━ [步骤 %d] %s ━━━${NC}\n" "$STEP_NUM" "$*"
}

# 重置步骤计数（每个脚本开头调用）
reset_steps() {
    STEP_NUM=0
}

# ═══════════════════════════════════════════════════════════════════════════════
# header / footer — 脚本头尾
# ═══════════════════════════════════════════════════════════════════════════════

header() {
    local title="$1"
    local width=60
    printf "\n${BOLD}${CYAN}"
    printf '═%.0s' $(seq 1 $width)
    printf "\n  %s\n" "$title"
    printf '═%.0s' $(seq 1 $width)
    printf "${NC}\n"
}

footer() {
    printf "\n${BOLD}${GREEN}"
    printf '─%.0s' $(seq 1 40)
    printf "\n  脚本执行完毕\n"
    printf '─%.0s' $(seq 1 40)
    printf "${NC}\n\n"
}

# ═══════════════════════════════════════════════════════════════════════════════
# confirm — 交互确认
#
# 用法: confirm "是否继续？" && do_something
# 默认 N（直接回车 = 拒绝）
# ═══════════════════════════════════════════════════════════════════════════════

confirm() {
    local prompt="${1:-确认？}"
    printf "${YELLOW}%s [y/N] ${NC}" "$prompt"
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# check_cmd — 检查命令是否存在
# ═══════════════════════════════════════════════════════════════════════════════

check_cmd() {
    command -v "$1" &>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# bootstrap_init — OS 检测 + sudo + 用户信息
#
# 调用后可用变量:
#   SUDO          — "sudo" 或 ""
#   TARGET_USER   — 目标用户名
#   TARGET_HOME   — 目标用户 home 目录
#   OS_ID         — debian/ubuntu 等
#   OS_PRETTY     — 完整 OS 名称
#   OS_CODENAME   — 版本代号
# ═══════════════════════════════════════════════════════════════════════════════

bootstrap_init() {
    # OS 检测
    if [[ ! -f /etc/os-release ]]; then
        err "无法检测 OS: /etc/os-release 不存在"
        exit 1
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    if [[ "$ID" != "ubuntu" && "$ID" != "debian" \
       && "${ID_LIKE:-}" != *"debian"* && "${ID_LIKE:-}" != *"ubuntu"* ]]; then
        err "此脚本仅支持 Debian/Ubuntu，当前系统: $PRETTY_NAME"
        exit 1
    fi

    OS_ID="$ID"
    OS_PRETTY="$PRETTY_NAME"
    OS_CODENAME="${VERSION_CODENAME:-unknown}"

    info "系统: $OS_PRETTY ($OS_CODENAME) | 架构: $(uname -m)"

    # sudo 检测
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
        warn "当前以 root 运行，建议使用普通用户 + sudo"
    else
        if ! check_cmd sudo; then
            err "sudo 未安装，请安装 sudo 或以 root 运行"
            exit 1
        fi
        SUDO="sudo"
        info "请求 sudo 权限..."
        $SUDO true || { err "sudo 验证失败"; exit 1; }
        ok "sudo 权限已确认"
    fi

    # 目标用户
    TARGET_USER="${SUDO_USER:-$USER}"
    TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

    info "目标用户: $TARGET_USER (home: $TARGET_HOME)"

    # 常用路径
    SETUP_REPO_DIR="$TARGET_HOME/sandbox/github/mySetups"
    NVIM_REPO_DIR="$TARGET_HOME/sandbox/github/nvim-pro-kit"
}

# 以目标用户身份执行命令
as_user() {
    if [[ -n "$SUDO" ]]; then
        sudo -u "$TARGET_USER" "$@"
    else
        "$@"
    fi
}
