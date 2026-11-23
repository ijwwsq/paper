-- paper — soft paper colorscheme for Neovim. Same palette as Alacritty / tmux / widgets.
-- :colorscheme paper   (dark variant: vim.o.background = "dark")

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "paper"

local dark = vim.o.background == "dark"
local p = dark and {
  bg = "#1c1c1a", bg2 = "#222220", bg3 = "#2a2a27", line = "#33332f",
  fg = "#d6d6d0", fg2 = "#a8a8a2", dim = "#6b6b67", faint = "#4a4a46",
  blue = "#7c8fc4", green = "#7fa37c", red = "#c46f66", yellow = "#c4a15c",
  magenta = "#a886b0", cyan = "#6fa5a7", sel = "#2e3546", search = "#4a3f22",
  add = "#2a3a29", del = "#3e2826", chg = "#2b3242",
} or {
  bg = "#fcfcfa", bg2 = "#f6f6f3", bg3 = "#efefeb", line = "#e4e4e0",
  fg = "#2f2f2f", fg2 = "#55554f", dim = "#8c8c88", faint = "#c4c4bf",
  blue = "#5b6fa8", green = "#5e8a5c", red = "#b5584e", yellow = "#a5803a",
  magenta = "#8d6597", cyan = "#4d8a8c", sel = "#e1e7f0", search = "#f2e6c4",
  add = "#e7f0e5", del = "#f5e3e0", chg = "#e6ebf4",
}

local function hi(group, spec) vim.api.nvim_set_hl(0, group, spec) end
local links = function(t) for from, to in pairs(t) do hi(from, { link = to }) end end

-- ── editor ──────────────────────────────────────────────────────────────
hi("Normal",       { fg = p.fg, bg = p.bg })
hi("NormalNC",     { fg = p.fg, bg = p.bg })
hi("NormalFloat",  { fg = p.fg, bg = p.bg2 })
hi("FloatBorder",  { fg = p.faint, bg = p.bg2 })
hi("FloatTitle",   { fg = p.fg, bg = p.bg2, bold = true })
hi("Cursor",       { fg = p.bg, bg = p.dim })
hi("CursorLine",   { bg = p.bg2 })
hi("CursorColumn", { bg = p.bg2 })
hi("ColorColumn",  { bg = p.bg2 })
hi("LineNr",       { fg = p.faint })
hi("CursorLineNr", { fg = p.fg2, bold = true })
hi("SignColumn",   { bg = p.bg })
hi("FoldColumn",   { fg = p.faint, bg = p.bg })
hi("Folded",       { fg = p.dim, bg = p.bg2 })
hi("VertSplit",    { fg = p.line })
hi("WinSeparator", { fg = p.line })
hi("EndOfBuffer",  { fg = p.bg })
hi("NonText",      { fg = p.faint })
hi("Whitespace",   { fg = p.line })
hi("SpecialKey",   { fg = p.faint })
hi("Visual",       { bg = p.sel })
hi("VisualNOS",    { bg = p.sel })
hi("Search",       { fg = p.fg, bg = p.search })
hi("IncSearch",    { fg = p.bg, bg = p.blue })
hi("CurSearch",    { fg = p.bg, bg = p.blue })
hi("Substitute",   { fg = p.bg, bg = p.yellow })
hi("MatchParen",   { fg = p.blue, bold = true, underline = true })
hi("Directory",    { fg = p.blue })
hi("Title",        { fg = p.fg, bold = true })
hi("Question",     { fg = p.green })
hi("MoreMsg",      { fg = p.green })
hi("ModeMsg",      { fg = p.dim })
hi("ErrorMsg",     { fg = p.red })
hi("WarningMsg",   { fg = p.yellow })
hi("Conceal",      { fg = p.dim })
hi("QuickFixLine", { bg = p.sel })

