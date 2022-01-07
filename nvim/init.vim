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
call plug#begin('~/.config/nvim/plugged')

    Plug 'neovim/nvim-lspconfig'
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

    """ useful to matchup different kinds of keyword for example begin...end,
    """ task...endtask . etc.
    Plug 'andymass/vim-matchup'

    Plug 'skywind3000/quickmenu.vim'
    noremap <silent><F12> :call quickmenu#toggle(0)<cr> 
    """let g:quickmenu_options="HL"

    Plug 'vimwiki/vimwiki'
    Plug 'preservim/nerdtree'
    Plug 'fholgado/minibufexpl.vim'

    """ verilog/system_verilog.vim is disabled because nvim-treesitter-verilog is supposed to do better
    """ job than it.
    "Plug 'vhda/verilog_systemverilog.vim'

    if g:w_is_ctags_installed == 0
        "Plug 'ludovicchabant/vim-gutentags'

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

if filereadable($HOME."/.vimrc.local")
    "echo "read ".$HOME."/.vimrc.local"
    let $VIMRC_LOCAL = $HOME."/.vimrc.local"
    so $VIMRC_LOCAL
endif


lua <<EOF
require'nvim-treesitter.configs'.setup {
    -- One of "all", "maintained" (parsers with maintainers), or a list of languages
    ensure_installed = "maintained",

    -- Install languages synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- List of parsers to ignore installing
    ignore_install = { "javascript" },

    highlight = {
        -- `false` will disable the whole extension
        enable = true,

        -- list of language that will be disabled
        disable = { "rust" },

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },

    indent = {
        enable = true
    },

    --- W: why it's not working ?
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },

    playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
    keybindings = {
        toggle_query_editor = 'o',
        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',
        focus_language = 'f',
        unfocus_language = 'F',
        update = 'R',
        goto_node = '<cr>',
        show_help = '?',
        },
    }
}
EOF


