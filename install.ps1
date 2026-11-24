# paper — Windows side: Alacritty + JetBrains Mono, Obsidian snippet, desktop widgets.
#
#   .\install.ps1                         Alacritty + шрифт
#   .\install.ps1 -Vault D:\notes\vault   + сниппет paper.css в Obsidian
#   .\install.ps1 -Widgets                + виджеты рабочего стола (в автозагрузку)
#   .\install.ps1 -All -Vault ...         всё сразу
#   .\install.ps1 -Theme gruvbox          тёмная тема (по умолчанию paper) — Alacritty и виджеты;
#                                         в WSL то же самое: THEME="gruvbox" в ~/.config/paper/config
#
# Существующие файлы уходят в *.bak-<дата>. Ничего не требует прав администратора.
param([string]$Vault, [switch]$Widgets, [switch]$All, [switch]$NoFont,
      [ValidateSet('paper', 'gruvbox')][string]$Theme = 'paper')
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
function Say($m) { Write-Host "  · $m" }
function Backup($p) { if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p "$p.bak-$stamp"; Say "backup  $p.bak-$stamp" } }

Write-Host "`n  paper — installing`n"

# ── Alacritty: config lives in ~/.config/paper, %APPDATA% just imports it ───────────────
$cfgDir = Join-Path $env:USERPROFILE '.config\paper'
New-Item -ItemType Directory -Force $cfgDir | Out-Null
$ala = Join-Path $cfgDir 'alacritty.toml'
Backup $ala
Copy-Item (Join-Path $here 'alacritty\alacritty.toml') $ala -Force
$alaTheme = Join-Path $cfgDir 'alacritty-theme.toml'
Copy-Item (Join-Path $here "alacritty\themes\$Theme.toml") $alaTheme -Force
$stub = Join-Path $env:APPDATA 'alacritty\alacritty.toml'
New-Item -ItemType Directory -Force (Split-Path $stub) | Out-Null
$want = "[general]`nlive_config_reload = true`nimport = [`"$($ala -replace '\\', '/')`", `"$($alaTheme -replace '\\', '/')`"]"
if (-not ((Test-Path $stub) -and (Get-Content $stub -Raw).Trim() -eq $want)) {
    Backup $stub
    Set-Content -Encoding ascii $stub $want
}
Say "alacritty → $ala  (тема $Theme)"

# ── JetBrains Mono (per user, from the official GitHub release) ───────────────────────
$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$haveFont = Test-Path (Join-Path $fontDir 'JetBrainsMono-Regular.ttf')
if (-not $NoFont -and -not $haveFont) {
    $tmp = Join-Path $env:TEMP "paper-font-$stamp"; New-Item -ItemType Directory -Force $tmp | Out-Null
    $rel = Invoke-RestMethod 'https://api.github.com/repos/JetBrains/JetBrainsMono/releases/latest' -Headers @{ 'User-Agent' = 'paper-installer' }
    $zip = ($rel.assets | Where-Object name -match '^JetBrainsMono-[\d.]+\.zip$' | Select-Object -First 1).browser_download_url
    Invoke-WebRequest $zip -OutFile "$tmp\jbm.zip" -UseBasicParsing
    Expand-Archive "$tmp\jbm.zip" "$tmp\x" -Force
    New-Item -ItemType Directory -Force $fontDir | Out-Null
    $reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    foreach ($f in Get-ChildItem "$tmp\x\fonts\ttf\JetBrainsMono-*.ttf") {
        Copy-Item $f.FullName $fontDir -Force
        New-ItemProperty $reg -Name "$($f.BaseName -replace '-', ' ') (TrueType)" -Value (Join-Path $fontDir $f.Name) -PropertyType String -Force | Out-Null
    }
    Remove-Item $tmp -Recurse -Force
    Say "font   JetBrains Mono $($rel.tag_name)"
} elseif ($haveFont) { Say "font   JetBrains Mono уже стоит" }

# ── Obsidian snippet ──────────────────────────────────────────────────────────────────
if ($Vault) {
    if (-not (Test-Path (Join-Path $Vault '.obsidian'))) { throw "не похоже на волт Obsidian: $Vault" }
    $snip = Join-Path $Vault '.obsidian\snippets\paper.css'
    New-Item -ItemType Directory -Force (Split-Path $snip) | Out-Null
    Backup $snip
    Copy-Item (Join-Path $here 'obsidian\paper.css') $snip -Force
    Say "obsidian → $snip  (включи: Настройки → Оформление → CSS-сниппеты)"
}

# ── desktop widgets ───────────────────────────────────────────────────────────────────
if ($Widgets -or $All) {
    $wd = Join-Path $env:USERPROFILE 'paper-widgets'
    New-Item -ItemType Directory -Force "$wd\fonts" | Out-Null
    Copy-Item (Join-Path $here 'windows\widgets\*') $wd -Recurse -Force -Exclude 'widgets.config.json'
    Copy-Item (Join-Path $fontDir 'JetBrainsMono-*.ttf') "$wd\fonts" -Force -ErrorAction SilentlyContinue
    $cfg = Join-Path $wd 'widgets.config.json'
    if (-not (Test-Path $cfg)) {
        Copy-Item "$wd\widgets.config.example.json" $cfg
        if ($Vault) { (Get-Content $cfg -Raw).Replace('%USERPROFILE%\\Documents\\vault', ($Vault -replace '\\', '\\')) | Set-Content $cfg -Encoding UTF8 }
        Say "config → $cfg  (поправь волт и VPN-клиентов)"
    } else { Say "keep   $cfg" }
    $j = Get-Content $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($j.theme -ne $Theme) {
        $j | Add-Member -NotePropertyName theme -NotePropertyValue $Theme -Force
        $j | ConvertTo-Json -Depth 8 | Set-Content $cfg -Encoding UTF8
        Say "widgets theme → $Theme"
    }
    $lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'paper-widgets.lnk'
    $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
    $s.TargetPath = 'wscript.exe'; $s.Arguments = "`"$wd\start.vbs`""; $s.Save()
    Start-Process wscript.exe "`"$wd\start.vbs`""
    Say "widgets → $wd  (автозагрузка: $lnk)"
}

Write-Host @"

  дальше
  1. WSL:      wsl -d Debian -- bash install.sh   (t, приветствие, tmux)
  2. VS Code:  vscode\paper-*.jsonc или vscode\gruvbox.jsonc → в settings.json
  3. Obsidian: для gruvbox — тема «Obsidian gruvbox» из каталога тем, сниппет подстроится
  4. обои:     python tools\ascii_photo.py фото.jpg out.png 1920 1080 13 <шрифт.ttf>

"@
