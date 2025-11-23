$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Starts the WUI in dev mode using the remote bridge + shim.
# Mirrors scripts/dev-wui-remote.sh for PowerShell users.

$scriptDir = Split-Path -Parent $PSCommandPath
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$rootDir = (Resolve-Path (Join-Path $scriptDir "..")).Path
$homeDir = if (-not [string]::IsNullOrWhiteSpace($env:HOME)) { $env:HOME } else { $env:USERPROFILE }

$remoteHost = try {
    # If the bridge/daemon runs in WSL, discover its IP so Windows can reach it.
    $ip = wsl -e sh -c 'ip -4 addr show eth0 | grep -oP "(?<=inet\\s)\\d+(\\.\\d+){3}"' 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($ip)) { $ip.Trim() } else { "localhost" }
} catch {
    "localhost"
}

$bridgePort = "17650"
$socketPath = Join-Path $homeDir ".humanlayer/daemon-remote.sock"
$daemonPort = "7777"

$env:HUMANLAYER_WUI_AUTOLAUNCH_DAEMON = "false"
$env:HUMANLAYER_DAEMON_SOCKET = $socketPath
$env:VITE_HUMANLAYER_DAEMON_URL = "http://${remoteHost}:${daemonPort}"
$env:VITE_REMOTE_TAURI_SHIM = "1"
$env:VITE_TAURI_BRIDGE_URL = "http://${remoteHost}:${bridgePort}"

$tauriConfigPath = (Join-Path (Join-Path $rootDir "humanlayer-wui") "src-tauri/tauri.remote-only.conf.json")
$env:TAURI_FEATURES = "remote-only"

Write-Host "Starting WUI with:"
Write-Host "  HUMANLAYER_REMOTE_HOST=$remoteHost"
Write-Host "  HUMANLAYER_DAEMON_SOCKET=$($env:HUMANLAYER_DAEMON_SOCKET)"
Write-Host "  VITE_HUMANLAYER_DAEMON_URL=$($env:VITE_HUMANLAYER_DAEMON_URL)"
Write-Host "  VITE_REMOTE_TAURI_SHIM=$($env:VITE_REMOTE_TAURI_SHIM)"
Write-Host "  VITE_TAURI_BRIDGE_URL=$($env:VITE_TAURI_BRIDGE_URL)"
Write-Host "  TAURI_CONFIG=$tauriConfigPath"
Write-Host "  TAURI_FEATURES=$($env:TAURI_FEATURES)"

Set-Location (Join-Path $rootDir "humanlayer-wui")
bun run tauri dev -- --config "$tauriConfigPath"
