return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonUpdate", "MasonInstall", "MasonLog" },
    opts = { ui = { border = "rounded" } },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=never",
          "--completion-style=detailed",
        },
      })

      -- stylua is only for conform to format with, not a language server
      require("mason-lspconfig").setup({ automatic_enable = { exclude = { "stylua" } } })

      require("mason-tool-installer").setup({
        ensure_installed = {
          -- language servers
          "clangd", "pyright", "ruff", "lua_ls", "bashls", "ts_ls", "texlab",
          "rust_analyzer", "gopls", "glsl_analyzer", "neocmake", "verible",
          -- formatters and debuggers. clang-format isn't here because mason
          -- builds it in a venv and python3-venv needs sudo, so it comes from
          -- `uv tool install clang-format` instead
          "stylua", "codelldb",
        },
      })

      -- ocamllsp comes from opam so it matches the OxCaml switch, not mason
      if vim.fn.executable("ocamllsp") == 1 then
        vim.lsp.enable("ocamllsp")
      end

      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "*" },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
          },
        },
        float = { border = "rounded", source = true },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(event)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
          end
          -- let pyright answer hover, ruff is only there for lint and fixes
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          map("n", "gd", vim.lsp.buf.definition, "Go to definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
          map("n", "K", vim.lsp.buf.hover, "Hover docs")
          map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
          map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
        end,
      })
    end,
  },
}
