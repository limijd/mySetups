#!/bin/csh -v 

set my_os=`uname -s`
set my_arch=`uname -p`

if(! $?prompt) then
    exit 0
endif

echo "--- General settings for tcsh";

#Settings
set prompt='%B%T%b@%m %/ %#.%?\% '
set autolist #make complete even better
bindkey -v
setenv EDITOR vi
setenv LDFLAGS

#Completes
complete setenv     'p/1/e/'
complete unsetenv   'p/1/e/'
complete gunzip     'p/1/t:*.{gz,Z}/' 'n/-r/d/'
complete vi         'p/1/f:^*.o/'
complete vim        'p/1/f:^*.o/'
complete make       'p/1/Makefile*/'
complete kill       'p/*/`ps | awk \{print\ \$1\}`/'
complete alias      'p/1/a/'
complete cd         'p/1/d/'
complete set        'p/1/s/'
complete unset      'p/1/s/'
complete su         'p/1/u/'
complete man        'n/*/c/'
complete which      'n/*/c/'
complete git        'p/1/(add bisect branch checkout clone commit diff fetch grep init log merge  mv pull push rebase reset rm show status tag)/'

#Alias
alias gitpullsubs   "git submodule update --init --recursive"
alias ne  	        "source ~/.cshrc"
alias vicshrc 	    "vim ~/.cshrc"
alias cdnewdir      "mkdir \!*; cd \!*"
alias viwhich       'vi `which \!*`'
alias myindent      "indent -nbbo -blin -i4 -ip4 -lp -brs -nbc -di16 -br -ce -cdb -sc -bad -kr"
alias krindent      "indent -kr -nut"
alias e             "emacs -nw"
alias txtman        "man \!* | col -b | uniq>\!*.howto"
alias g             "g++"
alias his           "history"
alias cls           "(clear;pwd;ll;ls)"
alias sl            "ll -S "
alias tl            "ll -t -r"
alias la            "ls -a -l"
alias ll            "ls -l "
alias env           "env |sort|less"
alias ls 	        "/bin/ls --color "
alias gitlog        "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
alias dev	        "cd ~/dev-sandbox"
alias tarzip        "tar -cvf \!*.tar \!*; gzip \!*.tar"
alias tarzip_repl   "tar -cvf \!*.tar \!*; gzip \!*.tar; rm -r \!*"
alias tn            'tmux rename-window `basename $PWD`'
alias showpath      'foreach p ( $path )\
                        if ( -e $p ) then\
                            echo "    $p"\
                        else\
                            echo "[X] $p"\
                        endif\
                    end'
alias parr          'foreach e ( \!* )\
                        echo $e\
                    end'

alias checkpath     'foreach d ($path)\
                        if ( ! -e $d ) then\
                            echo "Invalid PATH: $d"\
                        endif\
                    end'
                
alias echoarr   parr

if ( -x `which nvim` ) then
    alias vim nvim
    alias vi nvim
endif

#PATHs
set path = (/usr/local/bin /usr/local/sbin /sbin /bin /usr/bin/ /usr/sbin )

#platform specific

if ( $my_os == 'GNU/Linux' ) then
    echo "--- Specific setting for $my_os";
    alias ls "ls --color" 

    checkpath
endif

if ( $my_os == 'Darwin' ) then
    set path = (/usr/local/bin /sbin /bin /usr/bin/ /usr/sbin )
    echo "--- Specific setting for $my_os";

    # Homebrew and it's installed packages
    set path = (/opt/homebrew/bin $path)
    set path = (/opt/homebrew/opt/fzf/bin $path)

    checkpath
endif #endof: if $my_os == 'Darwin'
    
if ( $my_os/$my_arch == 'Linux/aarch64' ) then
    echo "--- Setting up for Linux/aarch64"
endif

if ( -e ${HOME}/.cshrc.local ) then
    echo "--- source ${HOME}/.cshrc.local"
    source ${HOME}/.cshrc.local
endif

checkpath

echo "--- Done. -"

