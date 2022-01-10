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

colorscheme torte
"let $NVIM_TUI_ENABLE_TRUE_COLOR=1
"set termguicolors

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
    set updatetime=300
    set signcolumn=yes
    nnoremap <silent> K :call <SID>show_documentation()<CR>
    " GoTo code navigation.
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)

    " Formatting selected code.
    xmap <leader>f  <Plug>(coc-format-selected)
    nmap <leader>f  <Plug>(coc-format-selected)

    " Add (Neo)Vim's native statusline support.
    " NOTE: Please see `:h coc-status` for integrations with external plugins that
    " provide custom statusline: lightline.vim, vim-airline.
    "set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}


    function! s:show_documentation()
        if (index(['vim','help'], &filetype) >= 0)
            execute 'h '.expand('<cword>')
        elseif (coc#rpc#ready())
            call CocActionAsync('doHover')
        else
            execute '!' . &keywordprg . " " . expand('<cword>')
        endif
    endfunction

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
    },
}

EOF
