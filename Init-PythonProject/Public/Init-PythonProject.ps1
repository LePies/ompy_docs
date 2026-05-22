function Init-PythonProject {
    <#
    .SYNOPSIS
        Initialize a Python project with uv, ruff, ty, Sphinx/Furo docs, and examples.
    .PARAMETER DocsOnly
        Skip uv/ruff/ty bootstrap; only scaffold documentation (and examples unless -SkipExamples).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$ProjectPath = (Get-Location).Path,
        [string]$ProjectName,
        [string]$PackageName,
        [string]$Author = $env:USERNAME,
        [string]$Version = '0.1.0',
        [string]$PythonVersion = '3.12',
        [string]$TodoRelativePath = 'todo.md',
        [switch]$DocsOnly,
        [switch]$SkipExamples,
        [switch]$SkipUvSync,
        [switch]$UpdateReadme,
        [switch]$Force
    )

    $ProjectPath = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
    if (-not $ProjectName) {
        $ProjectName = Split-Path -Leaf $ProjectPath
    }
    $templateRoot = Get-ModuleTemplateRoot
    $pkgName = if ($PackageName) { $PackageName } else { Get-NormalizedPackageName -Name $ProjectName }

    if (-not $PSCmdlet.ShouldProcess($ProjectPath, 'Initialize Python project')) {
        return
    }

    $docsDir = Join-Path $ProjectPath 'docs'
    $examplesDir = Join-Path $ProjectPath 'examples'

    if ((Test-Path $docsDir) -and -not $Force) {
        throw "docs/ already exists. Use -Force to overwrite."
    }
    if (-not $SkipExamples -and (Test-Path $examplesDir) -and -not $Force) {
        throw "examples/ already exists. Use -Force or -SkipExamples."
    }

    if (-not $DocsOnly) {
        $boot = Invoke-UvBootstrap -ProjectPath $ProjectPath -ProjectName $ProjectName `
            -PackageName $pkgName -PythonVersion $PythonVersion -TemplateRoot $templateRoot `
            -SkipUvSync:$SkipUvSync -WhatIf:$false -Force:$Force
        $pkgName = Get-DetectedPackage -ProjectPath $ProjectPath -PackageName $PackageName
    }
    else {
        $pkgName = Get-DetectedPackage -ProjectPath $ProjectPath -PackageName $PackageName
    }

    $tokens = Get-ProjectTokens -ProjectPath $ProjectPath -ProjectName $ProjectName `
        -PackageName $pkgName -Author $Author -Version $Version -TodoRelativePath $TodoRelativePath

    $todoPath = Join-Path $ProjectPath $TodoRelativePath
    if (-not (Test-Path $todoPath)) {
        Write-TokenTemplateFile -SourceFile (Join-Path $templateRoot 'todo.md') `
            -DestFile $todoPath -Tokens $tokens -Force:$true | Out-Null
    }

    Update-GitIgnore -ProjectPath $ProjectPath `
        -AppendFile (Join-Path $templateRoot 'gitignore.append.txt')

    if ((Test-Path $docsDir) -and $Force) {
        Remove-Item -Path $docsDir -Recurse -Force
    }
    Copy-TokenTemplateTree -SourceDir (Join-Path $templateRoot 'docs') -DestDir $docsDir `
        -Tokens $tokens -Force:$true

    $apiBody = New-ApiRstTree -ProjectPath $ProjectPath -PackageName $pkgName `
        -DocsApiDir (Join-Path $docsDir 'api') -Force:$true

    $apiIndexTplPath = Join-Path $templateRoot 'docs\api\index.rst'
    $apiIndexTpl = Expand-TokenString -Text ([System.IO.File]::ReadAllText($apiIndexTplPath)) -Tokens $tokens
    $apiIndexTpl = $apiIndexTpl -replace '\{\{API_INDEX_BODY\}\}', $apiBody
    [System.IO.File]::WriteAllText((Join-Path $docsDir 'api\index.rst'), $apiIndexTpl)

    if (-not $SkipExamples) {
        if ((Test-Path $examplesDir) -and $Force) {
            Remove-Item -Path $examplesDir -Recurse -Force
        }
        Copy-TokenTemplateTree -SourceDir (Join-Path $templateRoot 'examples') `
            -DestDir $examplesDir -Tokens $tokens -Force:$true

        $exBody = New-ExamplesRstBody -ProjectPath $ProjectPath -PackageName $pkgName
        $tokens['EXAMPLES_BODY'] = $exBody
        $exRst = Join-Path $docsDir 'examples.rst'
        $exTplPath = Join-Path $templateRoot 'docs\examples.rst'
        $exTpl = [System.IO.File]::ReadAllText($exTplPath)
        [System.IO.File]::WriteAllText($exRst, (Expand-TokenString -Text $exTpl -Tokens $tokens))
    }

    Write-RequirementsDocsMirror -DocsDir $docsDir

    if ($UpdateReadme) {
        Update-ProjectReadme -ProjectPath $ProjectPath `
            -TemplateFile (Join-Path $templateRoot 'README.md.tpl') -Tokens $tokens -Force:$Force
    }

    Write-Host ""
    Write-Host "Initialized: $ProjectPath" -ForegroundColor Green
    Write-Host "  Package: $pkgName (src/$pkgName/)"
    Write-Host "  Docs:    docs/  ->  docs/_build/index.html"
    if (-not $SkipExamples) { Write-Host "  Example: uv run python examples/hello.py" }
    Write-Host ""
    Write-Host "Next:"
    Write-Host "  cd `"$ProjectPath`""
    if (-not $DocsOnly -and -not $SkipUvSync) { Write-Host "  uv sync" }
    elseif (-not $DocsOnly) { Write-Host "  uv sync" }
    Write-Host "  uv run ruff check ."
    Write-Host "  uv run ty check"
    Write-Host "  uv run sphinx-build -b html docs docs/_build"
}

Set-Alias -Name Init-PythonSphinxDocs -Value Init-PythonProject
