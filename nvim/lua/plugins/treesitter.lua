return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash", "c", "cpp", "css", "diff", "dockerfile", "git_config",
        "gitcommit", "gitignore", "go", "html", "javascript", "json",
        "lua", "luadoc", "make", "markdown", "markdown_inline", "python",
        "query", "regex", "rust", "toml", "tsx", "typescript", "vim",
        "vimdoc", "yaml",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          node_decremental = "<bs>",
        },
      },
    },
  },
}
