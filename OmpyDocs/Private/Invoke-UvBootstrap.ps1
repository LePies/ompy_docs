function Test-UvAvailable {
    $uv = Get-Command uv -ErrorAction SilentlyContinue
    if (-not $uv) {
        $candidates = @(
            (Join-Path $env:USERPROFILE '.local\bin\uv.exe'),
            (Join-Path $env:LOCALAPPDATA 'Programs\uv\uv.exe')
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) {
                $bin = Split-Path -Parent $c
                if ($env:Path -notlike "*$bin*") {
                    $env:Path = "$bin;$env:Path"
                }
                return
            }
        }
        throw @"
uv is not on PATH. Install from https://docs.astral.sh/uv/getting-started/installation/
  winget install astral-sh.uv
  # or: powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
"@
    }
}

function Invoke-UvCommand {
    param(
        [string[]]$Arguments,
        [string]$WorkingDirectory,
        [switch]$WhatIf
    )
    $argLine = $Arguments -join ' '
    if ($WhatIf) {
        Write-Host "WhatIf: uv $argLine (in $WorkingDirectory)"
        return
    }
    Push-Location $WorkingDirectory
    try {
        & uv @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "uv failed (exit $LASTEXITCODE): uv $argLine"
        }
    }
    finally {
        Pop-Location
    }
}

function Ensure-PackageSrcLayout {
    <#
    .SYNOPSIS
        Guarantee src/<PackageName>/__init__.py (and py.typed) before uv add/sync builds the project.
        Repairs partial inits where pyproject.toml exists but the package tree is missing.
    #>
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [string]$PackageName,
        [string]$Author,
        [string]$Version,
        [string]$TodoRelativePath,
        [string]$TemplateRoot,
        [switch]$Force,
        [switch]$WhatIf
    )

    if ($WhatIf) {
        Write-Host "WhatIf: ensure src/$PackageName/__init__.py under $ProjectPath"
        return
    }

    $srcRoot = Join-Path $ProjectPath 'src'
    $pkgDir = Join-Path $srcRoot $PackageName
    $destInit = Join-Path $pkgDir '__init__.py'
    $typed = Join-Path $pkgDir 'py.typed'

    if (-not (Test-Path $srcRoot)) {
        New-Item -ItemType Directory -Path $srcRoot -Force | Out-Null
    }

    if (Test-Path $srcRoot) {
        $dirs = @(Get-ChildItem -Path $srcRoot -Directory -ErrorAction SilentlyContinue)
        if ($dirs.Count -eq 1 -and $dirs[0].Name -ne $PackageName -and -not (Test-Path $pkgDir)) {
            Move-Item -Path $dirs[0].FullName -Destination $pkgDir
        }
    }

    if (-not (Test-Path $pkgDir)) {
        New-Item -ItemType Directory -Path $pkgDir -Force | Out-Null
    }

    $initTpl = Join-Path $TemplateRoot 'src\__init__.py.tpl'
    if (Test-Path $initTpl) {
        $tokens = Get-ProjectTokens -ProjectPath $ProjectPath -ProjectName $ProjectName `
            -PackageName $PackageName -Author $Author -Version $Version -TodoRelativePath $TodoRelativePath
        if (-not (Test-Path $destInit)) {
            Write-TokenTemplateFile -SourceFile $initTpl -DestFile $destInit -Tokens $tokens -Force:$true | Out-Null
        }
        elseif ($Force) {
            Write-TokenTemplateFile -SourceFile $initTpl -DestFile $destInit -Tokens $tokens -Force:$true | Out-Null
        }
    }
    elseif (-not (Test-Path $destInit)) {
        @"
"""$ProjectName package."""


def hello() -> str:
    return "Hello from $PackageName!"
"@ | Set-Content -Path $destInit -Encoding utf8
    }

    if (-not (Test-Path $typed)) {
        New-Item -ItemType File -Path $typed -Force | Out-Null
    }

    if (-not (Test-Path $destInit)) {
        throw "Could not create package entry point: $destInit"
    }
}

function Invoke-UvBootstrap {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [string]$PackageName,
        [string]$Author,
        [string]$Version,
        [string]$PythonVersion,
        [string]$TodoRelativePath,
        [string]$TemplateRoot,
        [switch]$DocsOnly,
        [switch]$SkipUvSync,
        [switch]$WhatIf,
        [switch]$Force
    )
    if ($DocsOnly) { return @{ Greenfield = $false } }

    Test-UvAvailable

    $pyProject = Join-Path $ProjectPath 'pyproject.toml'
    $greenfield = -not (Test-Path $pyProject)

    if ($greenfield) {
        Invoke-UvCommand -Arguments @('init', '--lib', '--name', $PackageName) -WorkingDirectory $ProjectPath -WhatIf:$WhatIf
    }

    Ensure-PackageSrcLayout -ProjectPath $ProjectPath -ProjectName $ProjectName `
        -PackageName $PackageName -Author $Author -Version $Version `
        -TodoRelativePath $TodoRelativePath -TemplateRoot $TemplateRoot `
        -Force:$Force -WhatIf:$WhatIf

    $addDev = @('add', '--dev', 'ruff', 'ty')
    $addDocs = @('add', '--group', 'docs', 'sphinx>=7,<9', 'furo>=2024.1', 'sphinxcontrib-bibtex')

    Invoke-UvCommand -Arguments $addDev -WorkingDirectory $ProjectPath -WhatIf:$WhatIf
    Invoke-UvCommand -Arguments $addDocs -WorkingDirectory $ProjectPath -WhatIf:$WhatIf

    if (-not $WhatIf) {
        Merge-PyProjectTooling -PyProjectPath $pyProject `
            -ToolingFragmentPath (Join-Path $TemplateRoot 'pyproject.tooling.toml')
    }

    Set-PythonVersionFile -ProjectPath $ProjectPath -PythonVersion $PythonVersion

    if (-not $SkipUvSync) {
        Invoke-UvCommand -Arguments @('sync') -WorkingDirectory $ProjectPath -WhatIf:$WhatIf
    }

    return @{ Greenfield = $greenfield }
}
