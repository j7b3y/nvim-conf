-- VSCode 風レイアウトの支援設定
-- ・エディタ領域は分割なし(単一画面)
-- ・ウィンドウ間移動を Ctrl+hjkl で
-- ・リサイズ系キーマップ

-- ==============================
-- エディタ領域は単一画面に固定
-- （下部ターミナルと併用しても狭くならないよう）
-- （フロート/ターミナル/quickfix等はカウントしない）
-- ==============================
vim.g.max_editor_windows = 1

local function is_editor_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local cfg = vim.api.nvim_win_get_config(win)
  if cfg.relative ~= "" or cfg.external then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  -- ターミナル(buftype=terminal: シェル・opencodeとも)は数えない
  -- ツール系(oilは非listed、grug-far/pickerはnofile)は buftype で除外される
  return vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
end

local function editor_windows()
  local wins = {}
  -- 同一タブページ内のみ数える(別タブのdiff等を邪魔しない)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor_win(win) then
      table.insert(wins, win)
    end
  end
  return wins
end

vim.api.nvim_create_autocmd("WinNew", {
  group = vim.api.nvim_create_augroup("UserMaxSplits", { clear = true }),
  callback = function()
    -- ウィンドウの確定後に判定する
    vim.defer_fn(function()
      local eds = editor_windows()
      if #eds <= (vim.g.max_editor_windows or 1) then
        return
      end
      -- 新しい方(窓ID最大)のエディタ窓を閉じる。
      -- フォーカス中の窓を無条件に閉じると、開いたばかりのターミナル等が
      -- 身代わりに閉じられるため、ターミナルは絶対に対象にしない
      table.sort(eds)
      local target = eds[#eds]
      vim.notify("エディタは単一画面のみです", vim.log.levels.WARN)
      pcall(vim.api.nvim_win_close, target, true)
    end, 50)
  end,
})

-- ==============================
-- ウィンドウ間移動（tmux 風・CLI 向け）
-- ==============================
local nav_keys = {
  { "<C-h>", "<C-w>h", "左のウィンドウへ" },
  { "<C-j>", "<C-w>j", "下のウィンドウへ" },
  { "<C-k>", "<C-w>k", "上のウィンドウへ" },
  { "<C-l>", "<C-w>l", "右のウィンドウへ" },
}
for _, k in ipairs(nav_keys) do
  vim.keymap.set("n", k[1], k[2], { silent = true, desc = k[3] })
end

-- ==============================
-- 単一画面運用のウィンドウキー
-- (エディタ分割は使わない運用)
-- ==============================
vim.keymap.set("n", "<leader>wo", "<cmd>only<CR>", { silent = true, desc = "単一画面に戻す" })
vim.keymap.set("n", "<leader>w=", "<C-w>=", { silent = true, desc = "ウィンドウ幅を均等化" })
vim.keymap.set("n", "<leader>wd", "<C-w>q", { silent = true, desc = "ウィンドウを閉じる" })
-- ターミナル(下部パネル)の高さ調整用: 通常のウィンドウリサイズと共通
vim.keymap.set("n", "<leader>w+", "<cmd>resize +2<CR>", { silent = true, desc = "ウィンドウ高さを+2" })
vim.keymap.set("n", "<leader>w-", "<cmd>resize -2<CR>", { silent = true, desc = "ウィンドウ高さを-2" })
vim.keymap.set("n", "<leader>w>", "<cmd>vertical resize +5<CR>", { silent = true, desc = "ウィンドウ幅を+5" })
vim.keymap.set("n", "<leader>w<", "<cmd>vertical resize -5<CR>", { silent = true, desc = "ウィンドウ幅を-5" })

-- ==============================
-- ターミナル（下部パネル）の操作性
-- ==============================
-- ターミナルモードからも jk / Esc で抜ける（shell 内の Esc は jk で回避）
vim.keymap.set("t", "jk", "<C-\\><C-n>", { silent = true, desc = "ターミナルからノーマルモードへ" })
