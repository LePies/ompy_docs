#Requires -Version 5.1
<#
.SYNOPSIS
  Install the ompy_docs (OmpyDocs) module and templates into the user PowerShell module path.
#>
$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$moduleSrc = Join-Path $repoRoot 'OmpyDocs'
$templatesSrc = Join-Path $repoRoot 'templates'

if (-not (Test-Path $moduleSrc)) {
    throw "OmpyDocs folder not found at $moduleSrc"
}
if (-not (Test-Path $templatesSrc)) {
    throw "templates/ folder not found at $templatesSrc"
}

$dest = Join-Path $HOME 'Documents\PowerShell\Modules\OmpyDocs'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Copy-Item -Path (Join-Path $moduleSrc '*') -Destination $dest -Recurse -Force
Copy-Item -Path $templatesSrc -Destination (Join-Path $dest 'templates') -Recurse -Force

Write-Host "Installed to: $dest" -ForegroundColor Green

$uv = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uv) {
    $localUv = Join-Path $env:USERPROFILE '.local\bin\uv.exe'
    if (Test-Path $localUv) {
        $env:Path = "$(Split-Path $localUv -Parent);$env:Path"
    }
    else {
        Write-Warning "uv is not on PATH. Install before running Init-OmpyDocs: https://docs.astral.sh/uv/"
    }
}

Import-Module (Join-Path $dest 'OmpyDocs.psd1') -Force
Write-Host "Loaded: OmpyDocs $(Get-Module OmpyDocs | Select-Object -ExpandProperty Version)"
Write-Host "Command:  Init-OmpyDocs  (alias: ompy_docs)"
