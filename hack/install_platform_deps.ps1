#!/usr/bin/env pwsh
# install_platform_deps.ps1 - Windows-only notice

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
    Write-Host "This PowerShell script is intended for Windows only. On Linux/macOS, use hack/install_platform_deps.sh."
    exit 0
}

Write-Host ">> Windows detected - no Linux/macOS platform dependency installation needed."
Write-Host "   Ensure Windows prerequisites are installed:"
Write-Host "     - Rust toolchain (rustup)"
Write-Host "     - bun / Node.js"
Write-Host "     - Visual Studio C++ build tools"
Write-Host "     - Tauri prerequisites per https://tauri.app/v1/guides/getting-started/prerequisites#setting-up-windows"
