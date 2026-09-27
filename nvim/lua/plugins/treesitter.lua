-- nvim-treesitter's main branch only installs parsers. Highlighting comes from
-- Neovim itself, so it gets switched on per buffer below. Needs the
-- tree-sitter CLI and a C compiler on PATH. Node selection is built into
-- Neovim 0.12: `van` to select a node, `an` again to grow, `in` to shrink.
local parsers = {
  "bash", "bibtex", "c", "cmake", "cpp", "css", "cuda", "diff", "dockerfile",
  "git_config", "gitcommit", "gitignore", "glsl", "go", "html", "javascript",
  "json", "lua", "luadoc", "make", "markdown", "markdown_inline", "ocaml",
  "ocaml_interface", "ocamllex", "python", "query", "regex", "rust", "toml", "tsx",
  "typescript", "systemverilog", "vim", "vimdoc", "yaml",
}

-- vimtex does its own LaTeX highlighting and gets confused by treesitter's
local skip = { latex = true }

local function attach(buf, lang)
  if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then return end
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      local task = ts.install(parsers)
      -- block in headless runs (live-setup.sh) so they don't quit mid-install
      if #vim.api.nvim_list_uis() == 0 then task:wait(900000) end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or skip[lang] then return end

          if vim.list_contains(ts.get_installed(), lang) then
            attach(ev.buf, lang)
          elseif vim.list_contains(ts.get_available(), lang) then
            -- stands in for master's auto_install
            ts.install(lang):await(function()
              vim.schedule(function() attach(ev.buf, lang) end)
            end)
          end
        end,
      })
    end,
  },
}
