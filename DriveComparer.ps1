Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

if (-not ('CompareResult' -as [type])) {
    Add-Type -TypeDefinition @"
using System.ComponentModel;
public class CompareResult : INotifyPropertyChanged {
    public event PropertyChangedEventHandler PropertyChanged;
    private bool _selected;
    public bool Selected {
        get { return _selected; }
        set { _selected = value; if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs("Selected")); }
    }
    public string Status { get; set; }
    public string Path { get; set; }
    public long Size { get; set; }
    public string SizeDisplay { get; set; }
    public string Detail { get; set; }
}
"@
}

$script:SettingsPath = Join-Path $env:LOCALAPPDATA 'DriveComparer\settings.json'

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Drive Comparer" Height="860" Width="1280"
        WindowStartupLocation="CenterScreen"
        Background="#17171C" Foreground="#E6E6E6"
        FontFamily="Segoe UI" FontSize="13">
    <Window.Resources>
        <SolidColorBrush x:Key="Accent"     Color="#4FC3F7"/>
        <SolidColorBrush x:Key="AccentDeep" Color="#0D7AC9"/>
        <SolidColorBrush x:Key="Panel"      Color="#242429"/>
        <SolidColorBrush x:Key="PanelDeep"  Color="#1B1B20"/>
        <SolidColorBrush x:Key="Border"     Color="#3A3A44"/>
        <SolidColorBrush x:Key="Muted"      Color="#8B8B94"/>
        <SolidColorBrush x:Key="RowAlt"     Color="#1F1F25"/>
        <SolidColorBrush x:Key="Missing"    Color="#F06A6A"/>
        <SolidColorBrush x:Key="Different"  Color="#F0C36A"/>
        <SolidColorBrush x:Key="Extra"      Color="#8AB4F8"/>
        <SolidColorBrush x:Key="Ok"         Color="#6AD08A"/>

        <Style TargetType="Button">
            <Setter Property="Background" Value="{StaticResource Panel}"/>
            <Setter Property="Foreground" Value="#E6E6E6"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#33333C"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.45"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="{StaticResource AccentDeep}"/>
            <Setter Property="BorderBrush" Value="{StaticResource AccentDeep}"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource Panel}"/>
            <Setter Property="Foreground" Value="#E6E6E6"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="CaretBrush" Value="#E6E6E6"/>
            <Setter Property="SelectionBrush" Value="{StaticResource Accent}"/>
        </Style>

        <Style TargetType="Label">
            <Setter Property="Foreground" Value="{StaticResource Muted}"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Padding" Value="0"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E6E6E6"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Margin" Value="0,0,24,0"/>
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Background" Value="{StaticResource PanelDeep}"/>
            <Setter Property="Foreground" Value="{StaticResource Accent}"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <Style TargetType="DataGrid">
            <Setter Property="Background"            Value="{StaticResource PanelDeep}"/>
            <Setter Property="Foreground"            Value="#E6E6E6"/>
            <Setter Property="BorderBrush"           Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness"       Value="1"/>
            <Setter Property="GridLinesVisibility"   Value="Horizontal"/>
            <Setter Property="HorizontalGridLinesBrush" Value="#2A2A30"/>
            <Setter Property="RowBackground"         Value="{StaticResource PanelDeep}"/>
            <Setter Property="AlternatingRowBackground" Value="{StaticResource RowAlt}"/>
            <Setter Property="HeadersVisibility"     Value="Column"/>
            <Setter Property="RowHeaderWidth"        Value="0"/>
            <Setter Property="SelectionMode"         Value="Extended"/>
            <Setter Property="SelectionUnit"         Value="FullRow"/>
            <Setter Property="EnableRowVirtualization" Value="True"/>
        </Style>

        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background"      Value="{StaticResource Panel}"/>
            <Setter Property="Foreground"      Value="{StaticResource Muted}"/>
            <Setter Property="BorderBrush"     Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
            <Setter Property="Padding"         Value="10,8"/>
            <Setter Property="FontWeight"      Value="SemiBold"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
        </Style>

        <Style TargetType="DataGridCell">
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding"         Value="8,4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="DataGridCell">
                        <Border Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#2A3A4D"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="DataGridRow">
            <Setter Property="Foreground" Value="#E6E6E6"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,16">
            <TextBlock Text="Drive Comparer" FontSize="24" FontWeight="SemiBold" Foreground="{StaticResource Accent}"/>
            <TextBlock Text="compare &#183; verify &#183; selectively copy" Margin="14,0,0,0"
                       VerticalAlignment="Center" Foreground="{StaticResource Muted}"/>
        </StackPanel>

        <Grid Grid.Row="1" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Label  Grid.Row="0" Grid.Column="0" Content="Source" Width="60"/>
            <TextBox Grid.Row="0" Grid.Column="1" x:Name="TxtSource" AllowDrop="True" Margin="0,0,8,6"/>
            <Button  Grid.Row="0" Grid.Column="2" x:Name="BtnBrowseSource" Content="Browse..." Width="110" Margin="0,0,0,6"/>
            <Label  Grid.Row="1" Grid.Column="0" Content="Target" Width="60"/>
            <TextBox Grid.Row="1" Grid.Column="1" x:Name="TxtTarget" AllowDrop="True" Margin="0,0,8,0"/>
            <Button  Grid.Row="1" Grid.Column="2" x:Name="BtnBrowseTarget" Content="Browse..." Width="110"/>
        </Grid>

        <Grid Grid.Row="2" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Label Grid.Column="0" Content="Exclude" Width="60"/>
            <TextBox Grid.Column="1" x:Name="TxtExclude" ToolTip="Semicolon-separated globs, matched against any path segment. e.g. *.tmp;node_modules;.git"/>
        </Grid>

        <Border Grid.Row="3" Background="{StaticResource PanelDeep}" BorderBrush="{StaticResource Border}"
                BorderThickness="1" CornerRadius="4" Padding="12,10" Margin="0,0,0,12">
            <StackPanel Orientation="Horizontal">
                <CheckBox x:Name="ChkTwoWay"     Content="Two-way compare"/>
                <CheckBox x:Name="ChkChecksum"   Content="Verify with SHA256"/>
                <CheckBox x:Name="ChkSkipHidden" Content="Skip hidden files" Margin="0,0,0,0"/>
            </StackPanel>
        </Border>

        <DataGrid Grid.Row="4" x:Name="GridResults" AutoGenerateColumns="False" CanUserAddRows="False"
                  CanUserDeleteRows="False" CanUserResizeRows="False" IsReadOnly="False">
            <DataGrid.Columns>
                <DataGridCheckBoxColumn Header="" Binding="{Binding Selected, UpdateSourceTrigger=PropertyChanged}" Width="40"/>
                <DataGridTextColumn Header="Status"      Binding="{Binding Status}"      Width="110" IsReadOnly="True"/>
                <DataGridTextColumn Header="Path"        Binding="{Binding Path}"        Width="*"   IsReadOnly="True"/>
                <DataGridTextColumn Header="Size"        Binding="{Binding SizeDisplay}" Width="120" IsReadOnly="True"/>
                <DataGridTextColumn Header="Detail"      Binding="{Binding Detail}"      Width="220" IsReadOnly="True"/>
            </DataGrid.Columns>
        </DataGrid>

        <Grid Grid.Row="5" Margin="0,12,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <ProgressBar Grid.Column="0" x:Name="ProgressBar" Height="18" Minimum="0" Maximum="100" Value="0"/>
            <TextBlock   Grid.Column="1" x:Name="TxtStatus" Text="Idle" Margin="14,0,0,0"
                         VerticalAlignment="Center" Foreground="{StaticResource Muted}" MinWidth="220"/>
        </Grid>

        <Border Grid.Row="6" Background="{StaticResource PanelDeep}" BorderBrush="{StaticResource Border}"
                BorderThickness="1" CornerRadius="4" Padding="12,8" Margin="0,10,0,0">
            <TextBlock x:Name="TxtSummary" Foreground="{StaticResource Muted}" TextWrapping="Wrap"
                       Text="No comparison run yet."/>
        </Border>

        <Grid Grid.Row="7" Margin="0,12,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Orientation="Horizontal">
                <Button x:Name="BtnSelectAll"  Content="Select All"   Width="100" Height="32" Margin="0,0,6,0"/>
                <Button x:Name="BtnSelectNone" Content="Select None"  Width="100" Height="32" Margin="0,0,6,0"/>
                <Button x:Name="BtnCopySel"    Content="Copy Selected to Target" Width="200" Height="32"/>
            </StackPanel>
            <StackPanel Grid.Column="2" Orientation="Horizontal">
                <Button x:Name="BtnSave"   Content="Save Results"   Width="140" Height="32" Margin="0,0,6,0"/>
                <Button x:Name="BtnCancel" Content="Cancel"         Width="100" Height="32" Margin="0,0,6,0" IsEnabled="False"/>
                <Button x:Name="BtnRun"    Content="Run Comparison" Width="180" Height="32" Style="{StaticResource PrimaryButton}"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$TxtSource       = $window.FindName("TxtSource")
