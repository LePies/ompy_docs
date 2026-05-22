@{
    ModuleVersion     = '1.3.0'
    GUID              = 'a3f8c2e1-9b4d-4f6a-8e2c-1d5b7a9e0f3c'
    Author            = 'Oliver Mohr'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2026 Oliver Mohr. All rights reserved.'
    Description       = 'ompy_docs — initialize and build Python projects with uv, ruff, ty, and Sphinx/Furo documentation.'
    PowerShellVersion = '5.1'
    RootModule        = 'OmpyDocs.psm1'
    FunctionsToExport = @('Init-OmpyDocs', 'Build-OmpyDocs')
    AliasesToExport   = @('ompy_docs')
    VariablesToExport = @()
    CmdletsToExport   = @()
}
