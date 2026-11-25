return {
  -- цветовая схема: colors/paper.lua и colors/concoctis.lua свои, gruvbox — этот плагин
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    cond = function() return require("paper.theme").colors == "gruvbox" end,
    config = function()
      require("gruvbox").setup({
        contrast = "",
        italic = { strings = false, emphasis = true, comments = true, operators = false, folds = true },
        overrides = {
          SignColumn  = { bg = "#282828" },
          PaperArt    = { fg = "#928374" },
          PaperTitle  = { fg = "#ebdbb2", bold = true },
          PaperDim    = { fg = "#928374" },
          PaperKey    = { fg = "#fabd2f", bold = true },
          PaperAccent = { fg = "#fe8019" },
        },
      })
      vim.cmd.colorscheme("gruvbox")
    end,
  },

  -- ---------- статусбар: тихая строка в палитре темы --------------------------
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local colors = require("paper.theme").colors
      local gruvbox = colors == "gruvbox"
      local dark = vim.o.background == "dark"
      local c = colors == "concoctis" and { bg = "#171819", fg = "#a89984", dim = "#928374", ink = "#d4be98", blue = "#d8a657", green = "#a9b665", red = "#ea6962", yellow = "#e78a4e" }
             or gruvbox and { bg = "#3c3836", fg = "#d5c4a1", dim = "#928374", ink = "#ebdbb2", blue = "#fabd2f", green = "#b8bb26", red = "#fb4934", yellow = "#fe8019" }
             or dark and { bg = "#222220", fg = "#a8a8a2", dim = "#6b6b67", ink = "#d6d6d0", blue = "#7c8fc4", green = "#7fa37c", red = "#c46f66", yellow = "#c4a15c" }
             or { bg = "#f6f6f3", fg = "#55554f", dim = "#8c8c88", ink = "#2f2f2f", blue = "#5b6fa8", green = "#5e8a5c", red = "#b5584e", yellow = "#a5803a" }
      local mode = function(col) return { a = { fg = col, bg = c.bg, gui = "bold" }, b = { fg = c.fg, bg = c.bg }, c = { fg = c.dim, bg = c.bg } } end
      return {
        options = {
          theme = {
            normal = mode(c.ink), insert = mode(c.blue), visual = mode(c.green),
            replace = mode(c.red), command = mode(c.yellow), terminal = mode(c.blue),
            inactive = mode(c.dim),
          },
          icons_enabled = false,
          section_separators = "",
          component_separators = "",
          globalstatus = true,
          refresh = { statusline = 5000 },
        },
        sections = {
          lualine_a = { { "mode", fmt = function(s) return s:lower() end } },
          lualine_b = { { "branch", fmt = function(s) return s ~= "" and ("git:" .. s) or s end } },
          lualine_c = { { "filename", path = 1, symbols = { modified = " ●", readonly = " ro", unnamed = "[новый]" } } },
          lualine_x = {
            { "diagnostics", symbols = { error = "✘ ", warn = "▲ ", info = "● ", hint = "○ " } },
            { function() return require("paper.t").status() end, color = { fg = c.blue } },
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { { "location", color = { fg = c.dim, bg = c.bg } } },
        },
      }
    end,
  },

  -- ---------- файловое дерево (ASCII, без иконок) ----------------------------
  {
    "nvim-tree/nvim-tree.lua",
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>",    desc = "Toggle tree" },
      { "<leader>o", "<cmd>NvimTreeFindFile<cr>",  desc = "Find file in tree" },
    },
    opts = {
      view = { width = 34, side = "left" },
      renderer = {
        indent_markers = { enable = true },
        group_empty = true,
        icons = {
          show = { file = false, folder = false, folder_arrow = true, git = true, modified = false },
          glyphs = {
            folder = { arrow_closed = "›", arrow_open = "⌄" },
            git = {
              unstaged = "M", staged = "S", untracked = "?",
              renamed = "R", deleted = "D", unmerged = "!", ignored = "•",
            },
          },
        },
      },
      filters = { dotfiles = false, custom = { "^\\.git$", "__pycache__", "\\.venv", "node_modules", "target" } },
      git     = { ignore = false },
      actions = { open_file = { quit_on_open = false } },
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
  },

  -- ---------- fuzzy finder ---------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      -- VSCode-style: Ctrl+P — файлы, Ctrl+Shift+F — grep по проекту
      { "<C-p>",      "<cmd>Telescope find_files<cr>",           desc = "Fuzzy find files" },
      { "<C-f>",      "<cmd>Telescope live_grep<cr>",            desc = "Fuzzy grep" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>",           desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",            desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",              desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>",             desc = "Recent files" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",            desc = "Help" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>",          desc = "Diagnostics" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>",              desc = "Keymaps" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "%.git/", "__pycache__/", "node_modules/", "target/", "%.venv/", "env/" },
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
      },
    },
  },

  -- ---------- git-подсветка в gutter -----------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local kmap = function(k, f, d) vim.keymap.set("n", k, f, { buffer = bufnr, desc = d }) end
        kmap("]c", function() gs.nav_hunk("next") end, "Next git hunk")
        kmap("[c", function() gs.nav_hunk("prev") end, "Prev git hunk")
        kmap("<leader>gs", gs.stage_hunk,          "Stage hunk")
        kmap("<leader>gr", gs.reset_hunk,          "Reset hunk")
        kmap("<leader>gp", gs.preview_hunk,        "Preview hunk")
        kmap("<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
      end,
    },
  },
}
