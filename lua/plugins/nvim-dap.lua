return {
  "mfussenegger/nvim-dap",
  -- デバッグ開始時のみロード（:Dap コマンド群で起動）
  cmd = {
    "DapToggleBreakpoint",
    "DapContinue",
    "DapDisconnect",
    "DapStepInto",
    "DapStepOver",
    "DapStepOut",
    "DapTerminate",
  },
  dependencies = {
    "leoluz/nvim-dap-go",
    "jay-babu/mason-nvim-dap.nvim",
  },
  config = function()
    require("mason-nvim-dap").setup({
      ensure_installed = { "delve" },
    })
    require("dap-go").setup()
  end,
}