hi("StatusLine",   { fg = p.fg2, bg = p.bg2 })
hi("StatusLineNC", { fg = p.dim, bg = p.bg2 })
hi("TabLine",      { fg = p.dim, bg = p.bg2 })
hi("TabLineSel",   { fg = p.fg, bg = p.bg, bold = true })
hi("TabLineFill",  { bg = p.bg2 })
hi("WinBar",       { fg = p.dim, bg = p.bg })
hi("WinBarNC",     { fg = p.faint, bg = p.bg })

hi("Pmenu",        { fg = p.fg, bg = p.bg2 })
hi("PmenuSel",     { fg = p.fg, bg = p.sel, bold = true })
hi("PmenuSbar",    { bg = p.bg3 })
hi("PmenuThumb",   { bg = p.faint })
hi("PmenuKind",    { fg = p.dim, bg = p.bg2 })
hi("PmenuExtra",   { fg = p.dim, bg = p.bg2 })
hi("WildMenu",     { fg = p.fg, bg = p.sel })

hi("SpellBad",     { undercurl = true, sp = p.red })
hi("SpellCap",     { undercurl = true, sp = p.yellow })
hi("SpellRare",    { undercurl = true, sp = p.magenta })
hi("SpellLocal",   { undercurl = true, sp = p.cyan })

hi("DiffAdd",      { bg = p.add })
hi("DiffDelete",   { fg = p.red, bg = p.del })
hi("DiffChange",   { bg = p.chg })
hi("DiffText",     { bg = p.sel, bold = true })
hi("Added",        { fg = p.green })
hi("Removed",      { fg = p.red })
hi("Changed",      { fg = p.blue })

-- ── syntax: muted, ink first ────────────────────────────────────────────
hi("Comment",      { fg = p.dim, italic = true })
hi("Constant",     { fg = p.magenta })
hi("String",       { fg = p.green })
hi("Character",    { fg = p.green })
hi("Number",       { fg = p.magenta })
hi("Boolean",      { fg = p.magenta })
hi("Float",        { fg = p.magenta })
hi("Identifier",   { fg = p.fg })
hi("Function",     { fg = p.fg, bold = true })
hi("Statement",    { fg = p.blue })
hi("Keyword",      { fg = p.blue })
hi("Conditional",  { fg = p.blue })
hi("Repeat",       { fg = p.blue })
hi("Label",        { fg = p.blue })
hi("Exception",    { fg = p.red })
hi("Operator",     { fg = p.fg2 })
hi("PreProc",      { fg = p.cyan })
hi("Include",      { fg = p.blue })
hi("Define",       { fg = p.cyan })
hi("Macro",        { fg = p.cyan })
hi("Type",         { fg = p.cyan })
hi("StorageClass", { fg = p.blue })
hi("Structure",    { fg = p.cyan })
hi("Typedef",      { fg = p.cyan })
hi("Special",      { fg = p.yellow })
hi("SpecialChar",  { fg = p.yellow })
hi("Tag",          { fg = p.blue })
hi("Delimiter",    { fg = p.fg2 })
hi("SpecialComment", { fg = p.dim, bold = true })
hi("Debug",        { fg = p.red })
hi("Underlined",   { fg = p.blue, underline = true })
hi("Error",        { fg = p.red, bold = true })
hi("Todo",         { fg = p.bg, bg = p.yellow, bold = true })

