-- =============================================================================
-- init.lua — paper: минимальный, но удобный конфиг под Python + Rust
-- тема colors/paper.lua · стартовый экран и :T — lua/paper/
-- =============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- гарантируем, что LSP-серверы видят user-local бинари (cargo/rustc/ruff и т.п.)
-- независимо от того, откуда стартовал nvim
vim.env.PATH = table.concat({
  vim.fn.expand("~/.local/bin"),
  vim.fn.expand("~/.cargo/bin"),
  vim.env.PATH or "",
}, ":")

-- --------- options -----------------------------------------------------------
local o = vim.opt
o.number         = true
o.relativenumber = true
o.cursorline     = true
o.signcolumn     = "yes"
o.wrap           = false
o.tabstop        = 4
o.shiftwidth     = 4
o.expandtab      = true
o.smartindent    = true
o.ignorecase     = true
o.smartcase      = true
o.termguicolors  = true
o.mouse          = "a"
o.clipboard      = "unnamedplus"
o.undofile       = true
o.updatetime     = 250
o.timeoutlen     = 400
o.splitright     = true
o.splitbelow     = true
o.scrolloff      = 6
o.sidescrolloff  = 8
o.completeopt    = { "menuone", "noselect" }

-- filetype-specific indent (Python — 4, Rust — 4, Lua/JSON/YAML — 2)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "json", "yaml", "yml", "toml", "html", "css", "js", "ts" },
  callback = function() vim.opt_local.shiftwidth = 2; vim.opt_local.tabstop = 2 end,
})

-- --------- keymaps -----------------------------------------------------------
local m = vim.keymap.set

m("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
m("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
m("n", "<Esc>",     "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })

-- window nav (без <C-w>)
m("n", "<C-h>", "<C-w>h")
m("n", "<C-j>", "<C-w>j")
m("n", "<C-k>", "<C-w>k")
m("n", "<C-l>", "<C-w>l")

-- сохранять положение курсора на страничных прыжках
m("n", "<C-d>", "<C-d>zz")
m("n", "<C-u>", "<C-u>zz")
m("n", "n", "nzzzv")
m("n", "N", "Nzzzv")

-- визуально двигать строки
m("v", "J", ":m '>+1<cr>gv=gv")
m("v", "K", ":m '<-2<cr>gv=gv")

-- в visual mode оставаться после > <
m("v", ">", ">gv")
m("v", "<", "<gv")

-- быстрый выход из terminal
m("t", "<Esc><Esc>", [[<C-\><C-n>]])

-- --------- lazy.nvim bootstrap ----------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- --------- look --------------------------------------------------------------
o.background    = "light"       -- "dark" → charcoal paper
o.fillchars     = { eob = " ", vert = "│", fold = " " }
o.showmode      = false         -- mode is in the statusline
o.laststatus    = 3
o.pumheight     = 10
vim.cmd.colorscheme("paper")

require("lazy").setup("plugins", {
  install = { colorscheme = { "paper" } },
  change_detection = { notify = false },
  ui = { border = "rounded", backdrop = 100 },
})

require("paper.t").setup()          -- :T, <leader>t…  — задачи из `t`
require("paper.dashboard").setup()  -- стартовый экран
