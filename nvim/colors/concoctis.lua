-- concoctis — Neovim port of the VS Code theme "gruvboxConcoctis dark hard"
-- (wheredoesyourmindgo.gruvbox-concoctis, gruvbox-material palette). Colors taken from its darkHard.json;
-- VS Code's translucent colors are pre-blended onto the #202020 background.
-- :colorscheme concoctis   or   NVIM_COLORS="concoctis" in ~/.config/paper/config

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.background = "dark"
vim.g.colors_name = "concoctis"

local p = {
  bg = "#202020", dark = "#171819", bg2 = "#2a2827", float = "#32302f", cur = "#272625",
  line = "#0f1010", indent = "#32302f", indent_hi = "#514945",
  fg = "#d4be98", fg2 = "#a89984", prop = "#c5b18d", dim = "#928374", faint = "#5a524c",
  red = "#ea6962", orange = "#e78a4e", yellow = "#d8a657", green = "#a9b665",
  aqua = "#89b482", blue = "#7daea3", purple = "#d3869b",
  sel = "#3a3633", psel = "#3d3835", search = "#353d33", cursearch = "#462e2c",
  add = "#2c322b", del = "#342726", chg = "#2b3130",
  gadd = "#8f9a52", gchg = "#68948a",
}

local function hi(group, spec) vim.api.nvim_set_hl(0, group, spec) end
local links = function(t) for from, to in pairs(t) do hi(from, { link = to }) end end

-- ── editor ──────────────────────────────────────────────────────────────
hi("Normal",       { fg = p.fg, bg = p.bg })
hi("NormalNC",     { fg = p.fg, bg = p.bg })
hi("NormalFloat",  { fg = p.fg, bg = p.float })
hi("FloatBorder",  { fg = p.faint, bg = p.float })
hi("FloatTitle",   { fg = p.yellow, bg = p.float, bold = true })
hi("Cursor",       { fg = p.bg, bg = p.fg })
hi("CursorLine",   { bg = p.cur })
hi("CursorColumn", { bg = p.cur })
hi("ColorColumn",  { bg = p.cur })
hi("LineNr",       { fg = p.faint })
hi("CursorLineNr", { fg = p.prop, bold = true })
hi("SignColumn",   { bg = p.bg })
hi("FoldColumn",   { fg = p.faint, bg = p.bg })
hi("Folded",       { fg = p.dim, bg = p.bg2 })
hi("VertSplit",    { fg = p.line })
hi("WinSeparator", { fg = p.line })
hi("EndOfBuffer",  { fg = p.bg })
hi("NonText",      { fg = p.faint })
hi("Whitespace",   { fg = p.faint })
hi("SpecialKey",   { fg = p.faint })
hi("Visual",       { bg = p.sel })
hi("VisualNOS",    { bg = p.sel })
hi("Search",       { bg = p.search })
hi("IncSearch",    { fg = p.bg, bg = p.orange })
hi("CurSearch",    { fg = p.bg, bg = p.orange })
hi("Substitute",   { fg = p.bg, bg = p.yellow })
hi("MatchParen",   { bg = "#3a3633", bold = true })
hi("Directory",    { fg = p.aqua })
hi("Title",        { fg = p.purple, bold = true })
hi("Question",     { fg = p.yellow })
hi("MoreMsg",      { fg = p.yellow })
hi("ModeMsg",      { fg = p.fg2 })
hi("ErrorMsg",     { fg = p.red, bold = true })
hi("WarningMsg",   { fg = p.orange })
hi("Conceal",      { fg = p.dim })
hi("QuickFixLine", { bg = p.sel })

hi("StatusLine",   { fg = p.fg2, bg = p.dark })
hi("StatusLineNC", { fg = p.dim, bg = p.dark })
hi("TabLine",      { fg = p.dim, bg = p.bg2 })
hi("TabLineSel",   { fg = p.fg, bg = p.bg, bold = true })
hi("TabLineFill",  { bg = p.dark })
hi("WinBar",       { fg = p.dim, bg = p.bg })
hi("WinBarNC",     { fg = p.faint, bg = p.bg })

hi("Pmenu",        { fg = p.fg, bg = p.float })
hi("PmenuSel",     { fg = p.fg, bg = p.psel, bold = true })
hi("PmenuSbar",    { bg = p.float })
hi("PmenuThumb",   { bg = "#4a443f" })
hi("PmenuKind",    { fg = p.aqua, bg = p.float })
hi("PmenuExtra",   { fg = p.dim, bg = p.float })
hi("WildMenu",     { fg = p.fg, bg = p.psel })

