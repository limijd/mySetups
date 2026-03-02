# Bootstrap — Debian/Ubuntu 系统初始化工具

一键配置全新 Debian/Ubuntu 系统的开发环境，所有脚本**幂等**（可安全重复运行）。

## 快速开始

```bash
# 方式一：交互式菜单（推荐）
bash bootstrap/setup.sh

# 方式二：运行全部模块
bash bootstrap/setup.sh all

# 方式三：只运行指定模块（按编号）
bash bootstrap/setup.sh 1 3 4

# 方式四：单体脚本（旧版，包含全部功能）
bash bootstrap/debian_ubuntu.sh
```

## 模块一览

| 编号 | 脚本 | 功能 | 需要 sudo |
|------|------|------|-----------|
| 1 | `01_apt_packages.sh` | 系统包安装 (50+ 工具) | Yes |
| 2 | `02_shell_setup.sh` | 设置默认 Shell 为 zsh | Yes |
| 3 | `03_repos_dotfiles.sh` | 克隆仓库 + Dotfiles 软链接 | No |
| 4 | `04_rust.sh` | Rust 工具链 (rustup) | No |
| 5 | `05_python_uv.sh` | Python 包管理器 (uv) | No |
| 6 | `06_nodejs_nvm.sh` | Node.js (nvm + LTS) | No |
| 7 | `07_security.sh` | 安全加固 (ufw + fail2ban) | Yes |
| 8 | `08_system_tuning.sh` | 系统调优 (sysctl, limits, SSH) | Yes |

## 各模块详细说明

### 1. 系统包安装 (`01_apt_packages.sh`)

安装开发所需的全套 APT 包，按类别组织：

| 类别 | 包 |
|------|----|
| Shell | zsh, tcsh |
| 编辑器 | vim, vim-gtk3 |
| 终端复用 | tmux, screen |
| 编译器/构建 | gcc, g++, clang, llvm, cmake, ninja-build, ccache, bear |
| C/C++ 工具 | clang-format, clang-tools, valgrind, gdb, strace |
| 开发库 | libssl-dev, libffi-dev, zlib1g-dev, libreadline-dev |
| 版本控制 | git, git-lfs |
| Python | python3, python3-venv, python3-pip |
| 现代 CLI | ripgrep, fd-find, fzf, bat, eza, zoxide, git-delta, tldr |
| 系统监控 | htop, btop, ncdu, duf, iotop, sysstat, lsof |
| 网络工具 | curl, wget, nmap, tcpdump, iperf3, openssh-server |
| 代码导航 | universal-ctags, cscope |
| Shell/文本 | direnv, shellcheck, jq, tree, xclip, zstd |

已安装的包会自动跳过。

### 2. Shell 设置 (`02_shell_setup.sh`)

将当前用户的默认 Shell 切换为 zsh。如果已经是 zsh 则跳过。

**前置条件：** 需要先运行模块 1 安装 zsh。

### 3. 仓库与 Dotfiles (`03_repos_dotfiles.sh`)

克隆两个 Git 仓库并创建 dotfile 软链接：

**克隆仓库：**
- `limijd/mySetups` → `~/sandbox/github/mySetups`
- `limijd/nvim-pro-kit` → `~/sandbox/github/nvim-pro-kit`

**创建软链接：**
```
~/.zshrc       → mySetups/zsh/202511.zshrc
~/.zshenv      → mySetups/zsh/.zshenv
~/.vimrc       → mySetups/vim/dot.vimrc
~/.cshrc       → mySetups/tcsh/tcsh.cshrc
~/.tmux.conf   → mySetups/tmux/tmux.conf
~/.config/nvim → nvim-pro-kit/
```

冲突的文件会自动备份到 `~/.dotfiles.bak/`。还会安装 vim-plug。

**手动后续步骤：** 运行 `vim +PlugInstall +qall` 安装 vim 插件。

### 4. Rust 工具链 (`04_rust.sh`)

通过官方 rustup 安装 Rust stable 工具链。

- 已安装则执行 `rustup update`
- 安装到 `~/.cargo/`（用户级，无需 sudo）
- 安装后可用：`rustup`, `rustc`, `cargo`

### 5. Python uv (`05_python_uv.sh`)

安装 [uv](https://github.com/astral-sh/uv)——快速的 Python 包管理器。

- 已安装则执行 `uv self update`
- 安装到 `~/.local/bin` 或 `~/.cargo/bin`
- 前置建议：先运行模块 1 安装 python3

### 6. Node.js (`06_nodejs_nvm.sh`)

通过 [nvm](https://github.com/nvm-sh/nvm) 安装 Node.js。

- 自动获取最新 nvm 版本（回退到 v0.40.1）
- 安装 Node.js LTS 并设为默认
- 安装到 `~/.nvm/`

### 7. 安全加固 (`07_security.sh`)

配置基础系统安全：

**UFW 防火墙：**
- 默认拒绝入站、允许出站
- 放行 SSH

**fail2ban 防暴力破解：**
- Ban 时长：1 小时
- 检测窗口：10 分钟
- 最大重试：5 次
- 监控 SSH 登录

### 8. 系统调优 (`08_system_tuning.sh`)

优化系统参数：

**Locale：** 生成 `en_US.UTF-8`

**Sysctl 内核参数** (`/etc/sysctl.d/99-bootstrap.conf`)：
- inotify watchers: 524288（IDE/文件监控需要）
- file-max: 2097152
- somaxconn: 4096
- swappiness: 10（优先用内存）
- vfs_cache_pressure: 50

**用户文件限制** (`/etc/security/limits.d/99-bootstrap.conf`)：
- nofile: 65536 (soft) / 131072 (hard)
- nproc: 65536 (soft) / 131072 (hard)

**SSH 加固** (`/etc/ssh/sshd_config.d/99-bootstrap.conf`)：
- 禁止 root 登录
- 最大认证尝试：5 次
- 登录超时：60 秒

## 架构

```
bootstrap/
├── setup.sh              # 主入口：交互式菜单
├── debian_ubuntu.sh      # 旧版单体脚本（包含全部功能）
├── lib/
│   └── common.sh         # 共享函数库（颜色、run_cmd、bootstrap_init 等）
└── scripts/
    ├── 01_apt_packages.sh
    ├── 02_shell_setup.sh
    ├── 03_repos_dotfiles.sh
    ├── 04_rust.sh
    ├── 05_python_uv.sh
    ├── 06_nodejs_nvm.sh
    ├── 07_security.sh
    └── 08_system_tuning.sh
```

- `setup.sh` 是推荐的入口，提供交互式菜单选择模块
- `debian_ubuntu.sh` 是旧版单体脚本，功能等价但不支持选择
- 每个 `scripts/` 下的模块都是独立的，可单独运行
- `lib/common.sh` 提供共享工具函数（`run_cmd`, `step`, `bootstrap_init` 等）

## 注意事项

- 所有脚本仅支持 **Debian/Ubuntu**（及其衍生发行版）
- 建议以**普通用户 + sudo** 运行，不要直接用 root
- 首次运行建议按顺序 `1 → 8` 全部执行
- 重复运行是安全的——已安装/已配置的项会自动跳过
- 运行完毕后需要**重新登录**或 `exec zsh` 使所有更改生效
