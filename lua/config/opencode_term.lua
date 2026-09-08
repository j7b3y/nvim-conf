-- シェル(TERMINAL)とopencode専用画面(OPENCODE)の自前管理
-- toggletermの共有状態だと操作回数を重ねるごとにサイズ・開閉対象がずれるため、
-- バッファ・窓・配置をスロットごとに個別保持し、他方へ絶対に触れない。
-- 配置は固定:
--   シェル    : 右カラム全高(約40%幅)
--   opencode  : 下部(エディタの下。高さ20行)
-- 開くたびにサイズを掛け直すため、手動リサイズ後も次回開閉で仕様に戻る。
local M = {}

local SHELL_WIDTH_RATIO = 0.4
local OPENCODE_HEIGHT = 20

-- ターミナル窓の視認性: ベースより少し明るい背景 + 白い境界線
-- (エディタ側は透明のまま。colorscheme再読込に追従させる)
local function lighten(hex, amt)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  if not (r and g and b) then return hex end
  local function up(v)
    return math.floor(v + (255 - v) * amt + 0.5)
  end
  return string.format("#%02x%02x%02x", up(r), up(g), up(b))
end

local function apply_highlights()
  local base = "#1a1b26" -- tokyonight night の bg。取得できなければこれを使う
  local ok, tc = pcall(require, "tokyonight.colors")
  if ok and tc.setup then
    local pal_ok, pal = pcall(tc.setup)
    if pal_ok and type(pal) == "table" and pal.bg then
      base = pal.bg
    end
  end
  vim.api.nvim_set_hl(0, "TermBright", { bg = lighten(base, 0.12) })
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ffffff", bg = "NONE" })
end

local slots = {
  shell = { cmd = vim.o.shell, name = "TERMINAL", buf = nil, win = nil, prev = nil },
  opencode = { cmd = "opencode", name = "OPENCODE", buf = nil, win = nil, prev = nil },
}

local function has_opencode()
  return vim.fn.executable("opencode") == 1
end

local function is_open(slot)
  return slot.win ~= nil and vim.api.nvim_win_is_valid(slot.win)
end

-- プロセス終了時は窓を畳み、スロットを捨てて次回まっさら作り直す
local function on_term_close(key)
  return vim.schedule_wrap(function()
    local slot = slots[key]
    if not slot then return end
    if is_open(slot) then
      pcall(vim.api.nvim_win_close, slot.win, true)
    end
    if slot.buf and vim.api.nvim_buf_is_valid(slot.buf) then
      pcall(vim.api.nvim_buf_delete, slot.buf, { force = true })
    end
    slot.buf, slot.win, slot.prev = nil, nil, nil
  end)
end

local function ensure_buf(key)
  local slot = slots[key]
  if slot.buf and vim.api.nvim_buf_is_valid(slot.buf) then
    return slot.buf
  end
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_create_autocmd("TermClose", { buffer = buf, callback = on_term_close(key) })
  -- ジョブの起動(termopen)は窓を開いてから行う。ここでは器だけ用意する。
  slot.buf = buf
  return buf
end

-- 上部の通常窓(エディタ)を1つ返す。無ければカレント
local function editor_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(w) then
      local cfg = vim.api.nvim_win_get_config(w)
      local buf = vim.api.nvim_win_get_buf(w)
      if cfg.relative == "" and vim.bo[buf].buftype == "" then
        return w
      end
    end
  end
  return vim.api.nvim_get_current_win()
end

local function decorate(win, name)
  pcall(vim.api.nvim_set_option_value, "number", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "relativenumber", false, { win = win })
  pcall(vim.api.nvim_set_option_value, "winbar", " " .. name .. " ", { win = win })
  -- 窓だけ少し明るくする(エディタは透明のまま)
  pcall(vim.api.nvim_set_option_value, "winhighlight", "Normal:TermBright", { win = win })
end

