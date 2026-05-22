function Set-PackageIconTokens {
    param(
        [hashtable]$Tokens,
        [string]$IconPath,
        [string]$DocsDir,
        [switch]$Force
    )

    if ([string]::IsNullOrWhiteSpace($IconPath)) {
        $Tokens['HTML_LOGO_LINE'] = '# html_logo not set — pass -IconPath to Init-OmpyDocs to add a package icon'
        $Tokens['HTML_FAVICON'] = 'None'
        $Tokens['PACKAGE_ICON_RST'] = ''
        return
    }

    if (-not (Test-Path $IconPath)) {
        throw "Icon file not found: $IconPath"
    }

    if (-not (Test-Path $DocsDir)) {
        New-Item -ItemType Directory -Path $DocsDir -Force | Out-Null
    }
    $staticDir = Join-Path $DocsDir '_static'
    if (-not (Test-Path $staticDir)) {
        New-Item -ItemType Directory -Path $staticDir -Force | Out-Null
    }

    $ext = [System.IO.Path]::GetExtension($IconPath).ToLowerInvariant()
    if ($ext -notin @('.png', '.jpg', '.jpeg', '.svg', '.ico', '.gif', '.webp')) {
        throw "Unsupported icon extension '$ext'. Use .png, .jpg, .svg, or .ico."
    }

    $destName = "package_icon$ext"
    $destPath = Join-Path $staticDir $destName
    Copy-Item -Path $IconPath -Destination $destPath -Force:$Force

    $staticRef = "_static/$destName"
    $Tokens['HTML_LOGO_LINE'] = "html_logo = `"$staticRef`""
    $Tokens['HTML_FAVICON'] = "`"$staticRef`""
    $Tokens['PACKAGE_ICON_RST'] = @"

.. container:: package-icon-row

   .. image:: $staticRef
      :alt: $($Tokens['PROJECT_NAME'])
      :width: 120px
      :class: package-icon

"@
}
