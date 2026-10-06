-- Isabelle through its own language server (isabelle vscode_server): the prover colours
-- terms the way jEdit does (free, bound, skolem variables, ...), shows errors as
-- diagnostics, and the output panel shows the proof state at the cursor.
-- The first .thy file opened starts the server, which loads the HOL image (a few seconds).
return {
  {
    "Treeniks/isabelle-lsp.nvim",
    ft = "isabelle",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      -- jEdit's convention: free variables blue, bound green, skolem constants orange,
      -- schematic variables purple (colours from tokyonight)
      local colors = {
        IsabelleFree = { fg = "#7aa2f7" },
        IsabelleBound = { fg = "#9ece6a" },
        IsabelleSkolem = { fg = "#ff9e64" },
        IsabelleVar = { fg = "#bb9af7" },
        IsabelleRunning = { bg = "#3b3052" },
        IsabelleBad = { bg = "#4a2530" },
      }
      local function set_colors()
        for group, spec in pairs(colors) do vim.api.nvim_set_hl(0, group, spec) end
      end
      set_colors()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_colors })

      require("isabelle-lsp").setup({
        isabelle_path = vim.fn.exepath("isabelle"),
        vsplit = true,
        unicode_symbols_output = true,
        hl_group_map = {
          text_free = "IsabelleFree",
          text_bound = "IsabelleBound",
          text_skolem = "IsabelleSkolem",
          text_var = "IsabelleVar",
          text_inner_numeral = "Number",
          text_inner_cartouche = "String",
          background_running1 = "IsabelleRunning",
          background_bad = "IsabelleBad",
        },
      })
      vim.lsp.enable("isabelle")
    end,
  },
}
