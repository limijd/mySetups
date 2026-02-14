#!/bin/csh
#------------------------------------------------------------------------------
# Portable tcsh config — minimal, zero footprint on customer machines
# Usage: setenv PORTABLE_DIR /path/to/portable; source /path/to/portable/tcsh.cshrc
#------------------------------------------------------------------------------

if (! $?prompt) exit 0

# Auto-detect: require PORTABLE_DIR to be set
if (! $?PORTABLE_DIR) then
    echo "[portable] ERROR: set PORTABLE_DIR before sourcing. Example:"
    echo "  setenv PORTABLE_DIR /path/to/portable"
    echo "  source /path/to/portable/tcsh.cshrc"
    exit 1
endif

# Temp directory
set _portable_tmp = "/tmp/portable-${USER}"
mkdir -p "$_portable_tmp"

# Arch detection
set _portable_arch = `uname -m`

#------------------------------------------------------------------------------
# Tool detection and alias setup
#------------------------------------------------------------------------------

# nvim: AppImage with FUSE fallback
set _nvim_appimage = "${PORTABLE_DIR}/nvim-0.11.4-${_portable_arch}.appimage"
if ( -x "$_nvim_appimage" ) then
    # Check FUSE
    fusermount --version >& /dev/null
    if ( $status == 0 ) then
        alias nvim "'${_nvim_appimage}' -u '${PORTABLE_DIR}/vim.vimrc'"
        setenv EDITOR "${_nvim_appimage}"
    else
        # No FUSE: write a wrapper script for lazy extraction
        set _nvim_wrapper = "${_portable_tmp}/nvim-wrapper.sh"
        set _nvim_extract_dir = "${_portable_tmp}/nvim-squashfs"
        # Generate wrapper script
        echo '#!/bin/sh' > "$_nvim_wrapper"
        echo "EXTRACT_DIR='${_nvim_extract_dir}'" >> "$_nvim_wrapper"
        echo "APPIMAGE='${_nvim_appimage}'" >> "$_nvim_wrapper"
        echo "VIMRC='${PORTABLE_DIR}/vim.vimrc'" >> "$_nvim_wrapper"
        echo 'NVIM_BIN="${EXTRACT_DIR}/squashfs-root/usr/bin/nvim"' >> "$_nvim_wrapper"
        echo 'if [ ! -x "$NVIM_BIN" ]; then' >> "$_nvim_wrapper"
        echo '  echo "[portable] Extracting nvim AppImage (no FUSE)..."' >> "$_nvim_wrapper"
        echo '  mkdir -p "$EXTRACT_DIR" && cd "$EXTRACT_DIR" && "$APPIMAGE" --appimage-extract > /dev/null 2>&1' >> "$_nvim_wrapper"
        echo 'fi' >> "$_nvim_wrapper"
        echo 'exec "$NVIM_BIN" -u "$VIMRC" "$@"' >> "$_nvim_wrapper"
        chmod +x "$_nvim_wrapper"
        alias nvim "$_nvim_wrapper"
        setenv EDITOR "$_nvim_wrapper"
    endif
    alias vim nvim
    alias vi nvim
endif

# rg: static binary
set _rg_bin = "${PORTABLE_DIR}/rg.${_portable_arch}"
if ( -x "$_rg_bin" ) then
    alias rg "'$_rg_bin'"
endif

# tmux: static binary with config
set _tmux_bin = "${PORTABLE_DIR}/tmux.${_portable_arch}"
if ( -x "$_tmux_bin" ) then
    alias tmux "'$_tmux_bin' -f '${PORTABLE_DIR}/tmux.conf'"
endif

#------------------------------------------------------------------------------
# Shell options
#------------------------------------------------------------------------------
bindkey -v
set autolist
set history = 300
set savehist = 300
set histfile = "${_portable_tmp}/tcsh_history"

#------------------------------------------------------------------------------
# Prompt — ultra-minimal
#------------------------------------------------------------------------------
set prompt = '[portable] %n@%m %/ \n%# '

#------------------------------------------------------------------------------
# Completions (essential only)
#------------------------------------------------------------------------------
complete cd 'p/1/d/'
complete git 'p/1/(add bisect branch checkout clone commit diff fetch grep init log merge mv pull push rebase reset rm show status tag)/'
complete make 'p/1/Makefile*/'
complete man 'n/*/c/'
complete which 'n/*/c/'

#------------------------------------------------------------------------------
# Aliases
#------------------------------------------------------------------------------
alias ls '/bin/ls --color'
alias ll 'ls -l'
alias la 'ls -al'
alias tl 'll -t -r'
alias sl 'll -S'
alias his 'history'
alias cls '(clear; pwd; ll; ls)'
alias gitlog "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"

echo "[portable] Activated from ${PORTABLE_DIR} (arch: ${_portable_arch})"
