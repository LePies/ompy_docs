$PrivateDir = Join-Path $PSScriptRoot 'Private'
Get-ChildItem -Path $PrivateDir -Filter '*.ps1' | ForEach-Object {
    . $_.FullName
}
. (Join-Path $PSScriptRoot 'Public\Init-OmpyDocs.ps1')

Export-ModuleMember -Function Init-OmpyDocs -Alias ompy_docs
