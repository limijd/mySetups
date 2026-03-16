# ~/.bashrc
#
# Portable, low-dependency interactive Bash setup.
# Safe defaults first; machine-specific additions belong in ~/.bashrc.local.

# Only run for interactive shells.
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

_bashrc_have() {
  command -v "$1" >/dev/null 2>&1
}

_bashrc_prepend_path() {
  local dir
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    case ":$PATH:" in
      *":$dir:"*) ;;
      *) PATH="$dir${PATH:+:$PATH}" ;;
    esac
  done
}

_bashrc_append_path() {
  local dir
  for dir in "$@"; do
    [ -d "$dir" ] || continue
    case ":$PATH:" in
      *":$dir:"*) ;;
      *) PATH="${PATH:+$PATH:}$dir" ;;
    esac
  done
}

_bashrc_enable_shopt() {
  shopt -s "$1" 2>/dev/null
}

_bashrc_source_if_readable() {
  [ -f "$1" ] && [ -r "$1" ] && . "$1"
}

# Source the first matching file from a list.
_bashrc_source_first_readable() {
  local file
  for file in "$@"; do
    if [ -f "$file" ] && [ -r "$file" ]; then
      . "$file"
      return 0
    fi
  done
  return 1
}

# Favor private files by default. Override in ~/.bashrc.local if needed.
umask "${BASHRC_UMASK:-077}"

# Editor / pager.
if [ -z "${EDITOR:-}" ]; then
  if [ -n "${SSH_CONNECTION:-}" ]; then
    if _bashrc_have vim; then
      EDITOR=vim
    else
      EDITOR=vi
    fi
  elif _bashrc_have nvim; then
    EDITOR=nvim
  elif _bashrc_have vim; then
    EDITOR=vim
  else
    EDITOR=vi
  fi
fi
export EDITOR
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"

# Predictable history: append on exit, keep duplicates, ignore leading-space commands.
HISTFILE="${HISTFILE:-$HOME/.bash_history}"
HISTSIZE="${HISTSIZE:-300}"
HISTFILESIZE="${HISTFILESIZE:-$HISTSIZE}"
HISTCONTROL=ignorespace
export HISTFILE HISTSIZE HISTFILESIZE HISTCONTROL

shopt -s histappend cmdhist
_bashrc_enable_shopt checkwinsize
_bashrc_enable_shopt cdspell
_bashrc_enable_shopt autocd

set -o vi
bind 'set bell-style none'
bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind '"\C-r": reverse-search-history'
bind '"\C-s": forward-search-history'
stty -ixon 2>/dev/null

# PATH: user bins first, then common platform extras if present.
_bashrc_prepend_path "$HOME/bin" "$HOME/.local/bin"
_bashrc_prepend_path /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /usr/local/sbin
_bashrc_append_path /snap/bin "$HOME/.cargo/bin" "$HOME/.npm-global/bin"
export PATH

if [ -z "${BROWSER:-}" ]; then
  case "$(uname -s 2>/dev/null)" in
    Darwin) BROWSER=open ;;
    Linux)
      case "$(uname -r 2>/dev/null)" in
        *Microsoft*) BROWSER=/mnt/c/Windows/explorer.exe ;;
      esac
      ;;
  esac
fi
[ -n "${BROWSER:-}" ] && export BROWSER

showpath() {
  local old_ifs path_item
  old_ifs=$IFS
  IFS=:
  for path_item in $PATH; do
    if [ -e "$path_item" ]; then
      printf '  %s\n' "$path_item"
    else
      printf '[X] %s\n' "$path_item"
    fi
  done
  IFS=$old_ifs
}

checkpath() {
  local old_ifs path_item
  old_ifs=$IFS
  IFS=:
  for path_item in $PATH; do
    [ -e "$path_item" ] || printf '[Invalid] %s\n' "$path_item"
  done
  IFS=$old_ifs
}

mkcd() {
  [ -n "${1:-}" ] || {
    printf 'usage: mkcd <dir>\n' >&2
    return 1
  }
  mkdir -p "$1" && cd "$1"
}