$TxtTarget       = $window.FindName("TxtTarget")
$TxtExclude      = $window.FindName("TxtExclude")
$BtnBrowseSource = $window.FindName("BtnBrowseSource")
$BtnBrowseTarget = $window.FindName("BtnBrowseTarget")
$ChkTwoWay       = $window.FindName("ChkTwoWay")
$ChkChecksum     = $window.FindName("ChkChecksum")
$ChkSkipHidden   = $window.FindName("ChkSkipHidden")
$GridResults     = $window.FindName("GridResults")
$ProgressBar     = $window.FindName("ProgressBar")
$TxtStatus       = $window.FindName("TxtStatus")
$TxtSummary      = $window.FindName("TxtSummary")
$BtnRun          = $window.FindName("BtnRun")
$BtnCancel       = $window.FindName("BtnCancel")
$BtnSave         = $window.FindName("BtnSave")
$BtnCopySel      = $window.FindName("BtnCopySel")
$BtnSelectAll    = $window.FindName("BtnSelectAll")
$BtnSelectNone   = $window.FindName("BtnSelectNone")

$script:results = New-Object 'System.Collections.ObjectModel.ObservableCollection[CompareResult]'
$GridResults.ItemsSource = $script:results

function Format-Size([long]$bytes) {
    if ($bytes -lt 1024)          { return "$bytes B" }
    $u = 'KB','MB','GB','TB','PB'
    $v = [double]$bytes / 1024
    $i = 0
    while ($v -ge 1024 -and $i -lt $u.Length - 1) { $v /= 1024; $i++ }
    return ('{0:N2} {1}' -f $v, $u[$i])
}

