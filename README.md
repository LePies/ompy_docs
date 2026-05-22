# init-python-sphinx-docs

PowerShell module to bootstrap Python projects with the [Astral](https://astral.sh) stack (**uv**, **ruff**, **ty**) and **Sphinx + Furo** documentation (styled API reference, todo-list directive, examples folder).

Built from the documentation setup used in the OM_Master2026 thesis codebase; packaged as a reusable initializer in a **separate repository** from that project.

## Prerequisites

- Windows PowerShell 5.1+ (PowerShell 7+ also works)
- [Git](https://git-scm.com/)
- **[uv](https://docs.astral.sh/uv/getting-started/installation/)** on `PATH`:

```powershell
winget install astral-sh.uv
# or: irm https://astral.sh/uv/install.ps1 | iex
```

## Install the module

From a clone of this repository:

```powershell
git clone https://github.com/LePies/init-python-sphinx-docs.git
cd init-python-sphinx-docs
.\Install.ps1
Import-Module Init-PythonProject
Get-Command Init-PythonProject
```

`Install.ps1` copies `Init-PythonProject/` and `templates/` into:

`%USERPROFILE%\Documents\PowerShell\Modules\Init-PythonProject\`

### Try without installing

```powershell
Import-Module .\Init-PythonProject\Init-PythonProject.psd1 -Force
```

## Usage

### New project (greenfield)

```powershell
mkdir C:\dev\MyLibrary
Init-PythonProject -ProjectPath C:\dev\MyLibrary -ProjectName MyLibrary -UpdateReadme
cd C:\dev\MyLibrary
uv sync
uv run python examples/hello.py
uv run sphinx-build -b html docs docs/_build
```

This creates:

- `pyproject.toml`, `uv.lock`, `.python-version`, `.venv` (after `uv sync`)
- `src/<package>/` with `py.typed` and a `hello()` stub
- `examples/hello.py`
- `docs/` (Sphinx + Furo, API pages auto-scanned from `src/`)
- `todo.md` (included on the docs home page via `.. todo-list::`)

### Existing project (`src/<package>/` already)

```powershell
Init-PythonProject -ProjectPath C:\dev\ExistingRepo -PackageName mypkg -UpdateReadme
```

Adds uv tooling (unless `-DocsOnly`), docs tree, and examples when missing.

### Docs only

```powershell
Init-PythonProject -ProjectPath C:\dev\ExistingRepo -DocsOnly -PackageName mypkg
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

Alias: `Init-PythonSphinxDocs`

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
init-python-sphinx-docs/
  Init-PythonProject/    # PowerShell module
  templates/             # Copied into target projects (and shipped with module install)
  examples/              # Notes for using this tool
  Install.ps1
```

## Updating

```powershell
cd init-python-sphinx-docs
git pull
.\Install.ps1
```

## Publish this tool to GitHub

After cloning, authenticate and create the remote (one-time):

```powershell
gh auth login
cd C:\Users\OliverMohr\WorkingFolder\MSc\init-python-sphinx-docs
gh repo create init-python-sphinx-docs --public --source=. --remote=origin --push
```

Or create an empty repo on GitHub and:

```powershell
git remote add origin https://github.com/<your-user>/init-python-sphinx-docs.git
git push -u origin main
```

## License

MIT — see [LICENSE](LICENSE).
