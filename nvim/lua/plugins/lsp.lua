return {
  -- ---------- автодополнение (blink.cmp) -------------------------------------
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      -- спокойный режим: меню само не всплывает
      --   <C-space> — показать варианты; <Tab>/<S-Tab> — навигация;
      --   <CR> — принять; <C-e> — закрыть; <C-k> — документация
      keymap = {
        preset = "enter",
        ["<Tab>"]   = { "select_next", "snippet_forward",  "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<C-k>"]   = { "show_documentation", "hide_documentation", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        keyword = { range = "prefix" },
        trigger = {
          show_on_keyword = false,
          show_on_trigger_character = false,
          show_on_insert_on_trigger_character = false,
        },
        menu = {
          auto_show = false,
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
          },
        },
        documentation = {
          auto_show = false,
          window = { border = "rounded" },
        },
        list = { selection = { preselect = true, auto_insert = false } },
        accept = { auto_brackets = { enabled = true } },
        ghost_text = { enabled = false },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      snippets = { preset = "luasnip" },
    },
  },

  -- ---------- LSP: nvim 0.11+ API (vim.lsp.config) ---------------------------
  { "williamboman/mason.nvim", cmd = "Mason", opts = {} },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- capabilities от blink.cmp — прокидываем в каждый server явно,
      -- чтобы deep-merge в vim.lsp.config не пропустил
      local caps = require("blink.cmp").get_lsp_capabilities()

      -- Python: pyright — типы/hover, ruff — линт/формат
      vim.lsp.config("pyright", {
        capabilities = caps,
        settings = {
          python = {
            analysis = {
              typeCheckingMode       = "basic",
              diagnosticMode         = "openFilesOnly",
              autoImportCompletions  = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      })
      vim.lsp.config("ruff", {
        capabilities = caps,
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      })

      -- Rust
      vim.lsp.config("rust_analyzer", {
        capabilities = caps,
        settings = {
          ["rust-analyzer"] = {
            check              = { command = "clippy" },
            cargo              = { allFeatures = true, loadOutDirsFromCheck = true },
            procMacro          = { enable = true },
            completion         = {
              autoimport      = { enable = true },
              postfix         = { enable = true },
              privateEditable = { enable = false },
              fullFunctionSignatures = { enable = true },
            },
            imports = { granularity = { group = "module" } },
            checkOnSave = true,
          },
        },
      })

      -- Lua (правка конфига)
      vim.lsp.config("lua_ls", {
        capabilities = caps,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace   = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
            telemetry   = { enable = false },
          },
        },
      })

      -- mason ставит серверы (ruff не через mason — он ставится как standalone
      -- бинарь в ~/.local/bin, чтобы обойти python3-venv sudo-требование)
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "rust_analyzer", "lua_ls" },
        automatic_enable = true,
      })
      -- ruff — из системного PATH
      if vim.fn.executable("ruff") == 1 then
        vim.lsp.enable("ruff")
      end

      -- LSP-кеймапы по факту подключения
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(k, f, d) vim.keymap.set("n", k, f, { buffer = ev.buf, desc = d }) end
          map("gd", vim.lsp.buf.definition,       "Go to definition")
          map("gD", vim.lsp.buf.declaration,      "Go to declaration")
          map("gr", vim.lsp.buf.references,       "References")
          map("gi", vim.lsp.buf.implementation,   "Implementation")
          map("gt", vim.lsp.buf.type_definition,  "Type definition")
          map("K",  vim.lsp.buf.hover,            "Hover doc")
          map("<leader>rn", vim.lsp.buf.rename,       "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action,  "Code action")
          map("[d", vim.diagnostic.goto_prev,     "Prev diagnostic")
          map("]d", vim.diagnostic.goto_next,     "Next diagnostic")
          map("<leader>d", vim.diagnostic.open_float, "Show diagnostic")
        end,
      })

      vim.diagnostic.config({
        virtual_text  = { prefix = "●" },
        severity_sort = true,
        float         = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN]  = "▲",
            [vim.diagnostic.severity.INFO]  = "●",
            [vim.diagnostic.severity.HINT]  = "○",
          },
        },
      })
    end,
  },
}
