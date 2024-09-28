vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.termguicolors = true
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1
vim.o.mouse = ''

-- Bootstrap lazy.nvim
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

-- Set up LazyVim and your plugins
require("lazy").setup({
    {
        "navarasu/onedark.nvim",
        config = function()
            require('onedark').setup{
                style = 'darker',
                term_colors = true,
            }

            require('onedark').load()
        end
    },

    {
        "nvim-tree/nvim-web-devicons",
        config = function()
            require('nvim-web-devicons').setup{
                default = true
            }
        end

    },
})

