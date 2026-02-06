#!/usr/bin/env bash
#
# 05_python_uv.sh — Python uv 包管理器
#
# 安装或更新 uv (astral.sh 出品的快速 Python 包管理器)。
# 可独立运行: bash bootstrap/scripts/05_python_uv.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "Python 包管理器 (uv)"

step "检查系统 Python"
if check_cmd python3; then
    run_cmd "python3 版本" python3 --version
else
    warn "python3 未安装，建议先运行 01_apt_packages.sh"
fi

step "检查 uv 是否已安装"
if as_user bash -c 'command -v uv &>/dev/null'; then
    UV_PATH=$(as_user bash -c 'command -v uv')
    ok "uv 已安装: $UV_PATH"
    as_user uv --version

    step "更新 uv"
    run_cmd_allow_fail "uv self update" as_user bash -c 'uv self update'
else
    step "安装 uv"
    info "通过官方安装脚本安装 uv"
    run_cmd "安装 uv" \
        as_user bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
fi

step "验证安装"
# 刷新 PATH（uv 可能安装在 ~/.local/bin 或 ~/.cargo/bin）
UV_SEARCH_PATHS=(
    "$TARGET_HOME/.local/bin"
    "$TARGET_HOME/.cargo/bin"
)
for p in "${UV_SEARCH_PATHS[@]}"; do
    [[ -d "$p" ]] && export PATH="$p:$PATH"
done

if check_cmd uv; then
    run_cmd "uv 版本" uv --version
else
    warn "uv 不在 PATH 中，请重新登录或添加 ~/.local/bin 到 PATH"
fi

footer
