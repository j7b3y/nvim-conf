-- clone 後の初回 nvim 起動時に lazygit を ~/.local/bin へ自動導入する。
-- システム領域には一切触れず、各ディストリ共通で動く静的バイナリを利用する。

local VERSION = "0.65.0"
local bin_dir = vim.fn.expand("~/.local/bin")
local bin = bin_dir .. "/lazygit"

-- nvim 内の PATH に ~/.local/bin を優先的に追加（システムの PATH は変更しない）
vim.env.PATH = bin_dir .. ":" .. (vim.env.PATH or "")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "lazygit bootstrap" })
end

function M.ensure()
  if vim.fn.executable("lazygit") == 1 or vim.fn.executable(bin) == 1 then
    return
  end
  if vim.fn.executable("curl") == 0 or vim.fn.executable("tar") == 0 then
    return
  end

  local uname = vim.uv.os_uname()
  local sysname = uname.sysname:lower()
  if sysname ~= "linux" and sysname ~= "darwin" then
    return
  end
  local os_label = sysname == "linux" and "Linux" or "Darwin"
  local arch = ({ x86_64 = "x86_64", aarch64 = "arm64", armv7l = "armv6" })[uname.machine]
  if not arch then
    return
  end

  local url = ("https://github.com/jesseduffield/lazygit/releases/download/v%s/lazygit_%s_%s_%s.tar.gz")
    :format(VERSION, VERSION, os_label, arch)
  local tmp = vim.fn.tempname()

  vim.system({ "curl", "-fL", "--retry", "2", "-o", tmp, url }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        notify("ダウンロードに失敗しました（lazygitは手動で導入してください）\n" .. (res.stderr or ""), vim.log.levels.WARN)
        vim.fn.delete(tmp)
        return
      end
      vim.system({ "tar", "-xzf", tmp, "-C", vim.fn.fnamemodify(tmp, ":h") }, {}, function(r)
        vim.schedule(function()
          vim.fn.delete(tmp)
          if r.code ~= 0 then
            notify("展開に失敗しました", vim.log.levels.WARN)
            return
          end
          vim.fn.mkdir(bin_dir, "p")
          local extracted = vim.fn.fnamemodify(tmp, ":h") .. "/lazygit"
          if vim.fn.rename(extracted, bin) ~= 0 then
            notify("インストールに失敗しました", vim.log.levels.WARN)
            return
          end
          vim.fn.system({ "chmod", "+x", bin })
          notify("lazygit v" .. VERSION .. " を導入しました: " .. bin)
        end)
      end)
    end)
  end)
end

-- 起動後に非同期で導入（起動時間に影響しない）
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("UserLazygitBootstrap", { clear = true }),
  once = true,
  callback = function()
    M.ensure()
  end,
})

return M
