---
name: nvim-verify
description: nvim設定を変更した後の検証バッテリー。lua/plugins/ や lua/config/、README、キーマップを変更したときに必ず使う。
---

# 検証バッテリー

変更後に順に実行し、**エラー・警告がゼロであること**を確認する。

## 1. プラグイン同期(依存の導入・削除の反映)

```bash
nvim --headless "+Lazy! sync" +qa 2>&1 | grep -iE "error|fail"
```

## 2. 起動・ロードエラーの確認

```bash
nvim --headless init.lua "+edit README.md" \
  "+lua vim.defer_fn(function() local m=vim.api.nvim_exec2('messages',{output=true}).output; io.stderr:write('MSG_LEN='..#m..'\n'..m..'\n'); vim.cmd('qa!') end, 8000)" 2>&1
```

`MSG_LEN=0`(または既知の情報メッセージのみ)であること。treesitter 由来の `range` エラーが出たら `lua/config/treesitter_compat.lua` の扱いを疑う。

## 3. LSP・遅延プラグインの動作

```bash
nvim --headless init.lua "+edit init.lua" \
  "+lua vim.defer_fn(function() io.stderr:write('LSP='..vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients()))..'\n'); vim.cmd('qa!') end, 8000)"
```

- 期待するサーバーだけがアタッチすること(実行環境が無いサーバーは通知付きでスキップされるのが正)。
- `package.loaded["<プラグイン>"]` や `lazy.core.config().plugins[name]._.loaded` で遅延ロードの確認も可能(※headless では VeryLazy が発火しないため、`require('lazy').load({plugins={...}})` を明示的に呼ぶ)。

## 4. 起動時間

```bash
nvim --headless -u init.lua --startuptime /tmp/st.log +qa >/dev/null 2>&1; tail -1 /tmp/st.log
```

目安: ~20ms 台(想定外に伸びた場合は eager ロードされたプラグインを疑う)。

## 5. レイアウト・分割制限

```bash
nvim --headless init.lua "+lua vim.cmd('vsplit | vsplit'); vim.defer_fn(function() io.stderr:write('wins='..#vim.api.nvim_list_wins()..'\n'); vim.cmd('qa!') end, 1200)"
```

エディタウィンドウは2つに収まること(通知用 float を除く)。
