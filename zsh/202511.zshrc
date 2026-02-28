#------------------------------------------------------------------------------
# Ultimate zsh bootstrap (cross-platform, tidy, extensible)
# Every section is intentionally modular so you can comment blocks on/off per host.
#------------------------------------------------------------------------------

export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-$LANG}
#export TZ=${TZ:-UTC}
unset TZ

# Set restrictive umask: no group or other permissions for new files
# New files: 600 (rw-------), New directories: 700 (rwx------)
umask 0077

zmodload zsh/datetime 2>/dev/null
zmodload zsh/stat 2>/dev/null

# Record load time at the first possible moment so we can report initialization cost.
typeset -gF ZCFG_LOAD_STARTED_AT=$EPOCHREALTIME
ZCFG_STARTED_AT=$(strftime "%F %T" "$EPOCHSECONDS")
echo "[Info] zsh ~/.zshrc ${ZCFG_STARTED_AT}"

#------------------------------------------------------------------------------
# Host + platform facts (used for conditionals throughout the file)
#------------------------------------------------------------------------------
typeset -gA ZCFG
ZCFG[os]=$(uname -s)
ZCFG[arch]=$(uname -m)
ZCFG[kernel]=$(uname -r)
ZCFG[host]=$(hostname -s 2>/dev/null)

if [[ -f /etc/os-release ]]; then
  source /etc/os-release
  ZCFG[os_name]=${PRETTY_NAME:-$NAME}
else
  case ${ZCFG[os]} in
    Darwin) ZCFG[os_name]="macOS $(sw_vers -productVersion 2>/dev/null)";;
    *)      ZCFG[os_name]=${ZCFG[os]};;
  esac
fi

if [[ ${ZCFG[kernel]} == *Microsoft* ]]; then
  ZCFG[platform]="wsl"
elif [[ ${ZCFG[os]} == Darwin ]]; then
  if [[ ${ZCFG[arch]} == "arm64" ]]; then
    ZCFG[platform]="macos_arm"
  else
    ZCFG[platform]="macos_x86_64"
  fi
else
  ZCFG[platform]="linux"
fi

echo "[Info] platform: ${ZCFG[platform]}"


