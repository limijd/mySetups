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


#PATHs
set path = (/usr/local/bin /usr/local/sbin /sbin /bin /usr/bin/ /usr/sbin )

#platform specific

if ( $my_os == 'GNU/Linux' ) then
    echo "--- Specific setting for $my_os";
    alias ls "ls --color" 

    checkpath
endif

setenv LDFLAGS
if ( $my_os == 'Darwin' ) then
    echo "--- Specific setting for $my_os";

    # /usr/local/opt installations
    set path = (/usr/local/opt/binutils/bin $path)
    set path = (/usr/local/opt/google_tts $path)
    set path = (/usr/local/opt/ankiLearnChinese $path)
    set path = (/usr/local/opt/myChineseData/bin $path)
    set path = (/usr/local/opt/openjdk/bin $path)

    setenv PATH /usr/local/opt/qt/bin:$PATH
    setenv LDFLAGS -L/usr/local/opt/qt/lib;
    setenv CPPFLAGS -I/usr/local/opt/qt/include;
    setenv PKG_CONFIG_PATH /usr/local/opt/qt/lib/pkgconfig;

    #setenv PATH /usr/local/opt/mysql@8.0/bin:$PATH
    #setenv LDFLAGS "-L/usr/local/opt/mysql@8.0/lib $LDFLAGS"
    #setenv CPPFLAGS "-I/usr/local/opt/mysql@8.0/include $CPPFLAGS"
    #setenv PKG_CONFIG_PATH /usr/local/opt/mysql@8.0/lib/pkgconfig:$PKG_CONFIG_PATH

    # brew installations
    set path = (/usr/local/Cellar/universal-ctags/HEAD-dfa2ebf/bin $path)
    #set path = (/usr/local/Cellar/mysql/8.0.22/bin/ $path)
    set path = (/usr/local/Cellar/git/2.29.2/bin $path)
    #set path = (/usr/local/opt/python@3.8/bin $path)
    set path = (/usr/local/opt/python@3.9/bin $path)

    #rust installations
    set path = ($HOME/.cargo/bin $path)
    
    #ensure right python on Mac
    if ( `which pip2` != /usr/local/bin/pip2) echo "Warning! Unexpected pip2 at `which pip2`"
    #if ( `which pip3` != /usr/local/bin/pip3) echo "Warning! Unexpected pip3 at `which pip3`"
    if ( `which python2` != /usr/local/bin/python2 ) echo "Warning! Unexpected python2 at `which python2`"
    #if ( `which python3` != /usr/local/bin/python3 ) echo "Warning! Unexpected python3 at `which python3`"
    #if ( `which python3.8` != /usr/local/bin/python3.8 ) echo "Warning! Unexpected python3.8 at `which python3.8`"
    if ( `which python2.7` != /usr/local/bin/python2.7 ) echo "Warning! Unexpected python2.7 at `which python2.7`"

    checkpath

endif #endof: if $my_os == 'Darwin'
    

if ( -e ${HOME}/.cshrc.local ) then
    echo "--- source ${HOME}/.cshrc.local"
    source ${HOME}/.cshrc.local
endif

checkpath

set path = (/home/wli/install/x86_64@rh7/nvim-0.7.0-dev/bin $path)
set path = (/home/wli/install/x86_64@rh7/cmake-3.22.1/bin $path)
set path = (/home/wli/install/x86_64@rh7/gcc-7.5.0/bin $path)

#default c/c++ compiler for CentOS7 
setenv CC /home/wli/install/x86_64@rh7/gcc-7.5.0/bin/gcc
setenv CXX /home/wli/install/x86_64@rh7/gcc-7.5.0/bin/g++
setenv LDFLAGS "-Wl,-rpath,/home/wli/install/x86_64@rh7/gcc-7.5.0/lib64:XORIGIN ${LDFLAGS}"
setenv CFLAGS " -fPIC "
setenv CXXFLAGS " -fPIC "

set path = (/home/wli/install/x86_64@rh7/openssl-1.1.1l/bin $path)
setenv LDFLAGS "-L/home/wli/install/x86_64@rh7/openssl-1.1.1l/lib ${LDFLAGS}"
setenv CFLAGS "-I/home/wli/install/x86_64@rh7/openssl-1.1.1l/include ${CFLAGS}"
setenv CXXFLAGS "-I/home/wli/install/x86_64@rh7/openssl-1.1.1l/include ${CXXFLAGS}"

set path = (/home/wli/install/x86_64@rh7/python-3.10.1/bin $path)

set path = (/home/wli/install/x86_64@rh7/llvm-10.0.1/bin $path)
set path = (/home/wli/install/x86_64@rh7/nodejs-17.3.0/bin $path)
set path = ($HOME/.cargo/bin $path)
set path = (/home/wli/install/x86_64@rh7/patchelf-0.14.3/bin/ $path)

setenv CLASSPATH /usr/local/Cellar/antlr/4.9.2/antlr-4.9.2-complete.jar:.

#source $HOME/.cargo/env

echo "--- Done. -"

