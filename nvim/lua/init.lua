-- needed for satisfy lua-LSP
_G.vim          = vim

local home_dir  = os.getenv("HOME")
local user_name = os.getenv("USER") or os.getenv("USERNAME")

-------------------------------------------------------------------------------
--- Compile and load init.luac
-------------------------------------------------------------------------------
local init_luac = '/tmp/' .. user_name .. '.init.luac'
local init_lua  = vim.fn.stdpath('config') .. '/init.lua'

if vim.fn.filereadable(init_luac) == 1 then
    local lua_mtime = vim.fn.getftime(init_lua)
    local luac_mtime = vim.fn.getftime(init_luac)

    if lua_mtime > luac_mtime then
        os.remove(init_luac)
        print('Deleted outdated bytecode file: ' .. init_luac)
        pcall(dofile, init_lua)
        return
    end

    if not _G.is_dofile_init_luac then
        _G.is_dofile_init_luac = true
        local success, err = pcall(dofile, init_luac)
        if not success then
            print('Error loading bytecode: ' .. err)
        else
            print('Loaded bytecode init.luac')
        end
        return
    end
else
    local bytecode = string.dump(loadfile(init_lua), true)
    local f = io.open(init_luac, 'wb')
    if f then
        f:write(bytecode)
        f:close()
        print('Compiled ' .. init_lua .. ' to bytecode.')
    else
        print('Error: Unable to write to ' .. init_luac)
    end
end

function CloseFloatingAndStartGDB(executable, workdir)
    local original_dir = vim.fn.getcwd()
    vim.cmd('cd ' .. workdir)
    
    -- Check if current window is floating and close it
    local config = vim.api.nvim_win_get_config(0)
    if config.relative ~= '' then
        vim.api.nvim_win_close(0, true)
    end

    -- setup layout for vim-gdb
    vim.cmd("only | vnew")
    -- start gdb with the provided executable and arguments
    vim.cmd("GdbStart gdb --args " .. executable)

    vim.cmd('cd ' .. original_dir)
end
-------------------------------------------------------------------------------
--- Diagnostics
-------------------------------------------------------------------------------
_G.my_nvim_diag = false

if _G.my_nvim_diag then
    vim.env.NVIM_LOG_LEVEL = 'OFF'

    -- LSP: TRACE DEBUG INFO WARN ERROR OFF
    vim.lsp.set_log_level('TRACE')

    -- trace debug info warn error
    vim.env.NVIM_COC_LOG_LEVEL = 'trace'
else
    vim.env.NVIM_LOG_LEVEL = 'OFF'
    vim.lsp.set_log_level('OFF')
    vim.env.NVIM_COC_LOG_LEVEL = 'error'
end

-------------------------------------------------------------------------------
--- nvr/nvim-server
--- On MacOS:
---     brew install nvr
---     brew install neovim-remote
-------------------------------------------------------------------------------
-- this is optional.
vim.env.NVIM_LISTEN_ADDRESS = vim.fn.stdpath('data') .. '/nvim-server'

-------------------------------------------------------------------------------
--- Essential
-------------------------------------------------------------------------------

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.termguicolors = true
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1
vim.o.mouse = ''