-- ── treesitter ──────────────────────────────────────────────────────────
links({
  ["@comment"] = "Comment", ["@comment.todo"] = "Todo", ["@comment.note"] = "SpecialComment",
  ["@string"] = "String", ["@string.escape"] = "SpecialChar", ["@string.regexp"] = "SpecialChar",
  ["@string.special"] = "Special", ["@character"] = "Character",
  ["@number"] = "Number", ["@number.float"] = "Float", ["@boolean"] = "Boolean",
  ["@constant"] = "Constant", ["@constant.builtin"] = "Constant", ["@constant.macro"] = "Macro",
  ["@variable"] = "Identifier", ["@variable.member"] = "Identifier", ["@property"] = "Identifier",
  ["@variable.builtin"] = "Special", ["@variable.parameter"] = "Identifier",
  ["@function"] = "Function", ["@function.call"] = "Identifier", ["@function.builtin"] = "Function",
  ["@function.method"] = "Function", ["@function.method.call"] = "Identifier", ["@constructor"] = "Type",
  ["@function.macro"] = "Macro",
  ["@keyword"] = "Keyword", ["@keyword.function"] = "Keyword", ["@keyword.return"] = "Keyword",
  ["@keyword.import"] = "Include", ["@keyword.exception"] = "Exception", ["@keyword.operator"] = "Keyword",
  ["@keyword.conditional"] = "Conditional", ["@keyword.repeat"] = "Repeat",
  ["@operator"] = "Operator", ["@punctuation"] = "Delimiter", ["@punctuation.bracket"] = "Delimiter",
  ["@punctuation.delimiter"] = "Delimiter", ["@punctuation.special"] = "Special",
  ["@type"] = "Type", ["@type.builtin"] = "Type", ["@type.definition"] = "Typedef",
  ["@attribute"] = "PreProc", ["@module"] = "Identifier", ["@label"] = "Label",
  ["@tag"] = "Tag", ["@tag.attribute"] = "Identifier", ["@tag.delimiter"] = "Delimiter",
  ["@markup.heading"] = "Title", ["@markup.link"] = "Underlined", ["@markup.link.url"] = "Underlined",
  ["@markup.raw"] = "String", ["@markup.list"] = "Special", ["@markup.quote"] = "Comment",
  ["@diff.plus"] = "Added", ["@diff.minus"] = "Removed", ["@diff.delta"] = "Changed",
  ["@lsp.type.comment"] = "Comment", ["@lsp.type.namespace"] = "Identifier",
  ["@lsp.type.parameter"] = "Identifier", ["@lsp.type.property"] = "Identifier",
})
hi("@markup.strong", { bold = true })
hi("@markup.italic", { italic = true })
hi("@markup.strikethrough", { strikethrough = true })

-- ── diagnostics ─────────────────────────────────────────────────────────
for name, c in pairs({ Error = p.red, Warn = p.yellow, Info = p.blue, Hint = p.cyan, Ok = p.green }) do
  hi("Diagnostic" .. name, { fg = c })
  hi("DiagnosticVirtualText" .. name, { fg = c, italic = true })
  hi("DiagnosticUnderline" .. name, { undercurl = true, sp = c })
  hi("DiagnosticSign" .. name, { fg = c, bg = p.bg })
  hi("DiagnosticFloating" .. name, { fg = c, bg = p.bg2 })
end
hi("LspReferenceText",  { bg = p.bg3 })
hi("LspReferenceRead",  { bg = p.bg3 })
hi("LspReferenceWrite", { bg = p.bg3, underline = true })
hi("LspInlayHint",      { fg = p.faint, italic = true })
hi("LspSignatureActiveParameter", { fg = p.blue, bold = true })

-- ── plugins ─────────────────────────────────────────────────────────────
hi("GitSignsAdd",    { fg = p.green, bg = p.bg })
hi("GitSignsChange", { fg = p.blue, bg = p.bg })
hi("GitSignsDelete", { fg = p.red, bg = p.bg })

hi("TelescopeNormal",        { fg = p.fg, bg = p.bg2 })
hi("TelescopeBorder",        { fg = p.faint, bg = p.bg2 })
hi("TelescopePromptNormal",  { fg = p.fg, bg = p.bg2 })
hi("TelescopePromptBorder",  { fg = p.faint, bg = p.bg2 })
hi("TelescopePromptTitle",   { fg = p.bg, bg = p.blue, bold = true })
hi("TelescopeResultsTitle",  { fg = p.dim, bg = p.bg2 })
hi("TelescopePreviewTitle",  { fg = p.dim, bg = p.bg2 })
hi("TelescopeSelection",     { fg = p.fg, bg = p.sel, bold = true })
hi("TelescopeMatching",      { fg = p.blue, bold = true })
hi("TelescopePromptPrefix",  { fg = p.blue })

