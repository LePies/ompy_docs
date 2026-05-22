function Get-NormalizedPackageName {
    param([string]$Name)
    $n = $Name -replace '[^a-zA-Z0-9]+', '_'
    $n = $n.Trim('_').ToLower()
    if ($n -match '^\d') { $n = "pkg_$n" }
    if ([string]::IsNullOrWhiteSpace($n)) { $n = 'myproject' }
    return $n
}

function Get-ProjectTokens {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [string]$PackageName,
        [string]$Author,
        [string]$Version,
        [string]$TodoRelativePath
    )
    $year = (Get-Date).Year
    $short = $Version
    if ($Version -match '^(\d+\.\d+)') { $short = $Matches[1] }
    $authorBib = '"' + ($Author -replace '"', '') + '"'
    return @{
        PROJECT_NAME    = $ProjectName
        PACKAGE_NAME    = $PackageName
        IMPORT_PREFIX   = $PackageName
        AUTHOR          = $Author
        AUTHOR_BIB      = $authorBib
        VERSION         = $Version
        VERSION_SHORT   = $short
        COPYRIGHT_YEAR  = "$year"
        TODO_REL_PATH   = $TodoRelativePath -replace '\\', '/'
    }
}

function Get-DetectedPackage {
    param(
        [string]$ProjectPath,
        [string]$PackageName
    )
    $src = Join-Path $ProjectPath 'src'
    if (-not (Test-Path $src)) {
        throw "No src/ directory under $ProjectPath. Run without -DocsOnly on a greenfield path, or create src/<package>/ first."
    }
    $dirs = Get-ChildItem -Path $src -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName '__init__.py') }
    if ($PackageName) {
        $match = $dirs | Where-Object { $_.Name -eq $PackageName }
        if (-not $match) {
            throw "Package '$PackageName' not found under src/ (expected src/$PackageName/__init__.py)."
        }
        return $PackageName
    }
    if ($dirs.Count -eq 0) {
        throw "No Python package found under src/ (need src/<name>/__init__.py)."
    }
    if ($dirs.Count -gt 1) {
        $names = ($dirs.Name -join ', ')
        throw "Multiple packages under src/: $names. Pass -PackageName explicitly."
    }
    return $dirs[0].Name
}

function Get-ModuleTemplateRoot {
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $repoRoot = Split-Path -Parent $moduleRoot
    if (Test-Path (Join-Path $moduleRoot 'templates')) {
        return Join-Path $moduleRoot 'templates'
    }
    if (Test-Path (Join-Path $repoRoot 'templates')) {
        return Join-Path $repoRoot 'templates'
    }
    throw "Cannot find templates/ (expected next to Init-PythonProject module or repo root)."
}