up() {
  local count
  count=${1:-1}
  while [ "$count" -gt 0 ]; do
    cd .. || return 1
    count=$((count - 1))
  done
}

proxy_on() {
  local host port http_url socks_url
  host=${1:-127.0.0.1}
  port=${2:-10808}
  http_url="http://${host}:${port}"
  socks_url="socks5://${host}:${port}"

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
  printf 'proxy: OFF\n'
}

proxy_status() {
  local http socks
  http=${http_proxy:-${HTTP_PROXY:-}}
  socks=${all_proxy:-${ALL_PROXY:-}}

  if [ -z "$http" ] && [ -z "$socks" ]; then
    printf 'proxy: OFF\n'
    return 0
  fi

  printf 'proxy: ON (http=%s, socks=%s)\n' "${http:-<unset>}" "${socks:-<unset>}"
}

viwhich() {
  local target
  [ -n "${1:-}" ] || {
    printf 'usage: viwhich <command>\n' >&2
    return 1
  }
  target=$(command -v "$1") || return 1
  "$EDITOR" "$target"
}

gitpullsubs() {
  git submodule update --init --recursive "$@"
}

_bashrc_fetch_url() {
  if _bashrc_have curl; then
    curl -fsSL --connect-timeout 3 --max-time 5 "$1"
  elif _bashrc_have wget; then
    wget -qO- --timeout=5 "$1"
  else
    return 127
  fi
}

_bashrc_parse_public_ip() {
  sed -n '
    s/.*"ip"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p
    s/.*"query"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p
  ' | head -n 1
}

_bashrc_parse_country_code() {
  sed -n '
    s/.*"country"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p
    s/.*"country_code"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p
    s/.*"countryCode"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p
  ' | head -n 1
}

_bashrc_public_ip_country() {
  local response country ip

  response=$(_bashrc_fetch_url "https://ipinfo.io/json" 2>/dev/null) || response=
  if [ -n "$response" ]; then
    country=$(printf '%s\n' "$response" | _bashrc_parse_country_code)
    ip=$(printf '%s\n' "$response" | _bashrc_parse_public_ip)
    if [ -n "$country" ]; then
      printf '%s|%s\n' "$country" "$ip"
      return 0
    fi
  fi

  response=$(_bashrc_fetch_url "https://ipapi.co/json/" 2>/dev/null) || response=
  if [ -n "$response" ]; then
    country=$(printf '%s\n' "$response" | _bashrc_parse_country_code)
    ip=$(printf '%s\n' "$response" | _bashrc_parse_public_ip)
    if [ -n "$country" ]; then
      printf '%s|%s\n' "$country" "$ip"
      return 0
    fi
  fi

  response=$(_bashrc_fetch_url "https://ifconfig.co/json" 2>/dev/null) || response=
  if [ -n "$response" ]; then
    country=$(printf '%s\n' "$response" | _bashrc_parse_country_code)
    ip=$(printf '%s\n' "$response" | _bashrc_parse_public_ip)
    if [ -n "$country" ]; then
      printf '%s|%s\n' "$country" "$ip"
      return 0
    fi
  fi

  return 1
}

