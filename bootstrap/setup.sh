#!/usr/bin/env bash
#
# bootstrap/setup.sh — 主入口: 交互式菜单
#
# 用法:
#   bash bootstrap/setup.sh          # 交互式选择模块
#   bash bootstrap/setup.sh all      # 运行全部模块
#   bash bootstrap/setup.sh 1 3 4    # 运行指定模块
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# 模块列表
# ═══════════════════════════════════════════════════════════════════════════════

MODULES=(
    "01_apt_packages.sh|系统包安装 (apt)"
    "02_shell_setup.sh|设置默认 Shell (zsh)"
    "03_repos_dotfiles.sh|克隆仓库 + Dotfiles 软链接"
    "04_rust.sh|Rust 工具链 (rustup)"
    "05_python_uv.sh|Python 包管理器 (uv)"
    "06_nodejs_nvm.sh|Node.js (nvm)"
    "07_security.sh|安全加固 (ufw + fail2ban)"
    "08_system_tuning.sh|系统调优 (sysctl, limits, SSH)"
)

# ═══════════════════════════════════════════════════════════════════════════════
# 显示菜单
# ═══════════════════════════════════════════════════════════════════════════════

show_menu() {
    printf "\n${BOLD}${CYAN}"
    printf '═%.0s' $(seq 1 50)
    printf "\n  Debian/Ubuntu 系统配置工具\n"
    printf '═%.0s' $(seq 1 50)
    printf "${NC}\n\n"

    printf "  可用模块:\n\n"
    local i=1
    for entry in "${MODULES[@]}"; do
        local name="${entry#*|}"
        printf "    ${BOLD}%d${NC})  %s\n" "$i" "$name"
        ((i++))
    done

    printf "\n"
    printf "  ${DIM}输入模块编号 (空格分隔)，或:${NC}\n"
    printf "    ${BOLD}all${NC}   — 运行全部模块\n"
    printf "    ${BOLD}q${NC}     — 退出\n"
    printf "\n"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 运行指定模块
# ═══════════════════════════════════════════════════════════════════════════════

declare -a RUN_RESULTS=()

run_module() {
    local idx=$1
    local entry="${MODULES[$((idx-1))]}"
    local script="${entry%%|*}"
    local name="${entry#*|}"
    local script_path="$SCRIPT_DIR/scripts/$script"

    if [[ ! -f "$script_path" ]]; then
        err "脚本不存在: $script_path"
        RUN_RESULTS+=("✗ [$idx] $name — 脚本不存在")
        return 1
    fi

    printf "\n${BOLD}${YELLOW}"
    printf '▶▶▶ 运行模块 %d: %s ▶▶▶' "$idx" "$name"
    printf "${NC}\n"

    if bash "$script_path"; then
        RUN_RESULTS+=("✓ [$idx] $name")
    else
        RUN_RESULTS+=("✗ [$idx] $name — 执行出错")
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 汇总
# ═══════════════════════════════════════════════════════════════════════════════

show_summary() {
    printf "\n${BOLD}${CYAN}"
    printf '═%.0s' $(seq 1 50)
    printf "\n  执行结果汇总\n"
    printf '═%.0s' $(seq 1 50)
    printf "${NC}\n\n"

    for result in "${RUN_RESULTS[@]}"; do
        if [[ "$result" == ✓* ]]; then
            printf "  ${GREEN}%s${NC}\n" "$result"
        else
            printf "  ${RED}%s${NC}\n" "$result"
        fi
    done
    printf "\n"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 主逻辑
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local total=${#MODULES[@]}
    local selections=()

    # 如果有命令行参数，直接使用
    if [[ $# -gt 0 ]]; then
        if [[ "$1" == "all" ]]; then
            for ((i=1; i<=total; i++)); do
                selections+=("$i")
            done
        else
            selections=("$@")
        fi
    else
        # 交互式菜单
        show_menu
        printf "  ${BOLD}请选择: ${NC}"
        read -r input

        if [[ "$input" == "q" || "$input" == "Q" ]]; then
            info "退出"
            exit 0
        fi

        if [[ "$input" == "all" || "$input" == "ALL" ]]; then
            for ((i=1; i<=total; i++)); do
                selections+=("$i")
            done
        else
            # shellcheck disable=SC2206
            selections=($input)
        fi
    fi

    # 校验选择
    if [[ ${#selections[@]} -eq 0 ]]; then
        warn "未选择任何模块"
        exit 0
    fi

    for sel in "${selections[@]}"; do
        if ! [[ "$sel" =~ ^[0-9]+$ ]] || [[ "$sel" -lt 1 || "$sel" -gt $total ]]; then
            err "无效的模块编号: $sel (有效范围: 1-$total)"
            exit 1
        fi
    done

    # 确认
    printf "\n  即将运行以下模块:\n"
    for sel in "${selections[@]}"; do
        local entry="${MODULES[$((sel-1))]}"
        local name="${entry#*|}"
        printf "    ${BOLD}%s${NC}) %s\n" "$sel" "$name"
    done
    printf "\n"

    if ! confirm "确认执行？"; then
        info "已取消"
        exit 0
    fi

    # 逐个运行
    for sel in "${selections[@]}"; do
        run_module "$sel"
    done

    # 汇总
    show_summary
}

main "$@"
