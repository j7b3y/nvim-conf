return {
  'akinsho/toggleterm.nvim',
  version = '*', -- Use the latest version
  lazy = true,
  keys = { [[<C-\>]] },
  config = function()
    require('toggleterm').setup({
      -- your configuration comes here
      -- size can be specified as percentage or fixed number
      size = 15, -- VSCode の下部パネル相当
      open_mapping = [[<C-\>]], -- mapping to toggle the terminal
      direction = 'horizontal', -- direction of the terminal (horizontal, vertical, float)
      shade_terminals = true,
      hide_numbers = true,
      insert_mappings = true, -- go into insert mode once the terminal is open
      terminal_mappings = true, -- allows mappings in terminal mode
      start_in_insert = true,
      close_on_exit = true, -- close the terminal window when the process exits
      -- other options can be found in the github readme
    })
    -- lazygit 用の float terminal は lazygit 未導入環境(SSH)では
    -- エラーになるため削除。lazygit を使う場合は <leader>lg を利用
  end,
}
