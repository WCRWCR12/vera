# Saves the Telegram bot token straight into the Telegram plugin's token file (Windows).
# The token is typed into a small masked box. It never goes into a Claude chat, a transcript or a log,
# and this script never prints it.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File set-telegram-token.ps1          opens the box
#   powershell -NoProfile -ExecutionPolicy Bypass -File set-telegram-token.ps1 -Check   prints only "token: present" or "token: missing"
#
# The folder is the plugin's default (~\.claude\channels\telegram) unless TELEGRAM_STATE_DIR is set
# (or -StateDir is passed), the same rule the plugin uses.
param([switch]$Check, [string]$StateDir = "")
$ErrorActionPreference = "Stop"

if (-not $StateDir) { $StateDir = $env:TELEGRAM_STATE_DIR }
if (-not $StateDir) { $StateDir = Join-Path (Join-Path (Join-Path $HOME ".claude") "channels") "telegram" }
$TokenFile = Join-Path $StateDir ".env"
$Pattern = '^[0-9]{6,12}:[A-Za-z0-9_-]{30,}$'

function Test-TokenPresent {
  if (-not (Test-Path -LiteralPath $TokenFile)) { return $false }
  foreach ($line in [System.IO.File]::ReadAllLines($TokenFile)) {
    if ($line -match '^TELEGRAM_BOT_TOKEN=(.*)$') { if ($Matches[1].Trim() -match $Pattern) { return $true } }
  }
  return $false
}

function Set-OwnerOnly([string]$Path, [bool]$IsDir) {
  # Only the current Windows user (no inherited entries) can read or change it.
  $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
  if ($IsDir) {
    $acl = New-Object System.Security.AccessControl.DirectorySecurity
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($me, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.SetAccessRuleProtection($true, $false); $acl.AddAccessRule($rule)
    [System.IO.Directory]::SetAccessControl($Path, $acl)
  } else {
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($me, "FullControl", "Allow")
    $acl.SetAccessRuleProtection($true, $false); $acl.AddAccessRule($rule)
    [System.IO.File]::SetAccessControl($Path, $acl)
  }
}

if ($Check) {
  if (Test-TokenPresent) { Write-Output "token: present"; exit 0 } else { Write-Output "token: missing"; exit 1 }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Vera: Telegram token"
$form.Size = New-Object System.Drawing.Size(460, 210)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false; $form.MinimizeBox = $false; $form.TopMost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Paste the bot token from @BotFather, then click Save.`nIt is saved on this computer only and never shown in a chat."
$label.Location = New-Object System.Drawing.Point(14, 14); $label.Size = New-Object System.Drawing.Size(420, 40)
$form.Controls.Add($label)

$box = New-Object System.Windows.Forms.TextBox
$box.Location = New-Object System.Drawing.Point(14, 64); $box.Size = New-Object System.Drawing.Size(415, 24)
$box.UseSystemPasswordChar = $true
$form.Controls.Add($box)

$save = New-Object System.Windows.Forms.Button
$save.Text = "Save"; $save.Location = New-Object System.Drawing.Point(254, 110); $save.Size = New-Object System.Drawing.Size(85, 30)
$save.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($save); $form.AcceptButton = $save

$cancel = New-Object System.Windows.Forms.Button
$cancel.Text = "Cancel"; $cancel.Location = New-Object System.Drawing.Point(344, 110); $cancel.Size = New-Object System.Drawing.Size(85, 30)
$cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($cancel); $form.CancelButton = $cancel

$form.Add_Shown({ $form.Activate(); $box.Focus() })
$result = $form.ShowDialog()
$token = ($box.Text -replace '\s', '')
$box.Text = ""; $form.Dispose()

if ($result -ne [System.Windows.Forms.DialogResult]::OK) { Write-Output "Cancelled. Nothing saved."; exit 1 }
if ($token -notmatch $Pattern) {
  $token = $null
  [System.Windows.Forms.MessageBox]::Show("That does not look like a bot token. It should be numbers, a colon, then letters. Nothing was saved.", "Vera") | Out-Null
  Write-Output "Not a bot token. Nothing saved."; exit 1
}

if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
Set-OwnerOnly $StateDir $true
$tmp = Join-Path $StateDir (".env.tmp." + [System.Guid]::NewGuid().ToString("N"))
[System.IO.File]::WriteAllText($tmp, "TELEGRAM_BOT_TOKEN=$token`n", (New-Object System.Text.UTF8Encoding($false)))
$token = $null
Set-OwnerOnly $tmp $false
Move-Item -LiteralPath $tmp -Destination $TokenFile -Force
Set-OwnerOnly $TokenFile $false
Write-Output "Saved. The token file is readable by this Windows user only."
exit 0
