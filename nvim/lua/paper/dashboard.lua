-- paper.dashboard — start screen when nvim opens without a file:
-- ASCII art (~/.config/paper/art.txt), date, today's open tasks from `t`, and shortcuts.
local M = {}

local MONTHS = { "января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря" }
local DAYS = { "воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота" }

local KEYS = {
  { "f", "найти файл",        "Telescope find_files" },
  { "r", "недавние",          "Telescope oldfiles" },
  { "g", "поиск по тексту",   "Telescope live_grep" },
  { "e", "дерево файлов",     "NvimTreeOpen" },
  { "t", "задачи",            "lua require('paper.t').cmd({}, 'сегодня')" },
  { "n", "новый файл",        "enew" },
  { "c", "конфиг",            "edit $MYVIMRC" },
  { "q", "выйти",             "qa" },
}

local function art()
  local path = vim.fn.expand("~/.config/paper/art.txt")
  local cfg = vim.fn.expand("~/.config/paper/config")
  if vim.fn.filereadable(cfg) == 1 then
    for _, l in ipairs(vim.fn.readfile(cfg)) do
      local v = l:match('^%s*ART="?([^"#]+)"?')
      if v then path = vim.fn.expand((v:gsub("%$HOME", "~"):gsub("%s+$", ""))) end
    end
  end
  return vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
end

local function tasks()
  if vim.fn.executable("t") ~= 1 then return {} end
  local out = vim.system({ "t" }, { text = true }):wait().stdout or ""
  local list = {}
  for line in out:gmatch("[^\n]+") do
    local mark, rest = line:match("^%s*%d+%s+%[(.)%]%s+(.*)$")
    if mark == " " or mark == "/" then table.insert(list, (mark == "/" and "▶ " or "· ") .. rest) end
  end
  return list
end

function M.open()
  local buf = vim.api.nvim_get_current_buf()
  local d = os.date("*t")
  local lines, hl = {}, {}
  local function add(text, group) table.insert(lines, text); if group then hl[#lines] = group end end

  for _, l in ipairs(art()) do add(l, "PaperArt") end
  add("")
  add(string.format("%d %s, %s · %s", d.day, MONTHS[d.month], DAYS[d.wday], os.date("%H:%M")), "PaperTitle")
  add("")
  local ts = tasks()
  if #ts > 0 then
    add("сегодня", "PaperAccent")
    for i = 1, math.min(#ts, 5) do add(ts[i], ts[i]:sub(1, 3) == "▶" and "PaperAccent" or nil) end
    if #ts > 5 then add("… и ещё " .. (#ts - 5), "PaperDim") end
  else
    add("на сегодня задач нет", "PaperDim")
  end
  add("")
  local key_start = #lines + 1
  for _, k in ipairs(KEYS) do add(string.format("%s   %s", k[1], k[2])) end

  -- center the block
  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  local left = math.max(0, math.floor((vim.o.columns - width) / 2))
  local top = math.max(0, math.floor((vim.o.lines - #lines) / 2) - 2)
  local pad = string.rep(" ", left)
  local out = {}
  for _ = 1, top do table.insert(out, "") end
  for _, l in ipairs(lines) do table.insert(out, pad .. l) end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "paper-dashboard"
  for _, opt in ipairs({ "number", "relativenumber", "cursorline", "list" }) do vim.wo[opt] = false end
  vim.wo.signcolumn = "no"

  local ns = vim.api.nvim_create_namespace("paper-dashboard")
  for i, group in pairs(hl) do
    vim.api.nvim_buf_set_extmark(buf, ns, top + i - 1, 0, { line_hl_group = group })
  end
  for i = 0, #KEYS - 1 do
    vim.api.nvim_buf_set_extmark(buf, ns, top + key_start - 1 + i, left, { end_col = left + 1, hl_group = "PaperKey" })
    vim.api.nvim_buf_set_extmark(buf, ns, top + key_start - 1 + i, left + 1, { end_row = top + key_start - 1 + i, end_col = #out[top + key_start + i], hl_group = "PaperDim" })
  end
  for _, k in ipairs(KEYS) do
    vim.keymap.set("n", k[1], "<cmd>" .. k[3] .. "<cr>", { buffer = buf, nowait = true, silent = true })
  end
  vim.api.nvim_win_set_cursor(0, { top + key_start, left })
end

function M.setup()
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and vim.api.nvim_buf_line_count(0) <= 1
         and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "" then
        M.open()
      end
    end,
  })
end

return M
