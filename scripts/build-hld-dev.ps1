$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Builds the hld daemon with CGO enabled and wires the CLI default command to hlyr/dist/index.js.

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$HldDir = Join-Path $RepoRoot 'hld'
$CliDist = Join-Path $RepoRoot 'hlyr/dist/index.js'

if (-not (Test-Path $CliDist)) {
    throw "CLI bundle not found at $CliDist. Run 'bun run build' in hlyr first."
}

# Prefer system MinGW from Chocolatey, otherwise fall back to the user-local llvm-mingw toolchain we downloaded earlier.
$chocoBin = 'C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin'
$userMingwBin = Get-ChildItem -Path (Join-Path $env:USERPROFILE 'tools') -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'llvm-mingw-*' } |
    Sort-Object Name -Descending |
    Select-Object -First 1 |
    ForEach-Object { Join-Path $_.FullName 'bin' }

function Add-BinPathOnce {
    param([string] $PathToAdd)
    if (-not $PathToAdd) { return }
    $already = $env:PATH -split ';' | Where-Object { $_ -eq $PathToAdd }
    if (-not $already) {
        $env:PATH = "$PathToAdd;$env:PATH"
        Write-Host "Added to PATH: $PathToAdd" -ForegroundColor Cyan
    }
}

if (-not $env:CC) {
    if (Test-Path (Join-Path $chocoBin 'gcc.exe')) {
        $env:CC = Join-Path $chocoBin 'gcc.exe'
        $env:CXX = Join-Path $chocoBin 'g++.exe'
        Write-Host "Using MinGW compiler from Chocolatey:" -ForegroundColor Cyan
        Write-Host "  CC  = $env:CC"
        Write-Host "  CXX = $env:CXX"
        Add-BinPathOnce -PathToAdd $chocoBin
    }
    elseif ($userMingwBin -and (Test-Path (Join-Path $userMingwBin 'x86_64-w64-mingw32-gcc.exe'))) {
        $env:CC = Join-Path $userMingwBin 'x86_64-w64-mingw32-gcc.exe'
        $env:CXX = Join-Path $userMingwBin 'x86_64-w64-mingw32-g++.exe'
        Write-Host "Using user-local llvm-mingw toolchain:" -ForegroundColor Cyan
        Write-Host "  CC  = $env:CC"
        Write-Host "  CXX = $env:CXX"
        Add-BinPathOnce -PathToAdd $userMingwBin
    }
}

# If CC/CXX are set, ensure their bin directories are on PATH to satisfy cgo's plain 'gcc' lookup.
if ($env:CC) {
    $ccDir = Split-Path $env:CC -Parent
    Add-BinPathOnce -PathToAdd $ccDir
}

$env:CGO_ENABLED = '1'

$defaultCli = (Resolve-Path $CliDist).Path -replace '\\', '/'
$ldflags = "-X github.com/humanlayer/humanlayer/hld/config.DefaultCLICommand=$defaultCli"

Push-Location $HldDir
try {
    Write-Host "Building hld-dev.exe with CGO enabled..." -ForegroundColor Green
    & go build -ldflags $ldflags -o hld-dev.exe ./cmd/hld
    if ($LASTEXITCODE -ne 0) {
        throw "go build failed with exit code $LASTEXITCODE"
    }
    Write-Host "Build complete: $(Join-Path $HldDir 'hld-dev.exe')" -ForegroundColor Green
}
finally {
    Pop-Location
}
