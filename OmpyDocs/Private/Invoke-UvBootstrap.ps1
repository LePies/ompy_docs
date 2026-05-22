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

function Invoke-UvBootstrap {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [string]$PackageName,
        [string]$PythonVersion,
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
        # Init in ProjectPath; --name sets the import package under src/ (not the folder name).
        Invoke-UvCommand -Arguments @('init', '--lib', '--name', $PackageName) -WorkingDirectory $ProjectPath -WhatIf:$WhatIf
        # uv init --lib uses normalized name; ensure package dir matches our PackageName
        $pkgInit = Join-Path $ProjectPath "src\$PackageName\__init__.py"
        if (-not $WhatIf) {
            $uvPkgDir = Get-ChildItem (Join-Path $ProjectPath 'src') -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($uvPkgDir -and $uvPkgDir.Name -ne $PackageName) {
                $old = $uvPkgDir.FullName
                $new = Join-Path $ProjectPath "src\$PackageName"
                if (-not (Test-Path $new)) {
                    Move-Item -Path $old -Destination $new
                }
            }
            $initTpl = Join-Path $TemplateRoot 'src\__init__.py.tpl'
            if (Test-Path $initTpl) {
                $tokens = Get-ProjectTokens -ProjectPath $ProjectPath -ProjectName $ProjectName `
                    -PackageName $PackageName -Author $env:USERNAME -Version '0.1.0' -TodoRelativePath 'todo.md'
                $destInit = Join-Path $ProjectPath "src\$PackageName\__init__.py"
                $dir = Split-Path $destInit -Parent
                if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                Write-TokenTemplateFile -SourceFile $initTpl -DestFile $destInit -Tokens $tokens -Force:$Force | Out-Null
                $typed = Join-Path $dir 'py.typed'
                if (-not (Test-Path $typed)) { New-Item -ItemType File -Path $typed -Force | Out-Null }
            }
        }
    }

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
