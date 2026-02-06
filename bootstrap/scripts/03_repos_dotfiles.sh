#!/usr/bin/env bash
#
# 03_repos_dotfiles.sh — 克隆仓库 + 软链接 dotfiles
#
# 克隆 mySetups 和 nvim-pro-kit，创建 dotfile 软链接。
# 可独立运行: bash bootstrap/scripts/03_repos_dotfiles.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
bootstrap_init

header "仓库克隆 & Dotfiles 软链接"

DOTFILES_BACKUP="$TARGET_HOME/.dotfiles.bak"

# ═══════════════════════════════════════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════════════════════════════════════

clone_or_pull() {
    local repo_url="$1"
    local target_dir="$2"

    if [[ -d "$target_dir/.git" ]]; then
        ok "仓库已存在: $target_dir"
        run_cmd_allow_fail "拉取最新代码" as_user git -C "$target_dir" pull --ff-only
    else
        info "克隆 $repo_url → $target_dir"
        as_user mkdir -p "$(dirname "$target_dir")"
        run_cmd "git clone $repo_url" as_user git clone "$repo_url" "$target_dir"
    fi
}

safe_symlink() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        warn "源文件不存在: $source — 跳过"
        return
    fi

    # 已正确链接
    if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
        ok "软链接正确: $target → $source"
        return
    fi

    # 备份已有文件
    if [[ -e "$target" || -L "$target" ]]; then
        as_user mkdir -p "$DOTFILES_BACKUP"
        local backup_name
        backup_name="$(basename "$target").$(date +%Y%m%d%H%M%S)"
        info "备份: $target → $DOTFILES_BACKUP/$backup_name"
        as_user mv "$target" "$DOTFILES_BACKUP/$backup_name"
    fi

    # 创建父目录
    as_user mkdir -p "$(dirname "$target")"

    run_cmd "ln -s $source $target" as_user ln -s "$source" "$target"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 克隆仓库
# ═══════════════════════════════════════════════════════════════════════════════

step "克隆 mySetups 仓库"
clone_or_pull "https://github.com/limijd/mySetups.git" "$SETUP_REPO_DIR"

step "克隆 nvim-pro-kit 仓库"
clone_or_pull "https://github.com/limijd/nvim-pro-kit.git" "$NVIM_REPO_DIR"

# ═══════════════════════════════════════════════════════════════════════════════
# 软链接 dotfiles
# ═══════════════════════════════════════════════════════════════════════════════

step "创建 dotfile 软链接"
info "将 mySetups 中的配置文件链接到 home 目录"

safe_symlink "$SETUP_REPO_DIR/zsh/202511.zshrc"   "$TARGET_HOME/.zshrc"
safe_symlink "$SETUP_REPO_DIR/zsh/.zshenv"         "$TARGET_HOME/.zshenv"
safe_symlink "$SETUP_REPO_DIR/vim/dot.vimrc"       "$TARGET_HOME/.vimrc"
safe_symlink "$SETUP_REPO_DIR/tcsh/tcsh.cshrc"     "$TARGET_HOME/.cshrc"
safe_symlink "$SETUP_REPO_DIR/tmux/tmux.conf"      "$TARGET_HOME/.tmux.conf"

step "配置 Neovim"
NVIM_CONFIG_DIR="$TARGET_HOME/.config/nvim"
if [[ -f "$NVIM_REPO_DIR/init.lua" || -f "$NVIM_REPO_DIR/init.vim" ]]; then
    safe_symlink "$NVIM_REPO_DIR" "$NVIM_CONFIG_DIR"
else
    info "nvim-pro-kit 未找到 init.lua/init.vim — 跳过 nvim 配置链接"
    info "请检查仓库结构后手动链接"
fi

step "安装 vim-plug"
VIM_PLUG="$TARGET_HOME/.vim/autoload/plug.vim"
if [[ -f "$VIM_PLUG" ]]; then
    ok "vim-plug 已安装: $VIM_PLUG"
else
    info "下载 vim-plug..."
    as_user mkdir -p "$TARGET_HOME/.vim/autoload"
    run_cmd "下载 vim-plug" \
        as_user curl -fLo "$VIM_PLUG" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

footer
info "后续手动步骤:"
info "  运行 'vim +PlugInstall +qall' 安装 vim 插件"
