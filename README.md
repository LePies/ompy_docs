# ompy_docs

PowerShell module to bootstrap Python projects with the [Astral](https://astral.sh) stack (**uv**, **ruff**, **ty**) and **Sphinx + Furo** documentation (styled API reference, todo-list directive, examples folder).

## Prerequisites

- Windows PowerShell 5.1+ (PowerShell 7+ also works)
- [Git](https://git-scm.com/)
- **[uv](https://docs.astral.sh/uv/getting-started/installation/)** on `PATH`:

```powershell
winget install astral-sh.uv
# or: irm https://astral.sh/uv/install.ps1 | iex
```

## Install the module

```powershell
git clone https://github.com/LePies/ompy_docs.git
cd ompy_docs
.\Install.ps1
Import-Module OmpyDocs
Get-Command Init-OmpyDocs
# or use the alias:
Get-Command ompy_docs
```

`Install.ps1` copies `OmpyDocs/` and `templates/` into:

`%USERPROFILE%\Documents\PowerShell\Modules\OmpyDocs\`

### Try without installing

```powershell
Import-Module .\OmpyDocs\OmpyDocs.psd1 -Force
```

## Usage

### New project (greenfield)

```powershell
mkdir C:\dev\MyLibrary
Init-OmpyDocs -ProjectPath C:\dev\MyLibrary -ProjectName MyLibrary -UpdateReadme
# same as: ompy_docs -ProjectPath C:\dev\MyLibrary ...
cd C:\dev\MyLibrary
uv sync
uv run python examples/hello.py
uv run sphinx-build -b html docs docs/_build
```

### Existing project (`src/<package>/` already)

```powershell
Init-OmpyDocs -ProjectPath C:\dev\ExistingRepo -PackageName mypkg -UpdateReadme
```

### Docs only

```powershell
Init-OmpyDocs -ProjectPath C:\dev\ExistingRepo -DocsOnly -PackageName mypkg
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| `-ProjectPath` | Repository root (default: current directory) |
| `-ProjectName` | Project display name (default: folder name) |
| `-PackageName` | Import name under `src/` (auto-detected if omitted) |
| `-Author` | Docs metadata |
| `-DocsOnly` | Skip uv / ruff / ty bootstrap |
| `-SkipExamples` | Do not create `examples/` or `docs/examples.rst` |
| `-SkipUvSync` | Do not run `uv sync` at end of init |
| `-UpdateReadme` | Append development/docs section to `README.md` |
| `-Force` | Overwrite existing `docs/` and `examples/` |

## Daily workflow

```powershell
uv sync
uv run ruff check .
uv run ruff format .
uv run ty check
uv run sphinx-build -b html docs docs/_build
```

## Repository layout

```
ompy_docs/
  OmpyDocs/           # PowerShell module
  templates/          # Scaffold copied into target projects
  examples/           # How to use this tool
  Install.ps1
```

## Updating

```powershell
cd ompy_docs
git pull
.\Install.ps1
```

## License

MIT — see [LICENSE](LICENSE).