_bashrc_require_us_ip() {
  local result country ip

  result=$(_bashrc_public_ip_country) || {
    printf 'refusing to run claude: unable to verify public IP country\n' >&2
    return 1
  }

  country=${result%%|*}
  ip=${result#*|}

  if [ "$country" != "US" ]; then
    if [ -n "$ip" ] && [ "$ip" != "$result" ]; then
      printf 'refusing to run claude: public IP %s is in %s, not US\n' "$ip" "$country" >&2
    else
      printf 'refusing to run claude: public IP country is %s, not US\n' "$country" >&2
    fi
    return 1
  fi

  if [ -n "$ip" ] && [ "$ip" != "$result" ]; then
    printf 'US IP verified: %s\n' "$ip" >&2
  else
    printf 'US IP verified\n' >&2
  fi
  return 0
}

my_claude() {
  _bashrc_have claude || {
    printf 'claude not found in PATH\n' >&2
    return 127
  }
  _bashrc_require_us_ip || return 1
  command claude "$@"
}

my_claudey() {
  _bashrc_have claude || {
    printf 'claude not found in PATH\n' >&2
    return 127
  }
  _bashrc_require_us_ip || return 1
  command claude --dangerously-skip-permissions "$@"
}

_bashrc_set_ls_aliases() {
  if command ls --color=auto . >/dev/null 2>&1; then
    alias ls='ls --color=auto'
  elif command ls -G . >/dev/null 2>&1; then
    alias ls='ls -G'
  else
    alias ls='ls'
  fi
}

_bashrc_set_ls_aliases
alias reload='source ~/.bashrc'
alias bashconf='${EDITOR:-vi} ~/.bashrc'
alias cls='clear; printf "%s\n" "$PWD"; ls'
alias ll='ls -lh'
alias la='ls -Ahl'
alias sl='ls -lSr'
alias tl='ls -ltr'
alias his='history'
alias vi='${EDITOR:-vi}'
alias tn='tmux rename-window "$(basename "$PWD")"'
alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias proxyon='proxy_on'
alias proxyoff='proxy_off'
alias proxystatus='proxy_status'

# Optional completion support when the host provides it.
_bashrc_source_first_readable \
  /usr/share/bash-completion/bash_completion \
  /etc/bash_completion \
  /usr/local/etc/bash_completion \
  /opt/homebrew/etc/profile.d/bash_completion.sh

# Optional git prompt support. The prompt still works without it.
_bashrc_source_first_readable \
  /usr/share/git/completion/git-prompt.sh \
  /etc/bash_completion.d/git-prompt \
  /usr/local/etc/bash_completion.d/git-prompt.sh \
  /opt/homebrew/etc/bash_completion.d/git-prompt.sh

# Optional toolchain bootstrap. Keep it lazy and host-tolerant.
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [ -d "$PYENV_ROOT/bin" ]; then
  _bashrc_prepend_path "$PYENV_ROOT/bin"
fi
if _bashrc_have pyenv; then
  eval "$(pyenv init - bash)"
  if pyenv commands 2>/dev/null | grep -qx 'virtualenv-init'; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _bashrc_load_nvm() {
    unset -f nvm node npm npx 2>/dev/null
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  }

  nvm() {
    _bashrc_load_nvm
    nvm "$@"
  }

  node() {
    _bashrc_load_nvm
    node "$@"
  }

  npm() {
    _bashrc_load_nvm
    npm "$@"
  }

  npx() {
    _bashrc_load_nvm
    npx "$@"
  }
fi

_bashrc_source_if_readable "$HOME/.cargo/env"

_bashrc_prompt_command() {
  local exit_status prompt_char git_segment status_segment
  exit_status=$?
  prompt_char='$'
  git_segment=
  status_segment=

  [ "${EUID:-$(id -u)}" -eq 0 ] 2>/dev/null && prompt_char='#'

  if [ "$exit_status" -ne 0 ]; then
    status_segment=" [$exit_status]"
  fi

  if _bashrc_have __git_ps1; then
    git_segment="$(__git_ps1 ' git:%s')"
  fi

  PS1="\A@\h \w${git_segment}${status_segment} ${prompt_char} "
}

if [ -n "${PROMPT_COMMAND:-}" ]; then
  # Strip trailing semicolons to avoid ";;" when appending
  _pc="${PROMPT_COMMAND%%;}"
  case ";${_pc};" in
    *";_bashrc_prompt_command;"*) ;;
    *) PROMPT_COMMAND="${_pc};_bashrc_prompt_command" ;;
  esac
  unset _pc
else
  PROMPT_COMMAND=_bashrc_prompt_command
fi

# Keep machine-specific settings out of the shared baseline.
_bashrc_source_if_readable "$HOME/.bashrc.local"

if [ "${BASHRC_CHECKPATH_ON_STARTUP:-0}" = "1" ]; then
  checkpath
fi
. "$HOME/.cargo/env"
