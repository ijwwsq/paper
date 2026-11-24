# Desktop widgets: clock, unified VPN control, system stats. WPF, no dependencies.
param([string]$Snapshot)

# --- theme / font from widgets.config.json -----------------------------------------
# The script is written in the "paper" palette with JetBrains Mono. For "theme": "gruvbox" or a
# different "font", a re-colored copy (widgets.themed.ps1) is generated next to it and run instead.
if (-not $env:PAPER_WIDGETS_THEMED) {
    $dir0 = Split-Path -Parent $MyInvocation.MyCommand.Path
    $cfg0 = Join-Path $dir0 'widgets.config.json'
    $j0 = if (Test-Path -LiteralPath $cfg0) { Get-Content -LiteralPath $cfg0 -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $theme0 = if ($j0 -and $j0.theme) { "$($j0.theme)" } else { 'paper' }
    $font0 = if ($j0 -and $j0.font) { "$($j0.font)" } else { '' }
    if ($theme0 -ne 'paper' -or $font0) {
        $src0 = [IO.File]::ReadAllText($MyInvocation.MyCommand.Path)
        if ($theme0 -eq 'gruvbox') {
            $map0 = @{
                'FFFFFF' = '282828'; '2F2F2F' = 'EBDBB2'; '8C8C88' = '928374'; 'E4E4E0' = '504945'
                '5B6FA8' = 'FABD2F'; '5E8A5C' = 'B8BB26'; 'A5803A' = 'FE8019'; 'B5584E' = 'FB4934'
                'F2F2F2' = '3C3836'; 'EFEFEC' = '3C3836'; 'EDEDED' = '3C3836'; 'EAEAE6' = '3C3836'
                'E7E7E3' = '3C3836'; 'E4E4E4' = '3C3836'; 'E1E6F0' = '524629'; 'CBCCCD' = '665C54'
                'B9B9B4' = '665C54'
            }
            $src0 = [regex]::Replace($src0, '#[0-9A-Fa-f]{6}\b', { param($m) $k = $m.Value.Substring(1).ToUpper(); if ($map0.ContainsKey($k)) { '#' + $map0[$k] } else { $m.Value } })
            $src0 = $src0.Replace('$OffC = Color ' + '$Line', '$OffC = Color ''#' + '665C54''')   # split literals: the copy must not rewrite this line itself
        }
        if ($font0) {
            $src0 = $src0.Replace('FontFamily="@FONTS@#' + 'JetBrains Mono, Consolas"', "FontFamily=`"@FONTS@#$font0, Segoe UI`"")
            if ($font0 -eq 'Inter') {
                $src0 = $src0.Replace('<TextBlock x:Name="Time" ' + 'FontWeight="Light" FontSize="50"/>', '<TextBlock x:Name="Time" FontFamily="@FONTS@#Inter Display, Segoe UI Light" FontWeight="Light" FontSize="56"/>')
            }
        }
        $tmp0 = Join-Path $dir0 'widgets.themed.ps1'
        [IO.File]::WriteAllText($tmp0, $src0, (New-Object Text.UTF8Encoding $true))
        $env:PAPER_WIDGETS_THEMED = '1'
        & $tmp0 -Snapshot $Snapshot
        exit
    }
}

$created = $false
$mutex = New-Object System.Threading.Mutex($true, $(if ($Snapshot) { 'Local\DeskWidgetsSnapshot' } else { 'Local\DeskWidgets' }), [ref]$created)
if (-not $created) { exit }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -Namespace Desk -Name Native -MemberDefinition @'
[DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
[DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h, int i, int v);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
// WM_WINDOWPOSCHANGING: rewrite WINDOWPOS so any z-order change lands on HWND_BOTTOM.
public static IntPtr KeepBottom(IntPtr h, int msg, IntPtr w, IntPtr l, ref bool handled) {
    if (msg == 0x46) {
        int off = IntPtr.Size * 2 + 16;
        int flags = System.Runtime.InteropServices.Marshal.ReadInt32(l, off);
        System.Runtime.InteropServices.Marshal.WriteInt32(l, off, flags & ~0x4);
        System.Runtime.InteropServices.Marshal.WriteIntPtr(l, IntPtr.Size, new IntPtr(1));
    }
    return IntPtr.Zero;
}
'@

$Home_ = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $Home_ 'widgets.log'
function Log($m) { try { Add-Content -LiteralPath $LogFile -Value "$(Get-Date -Format s) $m" -Encoding UTF8 } catch {} }

# --- settings: widgets.config.json next to this script (see widgets.config.example.json) --------
function Expand-Path($p) { if ($p) { [Environment]::ExpandEnvironmentVariables($p) } }
$CfgPath = Join-Path $Home_ 'widgets.config.json'
$Cfg = if (Test-Path -LiteralPath $CfgPath) { Get-Content -LiteralPath $CfgPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
function CfgOr($v, $default) { if ($null -ne $v -and "$v" -ne '') { $v } else { $default } }

$Vault        = Expand-Path (CfgOr $Cfg.vault "$env:USERPROFILE\Documents\vault")
$VaultName    = CfgOr $Cfg.vaultName (Split-Path -Leaf $Vault)
$DailyDir     = CfgOr $Cfg.dailyDir 'daily'
$TemplatesDir = CfgOr $Cfg.templatesDir 'templates'
$RemindBefore = [int](CfgOr $Cfg.remindMinutes 15)
$OvpnGui      = Expand-Path (CfgOr $Cfg.openvpn.gui 'C:\Program Files\OpenVPN\bin\openvpn-gui.exe')
$OvpnDir      = Expand-Path (CfgOr $Cfg.openvpn.dir "$env:USERPROFILE\OpenVPN")
$OvpnStrip    = CfgOr $Cfg.openvpn.stripPrefix ''

$Vpns = New-Object System.Collections.ArrayList
if ($null -eq $Cfg -or $Cfg.openvpn.enabled -ne $false) {
    Get-ChildItem -LiteralPath (Join-Path $OvpnDir 'config') -Recurse -Filter *.ovpn -ErrorAction SilentlyContinue | ForEach-Object {
        $label = if ($OvpnStrip) { $_.BaseName -replace "^$([regex]::Escape($OvpnStrip))", '' } else { $_.BaseName }
        [void]$Vpns.Add(@{ Id = "ovpn:$($_.BaseName)"; Name = $label; Sub = ''; Kind = 'ovpn'; Key = $_.BaseName })
    }
}
# other clients: wireguard toggle (kind "wg") or an app shortcut detected by its network adapter (kind "app")
foreach ($a in @(CfgOr $Cfg.clients @(@{ id = 'wg'; name = 'WireGuard'; kind = 'wg' }))) {
    [void]$Vpns.Add(@{ Id = $a.id; Name = $a.name; Sub = (CfgOr $a.note ''); Kind = $a.kind; App = (Expand-Path $a.app); Match = $a.adapterMatch })
}

# --- background poller -------------------------------------------------------
$State = [hashtable]::Synchronized(@{ Vpn = @{}; Cpu = 0; Ram = 0; RamText = ''; Disk = 0; DiskText = ''; Down = 0.0; Up = 0.0; Stop = $false; Cal = $null; CalRev = 0; Cores = @(); Tick = 0 })
$rs = [runspacefactory]::CreateRunspace()
$rs.ApartmentState = 'MTA'
$rs.Open()
$rs.SessionStateProxy.SetVariable('State', $State)
$rs.SessionStateProxy.SetVariable('Vpns', $Vpns)
$rs.SessionStateProxy.SetVariable('OvpnDir', $OvpnDir)
$rs.SessionStateProxy.SetVariable('Vault', $Vault)
$rs.SessionStateProxy.SetVariable('TemplatesDir', $TemplatesDir)
$ps = [powershell]::Create()
$ps.Runspace = $rs
[void]$ps.AddScript({
    function Read-Tail($path) {
        try {
            $fs = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite,Delete')
            try {
                $fs.Seek([Math]::Max(0, $fs.Length - 32768), 'Begin') | Out-Null
                (New-Object IO.StreamReader($fs)).ReadToEnd()
            } finally { $fs.Close() }
        } catch { '' }
    }
    # Reads the vault (never writes). Dated: Tasks-plugin marks and time blocks in today's/future daily notes.
    function Read-Vault {
        $today = (Get-Date).Date
        $days = @{}
        $dated = New-Object System.Collections.ArrayList
        $open = New-Object System.Collections.ArrayList
        $seen = @{}
        $mark = '(?:📅|⏳|🛫)️?\s*(\d{4}-\d{2}-\d{2})|\[(?:due|scheduled)::\s*(\d{4}-\d{2}-\d{2})\]'
        $files = Get-ChildItem -LiteralPath $Vault -Recurse -Filter *.md -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch ('\\\.obsidian\\|\\' + [regex]::Escape($TemplatesDir) + '\\') }
        foreach ($f in $files) {
            $fileDay = $null
            if ($f.BaseName -match '^\d{4}-\d{2}-\d{2}$') {
                $fileDay = [datetime]::ParseExact($f.BaseName, 'yyyy-MM-dd', $null)
                if (-not $days[$f.BaseName]) { $days[$f.BaseName] = 'note' }
            }
            $rel = $f.FullName.Substring($Vault.Length + 1).Replace('\', '/') -replace '\.md$', ''
            foreach ($line in [IO.File]::ReadAllLines($f.FullName)) {
                if ($line -notmatch '^\s*- \[[ /]\]\s*(\S.*)$') { continue }   # [ ] todo, [/] in progress
                $t = $Matches[1]
                $d = $null; $time = ''
                $m = [regex]::Match($t, $mark)
                if ($m.Success) {
                    $d = [datetime]::ParseExact($(if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }), 'yyyy-MM-dd', $null)
                }
                $t = ([regex]::Replace($t, $mark, '')).Trim()
                if ($t -match '^(\d{1,2}:\d{2})(?:\s*[-–]\s*\d{1,2}:\d{2})?\s*(.*)$') { $time = $Matches[1]; $t = $Matches[2] }
                $t = ($t -replace '\s*\[(started|spent)::[^\]]*\]', '' -replace '\s*✅\s*\d{4}-\d{2}-\d{2}', '' -replace '\[\[|\]\]', '' -replace '(^|\s)#[\w/-]+', '').Trim()   # hide t's time fields
                if (-not $t) { continue }
                $byMark = [bool]$d
                if (-not $d -and $fileDay -and ($fileDay -gt $today -or ($fileDay -eq $today -and $time))) { $d = $fileDay }
                if ($d) {
                    if ($d -ge $today -or $byMark) {
                        [void]$dated.Add(@{ Date = $d; Time = $time; Text = $t; File = $rel; Overdue = ($d -lt $today) })
                        if ($d -ge $today) { $days[$d.ToString('yyyy-MM-dd')] = 'event' }
                    }
                } elseif ($fileDay -and -not $time -and -not $seen[$t]) {
                    $seen[$t] = $true
                    [void]$open.Add(@{ Date = $fileDay; Text = $t; File = $rel })
                }
            }
        }
        @{
            Days = $days
            Dated = @($dated | Sort-Object { $_.Date }, { $_.Time })
            Open = @($open | Sort-Object { $_.Date } -Descending)
        }
    }

    $virtual = 'TAP|Wintun|OpenVPN|Fortinet|Cisco|Citrix|VirtualBox|Hyper-V|WSL|Bluetooth|Loopback|WireGuard'
    $lastRx = 0L; $lastTx = 0L; $lastT = $null
    $nextVault = Get-Date
    while (-not $State.Stop) {
        try {
            if ((Get-Date) -ge $nextVault) {
                $nextVault = (Get-Date).AddSeconds(60)
                $State.Cal = Read-Vault
                $State.CalRev = $State.CalRev + 1
            }
            $procs = @(Get-CimInstance Win32_Process -Filter "Name='openvpn.exe'" -ErrorAction SilentlyContinue)
            $ads = @(Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })
            $vs = @{}
            foreach ($v in $Vpns) {
                $st = 'off'
                switch ($v.Kind) {
                    'ovpn' {
                        $key = [regex]::Escape($v.Key)
                        if ($procs | Where-Object { $_.CommandLine -match "--config `"$key\.ovpn`"" }) {
                            $tail = Read-Tail (Join-Path $OvpnDir "log\$($v.Key).log")
                            $done = $tail.LastIndexOf('Initialization Sequence Completed')
                            $lost = [Math]::Max($tail.LastIndexOf('Restart pause'), $tail.LastIndexOf('SIGUSR1'))
                            $st = if ($done -ge 0 -and $done -gt $lost) { 'on' } else { 'busy' }
                        }
                    }
                    'wg' { if (Get-Service 'WireGuardTunnel$*' -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }) { $st = 'on' } }
                    'app' { if ($ads | Where-Object { $_.InterfaceDescription -match $v.Match }) { $st = 'on' } }
                }
                $vs[$v.Id] = $st
            }
            $State.Vpn = $vs

            $os = Get-CimInstance Win32_OperatingSystem
            $pp = @(Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -ErrorAction SilentlyContinue)
            $tot = $pp | Where-Object { $_.Name -eq '_Total' }
            $State.Cpu = if ($tot) { [int]$tot.PercentProcessorTime } else { [int](Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average }
            $State.Cores = @($pp | Where-Object { $_.Name -ne '_Total' } | Sort-Object { [int]$_.Name } | ForEach-Object { [int]$_.PercentProcessorTime })
            $total = $os.TotalVisibleMemorySize; $free = $os.FreePhysicalMemory
            $State.Ram = [int](100 * ($total - $free) / $total)
            $State.RamText = '{0:0.0} ГБ' -f (($total - $free) / 1MB)
            $d = New-Object IO.DriveInfo 'C'
            $State.Disk = [int](100 * ($d.TotalSize - $d.AvailableFreeSpace) / $d.TotalSize)
            $State.DiskText = '{0:0} ГБ своб.' -f ($d.AvailableFreeSpace / 1GB)

            $rx = 0L; $tx = 0L
            foreach ($n in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
                if ("$($n.OperationalStatus)" -ne 'Up' -or $n.Description -match $virtual) { continue }
                if ("$($n.NetworkInterfaceType)" -notin 'Ethernet', 'Wireless80211') { continue }
                $s = $n.GetIPStatistics(); $rx += $s.BytesReceived; $tx += $s.BytesSent
            }
            $now = Get-Date
            if ($lastT) {
                $dt = ($now - $lastT).TotalSeconds
                $State.Down = [Math]::Max(0, ($rx - $lastRx) / $dt); $State.Up = [Math]::Max(0, ($tx - $lastTx) / $dt)
            }
            $lastRx = $rx; $lastTx = $tx; $lastT = $now
            $State.Tick = $State.Tick + 1
        } catch { $State.Err = "$_" }
        Start-Sleep -Seconds 3
    }
})
$poll = $ps.BeginInvoke()

# --- ui ----------------------------------------------------------------------
$FontBase = 'file:///' + $Home_.Replace([string][char]92, '/') + '/fonts/'
$xamlText = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ShowInTaskbar="False" ResizeMode="NoResize" Width="662" SizeToContent="Height"
        ShowActivated="False" FontFamily="@FONTS@#JetBrains Mono, Consolas" Foreground="#2F2F2F"
        TextOptions.TextFormattingMode="Ideal" TextOptions.TextRenderingMode="Grayscale" UseLayoutRounding="True">
  <Window.Resources>
    <Style x:Key="Card" TargetType="Border">
      <Setter Property="CornerRadius" Value="8"/>
      <Setter Property="Margin" Value="0,0,0,12"/>
      <Setter Property="Background" Value="#FFFFFF"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="BorderBrush" Value="#E4E4E4"/>
      <Setter Property="Effect">
        <Setter.Value><DropShadowEffect BlurRadius="24" ShadowDepth="4" Direction="270" Opacity="0.10" Color="#000000"/></Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Tint" TargetType="Border">
      <Setter Property="CornerRadius" Value="8"/>
      <Setter Property="Background" Value="Transparent"/>
    </Style>
    <Style x:Key="Head" TargetType="TextBlock">
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style x:Key="Dim" TargetType="TextBlock">
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="Foreground" Value="#8C8C88"/>
    </Style>
  </Window.Resources>
  <Grid x:Name="Root" Margin="22,20,22,12">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="*"/>
      <ColumnDefinition Width="12"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>
    <DockPanel Grid.Column="0">
      <Border x:Name="CardClock" DockPanel.Dock="Top" Style="{StaticResource Card}">
        <Border Style="{StaticResource Tint}" Padding="20,10,20,12">
          <DockPanel>
            <StackPanel DockPanel.Dock="Right" VerticalAlignment="Bottom" Margin="0,0,0,9">
              <TextBlock x:Name="Weekday" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Right"/>
              <TextBlock x:Name="Date" FontSize="12" Foreground="#8C8C88" HorizontalAlignment="Right"/>
            </StackPanel>
            <TextBlock x:Name="Time" FontWeight="Light" FontSize="50"/>
          </DockPanel>
        </Border>
      </Border>
      <Border x:Name="CardCal" Style="{StaticResource Card}">
        <Border Style="{StaticResource Tint}" Padding="16,14,16,12">
          <StackPanel>
            <DockPanel Margin="2,0,2,8">
              <TextBlock x:Name="Year" DockPanel.Dock="Right" Style="{StaticResource Dim}"/>
              <TextBlock x:Name="Month" Style="{StaticResource Head}"/>
            </DockPanel>
            <UniformGrid x:Name="WeekDays" Columns="7" Margin="0,0,0,2"/>
            <UniformGrid x:Name="DaysGrid" Columns="7"/>
            <Border Height="1" Background="#EDEDED" Margin="2,10,2,10"/>
            <StackPanel x:Name="Events"/>
          </StackPanel>
        </Border>
      </Border>
    </DockPanel>
    <DockPanel Grid.Column="2">
      <Border x:Name="CardSys" DockPanel.Dock="Bottom" Style="{StaticResource Card}">
        <Border Style="{StaticResource Tint}" Padding="18,14,18,12">
          <StackPanel>
            <!-- cpu: section rule, history graph, per-core bars -->
            <DockPanel Margin="0,0,0,6">
              <TextBlock x:Name="CpuPct" DockPanel.Dock="Right" FontSize="12" Margin="8,0,0,0"/>
              <TextBlock Text="cpu" Style="{StaticResource Head}" Margin="0,0,8,0"/>
              <Border Height="1" Background="#E4E4E0" VerticalAlignment="Center"/>
            </DockPanel>
            <Grid Height="46" ClipToBounds="True">
              <Border BorderBrush="#EFEFEC" BorderThickness="0,0,0,1"/>
              <Canvas x:Name="CpuGraph"/>
            </Grid>
            <Grid x:Name="Cores" Height="16" Margin="0,6,0,0"/>
            <TextBlock x:Name="CpuInfo" Style="{StaticResource Dim}" FontSize="10" Margin="0,4,0,12"/>
            <!-- mem / disk: segmented meters -->
            <DockPanel Margin="0,0,0,8">
              <TextBlock Text="mem" Style="{StaticResource Head}" Margin="0,0,8,0"/>
              <Border Height="1" Background="#E4E4E0" VerticalAlignment="Center"/>
            </DockPanel>
            <StackPanel x:Name="Rings"/>
            <!-- net: mirrored graph, down above / up below -->
            <DockPanel Margin="0,2,0,6">
              <TextBlock Text="net" Style="{StaticResource Head}" Margin="0,0,8,0"/>
              <Border Height="1" Background="#E4E4E0" VerticalAlignment="Center"/>
            </DockPanel>
            <DockPanel>
              <TextBlock x:Name="NetPeak" DockPanel.Dock="Right" Style="{StaticResource Dim}" FontSize="10"/>
              <TextBlock x:Name="NetDown" FontSize="11"/>
            </DockPanel>
            <Grid Height="52" Margin="0,4,0,4" ClipToBounds="True">
              <Border Height="1" Background="#E4E4E0" VerticalAlignment="Center"/>
              <Canvas x:Name="NetGraph"/>
            </Grid>
            <TextBlock x:Name="NetUp" FontSize="11" Foreground="#5B6FA8"/>
          </StackPanel>
        </Border>
      </Border>
      <Border x:Name="CardVpn" Style="{StaticResource Card}">
        <Border Style="{StaticResource Tint}" Padding="10,14,10,10">
          <StackPanel>
            <DockPanel Margin="8,0,8,4">
              <TextBlock x:Name="VpnCount" DockPanel.Dock="Right" Style="{StaticResource Dim}"/>
              <TextBlock Text="vpn" Style="{StaticResource Head}"/>
            </DockPanel>
            <StackPanel x:Name="VpnList"/>
          </StackPanel>
        </Border>
      </Border>
    </DockPanel>
  </Grid>
</Window>
'@
[xml]$xaml = $xamlText.Replace('@FONTS@', $FontBase)
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
foreach ($n in 'Time', 'Date', 'Weekday', 'VpnCount', 'VpnList', 'Rings', 'NetUp', 'NetDown', 'NetPeak', 'NetGraph', 'CpuGraph', 'CpuPct', 'CpuInfo', 'Cores', 'Month', 'Year', 'WeekDays', 'DaysGrid', 'Events', 'CardClock', 'CardVpn', 'CardSys', 'CardCal') { $ui[$n] = $win.FindName($n) }

function Color($c) { [Windows.Media.ColorConverter]::ConvertFromString($c) }
function Brush($c) { New-Object Windows.Media.SolidColorBrush (Color $c) }
# palette: soft paper (same as Alacritty)
$Ink = '#2F2F2F'; $Grey = '#8C8C88'; $Line = '#E4E4E0'; $Accent = '#5B6FA8'; $Ok = '#5E8A5C'; $Warn = '#A5803A'; $Bad = '#B5584E'
$GreenC = Color $Ink; $AmberC = Color $Grey; $OffC = Color $Line
$Dim = Brush $Grey; $White = Brush '#FFFFFF'; $Hover = Brush '#F2F2F2'; $Clear = Brush '#00FFFFFF'; $DotOff = Brush '#CBCCCD'

function New-Text($t, $size, $fg) {
    $b = New-Object Windows.Controls.TextBlock
    $b.Text = $t; $b.FontSize = $size
    if ($fg) { $b.Foreground = $fg }
    $b
}
function New-Section($t) {
    $s = New-Text $t 11 $Dim
    $s.Margin = '8,8,8,3'
    $s.Opacity = 0.8
    $s
}

$Rows = @{}
$Pending = @{}

function Invoke-Vpn($v) {
    try {
        $on = $State.Vpn[$v.Id] -ne 'off'
        switch ($v.Kind) {
            'ovpn' {
                $verb = if ($on) { 'disconnect' } else { 'connect' }
                Start-Process -FilePath $OvpnGui -ArgumentList '--command', $verb, "`"$($v.Key)`""
                $Pending[$v.Id] = (Get-Date).AddSeconds(15)
            }
            'wg' {
                Start-Process -FilePath powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$(Join-Path $Home_ 'wg-toggle.ps1')`""
                $Pending[$v.Id] = (Get-Date).AddSeconds(15)
            }
            'app' { Start-Process -FilePath $v.App }
        }
    } catch { Log "action $($v.Id): $($_.Exception.Message)" }
}

$group = ''
foreach ($v in $Vpns) {
    $g = if ($v.Kind -eq 'ovpn') { 'openvpn' } else { 'другие клиенты' }
    if ($g -ne $group) { [void]$ui.VpnList.Children.Add((New-Section $g)); $group = $g }

    $wrap = New-Object Windows.Controls.Border
    $wrap.CornerRadius = 5; $wrap.Padding = '8,4'; $wrap.Background = $Clear; $wrap.Cursor = 'Hand'; $wrap.Tag = $v
    $wrap.Add_MouseEnter({ param($s, $e) $s.Background = $Hover })
    $wrap.Add_MouseLeave({ param($s, $e) $s.Background = $Clear })
    $wrap.Add_MouseLeftButtonUp({ param($s, $e) Invoke-Vpn $s.Tag })

    $row = New-Object Windows.Controls.DockPanel
    $dot = New-Object Windows.Shapes.Ellipse
    $dot.Width = 6; $dot.Height = 6; $dot.Fill = $DotOff; $dot.Margin = '0,0,10,0'; $dot.VerticalAlignment = 'Center'
    [Windows.Controls.DockPanel]::SetDock($dot, 'Left')
    [void]$row.Children.Add($dot)

    $knob = $null; $track = $null
    if ($v.Kind -eq 'app') {
        $chev = New-Text '›' 18 $Dim
        $chev.Margin = '0,-5,4,-3'
        [Windows.Controls.DockPanel]::SetDock($chev, 'Right')
        [void]$row.Children.Add($chev)
    } else {
        $pill = New-Object Windows.Controls.Border
        $pill.Width = 30; $pill.Height = 16; $pill.CornerRadius = 8; $pill.VerticalAlignment = 'Center'
        $track = New-Object Windows.Media.SolidColorBrush $OffC
        $pill.Background = $track
        $knob = New-Object Windows.Media.TranslateTransform
        $e = New-Object Windows.Shapes.Ellipse
        $e.Width = 12; $e.Height = 12; $e.Fill = $White; $e.HorizontalAlignment = 'Left'; $e.Margin = '2,0,0,0'
        $e.RenderTransform = $knob
        $pill.Child = $e
        [Windows.Controls.DockPanel]::SetDock($pill, 'Right')
        [void]$row.Children.Add($pill)
    }

    $names = New-Object Windows.Controls.StackPanel
    $names.Orientation = 'Horizontal'
    $names.VerticalAlignment = 'Center'
    $nameText = New-Text $v.Name 12 $null
    [void]$names.Children.Add($nameText)
    $sub = New-Text '' 11 $Dim
    $sub.VerticalAlignment = 'Center'
    [void]$names.Children.Add($sub)
    [void]$row.Children.Add($names)

    $wrap.Child = $row
    [void]$ui.VpnList.Children.Add($wrap)
    $Rows[$v.Id] = @{ Dot = $dot; Track = $track; Knob = $knob; Sub = $sub; Base = $(if ($v.Sub) { "   $($v.Sub)" } else { '' }); Last = 'off' }
}

# Segmented meters (btop-style): "mem  ■■■■■■■■■■□□□□  89%" with the detail line under it.
$SegN = 22
$SegOn = Brush $Ink; $SegOff = Brush '#E7E7E3'; $SegHot = Brush $Bad
$Ring = @{}
foreach ($m in @(@('Ram', 'ram'), @('Disk', 'disk'))) {
    $row = New-Object Windows.Controls.Grid
    $row.Margin = '0,0,0,10'
    foreach ($w in 40, '*', 46) {
        $cd = New-Object Windows.Controls.ColumnDefinition
        $cd.Width = if ($w -eq '*') { New-Object Windows.GridLength 1, 'Star' } else { New-Object Windows.GridLength $w }
        [void]$row.ColumnDefinitions.Add($cd)
    }
    $name = New-Text $m[1] 11 $Dim
    $name.VerticalAlignment = 'Top'
    [void]$row.Children.Add($name)

    $mid = New-Object Windows.Controls.StackPanel
    [Windows.Controls.Grid]::SetColumn($mid, 1)
    $segs = New-Object Windows.Controls.Primitives.UniformGrid
    $segs.Columns = $SegN; $segs.Height = 8; $segs.Margin = '0,4,0,0'
    $cells = @()
    for ($i = 0; $i -lt $SegN; $i++) {
        $b = New-Object Windows.Controls.Border
        $b.Margin = '0,0,2,0'; $b.CornerRadius = 1; $b.Background = $SegOff
        [void]$segs.Children.Add($b); $cells += $b
    }
    $val = New-Text '' 10 $Dim
    $val.Margin = '0,4,0,0'
    [void]$mid.Children.Add($segs); [void]$mid.Children.Add($val)
    [void]$row.Children.Add($mid)

    $pct = New-Text '' 12 $null
    $pct.HorizontalAlignment = 'Right'; $pct.VerticalAlignment = 'Top'
    [Windows.Controls.Grid]::SetColumn($pct, 2)
    [void]$row.Children.Add($pct)

    [void]$ui.Rings.Children.Add($row)
    $Ring[$m[0]] = @{ Cells = $cells; Pct = $pct; Val = $val }
}

function Set-Ring($r, $pct, $text) {
    $p = [Math]::Max(0, [Math]::Min(100, [int]$pct))
    $r.Pct.Text = "$p%"
    $r.Val.Text = $text
    $on = [int][Math]::Round($p / 100 * $SegN)
    for ($i = 0; $i -lt $SegN; $i++) {
        $r.Cells[$i].Background = if ($i -ge $on) { $SegOff } elseif ($p -ge 90 -and $i -ge $SegN - 3) { $SegHot } else { $SegOn }
    }
}

# --- history graphs ------------------------------------------------------------
$HistN = 60                                   # 60 samples x 3 s = last 3 minutes
$Hist = @{ Cpu = New-Object Collections.Generic.List[double]; Down = New-Object Collections.Generic.List[double]; Up = New-Object Collections.Generic.List[double] }
$script:LastTick = -1
$GraphFill = Brush '#EAEAE6'; $GraphLine = Brush $Ink; $UpFill = Brush '#E1E6F0'; $UpLine = Brush $Accent

function Push-Hist($list, $v) { $list.Add([double]$v); while ($list.Count -gt $HistN) { $list.RemoveAt(0) } }

# Area graph: values 0..max -> polygon from the baseline. $dir = -1 grows up from $base, +1 grows down.
function Add-Area($canvas, $vals, [double]$max, [double]$base, [double]$span, [double]$dir, $fill, $line) {
    $w = $canvas.ActualWidth; if ($w -le 0) { $w = 270 }
    $n = $vals.Count; if ($n -lt 2) { return }
    $step = $w / ($HistN - 1)
    $x0 = $w - ($n - 1) * $step
    $pts = New-Object Windows.Media.PointCollection
    $poly = New-Object Windows.Media.PointCollection
    $poly.Add((New-Object Windows.Point $x0, $base))
    for ($i = 0; $i -lt $n; $i++) {
        $y = $base + $dir * $span * [Math]::Min(1, $vals[$i] / [Math]::Max($max, 1e-9))
        $p = New-Object Windows.Point ($x0 + $i * $step), $y
        $pts.Add($p); $poly.Add($p)
    }
    $poly.Add((New-Object Windows.Point $w, $base))
    $pg = New-Object Windows.Shapes.Polygon; $pg.Points = $poly; $pg.Fill = $fill
    $pl = New-Object Windows.Shapes.Polyline; $pl.Points = $pts; $pl.Stroke = $line; $pl.StrokeThickness = 1.2; $pl.StrokeLineJoin = 'Round'
    [void]$canvas.Children.Add($pg); [void]$canvas.Children.Add($pl)
}

function Update-Graphs {
    $c = $ui.CpuGraph; $c.Children.Clear()
    $h = 46
    Add-Area $c $Hist.Cpu 100 $h ($h - 3) -1 $GraphFill $GraphLine

    $g = $ui.NetGraph; $g.Children.Clear()
    $mid = 26
    $peak = [Math]::Max(64KB, [Math]::Max(($Hist.Down | Measure-Object -Maximum).Maximum, ($Hist.Up | Measure-Object -Maximum).Maximum))
    Add-Area $g $Hist.Down $peak $mid ($mid - 2) -1 $GraphFill $GraphLine
    Add-Area $g $Hist.Up $peak $mid ($mid - 2) 1 $UpFill $UpLine
    $ui.NetPeak.Text = "пик $(Format-Speed $peak)"
}

# per-core bars, built once the poller knows the core count
$CoreBars = @()
function Update-Cores {
    $cores = @($State.Cores)
    if (-not $cores.Count) { return }
    if ($CoreBars.Count -ne $cores.Count) {
        $ui.Cores.Children.Clear(); $ui.Cores.ColumnDefinitions.Clear(); $script:CoreBars = @()
        for ($i = 0; $i -lt $cores.Count; $i++) {
            $cd = New-Object Windows.Controls.ColumnDefinition; [void]$ui.Cores.ColumnDefinitions.Add($cd)
            $r = New-Object Windows.Controls.Border
            $r.Margin = '1,0,1,0'; $r.VerticalAlignment = 'Bottom'; $r.CornerRadius = 1
            [Windows.Controls.Grid]::SetColumn($r, $i)
            [void]$ui.Cores.Children.Add($r); $script:CoreBars += $r
        }
    }
    for ($i = 0; $i -lt $cores.Count; $i++) {
        $p = [Math]::Max(0, [Math]::Min(100, $cores[$i]))
        $CoreBars[$i].Height = 2 + 14 * $p / 100
        $CoreBars[$i].Background = if ($p -ge 90) { $SegHot } elseif ($p -ge 25) { $SegOn } else { Brush '#B9B9B4' }
    }
}

function Format-Speed($b) {
    if ($b -ge 1MB) { '{0:0.0} МБ/с' -f ($b / 1MB) } elseif ($b -ge 1KB) { '{0:0} КБ/с' -f ($b / 1KB) } else { '0 КБ/с' }
}

function Set-Toggle($r, $st) {
    if ($st -eq $r.Last) { return }
    $r.Last = $st
    $d = New-Object Windows.Duration ([TimeSpan]::FromMilliseconds(180))
    $x = if ($st -eq 'off') { 0 } else { 14 }   # 30 - 12 - 2*2
    $c = switch ($st) { 'on' { $GreenC } 'busy' { $AmberC } default { $OffC } }
    $r.Knob.BeginAnimation([Windows.Media.TranslateTransform]::XProperty, (New-Object Windows.Media.Animation.DoubleAnimation($x, $d)))
    $r.Track.BeginAnimation([Windows.Media.SolidColorBrush]::ColorProperty, (New-Object Windows.Media.Animation.ColorAnimation($c, $d)))
}

$Ru = [Globalization.CultureInfo]::GetCultureInfo('ru-RU')
$script:Boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$script:CalShown = -1
$script:CalDay = ''

function Open-Note($file) {
    try { Start-Process "obsidian://open?vault=$([Uri]::EscapeDataString($VaultName))&file=$([Uri]::EscapeDataString($file))" } catch { Log "note: $($_.Exception.Message)" }
}

foreach ($d in 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс') {
    $h = New-Text $d 11 $Dim
    $h.HorizontalAlignment = 'Center'
    [void]$ui.WeekDays.Children.Add($h)
}

function Format-Day($d, $today) {
    if ($d -eq $today) { 'сегодня' } elseif ($d -eq $today.AddDays(1)) { 'завтра' } else { $d.ToString('ddd, d MMMM', $Ru) }
}

function New-EventRow($title, $sub, $subBrush, $file) {
    $b = New-Object Windows.Controls.Border
    $b.CornerRadius = 8; $b.Padding = '6,4'; $b.Background = $Clear; $b.Cursor = 'Hand'; $b.Tag = $file
    $b.Add_MouseEnter({ param($s, $e) $s.Background = $Hover })
    $b.Add_MouseLeave({ param($s, $e) $s.Background = $Clear })
    $b.Add_MouseLeftButtonUp({ param($s, $e) Open-Note $s.Tag })
    $st = New-Object Windows.Controls.StackPanel
    $t = New-Text $title 12 $null
    $t.TextTrimming = 'CharacterEllipsis'
    [void]$st.Children.Add($t)
    [void]$st.Children.Add((New-Text $sub 11 $subBrush))
    $b.Child = $st
    $b
}

function Update-Calendar($now) {
    $today = $now.Date
    $first = New-Object datetime $today.Year, $today.Month, 1
    $ui.Month.Text = $Ru.DateTimeFormat.GetMonthName($today.Month).ToLower()
    $ui.Year.Text = "$($today.Year)"
    $cal = $State.Cal
    $days = if ($cal) { $cal.Days } else { @{} }

    $ui.DaysGrid.Children.Clear()
    $lead = ([int]$first.DayOfWeek + 6) % 7
    $count = [datetime]::DaysInMonth($today.Year, $today.Month)
    for ($i = 0; $i -lt 42; $i++) {
        $n = $i - $lead + 1
        if ($i -ge 35 -and $n -gt $count) { break }
        $cell = New-Object Windows.Controls.Grid
        $cell.Height = 28
        if ($n -ge 1 -and $n -le $count) {
            $day = $first.AddDays($n - 1)
            $key = $day.ToString('yyyy-MM-dd')
            $kind = $days[$key]
            if ($day -eq $today) {
                $o = New-Object Windows.Shapes.Rectangle
                $o.Width = 24; $o.Height = 22; $o.RadiusX = 4; $o.RadiusY = 4; $o.Fill = Brush $Ink
                [void]$cell.Children.Add($o)
            }
            $t = New-Text "$n" 12 $null
            $t.HorizontalAlignment = 'Center'; $t.VerticalAlignment = 'Center'
            if ($day -eq $today) { $t.FontWeight = 'SemiBold'; $t.Foreground = $White }
            elseif ("$($day.DayOfWeek)" -in 'Saturday', 'Sunday') { $t.Foreground = $Dim }
            [void]$cell.Children.Add($t)
            if ($kind -and $day -ne $today) {
                $o = New-Object Windows.Shapes.Ellipse
                $o.Width = 4; $o.Height = 4; $o.VerticalAlignment = 'Bottom'; $o.Margin = '0,0,0,1'
                $o.Fill = if ($kind -eq 'event') { Brush $Accent } else { $DotOff }
                [void]$cell.Children.Add($o)
            }
            if ($kind) {
                $cell.Background = $Clear; $cell.Cursor = 'Hand'; $cell.Tag = "$DailyDir/$key"
                $cell.Add_MouseLeftButtonUp({ param($s, $e) Open-Note $s.Tag })
            }
        }
        [void]$ui.DaysGrid.Children.Add($cell)
    }

    $ui.Events.Children.Clear()
    $max = 4
    $shown = 0
    $dated = if ($cal) { @($cal.Dated) } else { @() }
    $s = New-Text 'ближайшее' 11 $Dim
    $s.Margin = '6,0,0,4'
    [void]$ui.Events.Children.Add($s)
    foreach ($e in $dated | Select-Object -First $max) {
        $when = Format-Day $e.Date $today
        if ($e.Time) { $when += " · $($e.Time)" }
        if ($e.Overdue) { [void]$ui.Events.Children.Add((New-EventRow $e.Text "просрочено · $when" (Brush $Bad) $e.File)) }
        else { [void]$ui.Events.Children.Add((New-EventRow $e.Text $when $Dim $e.File)) }
        $shown++
    }
    if (-not $shown) {
        $n = New-Text 'событий с датой нет' 11 $Dim
        $n.Margin = '6,0,0,8'
        [void]$ui.Events.Children.Add($n)
    }
    $rest = $max - $shown
    if ($cal -and $rest -gt 0 -and @($cal.Open).Count) {
        $s = New-Text 'открытые задачи' 11 $Dim
        $s.Margin = '6,6,0,4'
        [void]$ui.Events.Children.Add($s)
        foreach ($e in @($cal.Open) | Select-Object -First $rest) {
            [void]$ui.Events.Children.Add((New-EventRow $e.Text "из заметки $($e.Date.ToString('d MMMM', $Ru))" $Dim $e.File))
        }
    }
}

# --- reminders: native Windows toast 15 min before a timed vault task ---------
$ToastAppId = 'DeskWidgets.Calendar'
$Notified = @{}
try {
    # Register an app id so toasts show "Календарь" instead of "Windows PowerShell".
    $k = "HKCU:\Software\Classes\AppUserModelId\$ToastAppId"
    if (-not (Test-Path $k)) { New-Item $k -Force | Out-Null }
    Set-ItemProperty $k DisplayName 'Календарь'
    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($ToastAppId)
} catch { $Notifier = $null; Log "toast init: $($_.Exception.Message)" }

function Show-Reminder($e, $start) {
    if (-not $Notifier) { return }
    $x = { param($s) [Security.SecurityElement]::Escape("$s") }
    $mins = [int][Math]::Ceiling(($start - (Get-Date)).TotalMinutes)
    $when = if ($mins -le 0) { "сейчас · $($e.Time)" } else { "через $mins мин · $($e.Time)" }
    $url = "obsidian://open?vault=$([Uri]::EscapeDataString($VaultName))&amp;file=$([Uri]::EscapeDataString($e.File))"
    $xml = @"
<toast scenario="urgent" launch="$url" activationType="protocol">
  <visual><binding template="ToastGeneric">
    <text>$(& $x $e.Text)</text>
    <text>$(& $x $when)</text>
  </binding></visual>
  <actions>
    <action content="Открыть заметку" arguments="$url" activationType="protocol"/>
    <action content="Закрыть" arguments="dismiss" activationType="system"/>
  </actions>
  <audio src="ms-winsoundevent:Notification.Reminder"/>
</toast>
"@
    try {
        $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $doc.LoadXml($xml)
        $Notifier.Show((New-Object Windows.UI.Notifications.ToastNotification $doc))
        Log "reminder: $($e.Text) @ $start"
    } catch { Log "toast: $($_.Exception.Message)" }
}

function Test-Reminders($now) {
    $cal = $State.Cal
    if (-not $cal) { return }
    foreach ($e in @($cal.Dated)) {
        if (-not $e.Time -or $e.Overdue) { continue }
        $start = $e.Date.Add([TimeSpan]::Parse($e.Time))
        $key = "$($start.ToString('s'))|$($e.Text)"
        if ($Notified[$key]) { continue }
        if ($now -ge $start.AddMinutes(-$RemindBefore) -and $now -lt $start.AddMinutes(1)) {
            $Notified[$key] = $true
            Show-Reminder $e $start
        }
    }
}

function Update-Ui {
    $now = Get-Date
    try { Test-Reminders $now } catch { Log "reminders: $($_.Exception.Message)" }
    $ui.Time.Text = $now.ToString('HH:mm')
    $ui.Weekday.Text = $now.ToString('dddd', $Ru)
    $ui.Date.Text = $now.ToString('d MMMM', $Ru)

    $active = 0
    foreach ($v in $Vpns) {
        $r = $Rows[$v.Id]
        $st = $State.Vpn[$v.Id]
        if (-not $st) { $st = 'off' }
        if ($Pending.ContainsKey($v.Id)) {
            if ($now -gt $Pending[$v.Id]) { $Pending.Remove($v.Id) } elseif ($st -eq 'off') { $st = 'busy' }
        }
        if ($st -eq 'on') { $active++ }
        $r.Dot.Fill = switch ($st) { 'on' { Brush $Ok } 'busy' { Brush $Warn } default { $DotOff } }
        $r.Sub.Text = if ($st -eq 'busy') { '   подключение…' } else { $r.Base }
        if ($r.Knob) { Set-Toggle $r $st }
    }
    $ui.VpnCount.Text = if ($active) { "активно: $active" } else { 'всё выключено' }

    Set-Ring $Ring.Ram $State.Ram $State.RamText
    Set-Ring $Ring.Disk $State.Disk $State.DiskText
    $ui.CpuPct.Text = "$($State.Cpu)%"
    $up = (Get-Date) - $script:Boot
    $ui.CpuInfo.Text = "потоков: $env:NUMBER_OF_PROCESSORS · uptime $([int]$up.TotalDays)д $($up.Hours)ч · 3 мин"
    $ui.NetDown.Text = "↓ $(Format-Speed $State.Down)"
    $ui.NetUp.Text = "↑ $(Format-Speed $State.Up)"
    if ($State.Tick -ne $script:LastTick) {               # new sample from the poller (every 3 s)
        $script:LastTick = $State.Tick
        Push-Hist $Hist.Cpu $State.Cpu; Push-Hist $Hist.Down $State.Down; Push-Hist $Hist.Up $State.Up
        Update-Graphs
        Update-Cores
    }

    $dayKey = $now.ToString('yyyy-MM-dd')
    if ($State.CalRev -ne $script:CalShown -or $dayKey -ne $script:CalDay) {
        $script:CalShown = $State.CalRev; $script:CalDay = $dayKey
        Update-Calendar $now
    }
}

# Frosted glass: each card shows the part of the blurred wallpaper that lies behind it.
$GlassPath = Join-Path $Home_ 'glass.jpg'
$Glass = $null
if ($false -and (Test-Path -LiteralPath $GlassPath)) {   # glass off: light theme uses solid white cards
    $Glass = New-Object Windows.Media.Imaging.BitmapImage
    $Glass.BeginInit()
    $Glass.UriSource = New-Object Uri $GlassPath
    $Glass.CacheOption = 'OnLoad'
    $Glass.EndInit()
}

function Set-Glass {
    if (-not $Glass) { return }
    $sw = [Windows.SystemParameters]::PrimaryScreenWidth
    $sh = [Windows.SystemParameters]::PrimaryScreenHeight
    foreach ($c in $ui.CardClock, $ui.CardVpn, $ui.CardSys, $ui.CardCal) {
        $p = $c.TranslatePoint((New-Object Windows.Point 0, 0), $win)
        $b = New-Object Windows.Media.ImageBrush $Glass
        $b.ViewboxUnits = 'RelativeToBoundingBox'
        $b.Viewbox = New-Object Windows.Rect (($win.Left + $p.X) / $sw), (($win.Top + $p.Y) / $sh), ($c.ActualWidth / $sw), ($c.ActualHeight / $sh)
        $b.Stretch = 'Fill'
        $c.Background = $b
    }
}

function Set-Place {
    $area = [Windows.SystemParameters]::WorkArea
    $win.Left = $area.Right - $win.ActualWidth
    $win.Top = $area.Top
    Set-Glass
}

$win.Add_SourceInitialized({
    $h = (New-Object Windows.Interop.WindowInteropHelper $win).Handle
    $ex = [Desk.Native]::GetWindowLong($h, -20)
    [void][Desk.Native]::SetWindowLong($h, -20, $ex -bor 0x80 -bor 0x08000000)   # TOOLWINDOW | NOACTIVATE
    [Windows.Interop.HwndSource]::FromHwnd($h).AddHook([Delegate]::CreateDelegate([Windows.Interop.HwndSourceHook], [Desk.Native].GetMethod('KeepBottom')))
    [void][Desk.Native]::SetWindowPos($h, [IntPtr]1, 0, 0, 0, 0, 0x13)           # HWND_BOTTOM, no move/size/activate
})
$win.Add_ContentRendered({ Set-Place })
$win.Add_SizeChanged({ Set-Place })
foreach ($c in $ui.CardClock, $ui.CardVpn, $ui.CardSys, $ui.CardCal) { $c.Add_SizeChanged({ Set-Glass }) }

$menu = New-Object Windows.Controls.ContextMenu
$exit = New-Object Windows.Controls.MenuItem
$exit.Header = 'Закрыть виджеты'
$exit.Add_Click({ $win.Close() })
[void]$menu.Items.Add($exit)
$win.ContextMenu = $menu

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({ try { Update-Ui } catch { Log "tick: $($_.Exception.Message) @ line $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())" } })
$timer.Start()

if ($Snapshot) {
    # Renders the widget itself to a PNG; never reads the screen.
    $snap = New-Object Windows.Threading.DispatcherTimer
    $snap.Interval = [TimeSpan]::FromSeconds(25)
    $snap.Add_Tick({
        $snap.Stop()
        if ($State.Err) { Log "poll: $($State.Err)" }
        Log "snapshot left=$($win.Left) top=$($win.Top) down=$($State.Down) up=$($State.Up)"
        $c = $win.Content
        $w = [int]$win.ActualWidth; $h = [int]$win.ActualHeight
        $rtb = New-Object Windows.Media.Imaging.RenderTargetBitmap ($w * 2), ($h * 2), 192, 192, ([Windows.Media.PixelFormats]::Pbgra32)
        $rtb.Render($c)
        $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder
        $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($rtb))
        $fs = [IO.File]::Create($Snapshot)
        $enc.Save($fs); $fs.Close()
        $win.Close()
    })
    $snap.Start()
}

$app = New-Object Windows.Application
$app.ShutdownMode = 'OnMainWindowClose'
try { [void]$app.Run($win) } catch { Log "fatal: $($_.Exception.Message)" }
$State.Stop = $true
$mutex.ReleaseMutex()
[Environment]::Exit(0)
