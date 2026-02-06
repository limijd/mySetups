#!/usr/bin/env bash
#
# 06_nodejs_nvm.sh — Node.js (通过 nvm)
#
# 安装 nvm，再通过 nvm 安装 LTS 版本 Node.js。
# 可独立运行: bash bootstrap/scripts/06_nodejs_nvm.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "Node.js (nvm)"

NVM_DIR="$TARGET_HOME/.nvm"

step "检查 nvm 是否已安装"
if [[ -d "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" ]]; then
    ok "nvm 已安装: $NVM_DIR"
else
    step "安装 nvm"
    info "获取最新 nvm 版本号..."
    NVM_LATEST=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') || NVM_LATEST="v0.40.1"
    info "nvm 版本: $NVM_LATEST"

    run_cmd "安装 nvm $NVM_LATEST" \
        as_user bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST/install.sh | bash"
fi

step "通过 nvm 安装 Node.js LTS"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    err "nvm.sh 不存在，nvm 安装可能失败"
    exit 1
fi

# 需要在子 shell 中 source nvm
info "在子 shell 中加载 nvm 并安装 Node.js LTS..."
as_user bash -c "
    export NVM_DIR='$NVM_DIR'
    source \"\$NVM_DIR/nvm.sh\"

    echo '当前已安装的 Node.js 版本:'
    nvm ls --no-colors 2>/dev/null || true

    echo ''
    echo '安装 LTS 版本...'
    nvm install --lts

    echo ''
    echo '设置默认版本为 LTS...'
    nvm alias default lts/*

    echo ''
    echo '验证:'
    echo \"  node: \$(node --version)\"
    echo \"  npm:  \$(npm --version)\"
"

step "验证安装结果"
as_user bash -c "
    export NVM_DIR='$NVM_DIR'
    source \"\$NVM_DIR/nvm.sh\"
    echo \"node 路径: \$(which node)\"
    echo \"node 版本: \$(node --version)\"
    echo \"npm  版本: \$(npm --version)\"
"

footer
