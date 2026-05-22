function Build-OmpyDocs {
    <#
    .SYNOPSIS
        Sync dependencies, run ruff and ty, build Sphinx HTML docs, and open the result in a browser.
    .PARAMETER ProjectPath
        Project root containing pyproject.toml and docs/ (default: current directory).
    .PARAMETER SkipRuff
        Skip ``uv run ruff check .``
    .PARAMETER SkipTy
        Skip ``uv run ty check``
    .PARAMETER SkipOpenBrowser
        Do not open docs/_build/index.html after a successful build.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$ProjectPath = (Get-Location).Path,
        [switch]$SkipRuff,
        [switch]$SkipTy,
        [switch]$SkipOpenBrowser
    )

    $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path

    if (-not $PSCmdlet.ShouldProcess($ProjectPath, 'Build documentation (uv sync, ruff, ty, sphinx)')) {
        return
    }

    $pyProject = Join-Path $ProjectPath 'pyproject.toml'
    $docsDir = Join-Path $ProjectPath 'docs'
    $buildDir = Join-Path $docsDir '_build'
    $indexHtml = Join-Path $buildDir 'index.html'

    if (-not (Test-Path $pyProject)) {
        throw "No pyproject.toml in $ProjectPath. Run Init-OmpyDocs first or cd to the project root."
    }
    if (-not (Test-Path $docsDir)) {
        throw "No docs/ in $ProjectPath. Run Init-OmpyDocs first."
    }

    Test-UvAvailable

    Write-Host "Project: $ProjectPath" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "[1/4] uv sync" -ForegroundColor Yellow
    Invoke-UvCommand -Arguments @('sync') -WorkingDirectory $ProjectPath

    if (-not $SkipRuff) {
        Write-Host "[2/4] uv run ruff check ." -ForegroundColor Yellow
        Invoke-UvCommand -Arguments @('run', 'ruff', 'check', '.') -WorkingDirectory $ProjectPath
    }
    else {
        Write-Host "[2/4] ruff check (skipped)" -ForegroundColor DarkGray
    }

    if (-not $SkipTy) {
        Write-Host "[3/4] uv run ty check" -ForegroundColor Yellow
        Invoke-UvCommand -Arguments @('run', 'ty', 'check') -WorkingDirectory $ProjectPath
    }
    else {
        Write-Host "[3/4] ty check (skipped)" -ForegroundColor DarkGray
    }

    Write-Host "[4/4] uv run sphinx-build -b html docs docs/_build" -ForegroundColor Yellow
    Invoke-UvCommand -Arguments @('run', 'sphinx-build', '-b', 'html', 'docs', 'docs/_build') -WorkingDirectory $ProjectPath

    if (-not (Test-Path $indexHtml)) {
        throw "Build finished but index.html not found at $indexHtml"
    }

    Write-Host ""
    Write-Host "Build succeeded: $indexHtml" -ForegroundColor Green

    if (-not $SkipOpenBrowser) {
        Write-Host "Opening in default browser..." -ForegroundColor Cyan
        Start-Process -FilePath $indexHtml
    }
}