hi("SpellBad",     { undercurl = true, sp = p.red })
hi("SpellCap",     { undercurl = true, sp = p.yellow })
hi("SpellRare",    { undercurl = true, sp = p.purple })
hi("SpellLocal",   { undercurl = true, sp = p.aqua })

hi("DiffAdd",      { bg = p.add })
hi("DiffDelete",   { fg = p.red, bg = p.del })
hi("DiffChange",   { bg = p.chg })
hi("DiffText",     { bg = "#36433f", bold = true })
hi("Added",        { fg = p.green })
hi("Removed",      { fg = p.red })
hi("Changed",      { fg = p.blue })

-- ── syntax: as in the VS Code theme ─────────────────────────────────────
-- keywords pink+bold · def/fn/class orange · functions & types aqua · strings green
-- named constants yellow · numbers/true/None red · self orange italic · properties cream italic
hi("Comment",      { fg = p.dim, italic = true })
hi("Constant",     { fg = p.yellow })
hi("String",       { fg = p.green })
hi("Character",    { fg = p.green })
hi("Number",       { fg = p.red })
hi("Boolean",      { fg = p.red })
hi("Float",        { fg = p.red })
hi("Identifier",   { fg = p.fg })
hi("Function",     { fg = p.aqua, italic = false })
hi("Statement",    { fg = p.purple, bold = true })
hi("Keyword",      { fg = p.purple, bold = true })
hi("Conditional",  { fg = p.purple, bold = true })
hi("Repeat",       { fg = p.purple, bold = true })
hi("Label",        { fg = p.purple })
hi("Exception",    { fg = p.purple, bold = true })
hi("Operator",     { fg = p.purple, bold = true })
hi("PreProc",      { fg = p.purple })
hi("Include",      { fg = p.purple, bold = true })
hi("Define",       { fg = p.purple })
hi("Macro",        { fg = p.aqua })
hi("Type",         { fg = p.aqua })
hi("StorageClass", { fg = p.orange, italic = true })
hi("Structure",    { fg = p.orange })
hi("Typedef",      { fg = p.orange })
hi("Special",      { fg = p.yellow })
hi("SpecialChar",  { fg = p.fg })
hi("Tag",          { fg = p.orange })
hi("Delimiter",    { fg = p.fg2 })
hi("SpecialComment", { fg = p.fg2, italic = true })
hi("Debug",        { fg = p.red })
hi("Underlined",   { fg = p.blue, underline = true })
hi("Error",        { fg = p.red, bold = true })
hi("Todo",         { fg = p.bg, bg = p.yellow, bold = true })

hi("ConcoctisDecl",     { fg = p.orange, bold = true })   -- def / fn / class / let
hi("ConcoctisSelf",     { fg = p.orange, italic = true }) -- self / this
hi("ConcoctisProperty", { fg = p.prop, italic = true })
hi("ConcoctisAccessor", { fg = p.purple, bold = true })   -- the dot in a.b
hi("ConcoctisParam",    { fg = p.blue })                  -- function parameters
hi("ConcoctisDef",      { fg = p.aqua, bold = true, italic = false })     -- name in def / class

