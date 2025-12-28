if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#------------------------------------------------------------------------------
# basics
#------------------------------------------------------------------------------
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled  # disable automatic updates
COMPLETION_WAITING_DOTS="true"

plugins=(git z fzf zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
else
   export EDITOR='nvim'
fi
bindkey -v

export MY_BORG_REPO=${HOME}/disk-4t-b/snapshots/borg/backup-repo

echo "========================================================================="
echo "-- oh-my-zsh.sh loaded"
echo "-- zsh ~/.zshrc $(date '+%F %T')"

#------------------------------------------------------------------------------
# SHELL Context
#------------------------------------------------------------------------------
my_os=$(uname -s)
my_arch=$(uname -p)
my_kernel=$(uname -r)
my_os_info=$(hostnamectl | grep "Operating System" | awk -F ': ' '{print $2}')

#------------------------------------------------------------------------------
# aliases
#------------------------------------------------------------------------------
alias ne='source ~/.zshrc'
alias zconf='nvim ~/.zshrc' 
alias ll='ls -l '
alias la='ls -a -l'
alias sl='ls -lrs'
alias tl="ls -l -t -r "
alias cls='(clear;pwd;ll;ls)'
alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias his='history'
alias tn='tmux rename-window `basename $PWD`'
alias vi='nvim'
alias autoclick='(while true; do xdotool click 1; sleep 10; done) '

#------------------------------------------------------------------------------
# functions
#------------------------------------------------------------------------------
showpath() {
    for p in ${(s/:/)PATH}; do
        if [ -e "$p" ]; then
            echo "  $p"
        else
            echo "[X] $p"
        fi
    done
} #showpath

checkpath() {
    for d in ${(s/:/)PATH}; do
        if [ ! -e "$d" ]; then
            echo "[Invalid] $d"
        fi
    done
} #checkpath

update_nvim_path() {
    nvr --remote-expr 'setenv("PATH", $PATH)'
} #update_nvim_path

update_nvim_cwd() {
    nvr --remote-expr 'setenv("PWD", $PWD)'
} #update_nvim_cwd

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

    echo "proxy: ON (http=${http_url}, socks=${socks_url})"
} #proxy_on

proxy_off() {
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    echo "proxy: OFF"
} #proxy_off

proxy_status() {
    local http="${http_proxy:-${HTTP_PROXY:-}}"
    local socks="${all_proxy:-${ALL_PROXY:-}}"
    if [[ -z $http && -z $socks ]]; then
        echo "proxy: OFF"
        return 0
    fi
    echo "proxy: ON (http=${http:-<unset>}, socks=${socks:-<unset>})"
} #proxy_status

alias proxyon='proxy_on'
alias proxyoff='proxy_off'
alias proxystatus='proxy_status'



# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

#------------------------------------------------------------------------------
# PATH for Ubuntu 24
#------------------------------------------------------------------------------
if [[ "$my_os_info" == Ubuntu\ 24* ]]; then
    echo "-- Setting PATH for $my_os_info"
    path=(${HOME}/.local/bin $path)
    path=(${HOME}/install/x86_64@ubt24/bin $path)
    path=(${HOME}/install/x86_64@ubt24/nvim-0.11/bin $path)
    path=(${HOME}/install/x86_64@ubt24/anki-launcher-25.07.5-linux $path)
    #path=(${HOME}/install/x86_64@ubt24/Python-3.13.0/bin $path)

    path=(${HOME}/install/scripts $path)
    path=(${HOME}/sandbox/github/myScripts $path)
    path=(${HOME}/sandbox/github/fileSync25 $path)
    path=(/usr/local/cuda/bin $path)
fi

#------------------------------------------------------------------------------
# TERM inside nvim
#------------------------------------------------------------------------------
if [[ -n $NVIM_LISTEN_ADDRESS ]]; then
    #avoid open nested vim/nvim inside toggleterm
    echo "Info: setting nvim/vim/vi to nvr because this is the shell inside neovim"
    alias nvim="nvr --remote-tab-silent"
    alias vim="nvr --remote-tab-silent"
    alias vi="nvr --remote-tab-silent"

    alias tmux='Nested tmux is not supposed run in shell inside neovim'

    ####################################################################################################
    # In toggleterm, when we do nvgdb, I want the floatting window be closed and 
    # then start vim-gdb in 'only|vnew' mode. This looks clean.
    #
    # FILE: start_vimgdb_close_toggleterm.sh
    #
    # #!/bin/tcsh
    # set wordir = $1
    # shift
    # set args = "$*"
    # cd $wordir
    # nvr --remote-tab-silent -c "lua CloseFloatingAndStartGdb('$args', '$workdir'")
    #
    # FILE: init.lua
    #
    # function CloseFloatingAndStartGDB(executable, workdir)
    # ....
    # endfunction
    #
    ####################################################################################################

    alias nvgdb='update_nvim_path; ${HOME}/install/scripts/start_vimgdb_close_toggleterm.sh `pwd` \!*'
fi

#------------------------------------------------------------------------------
# Source .zshrc.local for local specific settings.
#------------------------------------------------------------------------------
[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

#------------------------------------------------------------------------------
# Done.
#------------------------------------------------------------------------------
checkpath


echo "-- Done."

autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc
