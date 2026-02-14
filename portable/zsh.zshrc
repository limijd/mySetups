#------------------------------------------------------------------------------
# Portable zsh config — minimal, zero footprint on customer machines
# Usage: source /path/to/portable/zsh.zshrc
#------------------------------------------------------------------------------

# Auto-detect portable directory from this file's location
PORTABLE_DIR="${0:A:h}"

# Temp directory — all writes go here, nothing touches $HOME
_portable_tmp="/tmp/portable-${USER:-$(id -un)}"
mkdir -p "$_portable_tmp"

# Arch detection
_portable_arch=$(uname -m)

#------------------------------------------------------------------------------
# Tool detection and alias setup
#------------------------------------------------------------------------------

# FUSE availability check
_portable_has_fuse() {
  fusermount --version &>/dev/null
}

# nvim: AppImage with FUSE fallback
_portable_nvim_appimage="${PORTABLE_DIR}/nvim-0.11.4-${_portable_arch}.appimage"
if [[ -x "$_portable_nvim_appimage" ]]; then
  if _portable_has_fuse; then
    alias nvim="'${_portable_nvim_appimage}' -u '${PORTABLE_DIR}/vim.vimrc'"
    export EDITOR="${_portable_nvim_appimage}"
  else
    # Lazy extract on first use, reuse across sessions
    _portable_nvim_extract_dir="${_portable_tmp}/nvim-squashfs"
    _portable_nvim_extracted="${_portable_nvim_extract_dir}/squashfs-root/usr/bin/nvim"
    _portable_nvim() {
      if [[ ! -x "$_portable_nvim_extracted" ]]; then
        echo "[portable] Extracting nvim AppImage (no FUSE)..."
        mkdir -p "$_portable_nvim_extract_dir"
        (cd "$_portable_nvim_extract_dir" && "$_portable_nvim_appimage" --appimage-extract) &>/dev/null
      fi
      "$_portable_nvim_extracted" -u "${PORTABLE_DIR}/vim.vimrc" "$@"
    }
    alias nvim='_portable_nvim'
    # EDITOR wrapper script so external programs (git commit, etc.) can find nvim
    _portable_editor="${_portable_tmp}/nvim-editor"
    cat > "$_portable_editor" <<'WRAPPER'
#!/bin/sh
EXTRACT_DIR="__EXTRACT_DIR__"
APPIMAGE="__APPIMAGE__"
VIMRC="__VIMRC__"
NVIM_BIN="${EXTRACT_DIR}/squashfs-root/usr/bin/nvim"
if [ ! -x "$NVIM_BIN" ]; then
  echo "[portable] Extracting nvim AppImage (no FUSE)..."
  mkdir -p "$EXTRACT_DIR" && cd "$EXTRACT_DIR" && "$APPIMAGE" --appimage-extract > /dev/null 2>&1
fi
exec "$NVIM_BIN" -u "$VIMRC" "$@"
WRAPPER
    sed -i "s|__EXTRACT_DIR__|${_portable_nvim_extract_dir}|;s|__APPIMAGE__|${_portable_nvim_appimage}|;s|__VIMRC__|${PORTABLE_DIR}/vim.vimrc|" "$_portable_editor"
    chmod +x "$_portable_editor"
    export EDITOR="${_portable_editor}"
  fi
  alias vim='nvim'
  alias vi='nvim'
fi

# rg: static binary
_portable_rg_bin="${PORTABLE_DIR}/rg.${_portable_arch}"
if [[ -x "$_portable_rg_bin" ]]; then
  alias rg="'${_portable_rg_bin}'"
fi

# tmux: static binary with config
_portable_tmux_bin="${PORTABLE_DIR}/tmux.${_portable_arch}"
if [[ -x "$_portable_tmux_bin" ]]; then
  alias tmux="'${_portable_tmux_bin}' -f '${PORTABLE_DIR}/tmux.conf'"
fi

#------------------------------------------------------------------------------
# Shell options
#------------------------------------------------------------------------------
bindkey -v
bindkey '^R' history-incremental-search-backward

HISTFILE="${_portable_tmp}/zsh_history"
HISTSIZE=300
SAVEHIST=$HISTSIZE
setopt APPEND_HISTORY HIST_IGNORE_SPACE EXTENDED_HISTORY
setopt INTERACTIVE_COMMENTS NO_BEEP

#------------------------------------------------------------------------------
# Completion (minimal, cache in tmp)
#------------------------------------------------------------------------------
autoload -Uz compinit
compinit -i -d "${_portable_tmp}/zcompdump"

#------------------------------------------------------------------------------
# Prompt — ultra-minimal
#------------------------------------------------------------------------------
setopt PROMPT_SUBST
PROMPT='%F{cyan}[portable]%f %n@%m %F{yellow}%/%f
%(!.#.$) '

#------------------------------------------------------------------------------
# Aliases
#------------------------------------------------------------------------------
alias ls='ls --color'
alias ll='ls -lh'
alias la='ls -Ahl'
alias tl='ls -ltr'
alias sl='ls -lrs'
alias his='history 1'
alias cls='(clear && printf "%s\n" "$PWD" && ls)'
alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias tn='tmux rename-window "$(basename "$PWD")"'

echo "[portable] Activated from ${PORTABLE_DIR} (arch: ${_portable_arch})"
