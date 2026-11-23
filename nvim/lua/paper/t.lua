-- paper.t — the `t` task tool inside Neovim.
--   :T [args]          run any `t` command, output in a float      (:T week · :T report · :T done 2)
--   <leader>tt  list   <leader>ta  add      <leader>ts  start    <leader>td  done
--   <leader>tp  pause  <leader>tn  note     <leader>tl  log      <leader>tr  report
local M = {}
local cache = ""

local function run(args)
  local r = vim.system(vim.list_extend({ "t" }, args), { text = true }):wait()
  local out = (r.stdout or "") .. (r.stderr or "")
  return (out:gsub("\27%[[%d;]*m", ""):gsub("%s+$", ""))
end

local function float(text, title)
  local lines = vim.split(text, "\n")
  local width = 20
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  width = math.min(width + 4, math.floor(vim.o.columns * 0.9))
  local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.8))
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.tbl_map(function(l) return "  " .. l end, lines))
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded",
    width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1, col = math.floor((vim.o.columns - width) / 2),
    title = " " .. (title or "t") .. " ", title_pos = "left",
  })
  vim.wo[win].cursorline = false
  -- light syntax: numbers, statuses, times
  vim.fn.matchadd("PaperDim", [[^\s*\d\+\ze\s]], 10, -1, { window = win })
  vim.fn.matchadd("PaperAccent", [[\[/\]\|▶[^│]*\|\<\d\d:\d\d\>]], 10, -1, { window = win })
  vim.fn.matchadd("PaperDim", [[\[x\].*\|\[-\].*\|\[>\].*\|·.*]], 9, -1, { window = win })
  for _, k in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", k, "<cmd>close<cr>", { buffer = buf, nowait = true })
  end
end

function M.cmd(args, title)
  float(run(args), title or ("t " .. table.concat(args, " ")))
  M.refresh()
end

-- pick a task from today's list via vim.ui.select, then run `t <verb> N`
local function pick(verb, filter)
  local items = {}
  for line in run({}):gmatch("[^\n]+") do
    local n, mark, rest = line:match("^%s*(%d+)%s+%[(.)%]%s+(.*)$")
    if n and (not filter or filter:find(mark, 1, true)) then table.insert(items, { n = n, text = "[" .. mark .. "] " .. rest }) end
  end
  if #items == 0 then return vim.notify("t: подходящих задач нет", vim.log.levels.INFO) end
  vim.ui.select(items, { prompt = "t " .. verb, format_item = function(i) return i.text end }, function(choice)
    if choice then M.cmd({ verb, choice.n }) end
  end)
end

local function ask(prompt, fn)
  vim.ui.input({ prompt = prompt }, function(s) if s and s ~= "" then fn(s) end end)
end

function M.status() return cache end

function M.refresh()
  if vim.fn.executable("t") ~= 1 then return end
  vim.system({ "t", "status" }, { text = true }, function(r)
    cache = (r.stdout or ""):gsub("%s+$", "")
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("T", function(o) M.cmd(o.fargs) end, {
    nargs = "*",
    complete = function()
      return { "add", "tom", "start", "pause", "done", "cancel", "undo", "mv", "rm", "prio", "at", "rename",
               "week", "now", "report", "stats", "notes", "note", "log", "rollover", "find", "help" }
    end,
  })
  local map = function(k, f, d) vim.keymap.set("n", k, f, { desc = d }) end
  map("<leader>tt", function() M.cmd({}, "сегодня") end, "Задачи на сегодня")
  map("<leader>ta", function() ask("новая задача: ", function(s) M.cmd(vim.list_extend({ "add" }, vim.split(s, " "))) end) end, "Добавить задачу")
  map("<leader>ts", function() pick("start", " /!?") end, "Начать задачу (таймер)")
  map("<leader>td", function() pick("done", " /!?") end, "Закрыть задачу")
  map("<leader>tp", function() M.cmd({ "pause" }) end, "Пауза")
  map("<leader>tn", function() ask("заметка: ", function(s) M.cmd(vim.list_extend({ "note" }, vim.split(s, " "))) end) end, "Заметка в заметку дня")
  map("<leader>tl", function() ask("лог: ", function(s) M.cmd(vim.list_extend({ "log" }, vim.split(s, " "))) end) end, "Запись в лог дня")
  map("<leader>tr", function() M.cmd({ "report", "week" }, "неделя") end, "Отчёт за неделю")
  pcall(function() require("which-key").add({ { "<leader>t", group = "задачи (t)" } }) end)

  M.refresh()
  local timer = vim.uv.new_timer()
  timer:start(30000, 30000, vim.schedule_wrap(M.refresh))
end

return M
