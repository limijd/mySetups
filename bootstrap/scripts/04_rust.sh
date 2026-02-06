#!/usr/bin/env bash
#
# 04_rust.sh — Rust 工具链 (rustup)
#
# 安装或更新 rustup + stable 工具链。
# 可独立运行: bash bootstrap/scripts/04_rust.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "Rust 工具链 (rustup)"

CARGO_BIN="$TARGET_HOME/.cargo/bin"

step "检查 rustup 是否已安装"
if as_user bash -c 'command -v rustup &>/dev/null'; then
    RUSTUP_PATH=$(as_user bash -c 'command -v rustup')
    ok "rustup 已安装: $RUSTUP_PATH"

    step "查看当前版本"
    as_user rustup --version
    as_user rustc --version 2>/dev/null || true

    step "更新 rustup 和工具链"
    run_cmd_allow_fail "rustup self update" as_user rustup self update
    run_cmd_allow_fail "rustup update" as_user rustup update
else
    step "安装 rustup"
    info "通过官方安装脚本安装 rustup (stable toolchain, 不修改 PATH 配置)"
    run_cmd "安装 rustup" \
        as_user bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path'
fi

# 确保 cargo bin 可用
if [[ -d "$CARGO_BIN" ]]; then
    export PATH="$CARGO_BIN:$PATH"
fi

step "验证安装"
if check_cmd rustup; then
    run_cmd "rustup --version" rustup --version
    run_cmd "rustc --version" rustc --version
    run_cmd "cargo --version" cargo --version
    run_cmd "已安装的工具链" rustup toolchain list
else
    warn "rustup 不在 PATH 中，请重新登录或 source ~/.cargo/env"
fi

footer
