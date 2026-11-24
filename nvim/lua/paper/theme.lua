-- paper.theme — which palette to use, from THEME= in ~/.config/paper/config ("paper" | "gruvbox").
local M = { name = "paper" }

local cfg = vim.fn.expand("~/.config/paper/config")
if vim.fn.filereadable(cfg) == 1 then
  for _, line in ipairs(vim.fn.readfile(cfg)) do
    local v = line:match('^%s*THEME%s*=%s*"?([%w_-]+)"?')
    if v then M.name = v end
  end
end

M.dark = M.name == "gruvbox"
return M
