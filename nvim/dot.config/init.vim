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

let g:uname = system("uname")

"colorscheme torte
"let $NVIM_TUI_ENABLE_TRUE_COLOR=1
"set termguicolors

let g:w_which_ctags = system("which ctags")
" let g:w_is_ctags_installed = v:shell_error 
" W: current disable ctags and gutentags since coc.nvim is much better
" solution now.
let g:w_is_ctags_installed = 1

if g:uname == "Darwin\n"
	let g:coc_node_path = '/usr/local/bin/node'
else
	let g:coc_node_path = '/home/wli/install/x86_64@rh7/nodejs-17.3.0/bin/node'
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-plug managed plugins: vim-plug,
" 1. Downlaod https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" 2. Then put plug.vim into ~/.vim/autoload
" 3. start vim. run: PlugUpdate
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.config/nvim/plugged')

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
