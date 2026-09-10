# raw2dng GUI for Windows — no install. Run via raw2dng-gui.cmd
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dnglab = Join-Path $Here "dnglab.exe"
if (-not (Test-Path $Dnglab)) {
  [System.Windows.Forms.MessageBox]::Show("dnglab.exe not found next to this script.","raw2dng")
  exit 2
}

$RawExts = @(".arw",".cr2",".cr3",".crw",".dng",".nef",".nrw",".orf",".pef",".raf",".raw",".rw2",".srw",".x3f")

$form = New-Object System.Windows.Forms.Form
$form.Text = "raw2dng — RAW → DNG"
$form.Size = New-Object System.Drawing.Size(740, 560)
$form.StartPosition = "CenterScreen"

$list = New-Object System.Windows.Forms.ListBox
$list.SelectionMode = "MultiExtended"
$list.Location = New-Object System.Drawing.Point(12, 50)
$list.Size = New-Object System.Drawing.Size(700, 280)
$form.Controls.Add($list)

$btnFiles = New-Object System.Windows.Forms.Button
$btnFiles.Text = "파일 추가"
$btnFiles.Location = New-Object System.Drawing.Point(12, 12)
$btnFiles.Add_Click({
  $ofd = New-Object System.Windows.Forms.OpenFileDialog
  $ofd.Multiselect = $true
  $ofd.Filter = "RAW|*.arw;*.cr2;*.cr3;*.nef;*.raf;*.orf;*.rw2;*.dng;*.raw|All|*.*"
  if ($ofd.ShowDialog() -eq "OK") { foreach ($f in $ofd.FileNames) { [void]$list.Items.Add($f) } }
})
$form.Controls.Add($btnFiles)

$btnFolder = New-Object System.Windows.Forms.Button
$btnFolder.Text = "폴더 추가"
$btnFolder.Location = New-Object System.Drawing.Point(100, 12)
$btnFolder.Add_Click({
  $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
  if ($fbd.ShowDialog() -eq "OK") { [void]$list.Items.Add($fbd.SelectedPath) }
})
$form.Controls.Add($btnFolder)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "목록 비우기"
$btnClear.Location = New-Object System.Drawing.Point(188, 12)
$btnClear.Add_Click({ $list.Items.Clear() })
$form.Controls.Add($btnClear)

$chkSame = New-Object System.Windows.Forms.CheckBox
$chkSame.Text = "원본과 같은 폴더에 저장"
$chkSame.Checked = $true
$chkSame.Location = New-Object System.Drawing.Point(12, 340)
$chkSame.AutoSize = $true
$form.Controls.Add($chkSame)

$chkOver = New-Object System.Windows.Forms.CheckBox
$chkOver.Text = "덮어쓰기"
$chkOver.Checked = $true
$chkOver.Location = New-Object System.Drawing.Point(200, 340)
$chkOver.AutoSize = $true
$form.Controls.Add($chkOver)

$lblOut = New-Object System.Windows.Forms.Label
$lblOut.Text = "출력 폴더"
$lblOut.Location = New-Object System.Drawing.Point(12, 370)
$form.Controls.Add($lblOut)

$txtOut = New-Object System.Windows.Forms.TextBox
$txtOut.Location = New-Object System.Drawing.Point(90, 368)
$txtOut.Size = New-Object System.Drawing.Size(520, 23)
$txtOut.Enabled = $false
$form.Controls.Add($txtOut)

$btnOut = New-Object System.Windows.Forms.Button
$btnOut.Text = "찾기…"
$btnOut.Location = New-Object System.Drawing.Point(620, 366)
$btnOut.Enabled = $false
$btnOut.Add_Click({
  $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
  if ($fbd.ShowDialog() -eq "OK") { $txtOut.Text = $fbd.SelectedPath }
})
$form.Controls.Add($btnOut)

$chkSame.Add_CheckedChanged({
  $txtOut.Enabled = -not $chkSame.Checked
  $btnOut.Enabled = -not $chkSame.Checked
})

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ScrollBars = "Vertical"
$log.ReadOnly = $true
$log.Location = New-Object System.Drawing.Point(12, 430)
$log.Size = New-Object System.Drawing.Size(700, 70)
$form.Controls.Add($log)

function Get-RawFiles($items) {
  $files = @()
  foreach ($item in $items) {
    if (Test-Path $item -PathType Leaf) {
      $ext = [IO.Path]::GetExtension($item).ToLower()
      if ($RawExts -contains $ext) { $files += $item }
    } elseif (Test-Path $item -PathType Container) {
      Get-ChildItem -Path $item -Recurse -File | ForEach-Object {
        if ($RawExts -contains $_.Extension.ToLower()) { $files += $_.FullName }
      }
    }
  }
  return $files | Select-Object -Unique
}

$btnGo = New-Object System.Windows.Forms.Button
$btnGo.Text = "DNG로 변환"
$btnGo.Location = New-Object System.Drawing.Point(12, 398)
$btnGo.Size = New-Object System.Drawing.Size(120, 28)
$btnGo.Add_Click({
  if ($list.Items.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("파일이나 폴더를 추가하세요.","raw2dng"); return
  }
  if (-not $chkSame.Checked -and [string]::IsNullOrWhiteSpace($txtOut.Text)) {
    [System.Windows.Forms.MessageBox]::Show("출력 폴더를 지정하세요.","raw2dng"); return
  }
  $files = Get-RawFiles @($list.Items)
  if ($files.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("변환할 RAW가 없습니다.","raw2dng"); return
  }
  $ok = 0; $fail = 0
  foreach ($inp in $files) {
    if ($chkSame.Checked) {
      $out = [IO.Path]::ChangeExtension($inp, ".dng")
    } else {
      if (-not (Test-Path $txtOut.Text)) { New-Item -ItemType Directory -Path $txtOut.Text | Out-Null }
      $out = Join-Path $txtOut.Text ([IO.Path]::GetFileNameWithoutExtension($inp) + ".dng")
    }
    $args = @("convert")
    if ($chkOver.Checked) { $args += "-f" }
    $args += @($inp, $out)
    $log.AppendText("$([IO.Path]::GetFileName($inp)) → $out`r`n")
    $p = Start-Process -FilePath $Dnglab -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -eq 0) { $ok++ } else { $fail++; $log.AppendText("실패: exit $($p.ExitCode)`r`n") }
  }
  [System.Windows.Forms.MessageBox]::Show("완료`n성공 $ok`n실패 $fail","raw2dng")
})
$form.Controls.Add($btnGo)

[void]$form.ShowDialog()
