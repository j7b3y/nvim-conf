return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    { "mason-org/mason-lspconfig.nvim", opts = { ensure_installed = { "lua_ls", "ts_ls", "solargraph", "gopls" } } },
    -- LSP capabilities (snippet 対応等) を cmp 経由で付与する
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    -- Neovim 0.11+ の新API (vim.lsp.config / vim.lsp.enable) を使用。
    -- 旧 require("lspconfig") / mason-lspconfig handlers は廃止済み。
    local servers = { "lua_ls", "ts_ls", "solargraph", "gopls" }

    -- nvim-cmp の capabilities（snippet 等）を全サーバーへ適用
    vim.lsp.config("*", {
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
    })

    -- solargraph は bundler 管理下で起動し、診断/補完/整形を有効化
    vim.lsp.config("solargraph", {
      cmd = { "bundle", "exec", "solargraph", "stdio" },
      settings = {
        solargraph = {
          diagnostics = true,
          completion = true,
          formatting = true,
        },
      },
    })

    for _, server in ipairs(servers) do
      vim.lsp.enable(server)
    end

    vim.diagnostic.config({})

    -- LSP がアタッチされたバッファでのみ有効なキーマップ
    -- （README.md「コードを読む・定義へジャンプ」と対応）
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
      callback = function(ev)
        local opts = function(desc)
          return { buffer = ev.buf, desc = desc }
        end
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("定義へジャンプ"))
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("宣言へジャンプ"))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("実装へジャンプ"))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("参照一覧"))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("ホバーでドキュメント表示"))
        -- rename は Neovim 標準の grn、コードアクションは gra を使用
      end,
    })
  end,
}