hi("NvimTreeNormal",        { fg = p.fg2, bg = p.bg2 })
hi("NvimTreeNormalNC",      { fg = p.fg2, bg = p.bg2 })
hi("NvimTreeWinSeparator",  { fg = p.line, bg = p.bg })
hi("NvimTreeEndOfBuffer",   { fg = p.bg2, bg = p.bg2 })
hi("NvimTreeRootFolder",    { fg = p.dim, bold = true })
hi("NvimTreeFolderName",    { fg = p.fg })
hi("NvimTreeOpenedFolderName", { fg = p.fg, bold = true })
hi("NvimTreeEmptyFolderName",  { fg = p.dim })
hi("NvimTreeFolderArrowOpen",  { fg = p.dim })
hi("NvimTreeFolderArrowClosed", { fg = p.dim })
hi("NvimTreeIndentMarker",  { fg = p.line })
hi("NvimTreeSpecialFile",   { fg = p.yellow })
hi("NvimTreeExecFile",      { fg = p.green, bold = true })
hi("NvimTreeGitDirty",      { fg = p.blue })
hi("NvimTreeGitNew",        { fg = p.green })
hi("NvimTreeGitDeleted",    { fg = p.red })
hi("NvimTreeCursorLine",    { bg = p.sel })

hi("WhichKey",          { fg = p.blue, bold = true })
hi("WhichKeyGroup",     { fg = p.cyan })
hi("WhichKeyDesc",      { fg = p.fg })
hi("WhichKeySeparator", { fg = p.faint })
hi("WhichKeyNormal",    { bg = p.bg2 })
hi("WhichKeyBorder",    { fg = p.faint, bg = p.bg2 })

hi("BlinkCmpMenu",           { fg = p.fg, bg = p.bg2 })
hi("BlinkCmpMenuBorder",     { fg = p.faint, bg = p.bg2 })
hi("BlinkCmpMenuSelection",  { bg = p.sel, bold = true })
hi("BlinkCmpLabelMatch",     { fg = p.blue, bold = true })
hi("BlinkCmpKind",           { fg = p.dim })
hi("BlinkCmpDoc",            { fg = p.fg, bg = p.bg2 })
hi("BlinkCmpDocBorder",      { fg = p.faint, bg = p.bg2 })
hi("BlinkCmpSignatureHelp",  { fg = p.fg, bg = p.bg2 })
hi("BlinkCmpSignatureHelpBorder", { fg = p.faint, bg = p.bg2 })

hi("LazyNormal", { bg = p.bg2 })
hi("MasonNormal", { bg = p.bg2 })

-- dashboard (lua/paper/dashboard.lua)
hi("PaperArt",    { fg = p.dim })
hi("PaperTitle",  { fg = p.fg, bold = true })
hi("PaperDim",    { fg = p.dim })
hi("PaperKey",    { fg = p.blue, bold = true })
hi("PaperAccent", { fg = p.blue })

-- terminal inside nvim uses the same 16 colors as Alacritty
local term = dark
  and { "#3a3a37", "#c46f66", "#7fa37c", "#c4a15c", "#7c8fc4", "#a886b0", "#6fa5a7", "#c8c8c2",
        "#6b6b67", "#d48479", "#92b58f", "#d4b46e", "#93a3d1", "#b89bbf", "#85b7b9", "#e8e8e2" }
  or  { "#3a3a3a", "#b5584e", "#5e8a5c", "#a5803a", "#5b6fa8", "#8d6597", "#4d8a8c", "#a9a9a6",
        "#8c8c88", "#c46f66", "#729c6f", "#b8934c", "#7083b8", "#9f79a8", "#629b9d", "#cfcfcb" }
for i, c in ipairs(term) do vim.g["terminal_color_" .. (i - 1)] = c end
