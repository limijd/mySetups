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
" let g:w_is_ctags_installed = v:shell_error 
" W: current disable ctags and gutentags since coc.nvim is much better
" solution now.
let g:w_is_ctags_installed = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug managed plugins: vim-plug,
" 1. Downlaod https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" 2. Then put plug.vim into ~/.vim/autoload
" 3. start vim. run: PlugUpdate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('/home/wli/.config/nvim/plugged')

	let g:coc_node_path = '/home/wli/install/x86_64@rh7/nodejs-17.3.0/bin/node'
    "Plug 'neoclide/coc.nvim', {'branch': 'release'}
    "Plug 'neoclide/coc.nvim'
    Plug 'neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile' }

    "Plug 'neovim/nvim-lspconfig'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/cmp-nvim-lua'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/cmp-path'
    Plug 'hrsh7th/cmp-cmdline'
    Plug 'hrsh7th/nvim-cmp'

    " Use <Tab> and <S-Tab> to navigate through popup menu
    inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
    " Set completeopt to have a better completion experience
    set completeopt=menuone,noinsert,noselect
    " Avoid showing message extra message when using completion
    set shortmess+=c

    Plug 'nvim-treesitter/nvim-treesitter'
    Plug 'nvim-treesitter/playground'
    "Plug 'nvim-treesitter/completion-treesitter'

    Plug 'skywind3000/quickmenu.vim'
    noremap <silent><F12> :call quickmenu#toggle(0)<cr> 
    """let g:quickmenu_options="HL"

    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'

    Plug 'vimwiki/vimwiki'
    Plug 'preservim/nerdtree'
    Plug 'fholgado/minibufexpl.vim'
    Plug 'vhda/verilog_systemverilog.vim'


    """indent, use IndentLineToggle to toggle
    Plug 'Yggdroot/indentLine'
    let g:indentLine_enabled = 1
    "let g:indentLine_char_list = ['|', '¦', '┆', '┊']

    """ disable gutentags for now
    if g:w_is_ctags_installed == 0
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

let g:vimwiki_list = [{'path': '~/iCloud-sandbox/myWiki', 'index':'index', 'setup in syntax':'markdown', 'path_html': '~/iCloud-sandbox/myWiki/myWiki.html_ouput',  'ext':'.md'}]

set csprg=/usr/local/bin/cscope

let g:HAMMER_BROWSER='/usr/bin/chromium-browser'

let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1 

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Own Functions
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fu! Treesitter_install_langs()
    TSInstall bash
    TSInstall cpp
    TSInstall cmake 
    TSInstall css
    TSInstall html
    TSInstall java
    TSInstall javascript
    TSInstall json
    TSInstall llvm
    TSInstall lua
    TSInstall make
    TSInstall markdown
    TSInstall regex
    TSInstall verilog
    TSInstall vim
    TSInstall yaml
endfunction

fu! Coc_install_langs()
    """ ref: https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions
    CocInstall coc-tsserver coc-json coc-html coc-css 
    CocInstall coc-sh coc-pyright
    CocInstall coc-cmake
    CocInstall coc-yaml
    CocInstall coc-calc
    CocInstall coc-explorer
    CocInstall coc-git
    CocInstall coc-lists
    CocInstall coc-snippets
    """ may cause confuse on function names
    """CocInstall coc-spell-checker 
    CocInstall coc-svg
endfunction


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

if filereadable($HOME."/.vimrc.local")
    "echo "read ".$HOME."/.vimrc.local"
    let $VIMRC_LOCAL = $HOME."/.vimrc.local"
    so $VIMRC_LOCAL
endif