function Load-Settings {
    if (-not (Test-Path -LiteralPath $script:SettingsPath)) { return }
    try {
        $s = Get-Content -LiteralPath $script:SettingsPath -Raw | ConvertFrom-Json
        if ($s.Source)     { $TxtSource.Text     = [string]$s.Source }
        if ($s.Target)     { $TxtTarget.Text     = [string]$s.Target }
        if ($s.Exclude)    { $TxtExclude.Text    = [string]$s.Exclude }
        $ChkTwoWay.IsChecked     = [bool]$s.TwoWay
        $ChkChecksum.IsChecked   = [bool]$s.Checksum
        $ChkSkipHidden.IsChecked = [bool]$s.SkipHidden
    } catch { }
}

function Save-Settings {
    try {
        $dir = Split-Path -LiteralPath $script:SettingsPath -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $s = [ordered]@{
            Source     = $TxtSource.Text
            Target     = $TxtTarget.Text
            Exclude    = $TxtExclude.Text
            TwoWay     = [bool]$ChkTwoWay.IsChecked
            Checksum   = [bool]$ChkChecksum.IsChecked
            SkipHidden = [bool]$ChkSkipHidden.IsChecked
        }
        ($s | ConvertTo-Json) | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8
    } catch { }
}

function Select-Folder($description) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $description
    $dlg.ShowNewFolderButton = $true
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dlg.SelectedPath }
    return $null
}

$BtnBrowseSource.Add_Click({ $p = Select-Folder "Select source folder"; if ($p) { $TxtSource.Text = $p } })
$BtnBrowseTarget.Add_Click({ $p = Select-Folder "Select target folder"; if ($p) { $TxtTarget.Text = $p } })

