function Expand-TokenString {
    param(
        [string]$Text,
        [hashtable]$Tokens
    )
    foreach ($key in $Tokens.Keys) {
        $Text = $Text -replace [regex]::Escape("{{$key}}"), [string]$Tokens[$key]
    }
    return $Text
}

function Copy-TokenTemplateTree {
    param(
        [string]$SourceDir,
        [string]$DestDir,
        [hashtable]$Tokens,
        [switch]$Force
    )
    if (-not (Test-Path $SourceDir)) {
        throw "Template source not found: $SourceDir"
    }
    if ((Test-Path $DestDir) -and -not $Force) {
        throw "Destination exists: $DestDir (use -Force to overwrite)."
    }
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    Get-ChildItem -Path $SourceDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
        $outPath = Join-Path $DestDir $rel
        $outDir = Split-Path -Parent $outPath
        if ($outDir -and -not (Test-Path $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }
        $raw = [System.IO.File]::ReadAllText($_.FullName)
        $expanded = Expand-TokenString -Text $raw -Tokens $Tokens
        [System.IO.File]::WriteAllText($outPath, $expanded)
    }
}

function Write-TokenTemplateFile {
    param(
        [string]$SourceFile,
        [string]$DestFile,
        [hashtable]$Tokens,
        [switch]$Force
    )
    if ((Test-Path $DestFile) -and -not $Force) {
        return $false
    }
    $dir = Split-Path -Parent $DestFile
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $raw = [System.IO.File]::ReadAllText($SourceFile)
    $expanded = Expand-TokenString -Text $raw -Tokens $Tokens
    [System.IO.File]::WriteAllText($DestFile, $expanded)
    return $true
}

function Update-GitIgnore {
    param(
        [string]$ProjectPath,
        [string]$AppendFile
    )
    $gi = Join-Path $ProjectPath '.gitignore'
    $marker = '# --- ompy_docs ---'
    $append = [System.IO.File]::ReadAllText($AppendFile)
    if (Test-Path $gi) {
        $existing = [System.IO.File]::ReadAllText($gi)
        if ($existing -match [regex]::Escape($marker)) {
            return
        }
        [System.IO.File]::AppendAllText($gi, "`n$append")
    }
    else {
        [System.IO.File]::WriteAllText($gi, $append.TrimStart())
    }
}

function Update-ProjectReadme {
    param(
        [string]$ProjectPath,
        [string]$TemplateFile,
        [hashtable]$Tokens,
        [switch]$Force
    )
    $readme = Join-Path $ProjectPath 'README.md'
    $marker = '<!-- ompy_docs:development -->'
    $block = Expand-TokenString -Text ([System.IO.File]::ReadAllText($TemplateFile)) -Tokens $Tokens
    if (Test-Path $readme) {
        $content = [System.IO.File]::ReadAllText($readme)
        if ($content -match [regex]::Escape($marker)) {
            if (-not $Force) { return }
            $pattern = "(?s)$([regex]::Escape($marker)).*$"
            $content = [regex]::Replace($content, $pattern, $block.Trim())
        }
        else {
            $content = $content.TrimEnd() + "`n`n" + $block.Trim() + "`n"
        }
        [System.IO.File]::WriteAllText($readme, $content)
    }
    else {
        [System.IO.File]::WriteAllText($readme, $block.Trim() + "`n")
    }
}
