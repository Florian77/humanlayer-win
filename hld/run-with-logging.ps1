#!/usr/bin/env pwsh
# run-with-logging.ps1 - Run a command and tee output to a log file

[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $LogFile,

    [Parameter(Mandatory = $true, Position = 1, ValueFromRemainingArguments = $true)]
    [string[]] $Command
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Command -or $Command.Count -eq 0) {
    throw "No command provided to run-with-logging.ps1"
}

$logDir = Split-Path -Parent $LogFile
if ($logDir -and -not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

if (-not (Test-Path $LogFile)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

$cmd = $Command[0]
$args = if ($Command.Length -gt 1) { $Command[1..($Command.Length - 1)] } else { @() }

& $cmd @args 2>&1 | Tee-Object -FilePath $LogFile -Append

$exitCode = $LASTEXITCODE
Start-Sleep -Milliseconds 100
exit $exitCode