$dragOver = {
    param($s, $e)
    $e.Handled = $true
    if ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        $e.Effects = [System.Windows.DragDropEffects]::Copy
    } else {
        $e.Effects = [System.Windows.DragDropEffects]::None
    }
}
$dropHandler = {
    param($s, $e)
    $e.Handled = $true
    if ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
        $files = $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
        if ($files -and $files.Length -gt 0) {
            $p = [string]$files[0]
            if (Test-Path -LiteralPath $p -PathType Container) {
                $s.Text = $p
            } elseif (Test-Path -LiteralPath $p) {
                $s.Text = Split-Path -LiteralPath $p -Parent
            }
        }
    }
}
$TxtSource.Add_PreviewDragOver($dragOver)
$TxtTarget.Add_PreviewDragOver($dragOver)
$TxtSource.Add_Drop($dropHandler)
$TxtTarget.Add_Drop($dropHandler)

$script:sync = [hashtable]::Synchronized(@{
    Cancelled = $false
    Running   = $false
    Done      = $false
    Queue     = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    Status    = $null
    Progress  = [double]0
    Summary   = $null
})
$script:ps          = $null
$script:asyncResult = $null
$script:runspace    = $null
$script:uiTimer     = $null

function Reset-UIForRun($clearGrid) {
    if ($clearGrid) { $script:results.Clear() }
    $ProgressBar.Value = 0
    $TxtStatus.Text = "Starting..."
    $BtnRun.IsEnabled    = $false
    $BtnCancel.IsEnabled = $true
    $BtnSave.IsEnabled   = $false
    $BtnCopySel.IsEnabled   = $false
    $BtnSelectAll.IsEnabled  = $false
    $BtnSelectNone.IsEnabled = $false
    $BtnBrowseSource.IsEnabled = $false
    $BtnBrowseTarget.IsEnabled = $false
}

function Finalize-Run {
    $BtnRun.IsEnabled    = $true
    $BtnCancel.IsEnabled = $false
    $BtnSave.IsEnabled   = $true
    $BtnCopySel.IsEnabled    = $true
    $BtnSelectAll.IsEnabled  = $true
    $BtnSelectNone.IsEnabled = $true
    $BtnBrowseSource.IsEnabled = $true
    $BtnBrowseTarget.IsEnabled = $true
    if ($script:ps) {
        try { $script:ps.EndInvoke($script:asyncResult) | Out-Null } catch { }
        $script:ps.Dispose()
        $script:ps = $null
    }
    if ($script:runspace) {
        $script:runspace.Close()
        $script:runspace.Dispose()
        $script:runspace = $null
    }
    $script:sync.Running = $false
}

function Pump-UI {
    $item = $null
    $drained = 0
    while ($drained -lt 1000 -and $script:sync.Queue.TryDequeue([ref]$item)) {
        if ($item -is [CompareResult]) {
            $script:results.Add($item)
        }
        $drained++
    }
    if ($script:sync.Status) { $TxtStatus.Text = $script:sync.Status }
    $ProgressBar.Value = [Math]::Max(0, [Math]::Min(100, [double]$script:sync.Progress))
    if ($script:sync.Summary) { $TxtSummary.Text = $script:sync.Summary }
}

