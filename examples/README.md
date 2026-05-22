# Examples (ompy_docs repository)

This folder documents how to use **ompy_docs**, not sample code for a Python library.

## Quick demo

```powershell
# From repo root
Import-Module .\OmpyDocs\OmpyDocs.psd1 -Force

$demo = Join-Path $env:TEMP "ompy-docs-demo"
if (Test-Path $demo) { Remove-Item $demo -Recurse -Force }
New-Item -ItemType Directory -Path $demo | Out-Null

Init-OmpyDocs -ProjectPath $demo -ProjectName DemoLib -UpdateReadme
cd $demo
uv sync
uv run python examples/hello.py
```

## See also

- [README.md](../README.md) — full install and parameter reference