#------------------------------------------------------------------------------
# Helpers
# _path_prepend/_path_append let us manipulate $PATH reliably without duplicates.
#------------------------------------------------------------------------------
_path_prepend() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    path=($dir ${path:#$dir})
  done
}

_path_append() {
  local dir
  for dir in "$@"; do
    [[ -d $dir ]] || continue
    path=(${path:#$dir} $dir)
  done
}

_have() { command -v "$1" >/dev/null 2>&1; }

#------------------------------------------------------------------------------
# Editor / pager / history
# Choose editor dynamically, make history massive, and enable interactive niceties.
#------------------------------------------------------------------------------
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR=${EDITOR:-vim}
else
  if _have nvim; then
    export EDITOR=nvim
  elif _have vim; then
    export EDITOR=vim
  else
    export EDITOR=vi
  fi
fi
export VISUAL=$EDITOR
export PAGER=${PAGER:-less}

HISTFILE=${HISTFILE:-${HOME}/.zsh_history}
HISTSIZE=300
SAVEHIST=$HISTSIZE
# 简单可预测的 history：每个窗口独立，退出时保存
setopt APPEND_HISTORY        # 退出时追加到历史文件（不覆盖）
setopt HIST_IGNORE_SPACE     # 空格开头的命令不记录（用于隐藏敏感命令）
setopt EXTENDED_HISTORY      # 保存时间戳

# 明确关闭那些"智能"选项
unsetopt SHARE_HISTORY       # 不要跨窗口实时共享
unsetopt INC_APPEND_HISTORY  # 不要立即写入文件
unsetopt HIST_IGNORE_DUPS    # 不要吞掉重复命令
unsetopt HIST_IGNORE_ALL_DUPS
unsetopt HIST_EXPIRE_DUPS_FIRST
unsetopt HIST_FIND_NO_DUPS

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS CORRECT \
       INTERACTIVE_COMMENTS LONG_LIST_JOBS NO_BEEP

#------------------------------------------------------------------------------
# Key bindings & completion
#------------------------------------------------------------------------------
bindkey -v
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

autoload -Uz colors compinit compaudit promptinit vcs_info add-zsh-hook
colors
ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
mkdir -p "$ZSH_CACHE_DIR"
ZCFG_COMPAUDIT_VERBOSE=${ZCFG_COMPAUDIT_VERBOSE:-0}
{
  # Run compaudit first so broken/insecure completion files cannot abort compinit.
  compaudit_out=$(compaudit 2>&1)
  if [[ $? -eq 0 ]]; then
    compinit -d "${ZSH_CACHE_DIR}/zcompdump"
  else
    if (( ZCFG_COMPAUDIT_VERBOSE )); then
      print -u2 "[Warn] compaudit reported issues; using compinit -i. Details:"
      print -u2 "$compaudit_out"
    fi
    compinit -i -d "${ZSH_CACHE_DIR}/zcompdump"
  fi
}
promptinit

#------------------------------------------------------------------------------
# Prompt: informative, cross-platform, VCS-aware
# Uses built-in vcs_info so no external theme dependency is required.
#------------------------------------------------------------------------------
setopt PROMPT_SUBST
zstyle ':vcs_info:*' enable git        # we only need git but more can be enabled later
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr ' +'
zstyle ':vcs_info:git:*' unstagedstr ' *'
zstyle ':vcs_info:git:*' formats '%F{magenta}git:%b%f%F{yellow}%u%f%F{red}%c%f'
zstyle ':vcs_info:git:*' actionformats '%F{magenta}git:%b|%a%f%F{yellow}%u%f%F{red}%c%f'

typeset -gF ZCFG_CMD_STARTED_AT=0
typeset -gF ZCFG_CPU_TEMP_CACHE_AT=0
typeset -g ZCFG_CPU_TEMP_CACHE=""
typeset -gF ZCFG_TAILSCALE_CACHE_AT=0
typeset -g ZCFG_TAILSCALE_CACHE=""
typeset -gF ZCFG_GEOIP_CACHE_AT=0
typeset -g ZCFG_GEOIP_CACHE=""
typeset -gF ZCFG_OLLAMA_CACHE_AT=0
typeset -g ZCFG_OLLAMA_CACHE=""
typeset -gF ZCFG_GIT_REMOTE_CACHE_AT=0
typeset -g ZCFG_GIT_REMOTE_CACHE=""
typeset -g ZCFG_GIT_REMOTE_REPO=""

# Cache CPU temperature from `sensors` so we do not run it for every prompt render.
zcfg_cpu_temp_segment() {
  _have sensors || return 0

  local now=$EPOCHREALTIME
  if (( now - ZCFG_CPU_TEMP_CACHE_AT < 5 )) && [[ -n $ZCFG_CPU_TEMP_CACHE ]]; then
    print -r -- "$ZCFG_CPU_TEMP_CACHE"
    return 0
  fi

  local reading
  reading=$(
    LC_ALL=C sensors 2>/dev/null | awk '
      tolower($0) ~ /package id 0/ {
        if (match($0, /:[[:space:]]*[+-]?[0-9][0-9]*([.][0-9]+)?/)) {
          val=substr($0, RSTART+1, RLENGTH-1)
          gsub(/[^0-9.+-]/, "", val)
          if (length(val)) { print val; exit }
        }
      }
    '
  )

  [[ -n $reading ]] || return 0

  local -F temp_value=$reading
  local temp_color
  if (( temp_value >= 85 )); then
    temp_color="%F{196}"
  elif (( temp_value >= 70 )); then
    temp_color="%F{214}"
  else
    temp_color="%F{40}"
  fi

  local temp_display
  temp_display=$(printf '%.0f°C' "$temp_value")
  ZCFG_CPU_TEMP_CACHE="${temp_color}CPU ${temp_display}%f"
  ZCFG_CPU_TEMP_CACHE_AT=$now
  print -r -- "$ZCFG_CPU_TEMP_CACHE"
}

# Cache Tailscale status to avoid running the command on every prompt.
# Three states:
#   TS⊗ = Tailscale not installed or unavailable
#   TS⬢⁽ᵐ/ⁿ⁾ = Tailscale is active and online (m/n = online/total clients in superscript)
#   TS⬡ = Tailscale is installed but inactive
# Uses fast systemd check instead of slow 'tailscale status' command
zcfg_tailscale_segment() {
  local now=$EPOCHREALTIME
  if (( now - ZCFG_TAILSCALE_CACHE_AT < 60 )) && [[ -n $ZCFG_TAILSCALE_CACHE ]]; then
    print -r -- "$ZCFG_TAILSCALE_CACHE"
    return 0
  fi

  local ts_symbol ts_color
  
  # Check if tailscale command exists
  if ! command -v tailscale >/dev/null 2>&1; then
    ts_symbol="TS⊗"
    ts_color="%F{240}"  # dark gray for not installed
  else
    # Fast check: use systemctl to check if tailscaled service is active
    # This is much faster than running 'tailscale status'
    if systemctl is-active --quiet tailscaled 2>/dev/null; then
      # Get full status output to count total and online clients
      local status_output
      status_output=$(tailscale status --peers 2>/dev/null)
      
      # Count total peers
      local total_count
      total_count=$(echo "$status_output" | wc -l)
      
      # Count online peers (those without "offline" in their line)
      local online_count
      online_count=$(echo "$status_output" | grep -v -i "offline" | wc -l)
      
      # Convert counts to superscript
      local online_super total_super
      online_super=$(echo "$online_count" | sed 's/0/⁰/g; s/1/¹/g; s/2/²/g; s/3/³/g; s/4/⁴/g; s/5/⁵/g; s/6/⁶/g; s/7/⁷/g; s/8/⁸/g; s/9/⁹/g')
      total_super=$(echo "$total_count" | sed 's/0/⁰/g; s/1/¹/g; s/2/²/g; s/3/³/g; s/4/⁴/g; s/5/⁵/g; s/6/⁶/g; s/7/⁷/g; s/8/⁸/g; s/9/⁹/g')
      
      ts_symbol="TS⬢${online_super}⁄${total_super}"
      ts_color="%F{42}"   # green for active
    else
      ts_symbol="TS⬡"
      ts_color="%F{214}"  # orange for inactive
    fi
  fi

  ZCFG_TAILSCALE_CACHE="${ts_color}${ts_symbol}%f"
  ZCFG_TAILSCALE_CACHE_AT=$now
  print -r -- "$ZCFG_TAILSCALE_CACHE"
}

# Cache Ollama status: show running model(s) in prompt.
# Only visible when ollama service is active; hidden otherwise.
#   🦙model  = model actively loaded (green)
#   🦙       = service running, no model loaded (dim cyan)
zcfg_ollama_segment() {
  _have ollama || return 0

  local now=$EPOCHREALTIME
  if (( now - ZCFG_OLLAMA_CACHE_AT < 10 )) && [[ -n $ZCFG_OLLAMA_CACHE ]]; then
    print -r -- "$ZCFG_OLLAMA_CACHE"
    return 0
  fi

  # Quick check: is ollama service running?
  # systemctl for Linux, pgrep fallback for macOS/other
  local is_running=0
  if _have systemctl; then
    systemctl is-active --quiet ollama 2>/dev/null && is_running=1
  else
    pgrep -x ollama &>/dev/null && is_running=1
  fi

  if (( ! is_running )); then
    ZCFG_OLLAMA_CACHE=""
    ZCFG_OLLAMA_CACHE_AT=$now
    return 0
  fi

  # Get running models (local API call, typically <50ms)
  local ps_output
  ps_output=$(timeout 2 ollama ps 2>/dev/null | tail -n +2)

  local result
  if [[ -n $ps_output ]]; then
    local -a model_names=()
    local line
    for line in ${(f)ps_output}; do
      local name=${line%% *}
      name=${name%:latest}
      model_names+=("$name")
    done

    if (( ${#model_names[@]} > 1 )); then
      result="%F{42}🦙${model_names[1]}+$((${#model_names[@]}-1))%f"
    else
      result="%F{42}🦙${model_names[1]}%f"
    fi
  else
    # Service running but no model loaded
    result="%F{117}🦙%f"
  fi

  ZCFG_OLLAMA_CACHE="$result"
  ZCFG_OLLAMA_CACHE_AT=$now
  print -r -- "$ZCFG_OLLAMA_CACHE"
}

# Cache public IP geolocation with background refresh.
# Uses file cache for persistence, in-memory cache for speed.
# Supports curl with wget fallback, graceful degradation if neither available.
zcfg_geoip_segment() {
  local cache_file="${ZSH_CACHE_DIR}/geoip_location"
  local now=$EPOCHREALTIME
  
  # In-memory cache valid for 60s
  if (( now - ZCFG_GEOIP_CACHE_AT < 60 )) && [[ -n $ZCFG_GEOIP_CACHE ]]; then
    print -r -- "$ZCFG_GEOIP_CACHE"
    return 0
  fi

  # Check file age - refresh in background if older than 30 min
  local refresh_needed=0
  if [[ -r $cache_file ]]; then
    local -A file_stat
    zstat -H file_stat "$cache_file" 2>/dev/null
    local file_age=$(( EPOCHSECONDS - file_stat[mtime] ))
    (( file_age > 1800 )) && refresh_needed=1
  else
    refresh_needed=1
  fi

  # Background refresh (non-blocking) with curl/wget fallback
  if (( refresh_needed )); then
    (
      local json loc
      if _have curl; then
        json=$(curl -s --max-time 5 "https://ipinfo.io/json" 2>/dev/null)
      elif _have wget; then
        json=$(wget -qO- --timeout=5 "https://ipinfo.io/json" 2>/dev/null)
      else
        exit 0
      fi
      
      # Parse JSON without jq - extract city and country
      loc=$(echo "$json" | command grep -oP '"city":\s*"\K[^"]+|"country":\s*"\K[^"]+' 2>/dev/null | paste -sd', ')
      
      # Fallback: if grep -P not available, try sed
      if [[ -z $loc ]]; then
        local city country
        city=$(echo "$json" | sed -n 's/.*"city"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
        country=$(echo "$json" | sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
        [[ -n $city && -n $country ]] && loc="${city}, ${country}"
      fi
      
      [[ -n $loc ]] && print -r -- "$loc" > "$cache_file"
    ) &>/dev/null &!
  fi

  # Read from file cache
  if [[ -r $cache_file ]]; then
    local location
    location=$(<"$cache_file")
    if [[ -n $location ]]; then
      ZCFG_GEOIP_CACHE="%F{117}📍${location}%f"
      ZCFG_GEOIP_CACHE_AT=$now
      print -r -- "$ZCFG_GEOIP_CACHE"
    fi
  fi
}

# Git remote status: show ahead/behind upstream and behind main
# Uses caching with background refresh, handles offline gracefully
# Displays: [↑2↓3] for upstream, [m↓15] for behind main, [⛔] for offline
zcfg_git_remote_segment() {
  # Skip if not in a git repo (reuse vcs_info detection, zero overhead)
  [[ -z ${vcs_info_msg_0_} ]] && return 0

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0

  # Check exclusion: file in repo or global skip list
  [[ -f "${repo_root}/.zsh_no_remote_check" ]] && return 0
  if (( ${#ZCFG_GIT_REMOTE_SKIP_REPOS[@]} )); then
    local skip_repo
    for skip_repo in "${ZCFG_GIT_REMOTE_SKIP_REPOS[@]}"; do
      [[ "${repo_root}" == "${~skip_repo}" ]] && return 0
    done
  fi

  local now=$EPOCHREALTIME
  local repo_hash=$(print -r -- "$repo_root" | md5sum | cut -c1-8)
  local cache_file="${ZSH_CACHE_DIR}/git_remote_${repo_hash}"

  # Memory cache valid for 10s (same repo only)
  if [[ "$ZCFG_GIT_REMOTE_REPO" == "$repo_root" ]] && \
     (( now - ZCFG_GIT_REMOTE_CACHE_AT < 10 )) && [[ -n $ZCFG_GIT_REMOTE_CACHE ]]; then
    print -r -- "$ZCFG_GIT_REMOTE_CACHE"
    return 0
  fi

  # Read from file cache
  local cached_data=""
  local file_mtime=0
  if [[ -r $cache_file ]]; then
    cached_data=$(<"$cache_file")
    local -A file_stat
    zstat -H file_stat "$cache_file" 2>/dev/null
    file_mtime=${file_stat[mtime]:-0}
  fi

  # Parse cached data: ahead|behind|behind_main|offline
  local ahead=0 behind=0 behind_main=0 offline=0
  if [[ -n $cached_data ]]; then
    ahead=${cached_data%%|*}
    local rest=${cached_data#*|}
    behind=${rest%%|*}
    rest=${rest#*|}
    behind_main=${rest%%|*}
    offline=${rest#*|}
  fi

  # Build display string
  local result=""
  local upstream_part="" main_part=""

  # Offline indicator
  if (( offline )); then
    result="%F{240}[⊘]%f"
  fi

  # Upstream ahead/behind: [↑2↓3]
  if (( ahead > 0 || behind > 0 )); then
    upstream_part="["
    if (( ahead > 0 )); then
      if (( ahead >= 1000 )); then
        upstream_part+="%F{42}↑999+%f"
      else
        upstream_part+="%F{42}↑${ahead}%f"
      fi
    fi
    if (( behind > 0 )); then
      if (( behind >= 1000 )); then
        upstream_part+="%F{214}↓999+%f"
      else
        upstream_part+="%F{214}↓${behind}%f"
      fi
    fi
    upstream_part+="]"
  fi

  # Behind main: [m↓15]
  # Skip if on main/master branch
  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ "$current_branch" != "main" && "$current_branch" != "master" ]] && (( behind_main > 0 )); then
    if (( behind_main >= 1000 )); then
      main_part="%F{magenta}[m↓999+]%f"
    else
      main_part="%F{magenta}[m↓${behind_main}]%f"
    fi
  fi

  # Combine parts
  if (( offline )); then
    # Show offline + any cached upstream/main data
    if [[ -n $upstream_part || -n $main_part ]]; then
      result="%F{240}⊘%f${upstream_part}${main_part}"
    else
      result="%F{240}[⊘]%f"
    fi
  else
    result="${upstream_part}${main_part}"
  fi

  # Update memory cache
  ZCFG_GIT_REMOTE_CACHE="$result"
  ZCFG_GIT_REMOTE_CACHE_AT=$now
  ZCFG_GIT_REMOTE_REPO="$repo_root"

  # Background refresh if file cache older than 5 minutes
  local file_age=$(( EPOCHSECONDS - file_mtime ))
  if (( file_age > 300 )) || [[ ! -r $cache_file ]]; then
    (
      local branch
      branch=$(git symbolic-ref --short HEAD 2>/dev/null) || exit 0

      # Skip entirely if no remote named "origin" exists
      if ! git remote get-url origin &>/dev/null; then
        print -r -- "0|0|0|0" > "$cache_file"
        exit 0
      fi

      # Check connectivity with timeout (10s)
      # Use BatchMode to avoid SSH passkey/password prompts blocking the bg job
      local is_offline=0
      if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes" \
           timeout 10 git ls-remote origin HEAD &>/dev/null; then
        is_offline=1
      fi

      local new_ahead=0 new_behind=0 new_behind_main=0

      if (( ! is_offline )); then
        # Fetch current branch only (10s timeout)
        timeout 10 git fetch origin "${branch}" --no-tags &>/dev/null

        # Calculate ahead/behind upstream
        local upstream
        upstream=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
        if [[ -n $upstream ]]; then
          local counts
          counts=$(git rev-list --count --left-right --max-count=1000 "HEAD...${upstream}" 2>/dev/null)
          if [[ -n $counts ]]; then
            new_ahead=${counts%%$'\t'*}
            new_behind=${counts#*$'\t'}
          fi
        fi

        # Calculate behind main/master
        local main_ref=""
        if git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
          main_ref="origin/main"
        elif git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
          main_ref="origin/master"
        fi

        if [[ -n $main_ref ]]; then
          new_behind_main=$(git rev-list --count --max-count=1000 "HEAD..${main_ref}" 2>/dev/null)
          [[ -z $new_behind_main ]] && new_behind_main=0
        fi
      else
        # Offline: try to use local refs
        local upstream
        upstream=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
        if [[ -n $upstream ]]; then
          local counts
          counts=$(git rev-list --count --left-right --max-count=1000 "HEAD...${upstream}" 2>/dev/null)
          if [[ -n $counts ]]; then
            new_ahead=${counts%%$'\t'*}
            new_behind=${counts#*$'\t'}
          fi
        fi

        local main_ref=""
        if git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
          main_ref="origin/main"
        elif git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
          main_ref="origin/master"
        fi

        if [[ -n $main_ref ]]; then
          new_behind_main=$(git rev-list --count --max-count=1000 "HEAD..${main_ref}" 2>/dev/null)
          [[ -z $new_behind_main ]] && new_behind_main=0
        fi
      fi

      # Write cache
      print -r -- "${new_ahead}|${new_behind}|${new_behind_main}|${is_offline}" > "$cache_file"
    ) &>/dev/null &!
  fi

  [[ -n $result ]] && print -r -- "$result"
}

zcfg_prompt_preexec() {
  ZCFG_CMD_STARTED_AT=$EPOCHREALTIME
}

zcfg_prompt_precmd() {
  local exit_status=$?
  vcs_info

  # Left prompt shows command status, user@host, cwd, and git snapshot.
  local status_segment
  if (( exit_status == 0 )); then
    status_segment="%B%F{78}[ok]%f%b"
  else
    status_segment="%B%F{196}[${exit_status}]%f%b"
  fi

  local user_color
  if (( EUID == 0 )); then
    user_color="%F{196}"
  elif [[ -n $SSH_CONNECTION ]]; then
    user_color="%F{214}"
  else
    user_color="%F{81}"
  fi

  local host_ref=${ZCFG[host]:-$(hostname -s 2>/dev/null)}
  local user_host="%B${user_color}%n@${host_ref}%f%b"
  local cwd="%B%F{221}%d%f%b"
  local git_segment=""
  [[ -n ${vcs_info_msg_0_} ]] && git_segment=" ${vcs_info_msg_0_}"
  local git_remote_segment=$(zcfg_git_remote_segment)
  [[ -n $git_remote_segment ]] && git_segment+=" ${git_remote_segment}"

  # Display right prompt time + duration for commands slower than 100ms.
  local duration_segment=""
  if (( ZCFG_CMD_STARTED_AT > 0 )); then
    local elapsed=$(( EPOCHREALTIME - ZCFG_CMD_STARTED_AT ))
    if (( elapsed >= 1 )); then
      duration_segment=$(printf '%.2fs' "$elapsed")
    elif (( elapsed*1000 >= 100 )); then
      local elapsed_ms=$(( (EPOCHREALTIME - ZCFG_CMD_STARTED_AT) * 1000 ))
      duration_segment=$(printf '%.0fms' "$elapsed_ms")
    fi
  fi

  local time_segment="%F{244}%*%f"
  local cpu_temp_segment=$(zcfg_cpu_temp_segment)
  local tailscale_segment=$(zcfg_tailscale_segment)
  local ollama_segment=$(zcfg_ollama_segment)
  local geoip_segment=$(zcfg_geoip_segment)
  local -a rprompt_parts=()
  [[ -n $geoip_segment ]] && rprompt_parts+="$geoip_segment"
  [[ -n $tailscale_segment ]] && rprompt_parts+="$tailscale_segment"
  [[ -n $ollama_segment ]] && rprompt_parts+="$ollama_segment"
  [[ -n $cpu_temp_segment ]] && rprompt_parts+="$cpu_temp_segment"
  [[ -n $duration_segment ]] && rprompt_parts+=("%F{244}${duration_segment}%f")
  rprompt_parts+="$time_segment"
  local status_line="${(j: :)rprompt_parts}"
  RPROMPT=""

  # Right-align status on line 2: calculate visible width, pad with spaces
  local zero='%([BSUbfksu]|([FK]|){*})'
  local vis_text=${(S%%)status_line//$~zero/}
  local vis_len=${#vis_text}
  # Emoji are 2 cells wide but ${#} counts as 1
  [[ $vis_text == *📍* ]] && (( vis_len++ ))
  [[ $vis_text == *🦙* ]] && (( vis_len++ ))
  local pad=$(( ${COLUMNS:-80} - vis_len ))
  (( pad < 0 )) && pad=0

  local symbol='%(!.#.$)'  # show # for root shells
  PROMPT="${status_segment} ${user_host} ${cwd}${git_segment}"$'\n'"${(l:$pad:: :)}${status_line}"$'\n'"%F{111}${symbol}%f "
  ZCFG_CMD_STARTED_AT=0
}

add-zsh-hook precmd zcfg_prompt_precmd
add-zsh-hook preexec zcfg_prompt_preexec

# Send bell on each prompt to notify tmux when command completes
# Skip bell for claude to avoid notification when switching tabs quickly
typeset -g _ZCFG_LAST_CMD=""
_notify_bell_preexec() { _ZCFG_LAST_CMD="$1" }
_notify_bell() {
  [[ "$_ZCFG_LAST_CMD" == claude* ]] || printf '\a'
  _ZCFG_LAST_CMD=""
}
add-zsh-hook preexec _notify_bell_preexec
add-zsh-hook precmd _notify_bell

# Tmux @running indicator: show ⚡ in window tab when command is running
_tmux_running_preexec() {
  [[ -n "$TMUX" && -n "$TMUX_PANE" ]] && tmux set-option -q -t "$TMUX_PANE" -w @running 1
}
_tmux_running_precmd() {
  [[ -n "$TMUX" && -n "$TMUX_PANE" ]] && tmux set-option -q -t "$TMUX_PANE" -uw @running
}
add-zsh-hook preexec _tmux_running_preexec
add-zsh-hook precmd _tmux_running_precmd

#------------------------------------------------------------------------------
# PATH (base + platform tweaks)
# Start with user-local bin dirs, then branch per platform/distro.
#------------------------------------------------------------------------------
_path_prepend "${HOME}/bin" "${HOME}/.local/bin"

case ${ZCFG[platform]} in
  macos_arm)
    _path_prepend /opt/homebrew/bin /opt/homebrew/sbin
    _path_prepend /opt/homebrew/opt/llvm@20/bin
    export BROWSER=${BROWSER:-open}
    ;;
  macos_x86_64)
    _path_prepend /usr/local/bin /usr/local/sbin
    export BROWSER=${BROWSER:-open}
    ;;
  wsl)
    _path_append /mnt/c/Windows/System32
    export BROWSER=${BROWSER:-"/mnt/c/Windows/explorer.exe"}
    ;;
  linux)
    _path_prepend ${HOME}/sandbox/github/nvim-pro-kit/tools/linux_x86_64/nvim/latest
    _path_prepend ${HOME}/install/x86_64@ubt24/Python-3.13.0/bin
    _path_prepend ${HOME}/sandbox/github/ai-doctool

    _path_append /snap/bin
    _path_append ${HOME}/install/scripts 
    _path_append ${HOME}/install/flameshot
    _path_append ${HOME}/sandbox/github/fileSync25
    _path_append ${HOME}/install/anki/anki-latest
    _path_append ${HOME}/install/x86_64@ubt24/anki/anki-latest
    _path_append ${HOME}/install/x86_64@ubt24/nvim-0.11/bin
    _path_append ${HOME}/sandbox/github/myScripts
    _path_append ${HOME}/.claude/skills/w-skill-scripts/scripts
    _path_append ${HOME}/.nvm/versions/node/v20.19.6/bin/
    ;;
esac

#------------------------------------------------------------------------------
# Aliases (quality-of-life wrappers; safe to extend per host)
#------------------------------------------------------------------------------
alias reload='source ~/.zshrc'
alias reload-full='rm -f "${ZSH_CACHE_DIR}/geoip_location" && ZCFG_GEOIP_CACHE_AT=0 ZCFG_TAILSCALE_CACHE_AT=0 && source ~/.zshrc'
alias zconf='${EDITOR:-nvim} ~/.zshrc'
alias cls='(clear && printf "%s\n" "$PWD" && ls)'
alias ls='ls --color'
alias ll='ls -lh'
alias la='ls -Ahl'
alias sl='ls -lrs'
alias tl='ls -ltr'
alias his='history 1'
alias vi='${EDITOR:-nvim}'
alias tn='tmux rename-window "$(basename "$PWD")"'
alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias aria2c="aria2c --file-allocation=none --check-integrity=true -j 8 -s 8 -x 10"

#------------------------------------------------------------------------------
# Functions (diagnostics + directory helpers)
#------------------------------------------------------------------------------
proxy_on() {
  local host=${1:-127.0.0.1}
  local port=${2:-10808}
  local http_url="http://${host}:${port}"
  local socks_url="socks5://${host}:${port}"

  export http_proxy="$http_url"
  export https_proxy="$http_url"
  export all_proxy="$socks_url"
  export HTTP_PROXY="$http_url"
  export HTTPS_PROXY="$http_url"
  export ALL_PROXY="$socks_url"

  printf 'proxy: ON (http=%s, socks=%s)\n' "$http_url" "$socks_url"
}

proxy_off() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
  echo "proxy: OFF"
}

proxy_status() {
  local http="${http_proxy:-${HTTP_PROXY:-}}"
  local socks="${all_proxy:-${ALL_PROXY:-}}"
  if [[ -z $http && -z $socks ]]; then
    echo "proxy: OFF"
    return 0
  fi
  printf 'proxy: ON (http=%s, socks=%s)\n' "${http:-<unset>}" "${socks:-<unset>}"
}

alias proxyon='proxy_on'
alias proxyoff='proxy_off'
alias proxystatus='proxy_status'

showpath() {
  for p in ${(s/:/)PATH}; do
    if [[ -e $p ]]; then
      printf '  %s\n' "$p"
    else
      printf '[X] %s\n' "$p"
    fi
  done
}

checkpath() {
  for d in ${(s/:/)PATH}; do
    [[ -e $d ]] || printf '[Invalid] %s\n' "$d"
  done
}

mkcd() {
  [[ -n $1 ]] || { echo "usage: mkcd <dir>"; return 1; }
  mkdir -p "$1" && cd "$1"
}

up() {
  local count=${1:-1}
  while (( count-- > 0 )); do cd .. || return; done
}

# Force refresh git remote status cache for current repo
git-refresh() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repository"
    return 1
  }
  local repo_hash=$(print -r -- "$repo_root" | md5sum | cut -c1-8)
  local cache_file="${ZSH_CACHE_DIR}/git_remote_${repo_hash}"
  rm -f "$cache_file"
  ZCFG_GIT_REMOTE_CACHE_AT=0
  ZCFG_GIT_REMOTE_CACHE=""
  echo "Git remote cache cleared for: $repo_root"
}

# Skip git remote status checks for current repo
git-remote-skip() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repository"
    return 1
  }
  touch "${repo_root}/.zsh_no_remote_check"
  echo "Git remote checks disabled for: $repo_root"
  echo "Created: ${repo_root}/.zsh_no_remote_check"
}

# Re-enable git remote status checks for current repo
git-remote-unskip() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repository"
    return 1
  }
  if [[ -f "${repo_root}/.zsh_no_remote_check" ]]; then
    rm -f "${repo_root}/.zsh_no_remote_check"
    echo "Git remote checks re-enabled for: $repo_root"
  else
    echo "Git remote checks were not disabled for: $repo_root"
  fi
}

#------------------------------------------------------------------------------
# Tooling bootstrap (lightweight hooks for external helpers)
#------------------------------------------------------------------------------
if _have direnv; then
  eval "$(direnv hook zsh)"
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if _have pyenv; then
  eval "$(pyenv init - zsh)"
  eval "$(pyenv virtualenv-init -)"
fi

#------------------------------------------------------------------------------
# Platform specific niceties (commands or env that only make sense per OS)
#------------------------------------------------------------------------------
case ${ZCFG[platform]} in
  macos_arm)
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    export ARCHFLAGS="-arch arm64"
    export PATH
    ;;
  macos_x86_64)
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    export ARCHFLAGS="-arch x86_64"
    export PATH
    ;;
  wsl)
    export WSLENV="PATH/l:${WSLENV}"
    ;;
  linux)
    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export XMODIFIERS=@im=fcitx
    ;;
esac

#------------------------------------------------------------------------------
# Custom local overrides (per-machine secrets or exports)
#------------------------------------------------------------------------------
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

export PATH="$HOME/.npm-global/bin:$PATH"

# Lazy-load nvm: defers ~10s startup cost until first use of node/npm/npx/nvm
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_lazy_load() {
    unset -f nvm node npm npx 2>/dev/null
    printf -- "[Info] loading nvm (first use)...\n"
    \. "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
  }
  nvm()  { _nvm_lazy_load; nvm  "$@" }
  node() { _nvm_lazy_load; node "$@" }
  npm()  { _nvm_lazy_load; npm  "$@" }
  npx()  { _nvm_lazy_load; npx  "$@" }
fi

if [[ -r "$HOME/.cargo/env" ]]; then
  printf -- "[Info] setting rust/cargo\n"
  . "$HOME/.cargo/env"
fi            

# opencode
export PATH=$HOME/.opencode/bin:$PATH

alias codex="$HOME/.codex/bin/codex-tmux.sh"

if (( ${+ZCFG_LOAD_STARTED_AT} )); then
  typeset -F ZCFG_LOAD_ELAPSED
  ZCFG_LOAD_ELAPSED=$(( EPOCHREALTIME - ZCFG_LOAD_STARTED_AT ))
  # Quick startup telemetry so slow changes are easy to notice.
  printf -- "[Info] .zshrc loaded in %.2fs\n" "$ZCFG_LOAD_ELAPSED"
fi