$compareWorker = {
    param($sync, $opts)

    $q = $sync.Queue

    function Emit-Result([string]$status, [string]$path, [long]$size, [string]$detail, [bool]$selected) {
        $r = New-Object CompareResult
        $r.Selected    = $selected
        $r.Status      = $status
        $r.Path        = $path
        $r.Size        = $size
        $r.SizeDisplay = if ($size -ge 0) {
            if     ($size -lt 1024) { "$size B" }
            else {
                $u = 'KB','MB','GB','TB','PB'; $v = [double]$size / 1024; $i = 0
                while ($v -ge 1024 -and $i -lt $u.Length - 1) { $v /= 1024; $i++ }
                ('{0:N2} {1}' -f $v, $u[$i])
            }
        } else { '' }
        $r.Detail = $detail
        $q.Enqueue($r)
    }

    function SetStatus([string]$text, $progress) {
        $sync.Status = $text
        if ($null -ne $progress) { $sync.Progress = [double]$progress }
    }

    function Is-Excluded([System.IO.FileInfo]$f, [string]$root, [string[]]$patterns) {
        if (-not $patterns -or $patterns.Count -eq 0) { return $false }
        $rel = $f.FullName.Substring($root.Length + 1)
        foreach ($seg in ($rel -split '[\\/]+')) {
            foreach ($pat in $patterns) {
                if ($seg -like $pat) { return $true }
            }
        }
        return $false
    }

    try {
        $started = Get-Date

        $patterns = @()
        if ($opts.Exclude) {
            $patterns = @($opts.Exclude -split '[;,]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }

        SetStatus "Scanning source..." 0
        $srcAll = @(Get-ChildItem -LiteralPath $opts.Source -Recurse -File -Force -ErrorAction SilentlyContinue)
        $srcFiles = foreach ($f in $srcAll) {
            if ($opts.SkipHidden -and ($f.Attributes -band [IO.FileAttributes]::Hidden)) { continue }
            if (Is-Excluded $f $opts.Source $patterns) { continue }
            $f
        }
        $srcFiles = @($srcFiles)

        SetStatus "Scanning target..." 0
        $tgtAll = @(Get-ChildItem -LiteralPath $opts.Target -Recurse -File -Force -ErrorAction SilentlyContinue)
        $tgtFiles = foreach ($f in $tgtAll) {
            if ($opts.SkipHidden -and ($f.Attributes -band [IO.FileAttributes]::Hidden)) { continue }
            if (Is-Excluded $f $opts.Target $patterns) { continue }
            $f
        }
        $tgtFiles = @($tgtFiles)

        $srcLen = $opts.Source.Length + 1
        $tgtLen = $opts.Target.Length + 1

        $tgtIndex = New-Object 'System.Collections.Generic.Dictionary[string,System.IO.FileInfo]' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($f in $tgtFiles) {
            $rel = $f.FullName.Substring($tgtLen)
            $tgtIndex[$rel] = $f
        }

        $missingCount = 0L; $missingBytes = 0L
        $diffCount    = 0L; $diffBytes    = 0L
        $extraCount   = 0L; $extraBytes   = 0L

        $total = [Math]::Max($srcFiles.Count, 1)
        $count = 0
        SetStatus "Comparing..." 0

        foreach ($src in $srcFiles) {
            if ($sync.Cancelled) {
                SetStatus "Cancelled" $null
                $sync.Done = $true
                return
            }
            $count++
            if (($count % 100) -eq 0 -or $count -eq $total) {
                $pct = ($count / $total) * 100
                SetStatus ("Comparing... {0:N0} / {1:N0}" -f $count, $total) $pct
            }

            $rel = $src.FullName.Substring($srcLen)
            $tgt = $null
            if (-not $tgtIndex.TryGetValue($rel, [ref]$tgt)) {
                Emit-Result 'Missing' $rel $src.Length '' $true
                $missingCount++; $missingBytes += $src.Length
                continue
            }
            if ($src.Length -ne $tgt.Length) {
                $detail = "size {0:N0} vs {1:N0}" -f $src.Length, $tgt.Length
                Emit-Result 'Different' $rel $src.Length $detail $true
                $diffCount++; $diffBytes += $src.Length
                continue
            }
            if ($opts.Checksum) {
                $sh = (Get-FileHash -LiteralPath $src.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                $th = (Get-FileHash -LiteralPath $tgt.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
                if ($sh -ne $th) {
                    Emit-Result 'Different' $rel $src.Length 'hash mismatch' $true
                    $diffCount++; $diffBytes += $src.Length
                }
            }
        }

        if ($opts.TwoWay) {
            SetStatus "Finding extras in target..." 100
            $srcSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
            foreach ($f in $srcFiles) { [void]$srcSet.Add($f.FullName.Substring($srcLen)) }
            foreach ($f in $tgtFiles) {
                if ($sync.Cancelled) { break }
                $rel = $f.FullName.Substring($tgtLen)
                if (-not $srcSet.Contains($rel)) {
                    Emit-Result 'Extra' $rel $f.Length '' $false
                    $extraCount++; $extraBytes += $f.Length
                }
            }
        }

        $elapsed = (Get-Date) - $started
        $fmt = {
            param([long]$b)
            if ($b -lt 1024) { return "$b B" }
            $u = 'KB','MB','GB','TB','PB'; $v = [double]$b / 1024; $i = 0
            while ($v -ge 1024 -and $i -lt $u.Length - 1) { $v /= 1024; $i++ }
            '{0:N2} {1}' -f $v, $u[$i]
        }

        $parts = @(
            ("Missing {0:N0} ({1})"   -f $missingCount, (& $fmt $missingBytes))
            ("Different {0:N0} ({1})" -f $diffCount,    (& $fmt $diffBytes))
        )
        if ($opts.TwoWay) {
            $parts += ("Extra {0:N0} ({1})" -f $extraCount, (& $fmt $extraBytes))
        }
        $parts += ("Scanned src {0:N0} / tgt {1:N0}" -f $srcFiles.Count, $tgtFiles.Count)
        $parts += ("Elapsed {0:hh\:mm\:ss}" -f $elapsed)
        $sep = '   ' + [char]0x00B7 + '   '
        $sync.Summary = ($parts -join $sep)

        SetStatus "Done" 100
    }
    catch {
        SetStatus ("Error: " + $_.Exception.Message) $null
    }
    finally {
        $sync.Done = $true
    }
}

$copyWorker = {
    param($sync, $opts, $items)

    function SetStatus([string]$text, $progress) {
        $sync.Status = $text
        if ($null -ne $progress) { $sync.Progress = [double]$progress }
    }

    try {
        $total   = [Math]::Max($items.Count, 1)
        $copied  = 0
        $failed  = 0
        $skipped = 0
        $bytes   = 0L

        for ($i = 0; $i -lt $items.Count; $i++) {
            if ($sync.Cancelled) { break }
            $item = $items[$i]
            $pct = (($i + 1) / $total) * 100
            SetStatus ("Copying... {0:N0} / {1:N0}" -f ($i + 1), $total) $pct

            if ($item.Status -eq 'Extra') { $skipped++; continue }

            $srcPath = Join-Path $opts.Source $item.Path
            $dstPath = Join-Path $opts.Target $item.Path
            try {
                $destDir = Split-Path -LiteralPath $dstPath -Parent
                if (-not (Test-Path -LiteralPath $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Copy-Item -LiteralPath $srcPath -Destination $dstPath -Force -ErrorAction Stop
                $copied++
                $bytes += $item.Size
            } catch {
                $failed++
            }
        }

        $fmt = {
            param([long]$b)
            if ($b -lt 1024) { return "$b B" }
            $u = 'KB','MB','GB','TB','PB'; $v = [double]$b / 1024; $i = 0
            while ($v -ge 1024 -and $i -lt $u.Length - 1) { $v /= 1024; $i++ }
            '{0:N2} {1}' -f $v, $u[$i]
        }

        $sync.Summary = ("Copy complete  -  copied {0:N0} ({1}), failed {2:N0}, skipped {3:N0}" -f `
            $copied, (& $fmt $bytes), $failed, $skipped)
        if ($sync.Cancelled) { SetStatus "Cancelled" $null } else { SetStatus "Done" 100 }
    }
    catch {
        SetStatus ("Error: " + $_.Exception.Message) $null
    }
    finally {
        $sync.Done = $true
    }
}

function Start-Worker($scriptBlock, $arguments) {
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions  = "ReuseThread"
    $rs.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript($scriptBlock)
    foreach ($a in $arguments) { [void]$ps.AddArgument($a) }
    $script:runspace    = $rs
    $script:ps          = $ps
    $script:asyncResult = $ps.BeginInvoke()

    if ($script:uiTimer) { $script:uiTimer.Stop() }
    $script:uiTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:uiTimer.Interval = [TimeSpan]::FromMilliseconds(120)
    $script:uiTimer.Add_Tick({
        Pump-UI
        if ($script:sync.Done -and $script:sync.Queue.Count -eq 0) {
            $script:uiTimer.Stop()
            Pump-UI
            Finalize-Run
        }
    })
    $script:uiTimer.Start()
}

$BtnRun.Add_Click({
    if ($script:sync.Running) { return }

    $source = $TxtSource.Text.Trim()
    $target = $TxtTarget.Text.Trim()

    if (-not $source -or -not (Test-Path -LiteralPath $source -PathType Container)) {
        [System.Windows.MessageBox]::Show("Source folder is not valid.", "Invalid path", "OK", "Warning") | Out-Null; return
    }
    if (-not $target -or -not (Test-Path -LiteralPath $target -PathType Container)) {
        [System.Windows.MessageBox]::Show("Target folder is not valid.", "Invalid path", "OK", "Warning") | Out-Null; return
    }

    $opts = @{
        Source     = $source.TrimEnd('\')
        Target     = $target.TrimEnd('\')
        Exclude    = $TxtExclude.Text
        TwoWay     = [bool]$ChkTwoWay.IsChecked
        Checksum   = [bool]$ChkChecksum.IsChecked
        SkipHidden = [bool]$ChkSkipHidden.IsChecked
    }

    Save-Settings
    Reset-UIForRun $true
    $TxtSummary.Text = "Comparing..."

    $script:sync.Cancelled = $false
    $script:sync.Done      = $false
    $script:sync.Running   = $true
    $script:sync.Status    = "Starting..."
    $script:sync.Progress  = 0
    $script:sync.Queue     = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $script:sync.Summary   = $null

    Start-Worker $compareWorker @($script:sync, $opts)
})

$BtnCopySel.Add_Click({
    if ($script:sync.Running) { return }

    $selected = @($script:results | Where-Object { $_.Selected -and $_.Status -ne 'Extra' })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No selectable rows are checked. (Extra rows can't be copied.)", "Nothing to copy", "OK", "Information") | Out-Null
        return
    }

    $totalBytes = ($selected | Measure-Object -Property Size -Sum).Sum
    $msg = "Copy {0:N0} files ({1}) from source to target?" -f $selected.Count, (Format-Size ([long]$totalBytes))
    $confirm = [System.Windows.MessageBox]::Show($msg, "Confirm copy", "OKCancel", "Question")
    if ($confirm -ne [System.Windows.MessageBoxResult]::OK) { return }

    $opts = @{
        Source = $TxtSource.Text.TrimEnd('\')
        Target = $TxtTarget.Text.TrimEnd('\')
    }

    Reset-UIForRun $false

    $script:sync.Cancelled = $false
    $script:sync.Done      = $false
    $script:sync.Running   = $true
    $script:sync.Status    = "Copying..."
    $script:sync.Progress  = 0
    $script:sync.Queue     = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $script:sync.Summary   = $null

    Start-Worker $copyWorker @($script:sync, $opts, $selected)
})

$BtnSelectAll.Add_Click({
    foreach ($r in $script:results) { if ($r.Status -ne 'Extra') { $r.Selected = $true } }
})
$BtnSelectNone.Add_Click({
    foreach ($r in $script:results) { $r.Selected = $false }
})

$BtnCancel.Add_Click({
    if ($script:sync.Running) {
        $script:sync.Cancelled = $true
        $TxtStatus.Text = "Cancelling..."
    }
})

$BtnSave.Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter   = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
    $dlg.FileName = "DriveComparisonResults.txt"
    if ($dlg.ShowDialog() -eq $true) {
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine("Drive Comparer Results")
        [void]$sb.AppendLine("Source: $($TxtSource.Text)")
        [void]$sb.AppendLine("Target: $($TxtTarget.Text)")
        [void]$sb.AppendLine("Generated: $(Get-Date)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine(("{0,-12} {1,12}  {2}" -f 'STATUS','SIZE','PATH'))
        foreach ($r in $script:results) {
            [void]$sb.AppendLine(("{0,-12} {1,12}  {2}" -f $r.Status, $r.SizeDisplay, $r.Path))
        }
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("Summary: $($TxtSummary.Text)")
        [System.IO.File]::WriteAllText($dlg.FileName, $sb.ToString(), [System.Text.Encoding]::UTF8)
    }
})

$window.Add_Closing({
    if ($script:sync.Running) {
        $script:sync.Cancelled = $true
        if ($script:ps) { try { $script:ps.Stop() } catch {} }
    }
    if ($script:uiTimer) { $script:uiTimer.Stop() }
    Save-Settings
})

Load-Settings

[void]$window.ShowDialog()
