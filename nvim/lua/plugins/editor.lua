return {
  -- ---------- подсветка / синтаксис ------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",  -- новая ветка main ломает require('nvim-treesitter.configs')
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "python", "rust", "lua", "vim", "vimdoc", "bash",
        "json", "toml", "yaml", "markdown", "markdown_inline",
        "html", "css", "javascript", "typescript",
      },
      highlight = { enable = true },
      indent    = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<C-space>",
          node_incremental  = "<C-space>",
          node_decremental  = "<bs>",
          scope_incremental = false,
        },
      },
    },
  },

  -- автопарные скобки/кавычки
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- gcc/gc для комментов
  { "numToStr/Comment.nvim", event = { "BufReadPost", "BufNewFile" }, opts = {} },

  -- ---------- форматирование при сохранении ----------------------------------
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
        rust   = { "rustfmt" },
        lua    = { "stylua" },
        json   = { "prettier" },
        yaml   = { "prettier" },
        markdown = { "prettier" },
      },
      format_on_save = { timeout_ms = 800, lsp_fallback = true },
    },
  },

  -- показывает какие клавиши доступны по <leader>
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { preset = "modern" },
  },
}
