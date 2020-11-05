"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Basic configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype off

set expandtab
set tabstop=4
set shiftwidth=4
set smartindent
set nocompatible 

"turn off mouse in non-gui VIM 
if has("gui_running")
    "echo "yes, we have a GUI"
    set mouse=a
else
    "echo "Boring old console"
    set mouse=
endif
    
filetype plugin on 
syntax on 
set nu

let g:w_which_ctags = system("which ctags")
let g:w_is_ctags_installed = v:shell_error 

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug managed plugins: vim-plug,
" 1. Downlaod https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" 2. Then put plug.vim into ~/.vim/autoload
" 3. start vim. run: PlugUpdate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.vim/plugged')

    Plug 'skywind3000/quickmenu.vim'
    noremap <silent><F12> :call quickmenu#toggle(0)<cr> 
    """let g:quickmenu_options="HL"

    Plug 'vimwiki/vimwiki'
    Plug 'preservim/nerdtree'
    Plug 'fholgado/minibufexpl.vim'
    Plug 'vhda/verilog_systemverilog.vim'
    if g:w_is_ctags_installed == 0
        echo "ctags enabled"
        Plug 'ludovicchabant/vim-gutentags'

        "前半部分 “./.tags; ”代表在文件的所在目录下（不是 “:pwd”返回的 Vim 当前目录）查找名字为 “.tags”的符号文件，
        "后面一个分号代表查找不到的话向上递归到父目录，直到找到 .tags 文件或者递归到了根目录还没找到，
        "这样对于复杂工程很友好，源代码都是分布在不同子目录中，而只需要在项目顶层目录放一个 .tags文件即可；
        "逗号分隔的后半部分 .tags 是指同时在 Vim 的当前目录（“:pwd”命令返回的目录，可以用 :cd ..命令改变）下面查找 .tags 文件。
        set tags=./.tags;,.tags

        " 搜索工程目录的标志，碰到这些文件/目录名就停止向上一级目录递归
        let g:gutentags_project_root = ['.root', '.svn', '.git', '.hg','.project']

        " 所生成的数据文件的名称
        let g:gutentags_ctags_tagfile = '.tags'
       
        " 将自动生成的 tags 文件全部放入 ~/.cache/tags" 目录中，避免污染工程目录
        "let s:vim_tags = expand('~/.cache/tags')
        "let g:gutentags_cache_dir = s:vim_tags
        
        " 配置 ctags 的参数
        let g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extra=+q']
        let g:gutentags_ctags_extra_args += ['--c++-kinds=+px']
        let g:gutentags_ctags_extra_args += ['--c-kinds=+px']
        
        " 检测 ~/.cache/tags 不存在就新建
        " if !isdirectory(s:vim_tags)
        "    silent! call mkdir(s:vim_tags, 'p')
        " endif
    endif


call plug#end()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:vimwiki_list = [{'path': '~/dev-sandbox/local/myWiki', 'index':'index', 'setup in syntax':'markdown', 'path_html': '~/dev-local/myWiki.html_ouput',  'ext':'.md'}]

set csprg=/usr/local/bin/cscope

let g:HAMMER_BROWSER='/usr/bin/chromium-browser'

let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1 


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Python3
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if !has("python3")
    finish
endif

""" try in vim: ":call SayHello()"
function! SayHello()
python3 << EOF
# -*- coding: utf-8 -*-

def SayHello():
    print("hello!")
    MyPyVim.Hi()

SayHello()
EOF
endfunction

python3 << EOF
# -*- coding: utf-8 -*-
import os
import sys
sys.path.append("%s/.vim/python/"%os.environ["HOME"])
import MyPyVim #try import
EOF

