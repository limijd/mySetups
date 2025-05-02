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
--- Enviroments.
-------------------------------------------------------------------------------
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1

-------------------------------------------------------------------------------
--- Options
-------------------------------------------------------------------------------
-- vim.opt.colorcolumn = '80'
vim.opt.expandtab = true
vim.opt.mouse = ''
vim.opt.number = true
-- vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.shiftwidth = 4
vim.opt.signcolumn = 'yes'
vim.opt.smartindent = true
vim.opt.tabstop = 4
vim.opt.termguicolors = true


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

    --- python native LSP client. (no longer use coc.nvim now).
    {
        'neovim/nvim-lspconfig',
        config = function()
            --- C++
            require('lspconfig').pyright.setup({
                capabilities = capabilities,
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = 'strict',
                            autoSearchPaths = true,
                            diagnosticMode = 'workspace',
                        }
                    }
                }
            })

            --- C++
            require('lspconfig').clangd.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=never",
                },
            })
        end
    },

    --- manson package manager 
    {
        'williamboman/mason.nvim',
        config = function()
            require('mason').setup {
                --- use pyright LSP server
                ensure_installed = {'pyright'},
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗"
                    }
                }
            }
        end
    },

    {
        'williamboman/mason-lspconfig.nvim',
        config = function()
            require('mason-lspconfig').setup {
                --- use pyright LSP server
                ensure_installed = {
                    'pyright',  -- python
                    'clangd',   -- C++
                },
                automatic_installation = false
            }
        end
    },

    {
        'nvim-treesitter/nvim-treesitter',
        config = function()
        end
    },

    --- auto completion
    {
        'hrsh7th/nvim-cmp',
        config = function()
        end
    },

    -- LSP completion source
    {
        'hrsh7th/cmp-nvim-lsp',
        config = function()
        end
    },

    -- Better diagnostic
    {
        'folke/trouble.nvim',
        config = function()
        end
    },

    -- Debugging
    {
        'mfussenegger/nvim-dap',
        config = function()
            require('dap').adapters.python = ({
                type = 'executable',
                command = 'python',
                args = {'-m', 'debugpy.adapter'},
            })
            require('dap').configurations.python = ({
                {
                    type = 'python',
                    request = 'launch',
                    name = 'Launch file',
                    program = '${file}',
                    pythonPath = function() return 'python' end,
                },
            })
        end
    },

    {
        'mfussenegger/nvim-dap-python',
        config = function()
        end
    },

    --- formater
    {
        'stevearc/conform.nvim',
        config = function()
            require('conform').setup({
                formatters_by_ft = {
                    python = {'black'},
                },
                format_on_save = {
                    timeout_ms = 500,
                    lsp_fallback = true,
                },
            })
        end
    },

    {
        'nvim-tree/nvim-tree.lua',
        config = function()
            require('nvim-tree').setup()
        end
    },

    {
        'nvim-lualine/lualine.nvim',
        config = function()
            require('lualine').setup({
                options = {theme = 'catppuccin'}
            })
        end
    },

    {'catppuccin/nvim', name = 'catppuccin'},

    {
        "nvim-tree/nvim-web-devicons",
        config = function()
            require('nvim-web-devicons').setup {
                default = true
            }
        end

    },

    {'folke/which-key.nvim'},

    {'folke/trouble.nvim'},

    {'windwp/nvim-autopairs'},

    {'numToStr/Comment.nvim'},

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

vim.cmd.colorscheme('catppuccin-mocha')

-------------------------------------------------------------------------------
--- LSP Configuration
-------------------------------------------------------------------------------
-- Common on_attach
local on_attach = function(client, bufnr)
  -- Keymaps
  local map = function(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', { buffer = bufnr }, opts or {}))
  end

  map('n', 'gd', vim.lsp.buf.definition)
  map('n', 'gr', vim.lsp.buf.references)
  map('n', 'K', vim.lsp.buf.hover)
  map('n', '<leader>rn', vim.lsp.buf.rename)
  map('n', '<leader>ca', vim.lsp.buf.code_action)
  map('n', '<leader>d', '<cmd>TroubleToggle document_diagnostics<CR>')
end


