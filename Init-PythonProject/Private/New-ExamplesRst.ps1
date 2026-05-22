function New-ExamplesRstBody {
    param(
        [string]$ProjectPath,
        [string]$PackageName
    )
    $examplesDir = Join-Path $ProjectPath 'examples'
    if (-not (Test-Path $examplesDir)) {
        return "No ``examples/`` directory yet. Add scripts and re-run ``Init-PythonProject`` or edit this page."
    }

    $scripts = Get-ChildItem -Path $examplesDir -Filter '*.py' -File |
        Where-Object { $_.Name -notmatch '^_' }

    if (-not $scripts) {
        return "Add ``.py`` scripts under :file:`examples/` to list them here."
    }

    $sb = New-Object System.Text.StringBuilder
    foreach ($s in $scripts) {
        $name = $s.Name
        $doc = ''
        $lines = Get-Content $s.FullName -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line -match '^\s*"""(.*)"""?\s*$') {
                $doc = $Matches[1].Trim()
                break
            }
            if ($line -match '^\s*"""(.*)$') {
                $doc = $Matches[1].Trim()
                break
            }
        }
        if (-not $doc) { $doc = "Example script ``$name``." }

        [void]$sb.AppendLine($name)
        [void]$sb.AppendLine('~' * $name.Length)
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine($doc)
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('.. code-block:: bash')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("   uv run python examples/$name")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine(".. literalinclude:: ../examples/$name")
        [void]$sb.AppendLine('   :language: python')
        [void]$sb.AppendLine('')
    }
    return $sb.ToString().TrimEnd()
}
