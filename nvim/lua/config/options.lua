local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8

opt.splitright = true
opt.splitbelow = true

opt.undofile = true
opt.swapfile = false
opt.backup = false

opt.updatetime = 250
opt.timeoutlen = 400

opt.clipboard = "unnamedplus"

opt.list = true
opt.listchars = { tab = "> ", trail = "-", nbsp = "+" }

opt.inccommand = "split"

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Autosave: write the buffer whenever you leave insert mode, switch buffer, or
-- the terminal loses focus. `update` only writes if the buffer is actually
-- modified. Skips unnamed and special buffers. Not on TextChanged, since that
-- writes after every `x` or `dd` and keeps file watchers rebuilding.
-- vim.b.autosaving tells conform to skip format on save, so code only gets
-- reformatted on an explicit :w.
vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "FocusLost" }, {
  group = vim.api.nvim_create_augroup("autosave", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or vim.bo[buf].readonly then return end
    if vim.api.nvim_buf_get_name(buf) == "" then return end
    vim.b[buf].autosaving = true
    vim.api.nvim_buf_call(buf, function() vim.cmd("silent! update") end)
    vim.b[buf].autosaving = false
  end,
})
