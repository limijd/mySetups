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
  ZCFG[platform]="macos"
else
  ZCFG[platform]="linux"
fi

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
HISTSIZE=200000
SAVEHIST=$HISTSIZE
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE \
       EXTENDED_HISTORY INC_APPEND_HISTORY

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

zcfg_prompt_preexec() {
  ZCFG_CMD_STARTED_AT=$EPOCHREALTIME
}

zcfg_prompt_precmd() {
  local exit_status=$?
  vcs_info

  # Left prompt shows command status, user@host, cwd, and git snapshot.
  local status_segment
  if (( exit_status == 0 )); then
    status_segment="%F{42}[ok]%f"
  else
    status_segment="%F{196}[${exit_status}]%f"
  fi

  local user_color
  if (( EUID == 0 )); then
    user_color="%F{196}"
  elif [[ -n $SSH_CONNECTION ]]; then
    user_color="%F{214}"
  else
    user_color="%F{45}"
  fi

  local host_ref=${ZCFG[host]:-$(hostname -s 2>/dev/null)}
  local user_host="${user_color}%n@${host_ref}%f"
  local cwd="%F{220}%d%f"
  local git_segment=""
  [[ -n ${vcs_info_msg_0_} ]] && git_segment=" ${vcs_info_msg_0_}"

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
  local -a rprompt_parts=()
  [[ -n $tailscale_segment ]] && rprompt_parts+="$tailscale_segment"
  [[ -n $cpu_temp_segment ]] && rprompt_parts+="$cpu_temp_segment"
  [[ -n $duration_segment ]] && rprompt_parts+=("%F{244}${duration_segment}%f")
  rprompt_parts+="$time_segment"
  RPROMPT="${(j: :)rprompt_parts}"

  local symbol='%(!.#.$)'  # show # for root shells
  PROMPT="${status_segment} ${user_host} ${cwd}${git_segment}"$'\n'"%F{111}${symbol}%f "
  ZCFG_CMD_STARTED_AT=0
}

add-zsh-hook precmd zcfg_prompt_precmd
add-zsh-hook preexec zcfg_prompt_preexec

#------------------------------------------------------------------------------
# PATH (base + platform tweaks)
# Start with user-local bin dirs, then branch per platform/distro.
#------------------------------------------------------------------------------
_path_prepend "${HOME}/bin" "${HOME}/.local/bin"

case ${ZCFG[platform]} in
  macos)
    _path_prepend /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin
    _path_prepend /opt/homebrew/opt/llvm@20/bin
    export BROWSER=${BROWSER:-open}
    ;;
  wsl)
    _path_append /mnt/c/Windows/System32
    export BROWSER=${BROWSER:-"/mnt/c/Windows/explorer.exe"}
    ;;
  linux)
    [[ -d /snap/bin ]] && _path_append /snap/bin
    ;;
esac

# Example distro-specific tuning
if [[ -f /etc/os-release ]]; then
  case ${ID:-} in
    ubuntu)
      _path_prepend "${HOME}/install/x86_64@ubt24/nvim-0.11/bin" \
                    "${HOME}/sandbox/github/myScripts" \
                    "${HOME}/install/x86_64@ubt24/anki-launcher-25.07.5-linux"
      ;;
  esac
fi

#------------------------------------------------------------------------------
# Aliases (quality-of-life wrappers; safe to extend per host)
#------------------------------------------------------------------------------
alias reload='source ~/.zshrc'
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

#------------------------------------------------------------------------------
# Functions (diagnostics + directory helpers)
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# Tooling bootstrap (lightweight hooks for external helpers)
#------------------------------------------------------------------------------
if _have direnv; then
  eval "$(direnv hook zsh)"
fi

#------------------------------------------------------------------------------
# Platform specific niceties (commands or env that only make sense per OS)
#------------------------------------------------------------------------------
case ${ZCFG[platform]} in
  macos)
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    export PATH
    ;;
  wsl)
    export WSLENV="PATH/l:${WSLENV}"
    ;;
  linux)
    ;;
esac

#------------------------------------------------------------------------------
# Custom local overrides (per-machine secrets or exports)
#------------------------------------------------------------------------------
[[ -r ~/.zshrc.local ]] && source ~/.zshrc.local

if (( ${+ZCFG_LOAD_STARTED_AT} )); then
  typeset -F ZCFG_LOAD_ELAPSED
  ZCFG_LOAD_ELAPSED=$(( EPOCHREALTIME - ZCFG_LOAD_STARTED_AT ))
  # Quick startup telemetry so slow changes are easy to notice.
  printf -- "[Info] .zshrc loaded in %.2fs\n" "$ZCFG_LOAD_ELAPSED"
fi