-------------------------------------------------------------------------------
--- keymaps.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- Bootstrap lazy.nvim
-------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- Latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -------------------------------------------------------------------------------
    --- Plugin: Onedark them.
    -------------------------------------------------------------------------------
    {
        "navarasu/onedark.nvim",
        config = function()
            require('onedark').setup {
                style = 'darker',
                term_colors = true,
            }

            require('onedark').load()
        end
    },

    -------------------------------------------------------------------------------
    --- Plugin: web-devicons
    -------------------------------------------------------------------------------
    {
        "nvim-tree/nvim-web-devicons",
        config = function()
            require('nvim-web-devicons').setup {
                default = true
            }
        end

    },

    -------------------------------------------------------------------------------
    --- Plugin: coc.nvim
    ---
    --- 1. lazy.vim install and load coc.nvim
    --- 2. compile coc.nvim  (important)
    ---     %> cd ~/.local/share/nvim/lazy/coc.nvim
    ---     %> npm ci
    --- 3.  install coc extensiosn
    ---     :CocInstall <ext>
    ---     or
    ---     :lua install_coc_exts()
    -------------------------------------------------------------------------------
    {
        "neoclide/coc.nvim",
        event = { 'BufReadPre', 'BufNewFile' },
        -- coc.nvim will only be loaded when below kinds of files are opened.
        ft = { 'cpp', 'c', 'lua', 'zsh', 'rust', 'go', 'java', 'python', 'bash', 'make', 'verilog', 'systemverilog', 'tcsh', 'markdown' },
        config = function()
            vim.api.nvim_set_keymap('n', 'gd', '<Plug>(coc-definition)', { noremap = false, silent = true })
            vim.api.nvim_set_keymap('n', 'gt', '<Plug>(coc-type-definition)', { noremap = false, silent = true })
            vim.api.nvim_set_keymap('n', 'gi', '<Plug>(coc-implementation)', { noremap = false, silent = true })
            vim.api.nvim_set_keymap('n', 'gr', '<Plug>(coc-references)', { noremap = false, silent = true })
            vim.api.nvim_set_keymap('n', 'K', ":call CocAction('doHover')<CR>", { noremap = true, silent = true })

            vim.api.nvim_set_keymap('x', "<leader>f", "<Plug>(coc-format-selected)", { noremap = false, silent = true })
            vim.api.nvim_set_keymap('n', "<leader>f", "<Plug>(coc-format-selected)", { noremap = false, silent = true })
        end

    },
    -------------------------------------------------------------------------------
    --- Plugin: telescope.nvim
    ---
    --- 1. Fuzzy file finder
    --- 2. live grep/search (ripgrep is recommended)
    ---     sudo apt-get install ripgrep
    ---     brew install ripgrep
    --- 3. buffer/tag searching
    --- 4. git integration
    --- 5. preview
    ---
    --- * make sure telescope-fzf-native.vim  build successfully:
    ---     cd ~/.local/share/nvim/lazy/telescope.nvim/
    ---     make -f Makefile
    -------------------------------------------------------------------------------
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim',
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        config = function()
            require('telescope').setup {
            }

            vim.api.nvim_set_keymap('n', "<leader>rg", ':lua require("telescope.builtin").live_grep()<CR>',
                { noremap = false, silent = true })
            vim.api.nvim_set_keymap('n', "<leader>fh", ':lua require("telescope.builtin").help_tags()<CR>',
                { noremap = false, silent = true })

            require("telescope").load_extension("fzf")
        end,
        -- if  add below line, Telescope will not be loaded by default until do :Telescope
        -- cmd = "Telescope",
    },
}) -- end of require("Lazy').setup

-------------------------------------------------------------------------------
--- Install coc extensions manually, call install_coc_exts() in nvim.
---     :lua install_coc_exts() 
-------------------------------------------------------------------------------
function _G.install_coc_exts()
    local exts = {
        'coc-clangd', -- clangd need to be installed separately
        'coc-cmake',
        'coc-css',
        'coc-fzf-preview',
        'coc-git',
        'coc-go',
        'coc-html',
        'coc-java',
        'coc-json',
        'coc-lists',
        'coc-lua',         -- LSP is optional
        'coc-markdownlint',
        'coc-marketplace', -- CocList marketplace to list all available exts.
        'coc-pairs',       -- installed paired characters automatically {}, [], (), ..etc.
        'coc-prettier',    -- reformat javascript, typescript, css, and json
        'coc-python',
        'coc-sh',
        'coc-snippets',
        'coc-tsserver', -- typescript and javscript
        'coc-xml',
        'coc-yaml',
    }

    for _, ext in ipairs(exts) do
        print("Installing: " .. ext)
        vim.cmd("CocInstall -sync " .. ext)
        print("Finished installed: " .. ext)
    end
end
