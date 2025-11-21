#!/usr/bin/env pwsh
# clean_caches.ps1 - Remove cache/output folders using a shared path list

[CmdletBinding()]
param(
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent (Resolve-Path $MyInvocation.MyCommand.Path)
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$PathsFile = Join-Path $ScriptDir "paths.txt"

if (-not (Test-Path -LiteralPath $PathsFile)) {
    throw "Paths file not found: $PathsFile"
}

function Get-PathsFromFile {
    param([string] $FilePath)
    return Get-Content -Path $FilePath -ErrorAction Stop |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
}

function Has-Wildcard {
    param([string] $Path)
    return $Path -match '[\*\?\[]'
}

$targets = @()
$paths = Get-PathsFromFile -FilePath $PathsFile

foreach ($rel in $paths) {
    $full = Join-Path $RepoRoot $rel
    if (Has-Wildcard -Path $rel) {
        $matches = Get-ChildItem -Path $full -Force -ErrorAction SilentlyContinue
        if ($matches) {
            $targets += $matches.FullName
        }
    } else {
        if (Test-Path -LiteralPath $full) {
            $targets += $full
        }
    }
}

Write-Host "Repo root: $RepoRoot"
Write-Host "Will delete these paths if present:"
if ($targets.Count -eq 0) {
    Write-Host "  (none)"
} else {
    $targets | ForEach-Object { Write-Host "  - $_" }
}
if ($DryRun) { Write-Host "(dry run - nothing will be deleted)" }

if ($targets.Count -eq 0 -or $DryRun) {
    Write-Host "Dry run complete." -ForegroundColor Yellow
    exit 0
}

foreach ($path in $targets) {
    try {
        Remove-Item -Recurse -Force -LiteralPath $path -ErrorAction Stop
        Write-Host "Deleted: $path"
    } catch {
        Write-Host "Failed to delete: $path"
        Write-Host "  $_"
    }
}

Write-Host "Cache clean complete."
