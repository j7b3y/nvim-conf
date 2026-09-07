# AGENTS.md — このリポジトリでの作業ルール(エージェント向け)

## 環境の前提

- **SSH 接続の CLI 専用リモート(kvm)環境**。GUI・ブラウザ・ローカルクリップボード(OSC52未対応)は使えない。
- **システム変更は禁止**(パッケージ追加、`/etc` 配下の変更など)。必要なツールは `~/.local/bin` や mason(`~/.local/share/nvim/mason`)、nvim の初回起動時自動導入(lazygit)で賄う。
- この kvm は作業用。成果物はリモートリポジトリに push 後、別環境へデプロイする。
- Neovim **0.12.5** / lazy.nvim。`rm` コマンドは権限で拒否されるため **`git rm` を使う**。

## ファイル構成

| パス | 役割 |
|---|---|
| `init.lua` | エントリーポイント(基本オプション・キーマップのみ) |
| `lua/config/lazy.lua` | lazy.nvim のブートストラップ |
| `lua/config/layout.lua` | VSCode風レイアウト(最大2分割・ウィンドウキー) |
| `lua/config/lazygit.lua` | lazygit 自動導入(バージョン固定) |
| `lua/config/treesitter_compat.lua` | Neovim 0.12 × nvim-treesitter(legacy master) 互換シム |
| `lua/plugins/*.lua` | プラグイン設定(1ファイル=1プラグイン。lazy.nvim が自動 import) |
| `lua/plugins/snacks/` | snacks.nvim(spec と dashboard) |

## 重要な制約・パターン

- **汎用設定を維持**: 言語固有の LSP・パーサー・ft-plugin・デバッガを追加しない。言語サポートは拡張ポイントのみ: LSP → `lua/plugins/nvim-lspconfig.lua` の `servers`、パーサー → `nvim-treesitter.lua` の `ensure_installed`、アダプタ → `nvim-dap.lua`。
- treesitter は `branch = "master"`(legacy)固定。main branch に移行するときは `treesitter_compat.lua` の扱いも見直すこと。
- lazy-loading 規約: `keys`/`cmd`/`event`/`ft` で可能な限り遅延。deps に `opts = {}` がないと setup が呼ばれない点に注意。`opts` は内部で `require(<plugin名>).setup(opts)` を呼ぶ(モジュール名と setup の互換を確認すること。過去に treesitter で `opts` が無視される事故あり)。
- LSP は実行環境チェック付き `vim.lsp.enable`(`nvim-lspconfig.lua` を踏襲)。
- コメント・`desc`・README は**日本語**で書く。既存スタイル(lazy.nvim spec 形式)に倣う。
- キーマップの追加・変更をしたら **README.md の該当行を必ず更新**。which-key のグループ名(`which-key.nvim.lua`)とも整合させる。
- `lazy-lock.json` は git 管理下・バージョン固定に使用。`:Lazy! sync` 後にコミット対象になる。

## 検証(必須)

変更後は必ず headless で検証する(詳細は `.opencode/skills/nvim-verify/SKILL.md`):

```bash
nvim --headless "+Lazy! sync" +qa                                   # プラグイン同期
nvim --headless init.lua "+edit README.md" "+lua ..."               # 起動エラー・messages 確認
nvim --headless -u init.lua --startuptime /tmp/st.log +qa           # 起動時間
```

## スキル

- `.opencode/skills/nvim-plugin-add/SKILL.md` — プラグイン追加・言語サポート拡張の手順
- `.opencode/skills/nvim-verify/SKILL.md` — 変更後の検証バッテリー
