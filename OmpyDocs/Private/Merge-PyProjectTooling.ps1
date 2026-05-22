function Merge-PyProjectTooling {
    param(
        [string]$PyProjectPath,
        [string]$ToolingFragmentPath
    )
    if (-not (Test-Path $PyProjectPath)) { return }
    $fragment = [System.IO.File]::ReadAllText($ToolingFragmentPath).Trim()
    $content = [System.IO.File]::ReadAllText($PyProjectPath)
    if ($content -match '\[tool\.uv\]' -and $content -match '\[tool\.ruff\]') {
        return
    }
    if (-not $content.EndsWith("`n")) { $content += "`n" }
    if (-not $content.EndsWith("`n`n")) { $content += "`n" }
    [System.IO.File]::AppendAllText($PyProjectPath, "`n$fragment`n")
}

function Set-PythonVersionFile {
    param(
        [string]$ProjectPath,
        [string]$PythonVersion
    )
    $pv = Join-Path $ProjectPath '.python-version'
    if (-not (Test-Path $pv)) {
        [System.IO.File]::WriteAllText($pv, "$PythonVersion`n")
    }
}

function Write-RequirementsDocsMirror {
    param([string]$DocsDir)
    $req = Join-Path $DocsDir 'requirements-docs.txt'
    $text = @"
# Sphinx and extensions (mirrors [dependency-groups] docs in pyproject.toml)
sphinx>=7.0,<9
furo>=2024.1
sphinxcontrib-bibtex>=2.6
sphinx-gallery>=0.16

"@
    [System.IO.File]::WriteAllText($req, $text)
}
