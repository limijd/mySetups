# Portable Toolkit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite portable/zsh.zshrc, portable/tcsh.cshrc, and portable/vim.vimrc as minimal, self-contained configs that auto-detect and alias portable tools (nvim, rg, tmux) in customer environments with zero footprint.

**Architecture:** Each shell config auto-detects the portable directory, detects CPU arch, checks FUSE for AppImage, and sets up aliases. All temp files go under `/tmp/portable-$USER/`. No PATH modifications, no writes to `$HOME`.

**Tech Stack:** zsh, tcsh, vim script. Static binaries + AppImage.

**Design doc:** `docs/plans/2026-02-14-portable-toolkit-design.md`

---

### Task 1: Rewrite vim.vimrc to bare essentials

**Files:**
- Rewrite: `portable/vim.vimrc`

**Step 1: Write the minimal vimrc**

```vim
" Portable vim config — bare essentials, no plugins
set nocompatible
filetype plugin on
syntax on
set number
set expandtab tabstop=4 shiftwidth=4
set smartindent
set mouse=
set hlsearch incsearch
set backspace=indent,eol,start
```

**Step 2: Verify it loads cleanly**

Run: `vim -u portable/vim.vimrc -c ':q'`
Expected: exits cleanly, no errors

**Step 3: Commit**

```bash
git add portable/vim.vimrc
git commit -m "portable: rewrite vim.vimrc to bare essentials"
```

---

### Task 2: Rewrite zsh.zshrc

**Files:**
- Rewrite: `portable/zsh.zshrc`

**Step 1: Write the complete zsh.zshrc**

The file has these sections in order:

1. **Auto-detect portable dir** — `PORTABLE_DIR="${0:A:h}"`
2. **Temp dir setup** — create `/tmp/portable-$USER/`, set HISTFILE and completion cache there
3. **Arch detection** — `_portable_arch=$(uname -m)`
4. **FUSE check function** — test `fusermount --version`
5. **nvim alias setup** — check for AppImage matching arch, FUSE check, set alias with `-u vim.vimrc`. If no FUSE, create a wrapper function that lazy-extracts then runs nvim. Alias `vim` and `vi` to the same.
6. **rg alias setup** — check for `rg.$arch` binary, set alias
7. **tmux alias setup** — check for `tmux.$arch` binary, set alias with `-f tmux.conf`
8. **EDITOR** — set to the nvim wrapper if available
9. **Shell options** — minimal: vi mode, history settings (HISTSIZE=300, APPEND_HISTORY, HIST_IGNORE_SPACE), INTERACTIVE_COMMENTS, NO_BEEP
10. **Completion** — simple `compinit -i -d /tmp/portable-$USER/zcompdump`
11. **Prompt** — ultra-minimal two-line: `[portable] user@host /cwd\n$ `
12. **Aliases** — `ls --color`, `ll`, `la`, `tl`, `his`, `cls`, `gitlog`, `tn`

```zsh
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
  else
    # Lazy extract on first use, reuse across sessions
    _portable_nvim_extracted="${_portable_tmp}/nvim-squashfs/squashfs-root/usr/bin/nvim"
    _portable_nvim() {
      if [[ ! -x "$_portable_nvim_extracted" ]]; then
        echo "[portable] Extracting nvim AppImage (no FUSE)..."
        (cd "$_portable_tmp/nvim-squashfs" 2>/dev/null || mkdir -p "$_portable_tmp/nvim-squashfs" && cd "$_portable_tmp/nvim-squashfs" && "$_portable_nvim_appimage" --appimage-extract) &>/dev/null
      fi
      "$_portable_nvim_extracted" -u "${PORTABLE_DIR}/vim.vimrc" "$@"
    }
    alias nvim='_portable_nvim'
  fi
  alias vim='nvim'
  alias vi='nvim'
  export EDITOR="nvim"
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
```

**Step 2: Verify it sources cleanly**

Run: `zsh -c "source portable/zsh.zshrc && echo OK"`
Expected: prints activation message and "OK", no errors

**Step 3: Verify aliases are set**

Run: `zsh -c "source portable/zsh.zshrc && alias | grep -E '(nvim|rg|tmux)'"`
Expected: shows the alias definitions

**Step 4: Commit**

```bash
git add portable/zsh.zshrc
git commit -m "portable: rewrite zsh.zshrc to minimal customer config"
```

---

### Task 3: Rewrite tcsh.cshrc

**Files:**
- Rewrite: `portable/tcsh.cshrc`

**Step 1: Write the complete tcsh.cshrc**

Same tool detection logic adapted to tcsh syntax:

```tcsh
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
    else
        # No FUSE: extract on first use via wrapper script
        set _nvim_wrapper = "${_portable_tmp}/nvim-wrapper.sh"
        set _nvim_extract_dir = "${_portable_tmp}/nvim-squashfs"
        # Write a small wrapper script that handles lazy extraction
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
    endif
    alias vim nvim
    alias vi nvim
    setenv EDITOR nvim
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
```

**Step 2: Verify it sources cleanly**

Run: `tcsh -c "setenv PORTABLE_DIR $PWD/portable; source portable/tcsh.cshrc"`
Expected: prints activation message, no errors

**Step 3: Verify alias setup**

Run: `tcsh -c "setenv PORTABLE_DIR $PWD/portable; source portable/tcsh.cshrc; alias | grep -E '(nvim|rg|tmux)'"`
Expected: shows alias definitions

**Step 4: Commit**

```bash
git add portable/tcsh.cshrc
git commit -m "portable: rewrite tcsh.cshrc to minimal customer config"
```

---

### Task 4: Smoke test all three configs together

**Step 1: Verify zsh end-to-end**

```bash
zsh -c "source portable/zsh.zshrc && which nvim && which rg && echo PASS"
```

Expected: alias references printed, "PASS"

**Step 2: Verify tcsh end-to-end**

```bash
tcsh -c "setenv PORTABLE_DIR $PWD/portable; source portable/tcsh.cshrc; alias nvim; echo PASS"
```

Expected: alias shown, "PASS"

**Step 3: Verify vim loads cleanly**

```bash
# using system vim to test the vimrc
vim -u portable/vim.vimrc -c ':q'
```

Expected: exits cleanly

**Step 4: Verify no writes to $HOME**

```bash
# Check that sourcing doesn't create anything in $HOME
ls -la /tmp/portable-$USER/
```

Expected: temp files only in /tmp

**Step 5: Final commit if any fixes needed**

```bash
git add -A portable/
git commit -m "portable: fix smoke test issues"
```

---

### Task 5: Update architecture docs

**Step 1: Update docs/ARCHITECTURE.md**

Add a section documenting the portable toolkit module.

**Step 2: Update AGENTS.md if it exists**

Record any tcsh or AppImage gotchas discovered during implementation.

**Step 3: Commit**

```bash
git add docs/ARCHITECTURE.md AGENTS.md
git commit -m "docs: add portable toolkit to architecture docs"
```
