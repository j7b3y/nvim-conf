-- VSCode 風レイアウトの支援設定
-- ・エディタ領域は最大2分割
-- ・ウィンドウ間移動を Ctrl+hjkl で
-- ・分割系キーマップ

-- ==============================
-- エディタ領域の最大分割数を強制
-- （フロート/ターミナル/quickfix等はカウントしない）
-- ==============================
vim.g.max_editor_windows = 2

local function editor_windows()
  local n = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      local buf = vim.api.nvim_win_get_buf(win)
      local is_float = cfg.relative ~= "" or cfg.external
      local is_editor = vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
      if not is_float and is_editor then
        n = n + 1
      end
    end
  end
  return n
end

vim.api.nvim_create_autocmd("WinNew", {
  group = vim.api.nvim_create_augroup("UserMaxSplits", { clear = true }),
  callback = function()
    -- ウィンドウの確定後に判定する
    vim.defer_fn(function()
      if editor_windows() <= (vim.g.max_editor_windows or 2) then
        return
      end
      local cur = vim.api.nvim_get_current_win()
      if not vim.api.nvim_win_is_valid(cur) then
        return
      end
      local cfg = vim.api.nvim_win_get_config(cur)
      if cfg.relative == "" then
        vim.notify("エディタは最大 " .. (vim.g.max_editor_windows or 2) .. " 分割までです", vim.log.levels.WARN)
        pcall(vim.api.nvim_win_close, cur, true)
      end
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
-- VSCode 風の分割キー
-- ==============================
vim.keymap.set("n", "<leader>|", "<cmd>vsplit<CR>", { silent = true, desc = "左右に分割" })
vim.keymap.set("n", "<leader>-", "<cmd>split<CR>", { silent = true, desc = "上下に分割" })
vim.keymap.set("n", "<leader>w=", "<C-w>=", { silent = true, desc = "ウィンドウ幅を均等化" })
vim.keymap.set("n", "<leader>wd", "<C-w>q", { silent = true, desc = "ウィンドウを閉じる" })

-- ==============================
-- ターミナル（下部パネル）の操作性
-- ==============================
-- ターミナルモードからも jk / Esc で抜ける（shell 内の Esc は jk で回避）
vim.keymap.set("t", "jk", "<C-\\><C-n>", { silent = true, desc = "ターミナルからノーマルモードへ" })
