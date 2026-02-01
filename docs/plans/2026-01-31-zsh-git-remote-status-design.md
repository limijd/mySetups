# Zsh Prompt Git Remote Status 设计

## 概述

在 zsh prompt 中显示本地 git repo 与 remote 的同步状态，包括：
1. 当前 branch 与 upstream 的 ahead/behind
2. 当前 branch 与 main/master 的差距

## 功能需求

### 显示内容
- **upstream 状态**：本地 branch 与其 tracking branch 的 ahead/behind
- **main 状态**：本地 branch 落后 origin/main (或 origin/master) 多少

### 显示格式
```
git:feature-x +* [↑2↓3] [m↓15]
│             │   │       └── 落后 main 15 commits（品红色）
│             │   └────────── upstream: ahead 2, behind 3
│             └────────────── 现有的 staged/unstaged 标记
└──────────────────────────── 现有的 branch 名
```

### 配色方案
| 元素 | 颜色 | 色号 |
|------|------|------|
| ↑ ahead | 绿色 | `%F{42}` |
| ↓ behind upstream | 橙色 | `%F{214}` |
| m↓ behind main | 品红 | `%F{magenta}` |
| 离线标记 ⚡ | 深灰 | `%F{240}` |

### 状态示例
```
[↑2]           # 只领先，可以 push（绿色）
[↓3]           # 只落后，需要 pull（橙色）
[↑2↓3]         # 又领先又落后，需要 rebase（绿+橙）
[m↓15]         # 落后 main 15（品红）
[m↓999+]       # 落后 main 很多（品红）
[⚡↓3]         # 离线，显示缓存数据（灰+橙）
[⚡]           # 离线且无缓存数据（灰）
```

### 省略规则
- ahead=0 时不显示 ↑
- behind=0 时不显示 ↓
- 与 upstream 完全同步时不显示 `[↑↓]` 区块
- 在 main/master 分支上时不显示 `[m↓]`

## 技术设计

### 缓存机制

**全局变量：**
```zsh
typeset -gF ZCFG_GIT_REMOTE_CACHE_AT=0      # 内存缓存时间戳
typeset -g  ZCFG_GIT_REMOTE_CACHE=""         # 内存缓存内容
typeset -gi ZCFG_GIT_REMOTE_OFFLINE=0        # 离线标记
```

**文件缓存：**
- 位置：`${ZSH_CACHE_DIR}/git_remote_status_<repo_hash>`
- 格式：`ahead|behind|behind_main|timestamp|offline_flag`
- 示例：`2|3|15|1706789012|0`

**刷新策略：**
- 内存缓存有效期：10 秒
- 后台 fetch 间隔：5 分钟
- 网络超时：3 秒（ls-remote）/ 10 秒（fetch）

### 大仓优化

**历史很长（几万到几十万 commits）：**
```zsh
# rev-list 加上限，超过 999 就停止计数
git rev-list --count --max-count=1000 HEAD..@{upstream}
# 返回 1000 时显示 "999+"
```

**分支/tag 很多：**
```zsh
# 只 fetch 当前分支，不全量 fetch
git fetch origin <current-branch> --no-tags
# 或用 ls-remote 只查特定 ref
git ls-remote origin refs/heads/<branch> refs/heads/main
```

**Monorepo：**
- 只操作 refs，不读取文件内容
- 所有 git 命令复杂度 O(refs) 而非 O(files)

### 核心函数 `zcfg_git_remote_segment()`

**主流程：**
1. 检查是否在 git repo 内 → 不在则返回
2. 检查是否在排除列表 → 是则返回
3. 获取 repo root 的 hash 作为缓存 key
4. 检查内存缓存（10秒有效）→ 有效则返回缓存
5. 读取文件缓存并更新内存缓存
6. 检查是否需要后台刷新（>5分钟）→ 启动后台任务
7. 返回当前缓存内容

**后台刷新任务（subshell &!）：**
1. `git ls-remote origin --exit-code`（3秒超时）→ 失败则标记离线
2. `git fetch origin <current-branch> --no-tags`（10秒超时）
3. 计算 ahead/behind upstream：`git rev-list --count --left-right --max-count=1000 HEAD...@{upstream}`
4. 计算 behind main：`git rev-list --count --max-count=1000 HEAD..origin/main`
5. 写入文件缓存

### 离线处理

**判定条件：**
- `git ls-remote --exit-code` 超时（3秒）或失败

**显示策略：**
- 显示 `[⚡]` 图标明确告知离线状态
- 仍显示本地 refs 数据（如有缓存）

### 排除机制

**方式1：repo 内放文件**
```zsh
[[ -f "$(git rev-parse --show-toplevel)/.zsh_no_remote_check" ]]
```

**方式2：全局数组（.zshrc.local）**
```zsh
ZCFG_GIT_REMOTE_SKIP_REPOS=(
  ~/huge-monorepo
  ~/linux-kernel
)
```

### 集成

**修改 `zcfg_prompt_precmd()`：**
```zsh
local git_segment=""
[[ -n ${vcs_info_msg_0_} ]] && git_segment=" ${vcs_info_msg_0_}"

# 新增
local git_remote_segment=$(zcfg_git_remote_segment)
[[ -n $git_remote_segment ]] && git_segment+=" ${git_remote_segment}"
```

### 辅助功能

```zsh
# 手动刷新 git remote 缓存
git-refresh() {
  ZCFG_GIT_REMOTE_CACHE_AT=0
  # 删除当前 repo 的缓存文件，触发立即刷新
}

# 将当前 repo 加入排除列表
git-remote-skip() {
  touch "$(git rev-parse --show-toplevel)/.zsh_no_remote_check"
}
```

## 错误处理

- 所有 git 命令 stderr 重定向到 /dev/null
- 使用 `timeout` 命令控制超时
- 任何错误 graceful 降级，不影响 prompt 正常显示
