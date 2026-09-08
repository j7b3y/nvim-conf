return {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    options = {
      -- 画面最下部に1本化。横の窓境が WinSeparator(白線)になる
      globalstatus = true,
    },
    sections = {
      -- 他セクションは既定のまま。lualine_a のみ上書きされる
      lualine_a = {
        {
          'mode',
          -- opencode窓ではモード名を AGENT と表示する(色付けはmodeのまま)
          fmt = function(s)
            if vim.api.nvim_get_current_buf() == require('config.opencode_term').opencode_buf() then
              return 'AGENT'
            end
            return s
          end,
        },
      },
    },
  },
}