-- ── treesitter ──────────────────────────────────────────────────────────
links({
  ["@comment"] = "Comment", ["@comment.documentation"] = "SpecialComment",
  ["@comment.todo"] = "Todo", ["@comment.note"] = "SpecialComment",
  ["@comment.warning"] = "WarningMsg", ["@comment.error"] = "ErrorMsg",
  ["@string"] = "String", ["@string.documentation"] = "String", ["@string.escape"] = "SpecialChar",
  ["@string.regexp"] = "String", ["@string.special"] = "Special", ["@string.special.url"] = "Underlined",
  ["@character"] = "Character", ["@character.special"] = "SpecialChar",
  ["@number"] = "Number", ["@number.float"] = "Float", ["@boolean"] = "Boolean",
  ["@constant"] = "Constant", ["@constant.builtin"] = "Number", ["@constant.macro"] = "Constant",
  ["@variable"] = "Identifier", ["@variable.member"] = "ConcoctisProperty", ["@property"] = "ConcoctisProperty",
  ["@variable.builtin"] = "ConcoctisSelf", ["@variable.parameter"] = "ConcoctisParam",
  ["@variable.parameter.builtin"] = "ConcoctisSelf",
  ["@function"] = "ConcoctisDef", ["@function.call"] = "Function", ["@function.builtin"] = "Function",
  ["@function.method"] = "ConcoctisDef", ["@function.method.call"] = "Function", ["@function.macro"] = "Macro",
  ["@constructor"] = "Type",
  ["@keyword"] = "Keyword", ["@keyword.function"] = "ConcoctisDecl", ["@keyword.type"] = "ConcoctisDecl",
  ["@keyword.return"] = "Keyword", ["@keyword.import"] = "Include", ["@keyword.exception"] = "Exception",
  ["@keyword.operator"] = "Keyword", ["@keyword.conditional"] = "Conditional", ["@keyword.repeat"] = "Repeat",
  ["@keyword.modifier"] = "StorageClass", ["@keyword.coroutine"] = "Keyword", ["@keyword.directive"] = "PreProc",
  ["@operator"] = "Operator", ["@punctuation"] = "Delimiter", ["@punctuation.bracket"] = "Delimiter",
  ["@punctuation.delimiter"] = "Delimiter", ["@punctuation.delimiter.member"] = "ConcoctisAccessor", ["@punctuation.special"] = "Keyword",
  ["@type"] = "Type", ["@type.builtin"] = "Type", ["@type.definition"] = "ConcoctisDef", ["@type.qualifier"] = "StorageClass",
  ["@attribute"] = "Function", ["@attribute.builtin"] = "Function",
  ["@module"] = "Function", ["@module.builtin"] = "Function", ["@label"] = "Label",
  ["@tag"] = "Tag", ["@tag.builtin"] = "Tag", ["@tag.attribute"] = "Function", ["@tag.delimiter"] = "Comment",
  ["@markup.heading"] = "Title", ["@markup.link"] = "Function", ["@markup.link.label"] = "Function",
  ["@markup.link.url"] = "Underlined", ["@markup.raw"] = "String", ["@markup.list"] = "Keyword",
  ["@markup.list.checked"] = "Comment", ["@markup.list.unchecked"] = "Keyword", ["@markup.quote"] = "Constant",
  ["@diff.plus"] = "Added", ["@diff.minus"] = "Removed", ["@diff.delta"] = "Changed",
  ["@lsp.type.comment"] = "Comment", ["@lsp.type.namespace"] = "Function", ["@lsp.type.class"] = "Type",
  ["@lsp.type.enum"] = "Type", ["@lsp.type.enumMember"] = "Constant", ["@lsp.type.struct"] = "Type",
  ["@lsp.type.interface"] = "Type", ["@lsp.type.typeParameter"] = "Constant",
  ["@lsp.type.parameter"] = "ConcoctisParam", ["@lsp.type.property"] = "ConcoctisProperty",
  ["@lsp.type.variable"] = "Identifier", ["@lsp.type.function"] = "Function", ["@lsp.type.method"] = "Function",
  ["@lsp.type.macro"] = "Macro", ["@lsp.type.selfKeyword"] = "ConcoctisSelf",
  ["@lsp.typemod.variable.readonly"] = "Constant",
})
hi("@markup.strong", { fg = p.orange, bold = true })
hi("@markup.italic", { fg = p.orange, italic = true })
hi("@markup.strikethrough", { strikethrough = true })

-- ── diagnostics ─────────────────────────────────────────────────────────
for name, c in pairs({ Error = p.red, Warn = p.orange, Info = p.yellow, Hint = p.blue, Ok = p.green }) do
  hi("Diagnostic" .. name, { fg = c })
  hi("DiagnosticVirtualText" .. name, { fg = c, italic = true })
  hi("DiagnosticUnderline" .. name, { undercurl = true, sp = c })
  hi("DiagnosticSign" .. name, { fg = c, bg = p.bg })
  hi("DiagnosticFloating" .. name, { fg = c, bg = p.float })
end
hi("DiagnosticUnnecessary", { fg = p.faint })
hi("LspReferenceText",  { bg = p.float })
hi("LspReferenceRead",  { bg = p.float })
hi("LspReferenceWrite", { bg = p.float, underline = true })
hi("LspInlayHint",      { fg = p.faint, italic = true })
hi("LspSignatureActiveParameter", { fg = p.yellow, bold = true })

