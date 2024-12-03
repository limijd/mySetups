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
alias cls='(clear;pwd;ll;ls)'
alias gitlog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias his='history'
alias tn='tmux rename-window `basename $PWD`'

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



# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

#------------------------------------------------------------------------------
# PATH for Ubuntu 24
#------------------------------------------------------------------------------
if [[ "$my_os_info" == Ubuntu\ 24* ]]; then
    echo "-- Setting PATH for $my_os_info"
    path=(/home/wli/install/x86_64@ubt24/Python-3.13.0/bin $path)
fi

#------------------------------------------------------------------------------
# Done.
#------------------------------------------------------------------------------
checkpath

echo "-- Done."
