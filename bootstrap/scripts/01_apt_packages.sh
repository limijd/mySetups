#!/usr/bin/env bash
#
# 01_apt_packages.sh — 系统包安装
#
# 按分类分组安装 apt 包，每组显示安装过程。
# 可独立运行: bash bootstrap/scripts/01_apt_packages.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "系统包安装 (apt)"

# ── 包分组定义 ──

declare -A PKG_GROUPS
PKG_GROUPS=(
    [01_shells]="zsh tcsh"
    [02_editors]="vim vim-gtk3"
    [03_terminal]="tmux screen"
    [04_compilers]="gcc g++ clang llvm build-essential cmake ninja-build pkg-config autoconf automake libtool ccache bear"
    [05_cpp_tools]="clang-format clang-tools valgrind gdb strace"
    [06_dev_libs]="libssl-dev libffi-dev zlib1g-dev libreadline-dev"
    [07_vcs]="git git-lfs"
    [08_python]="python3 python3-venv python3-pip"
    [09_cli_modern]="ripgrep fd-find fzf bat eza zoxide git-delta tldr"
    [10_monitoring]="htop btop ncdu duf iotop sysstat lsof linux-tools-common"
    [11_network]="curl wget net-tools dnsutils traceroute mtr openssh-server nmap tcpdump socat iperf3"
    [12_code_nav]="universal-ctags cscope"
    [13_shell_text]="direnv shellcheck jq tree unzip zip pv xclip zstd indent lm-sensors"
    [14_system]="ca-certificates gnupg software-properties-common man-db locales"
)

# 分组显示名
declare -A PKG_GROUP_NAMES
PKG_GROUP_NAMES=(
    [01_shells]="Shell (zsh, tcsh)"
    [02_editors]="编辑器 (vim)"
    [03_terminal]="终端复用器 (tmux, screen)"
    [04_compilers]="编译器和构建工具"
    [05_cpp_tools]="C/C++ 开发工具"
    [06_dev_libs]="开发库"
    [07_vcs]="版本控制 (git)"
    [08_python]="Python 基础"
    [09_cli_modern]="现代 CLI 工具"
    [10_monitoring]="系统监控工具"
    [11_network]="网络工具"
    [12_code_nav]="代码导航工具"
    [13_shell_text]="Shell / 文本工具"
    [14_system]="系统基础包"
)

# ── 更新包索引 ──

step "更新 apt 包索引"
run_cmd "apt-get update" $SUDO apt-get update

# ── 分组安装 ──

# 按 key 排序遍历
SORTED_KEYS=$(echo "${!PKG_GROUPS[@]}" | tr ' ' '\n' | sort)

for key in $SORTED_KEYS; do
    group_name="${PKG_GROUP_NAMES[$key]}"
    # shellcheck disable=SC2086
    read -ra pkgs <<< "${PKG_GROUPS[$key]}"

    step "安装: $group_name"
    info "包列表: ${pkgs[*]}"

    # 检查哪些已安装
    to_install=()
    for pkg in "${pkgs[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            skip "$pkg 已安装"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        ok "全部已安装，跳过"
        continue
    fi

    info "需要安装: ${to_install[*]}"
    run_cmd_allow_fail "安装 ${group_name}" \
        $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"
done

footer
