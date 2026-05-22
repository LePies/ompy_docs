#Requires -Version 5.1
<#
.SYNOPSIS
  Install Init-PythonProject module and templates into the user PowerShell module path.
#>
$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$moduleSrc = Join-Path $repoRoot 'Init-PythonProject'
$templatesSrc = Join-Path $repoRoot 'templates'

if (-not (Test-Path $moduleSrc)) {
    throw "Init-PythonProject folder not found at $moduleSrc"
}
if (-not (Test-Path $templatesSrc)) {
    throw "templates/ folder not found at $templatesSrc"
}

$dest = Join-Path $HOME 'Documents\PowerShell\Modules\Init-PythonProject'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Copy-Item -Path (Join-Path $moduleSrc '*') -Destination $dest -Recurse -Force
Copy-Item -Path $templatesSrc -Destination (Join-Path $dest 'templates') -Recurse -Force

Write-Host "Installed to: $dest" -ForegroundColor Green

$uv = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uv) {
    Write-Warning "uv is not on PATH. Install before running Init-PythonProject: https://docs.astral.sh/uv/"
}

Import-Module (Join-Path $dest 'Init-PythonProject.psd1') -Force
Write-Host "Loaded: Init-PythonProject $(Get-Module Init-PythonProject | Select-Object -ExpandProperty Version)"
Write-Host "Command:  Init-PythonProject"
