# Installs the Lab Activity Monitor into the VS Code that opened this folder (Windows).
# Run automatically by .vscode/tasks.json when the folder is opened in a trusted window.
param([string]$ExecPath)
$ErrorActionPreference = "Stop"

$lab = Get-Content (Join-Path $PSScriptRoot "lab.json") -Raw | ConvertFrom-Json
$stateDir = if ($env:WEBLAB_STATE_DIR) { $env:WEBLAB_STATE_DIR } else { Join-Path $HOME ".weblab" }
$marker = Join-Path $stateDir "$($lab.labId).json"

# The monitor removes itself after the lab period; don't reinstall it after that.
if (Test-Path $marker) {
    $first = (Get-Content $marker -Raw | ConvertFrom-Json).firstSeenEpoch
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($now - $first -ge $lab.expiryHours * 3600) {
        Write-Host "Lab period has ended: Lab Activity Monitor is not reinstalled."
        exit 0
    }
}

# Use the CLI of the VS Code that is running this task (falls back to `code` on PATH)
$cli = Join-Path (Split-Path $ExecPath) "bin\code.cmd"
if (-not (Test-Path $cli)) { $cli = "code" }

$cliArgs = @("--install-extension", (Join-Path $PSScriptRoot "lab-activity-monitor.vsix"))
if ($env:LAB_EXTENSIONS_DIR) { $cliArgs += @("--extensions-dir", $env:LAB_EXTENSIONS_DIR) }
& $cli @cliArgs
