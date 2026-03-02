#!/usr/bin/env bash
#
# 05_python_pyenv.sh — Python 版本管理 (pyenv)
#
# 安装 pyenv 及最新稳定版 Python。
# 可独立运行: bash bootstrap/scripts/05_python_pyenv.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "Python 版本管理 (pyenv)"

# ─────────────────────────────────────────────────────────────────────────────
# pyenv 构建依赖 (Debian/Ubuntu)
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
# ─────────────────────────────────────────────────────────────────────────────

step "安装 pyenv 构建依赖"
PYENV_BUILD_DEPS=(
    build-essential libssl-dev zlib1g-dev
    libbz2-dev libreadline-dev libsqlite3-dev
    libncursesw5-dev xz-utils tk-dev
    libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
)
run_cmd "安装构建依赖" $SUDO apt-get install -y "${PYENV_BUILD_DEPS[@]}"

# ─────────────────────────────────────────────────────────────────────────────
# 安装 / 更新 pyenv
# ─────────────────────────────────────────────────────────────────────────────

PYENV_ROOT="$TARGET_HOME/.pyenv"

step "检查 pyenv 是否已安装"
if [[ -d "$PYENV_ROOT" ]]; then
    ok "pyenv 已安装: $PYENV_ROOT"
    step "更新 pyenv"
    run_cmd_allow_fail "git pull pyenv" \
        as_user git -C "$PYENV_ROOT" pull --ff-only
else
    step "安装 pyenv"
    run_cmd "克隆 pyenv" \
        as_user git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
fi

# 使 pyenv 在当前脚本可用
export PYENV_ROOT
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

step "验证 pyenv"
run_cmd "pyenv 版本" as_user bash -c "export PYENV_ROOT='$PYENV_ROOT' && export PATH='$PYENV_ROOT/bin:\$PATH' && pyenv --version"

# ─────────────────────────────────────────────────────────────────────────────
# 安装最新稳定版 Python
# ─────────────────────────────────────────────────────────────────────────────

step "查找最新稳定版 Python"
LATEST_PY=$(as_user bash -c "export PYENV_ROOT='$PYENV_ROOT' && export PATH='$PYENV_ROOT/bin:\$PATH' && pyenv install --list" \
    | grep -E '^\s+[0-9]+\.[0-9]+\.[0-9]+$' \
    | tail -1 \
    | tr -d '[:space:]')
info "最新稳定版: Python $LATEST_PY"

if as_user bash -c "export PYENV_ROOT='$PYENV_ROOT' && export PATH='$PYENV_ROOT/bin:\$PATH' && pyenv versions --bare" | grep -qxF "$LATEST_PY"; then
    ok "Python $LATEST_PY 已安装"
else
    step "安装 Python $LATEST_PY"
    run_cmd "pyenv install $LATEST_PY" \
        as_user bash -c "export PYENV_ROOT='$PYENV_ROOT' && export PATH='$PYENV_ROOT/bin:\$PATH' && pyenv install '$LATEST_PY'"
fi

step "设置全局默认版本"
run_cmd "pyenv global $LATEST_PY" \
    as_user bash -c "export PYENV_ROOT='$PYENV_ROOT' && export PATH='$PYENV_ROOT/bin:\$PATH' && pyenv global '$LATEST_PY'"

step "验证 Python"
run_cmd "python 版本" \
    as_user bash -c "export PYENV_ROOT='$PYENV_ROOT' && export PATH='$PYENV_ROOT/bin:$PYENV_ROOT/shims:\$PATH' && python --version"

# ─────────────────────────────────────────────────────────────────────────────
# Shell 配置提示
# ─────────────────────────────────────────────────────────────────────────────

step "Shell 配置检查"
info "pyenv 需要在 shell 配置中添加以下内容:"
printf "${DIM}    export PYENV_ROOT=\"\$HOME/.pyenv\"${NC}\n"
printf "${DIM}    export PATH=\"\$PYENV_ROOT/bin:\$PATH\"${NC}\n"
printf "${DIM}    eval \"\$(pyenv init -)\"${NC}\n"

for rc in "$TARGET_HOME/.zshrc" "$TARGET_HOME/.bashrc"; do
    if [[ -f "$rc" ]] && grep -q 'pyenv init' "$rc"; then
        ok "$(basename "$rc") 已配置 pyenv"
    elif [[ -f "$rc" ]]; then
        warn "$(basename "$rc") 未配置 pyenv，请手动添加上述内容"
    fi
done

footer