local function open_shell()
  local slot = slots.shell
  if is_open(slot) then return end
  local buf = ensure_buf("shell")
  slot.prev = vim.api.nvim_get_current_win()
  -- タブ全体の右に分割 → 常に右カラム全高になる(フォーカス位置に依存しない)
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  if vim.bo[buf].buftype ~= "terminal" then
    -- 通常の ~/.zshrc で起動する
    local job = vim.fn.termopen(slot.cmd)
    if not job or job <= 0 then
      vim.notify("シェルの起動に失敗しました", vim.log.levels.ERROR)
      pcall(vim.api.nvim_win_close, win, true)
      return
    end
  end
  vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * SHELL_WIDTH_RATIO))
  slot.win = win
  decorate(win, slot.name)
  pcall(vim.cmd, "startinsert")
end

local function open_opencode()
  local slot = slots.opencode
  if is_open(slot) then return end
  local buf = ensure_buf("opencode")
  slot.prev = vim.api.nvim_get_current_win()
  -- エディタ起点で下に分割 → 常にエディタ下になる
  -- (素の split は上に開く。botright は右シェルの幅まで奪うため使わない)
  vim.api.nvim_set_current_win(editor_win())
  vim.cmd("belowright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  if vim.bo[buf].buftype ~= "terminal" then
    local job = vim.fn.termopen(slot.cmd)
    if not job or job <= 0 then
      vim.notify("opencodeの起動に失敗しました", vim.log.levels.ERROR)
      pcall(vim.api.nvim_win_close, win, true)
      return
    end
  end
  vim.api.nvim_win_set_height(win, OPENCODE_HEIGHT)
  slot.win = win
  decorate(win, slot.name)
  pcall(vim.cmd, "startinsert")
end

local function close_slot(slot)
  if not is_open(slot) then return end
  local win = slot.win
  slot.win = nil
  pcall(vim.api.nvim_win_close, win, true)
  -- 閉じる前の窓へフォーカスを戻す(有効な場合のみ)
  if slot.prev and vim.api.nvim_win_is_valid(slot.prev) then
    pcall(vim.api.nvim_set_current_win, slot.prev)
  end
  slot.prev = nil
end

local function slot_of_win(win)
  for _, slot in pairs(slots) do
    if slot.win == win then return slot end
  end
  -- 窓IDが古い場合に備え、バッファでも照合する
  if vim.api.nvim_win_is_valid(win) then
    local buf = vim.api.nvim_win_get_buf(win)
    for _, slot in pairs(slots) do
      if slot.buf == buf then return slot end
    end
  end
  return nil
end

-- 右カラム全高に汎用シェルを開閉(シェルにしか触れない)
function M.toggle_shell()
  if is_open(slots.shell) then
    close_slot(slots.shell)
  else
    open_shell()
  end
end

-- 下部にopencodeを開閉(opencodeにしか触れない。実行環境必須)
function M.toggle_opencode()
  if not has_opencode() then
    vim.notify("opencode CLIが見つかりません。https://github.com/sst/opencode から導入してください", vim.log.levels.WARN)
    return
  end
  if is_open(slots.opencode) then
    close_slot(slots.opencode)
  else
    open_opencode()
  end
end

-- フォーカス中の自前ターミナルだけを閉じる(ターミナルモードの Ctrl+\ 用)
-- 自前窓でなければシェルを開く。いずれも他方には触れない。
function M.toggle_focused()
  local slot = slot_of_win(vim.api.nvim_get_current_win())
  if slot then
    close_slot(slot)
  else
    M.toggle_shell()
  end
end

-- opencodeスロットのバッファ番号(無効ならnil)。lualineのAGENT表示用
function M.opencode_buf()
  local buf = slots.opencode.buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    return buf
  end
  return nil
end

function M.setup()
  apply_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("OpencodeTermHl", { clear = true }),
    callback = apply_highlights,
  })
  vim.keymap.set({ "n", "i" }, [[<C-\>]], M.toggle_shell, { silent = true, desc = "右カラムにシェル開閉" })
  vim.keymap.set("t", [[<C-\>]], M.toggle_focused, { silent = true, desc = "フォーカス中のターミナルだけ閉じる" })
  vim.keymap.set("n", "<leader>o", M.toggle_opencode, { silent = true, desc = "opencode専用画面開閉(opencodeがある環境のみ)" })
end

return M
