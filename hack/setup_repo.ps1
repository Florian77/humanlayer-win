#!/usr/bin/env pwsh
# setup_repo.ps1 - Fresh repository setup script for Windows PowerShell (Windows-only)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

function Run-Silent {
    param(
        [Parameter(Mandatory = $true)] [string] $Description,
        [Parameter(Mandatory = $true)] [string] $Command
    )

    $verboseMode = $env:VERBOSE -eq '1'

    if ($verboseMode) {
        Write-Host "  [RUN] $Command"
        Invoke-Expression $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE"
        }
        return
    }
 
    $tempFile = [System.IO.Path]::GetTempFileName()
    $exitCode = 0

    try {
        $global:LASTEXITCODE = 0
        $null = Invoke-Expression $Command 2>&1 | Out-File -FilePath $tempFile -Encoding utf8
        $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }

        if ($exitCode -eq 0) {
            Write-Host "  [OK] $Description"
            return
        }

        throw "Command exited with code $exitCode"
    }
    catch {
        Write-Host "  [FAIL] $Description"
        Write-Host "  Command failed: $Command"
        if ($exitCode -ne 0) {
            Write-Host "  Exit code: $exitCode"
        }
        Get-Content -Path $tempFile -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "    $_" }
        throw
    }
    finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

Push-Location $RepoRoot
try {
    if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
        Write-Host "This setup script is Windows-only. For Linux/macOS use hack/setup_repo.sh instead."
        exit 0
    }

    Write-Host ">> Setting up HumanLayer repository (Windows)..."

    # Write-Host ">> Checking platform-specific dependencies..."
    # $installDepsPs = Join-Path $ScriptDir "install_platform_deps.ps1"
    # Run-Silent "install platform deps" "& `"$installDepsPs`""

    Write-Host ">> Root BUN Installing"
    Run-Silent "root bun install" "bun install"

    $hldSdkPath = Join-Path $RepoRoot "hld/sdk/typescript"
    Write-Host ">> Installing HLD SDK dependencies..."
    Run-Silent "hld-sdk bun install" "bun install --cwd=`"$hldSdkPath`""

    Write-Host ">> Building HLD TypeScript SDK..."
    Run-Silent "hld-sdk build" "bun run build --cwd=`"$hldSdkPath`""

    Write-Host ">> Installing WUI dependencies..."
    $wuiPath = Join-Path $RepoRoot "humanlayer-wui"
    try {
        Run-Silent "humanlayer-wui bun install" "bun install --cwd=`"$wuiPath`""
    }
    catch {
        Write-Host "   bun install failed (known Bun + file: path issue on Windows). Retrying with npm install..."
        Run-Silent "humanlayer-wui npm install" "npm install --prefix=`"$wuiPath`""
    }

    Write-Host ">> Creating placeholder binaries for Tauri..."
    $binDir = Join-Path $RepoRoot "humanlayer-wui/src-tauri/bin"
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null

    $hldBinary = Join-Path $binDir "hld"
    $humanlayerBinary = Join-Path $binDir "humanlayer"

    foreach ($binary in @($hldBinary, $humanlayerBinary)) {
        if (-not (Test-Path $binary)) {
            New-Item -ItemType File -Path $binary -Force | Out-Null
        }
        else {
            (Get-Item $binary).LastWriteTime = Get-Date
        }
    }

    Write-Host "> Repository setup complete!"
}
finally {
    Pop-Location
}
