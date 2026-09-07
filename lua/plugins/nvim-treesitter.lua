return {
  "nvim-treesitter/nvim-treesitter",
  -- 2025年以降の main branch は新APIのため endwise/autotag が非対応。
  -- legacy の master branch に固定して互換性を維持する
  branch = "master",
  build = ":TSUpdate",
  -- 最初のバッファの FileType より前にロードする必要がある
  -- （endwise/autotag/hl が1バッファ目から有効になる）
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    -- treesitter のカスタムモジュールとして動作するため deps に置く
    "RRethy/nvim-treesitter-endwise",
    -- v2以降は standalone setup 形式（treesitter module は廃止済み）
    { "windwp/nvim-ts-autotag", opts = {} },
  },
  -- opts に設定内容を書くと、内部で自動的に setup() を呼んでくれます
  opts = {
    ensure_installed = {
      "ruby",
      "embedded_template",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "javascript",
      "typescript",
      "python",
      "go",
    },
    highlight = { enable = true },
    indent = { enable = true },
    -- endwise / autotag は各プラグインが FileType autocmd 経由で
    -- 自前 attach するため、ここに module 設定は不要
  },
  -- optsを使う場合、config関数の記述は不要（省略可能）になります
}
