# Examples (installer repository)

This folder documents how to use **init-python-sphinx-docs**, not sample code for a Python library.

## Quick demo

```powershell
# From repo root
Import-Module .\Init-PythonProject\Init-PythonProject.psd1 -Force

$demo = Join-Path $env:TEMP "init-python-sphinx-docs-demo"
if (Test-Path $demo) { Remove-Item $demo -Recurse -Force }
New-Item -ItemType Directory -Path $demo | Out-Null

Init-PythonProject -ProjectPath $demo -ProjectName DemoLib -UpdateReadme
cd $demo
uv sync
uv run python examples/hello.py
```

## See also

- [README.md](../README.md) — full install and parameter reference
