-- Format on save through conform. Formatters that follow a project style only
-- run when that project has a config file, so upstream code like FFmpeg (no
-- .clang-format) never gets rewritten in someone else's style.
return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo", "FormatToggle" },
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        cuda = { "clang-format" },
        glsl = { "clang-format" },
        python = { "ruff_organize_imports", "ruff_format" },
        ocaml = { "ocamlformat" },
        rust = { "rustfmt" },
        go = { "gofmt" },
        lua = { "stylua" },
      },
      formatters = {
        ["clang-format"] = {
          condition = function(_, ctx)
            return #vim.fs.find({ ".clang-format", "_clang-format" }, { upward = true, path = ctx.dirname }) > 0
          end,
        },
        ruff_format = { require_cwd = true },
        ruff_organize_imports = { require_cwd = true },
        stylua = { require_cwd = true },
      },
      format_on_save = function(buf)
        if vim.g.disable_autoformat or vim.b[buf].autosaving then return end
        return { timeout_ms = 1000, lsp_format = "never" }
      end,
    },
    config = function(_, opts)
      require("conform").setup(opts)
      vim.api.nvim_create_user_command("FormatToggle", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("Format on save " .. (vim.g.disable_autoformat and "off" or "on"))
      end, { desc = "Toggle format on save" })
    end,
  },
}
