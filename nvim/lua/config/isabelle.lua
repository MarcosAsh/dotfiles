-- Isabelle: .ML files are Standard ML (Neovim leaves them undetected, and `.ml` is OCaml),
-- .thy files get the small syntax in syntax/isabelle.vim. Isabelle symbols such as \<forall>
-- are shown as Unicode (after/syntax/isabelle_symbols.vim); the file itself is unchanged.
vim.filetype.add({
  extension = { ML = "sml", thy = "isabelle" },
  filename = { ROOT = "isabelle", ROOTS = "conf" },
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("isabelle_conceal", { clear = true }),
  pattern = { "sml", "isabelle" },
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = ""
    vim.opt_local.commentstring = "(* %s *)"
  end,
})
