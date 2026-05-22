function Get-ApiModuleGroup {
    param([string]$ModuleLeaf)
    $leaf = $ModuleLeaf.ToLower()
    if ($leaf -in @('run', '__main__', 'cli', 'main', 'app')) { return 'EntryPoints' }
    if ($leaf -match '^(constants|config|settings)$') { return 'Configuration' }
    if ($leaf -match 'solver|numeric|fvm') { return 'Numerics' }
    if ($leaf -match '^(objects|models|model)$') { return 'Modelling' }
    if ($leaf -match '^(scripts|utils|helpers|plotting)$') { return 'Utilities' }
    return 'Other'
}

function Get-ApiPageTitle {
    param([string]$RelDotted)
    $leaf = ($RelDotted -split '\.')[-1]
    if ($leaf -eq '__init__') {
        $leaf = ($RelDotted -split '\.')[-2]
    }
    $t = $leaf -replace '_', ' '
    if ($t.Length -gt 0) {
        return (Get-Culture).TextInfo.ToTitleCase($t)
    }
    return 'Package'
}

function New-ApiRstTree {
    param(
        [string]$ProjectPath,
        [string]$PackageName,
        [string]$DocsApiDir,
        [switch]$Force
    )
    $pkgRoot = Join-Path $ProjectPath "src\$PackageName"
    if (-not (Test-Path $pkgRoot)) {
        throw "Package root not found: $pkgRoot"
    }

    if ((Test-Path $DocsApiDir) -and $Force) {
        Get-ChildItem $DocsApiDir -Recurse -File -Filter '*.rst' |
            Where-Object { $_.Name -ne 'index.rst' } |
            Remove-Item -Force
    }
    if (-not (Test-Path $DocsApiDir)) {
        New-Item -ItemType Directory -Path $DocsApiDir -Force | Out-Null
    }

    $pyFiles = Get-ChildItem -Path $pkgRoot -Recurse -Filter '*.py' |
        Where-Object {
            $_.FullName -notmatch '[\\/]__pycache__[\\/]'
            if ($_.Name -eq '__init__.py') {
                $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                return ($c -and $c.Trim().Length -gt 80)
            }
            if ($_.Name -match '^test_|^conftest\.py$') { return $false }
            return $true
        }

    $modules = foreach ($f in $pyFiles) {
        $rel = $f.FullName.Substring($pkgRoot.Length + 1).Replace('\', '/')
        $dotted = $rel -replace '\.py$', '' -replace '/', '.'
        if ($dotted -eq '__init__') {
            $importPath = $PackageName
            $rstRel = 'package'
        }
        elseif ($dotted -match '\.__init__$') {
            $sub = $dotted -replace '\.__init__$', ''
            $importPath = "$PackageName.$sub"
            $rstRel = $sub -replace '\.', '/'
        }
        else {
            $importPath = "$PackageName.$dotted"
            $rstRel = $dotted -replace '\.', '/'
        }
        [PSCustomObject]@{
            ImportPath = $importPath
            RstRel     = $rstRel
            Title      = (Get-ApiPageTitle -RelDotted $dotted)
            Group      = (Get-ApiModuleGroup -ModuleLeaf (($dotted -split '\.')[-1]))
        }
    }

    $menuLinks = New-Object System.Collections.Generic.List[string]
    $groupOrder = @(
        @{ Key = 'EntryPoints'; Title = 'Entry points' }
        @{ Key = 'Modelling'; Title = 'Modelling' }
        @{ Key = 'Configuration'; Title = 'Configuration' }
        @{ Key = 'Numerics'; Title = 'Numerics' }
        @{ Key = 'Utilities'; Title = 'Utilities' }
        @{ Key = 'Other'; Title = 'Other' }
    )

    $indexBody = New-Object System.Text.StringBuilder

    foreach ($g in $groupOrder) {
        $items = @($modules | Where-Object { $_.Group -eq $g.Key } | Sort-Object RstRel)
        if (-not $items.Count) { continue }

        [void]$indexBody.AppendLine("$($g.Title)")
        [void]$indexBody.AppendLine(('-' * $g.Title.Length))
        [void]$indexBody.AppendLine('.. toctree::')
        [void]$indexBody.AppendLine('   :maxdepth: 2')
        [void]$indexBody.AppendLine('')

        foreach ($m in $items) {
            $rstFile = Join-Path $DocsApiDir ($m.RstRel + '.rst')
            $rstDir = Split-Path -Parent $rstFile
            if ($rstDir -and -not (Test-Path $rstDir)) {
                New-Item -ItemType Directory -Path $rstDir -Force | Out-Null
            }

            $depth = 0
            if ($rstDir -and $rstDir -ne $DocsApiDir) {
                $rel = $rstDir.Substring($DocsApiDir.Length).Trim('\', '/')
                if ($rel) { $depth = ($rel -split '[\\/]').Count }
            }
            $includeMenu = if ($depth -eq 0) { '.. include:: _api_menu.rst' } else { '.. include:: ' + ('../' * $depth) + '_api_menu.rst' }

            $menuDoc = $m.RstRel -replace '\\', '/'
            [void]$menuLinks.Add(':doc:`' + $m.Title + ' </api/' + $menuDoc + '>`')

            $anchor = 'api-' + ($m.ImportPath -replace '\.', '-')
            $underline = '=' * $m.Title.Length
            $lines = @(
                ".. _$anchor`:"
                ''
                $m.Title
                $underline
                ''
                '.. rst-class:: api-subtitle'
                ''
                "   ``$($m.ImportPath)``"
                ''
                $includeMenu
                ''
                ".. automodule:: $($m.ImportPath)"
                '   :members:'
                '   :undoc-members:'
                '   :show-inheritance:'
                '   :noindex:'
                ''
            )
            [System.IO.File]::WriteAllText($rstFile, ($lines -join "`n"))
            [void]$indexBody.AppendLine("   $($m.RstRel)")
        }
        [void]$indexBody.AppendLine('')
    }

    $sep = [char]0x00B7  # middle dot
    $menu = '**API reference:** ' + ($menuLinks -join " $sep ")
    [System.IO.File]::WriteAllText((Join-Path $DocsApiDir '_api_menu.rst'), "$menu`n")

    return $indexBody.ToString()
}
