return {
  {
    "lervag/vimtex",
    -- vimtex sets itself up on filetype detection, lazy loading breaks it
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
  },
}
