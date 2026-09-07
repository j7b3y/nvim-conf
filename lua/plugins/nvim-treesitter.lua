return {
  "nvim-treesitter/nvim-treesitter",
  -- 2025年以降の main branch は新APIのため互換プラグインが非対応。
  -- legacy の master branch に固定して互換性を維持する
  branch = "master",
  build = ":TSUpdate",
  -- 最初のバッファの FileType より前にロードする必要がある
  -- （ハイライト等が1バッファ目から有効になる）
  event = { "BufReadPre", "BufNewFile" },
  -- Neovim 0.12 との互換シムを適用してから setup
  config = function(_, opts)
    require("config.treesitter_compat").apply()
    require("nvim-treesitter.configs").setup(opts)
  end,
  opts = {
    -- 汎用セット（nvim 自身の動作とドキュメント閲覧に必要な分のみ）。
    -- 各言語のパーサーが必要になったらここに追加（例: "ruby", "go", "typescript"）
    ensure_installed = {
      "lua",
      "vim",
      "vimdoc",
      "query",
      "markdown",
      "markdown_inline",
      "bash",
      "regex",
    },
    highlight = { enable = true },
    indent = { enable = true },
  },
}
