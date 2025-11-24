$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Starts the dev daemon with the same env layout as the Makefile daemon-dev target.
# Logs are written to ~/.humanlayer/logs/daemon-dev-<timestamp>.log.

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$HldDir = Join-Path $RepoRoot 'hld'
$Binary = Join-Path $HldDir 'hld-dev.exe'

if (-not (Test-Path $Binary)) {
    throw "hld-dev.exe not found at $Binary. Run scripts/build-hld-dev.ps1 first."
}

$homeDir = [Environment]::GetFolderPath('UserProfile')
$humanlayerDir = Join-Path $homeDir '.humanlayer'
$logDir = Join-Path $humanlayerDir 'logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$timestamp = Get-Date -Format 'yyyy-MM-dd-HH-mm-ss'
$dbPath = Join-Path $humanlayerDir 'daemon-dev.db'
$socketPath = Join-Path $humanlayerDir 'daemon-dev.sock'
$logPath = Join-Path $logDir ("daemon-dev-{0}.log" -f $timestamp)

# Derive version override from current branch; fall back if detached.
$branch = (& git -C $RepoRoot rev-parse --abbrev-ref HEAD 2>$null).Trim()
if (-not $branch -or $branch -eq 'HEAD') { $branch = 'dev-local' }

Write-Host "Starting dev daemon..." -ForegroundColor Green
Write-Host "  DB       : $dbPath"
Write-Host "  Socket   : $socketPath"
Write-Host "  Log      : $logPath"
Write-Host "  Version  : $branch"

# Ensure parent directory exists
New-Item -ItemType Directory -Path $humanlayerDir -Force | Out-Null

Push-Location $HldDir
try {
    $env:HUMANLAYER_DATABASE_PATH = $dbPath
    $env:HUMANLAYER_DAEMON_SOCKET = $socketPath
    $env:HUMANLAYER_DAEMON_HTTP_PORT = '0'
    $env:HUMANLAYER_DAEMON_VERSION_OVERRIDE = $branch

    Write-Host "Daemon output (also logged to file):" -ForegroundColor Cyan
    & $Binary 2>&1 | Tee-Object -FilePath $logPath
}
finally {
    Pop-Location
}
