-- paper.theme — which palette to use, from ~/.config/paper/config:
--   THEME="paper" | "gruvbox"       the whole setup (terminal, tmux, widgets, nvim)
--   NVIM_COLORS="concoctis"         optional: a different colorscheme for nvim only
--                                   (paper | gruvbox | concoctis = VS Code "gruvboxConcoctis dark hard")
local M = { name = "paper" }

local cfg = vim.fn.expand("~/.config/paper/config")
if vim.fn.filereadable(cfg) == 1 then
  for _, line in ipairs(vim.fn.readfile(cfg)) do
    local k, v = line:match('^%s*([%w_]+)%s*=%s*"?([%w_-]*)"?')
    if k == "THEME" and v ~= "" then M.name = v end
    if k == "NVIM_COLORS" and v ~= "" then M.colors = v end
  end
end

M.colors = M.colors or (M.name == "gruvbox" and "gruvbox" or "paper")
M.dark = M.colors ~= "paper" or M.name == "gruvbox"
return M