-- ── plugins ─────────────────────────────────────────────────────────────
hi("GitSignsAdd",    { fg = p.gadd, bg = p.bg })
hi("GitSignsChange", { fg = p.gchg, bg = p.bg })
hi("GitSignsDelete", { fg = p.red, bg = p.bg })

hi("TelescopeNormal",        { fg = p.fg, bg = p.float })
hi("TelescopeBorder",        { fg = p.faint, bg = p.float })
hi("TelescopePromptNormal",  { fg = p.fg, bg = p.float })
hi("TelescopePromptBorder",  { fg = p.faint, bg = p.float })
hi("TelescopePromptTitle",   { fg = p.bg, bg = p.yellow, bold = true })
hi("TelescopeResultsTitle",  { fg = p.dim, bg = p.float })
hi("TelescopePreviewTitle",  { fg = p.dim, bg = p.float })
hi("TelescopeSelection",     { fg = p.fg, bg = p.psel, bold = true })
hi("TelescopeMatching",      { fg = p.yellow, bold = true })
hi("TelescopePromptPrefix",  { fg = p.orange })

-- file tree = VS Code sidebar
hi("NvimTreeNormal",        { fg = p.dim, bg = p.dark })
hi("NvimTreeNormalNC",      { fg = p.dim, bg = p.dark })
hi("NvimTreeWinSeparator",  { fg = p.line, bg = p.bg })
hi("NvimTreeEndOfBuffer",   { fg = p.dark, bg = p.dark })
hi("NvimTreeRootFolder",    { fg = p.fg2, bold = true })
hi("NvimTreeFolderName",    { fg = p.fg2 })
hi("NvimTreeOpenedFolderName", { fg = p.fg, bold = true })
hi("NvimTreeEmptyFolderName",  { fg = p.dim })
hi("NvimTreeFolderArrowOpen",  { fg = p.dim })
hi("NvimTreeFolderArrowClosed", { fg = p.dim })
hi("NvimTreeIndentMarker",  { fg = p.indent })
hi("NvimTreeSpecialFile",   { fg = p.yellow })
hi("NvimTreeExecFile",      { fg = p.green, bold = true })
hi("NvimTreeGitDirty",      { fg = p.orange })
hi("NvimTreeGitNew",        { fg = p.green })
hi("NvimTreeGitDeleted",    { fg = p.red })
hi("NvimTreeCursorLine",    { bg = p.bg2 })

hi("WhichKey",          { fg = p.yellow, bold = true })
hi("WhichKeyGroup",     { fg = p.aqua })
hi("WhichKeyDesc",      { fg = p.fg })
hi("WhichKeySeparator", { fg = p.faint })
hi("WhichKeyNormal",    { bg = p.float })
hi("WhichKeyBorder",    { fg = p.faint, bg = p.float })

hi("BlinkCmpMenu",           { fg = p.fg, bg = p.float })
hi("BlinkCmpMenuBorder",     { fg = p.faint, bg = p.float })
hi("BlinkCmpMenuSelection",  { bg = p.psel, bold = true })
hi("BlinkCmpLabelMatch",     { fg = p.yellow, bold = true })
hi("BlinkCmpKind",           { fg = p.aqua })
hi("BlinkCmpDoc",            { fg = p.fg, bg = p.float })
hi("BlinkCmpDocBorder",      { fg = p.faint, bg = p.float })
hi("BlinkCmpSignatureHelp",  { fg = p.fg, bg = p.float })
hi("BlinkCmpSignatureHelpBorder", { fg = p.faint, bg = p.float })

hi("IblIndent", { fg = p.indent })
hi("IblScope",  { fg = p.indent_hi })
hi("LazyNormal", { bg = p.float })
hi("MasonNormal", { bg = p.float })

-- dashboard (lua/paper/dashboard.lua)
hi("PaperArt",    { fg = p.dim })
hi("PaperTitle",  { fg = p.fg, bold = true })
hi("PaperDim",    { fg = p.dim })
hi("PaperKey",    { fg = p.yellow, bold = true })
hi("PaperAccent", { fg = p.orange })

-- :terminal colors = the theme's terminal.ansi*
local term = { "#32302f", p.red, p.green, p.yellow, p.blue, p.purple, p.aqua, p.fg,
               p.dim, p.red, p.green, p.yellow, p.blue, p.purple, p.aqua, "#ddc7a1" }
for i, c in ipairs(term) do vim.g["terminal_color_" .. (i - 1)] = c end
