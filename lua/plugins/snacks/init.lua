-- VSCode 風サイドバー（左エクスプローラー）のトグル
local function toggle_explorer()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "snacks_picker_list" then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  Snacks.explorer({ cwd = Snacks.git.get_root() })
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = require("plugins.snacks.dashboard"),
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    -- SSH/CLI 環境では画像表示(ueberzugpp等)が使えないため無効
    image = { enabled = false },
    picker = {
      enabled = true,
      input = {
        keys = {
          -- 旧 telescope の <C-j>/<C-k> 操作を移植
          ["<C-j>"] = { "list_down", mode = { "i", "n" } },
          ["<C-k>"] = { "list_up", mode = { "i", "n" } },
        },
      },
    },
  },
  keys = {
    { "<leader>z",  function() Snacks.zen.zoom() end,           desc = "Toggle Zoom" },
    { "<leader>gB", function() Snacks.gitbrowse() end,          desc = "Git Browse (GitHub)" },
    { "<leader>gg", function() Snacks.lazygit() end,            desc = "Lazygit" },
    { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "[[",         function() Snacks.words.jump(-1) end,       desc = "Prev Reference" },
    { "]]",         function() Snacks.words.jump(1) end,        desc = "Next Reference" },
    { "<leader>sf", function() Snacks.picker.files() end,       desc = "Find Files" },
    { "<leader>sg", function() Snacks.picker.grep() end,        desc = "Grep" },
    { "<leader>e", toggle_explorer,                              desc = "エクスプローラー(サイドバー)開閉" },
    { "<leader>gS", function() Snacks.picker.git_status() end,  desc = "Git Status (Source Control)" },
    -- 旧 telescope のキーマップを snacks.picker に移植
    { "<leader>ff", function() Snacks.picker.files() end,       desc = "Find Files" },
    { "<leader>fg", function() Snacks.picker.grep() end,        desc = "Live Grep" },
    { "<leader>fb", function() Snacks.picker.buffers() end,     desc = "Buffers" },
    { "<leader>fh", function() Snacks.picker.help() end,        desc = "Help Tags" },
    { "<leader>gs", function() Snacks.picker.git_files() end,   desc = "Git Files" },
  },
}
