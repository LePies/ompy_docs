# ompy_docs

Bootstrap Python projects with the [Astral](https://astral.sh) stack (**uv**, **ruff**, **ty**) and **Sphinx + Furo** documentation (styled API reference, todo-list directive, Sphinx-Gallery examples).

Works on **Windows (PowerShell or CMD)**, **Linux**, and **macOS (bash)**.

## Prerequisites

- [Git](https://git-scm.com/)
- **[uv](https://docs.astral.sh/uv/getting-started/installation/)** on `PATH`
- **Python 3** on `PATH` (for bash/CMD wrappers; PowerShell module does not require it)

```powershell
# Windows
winget install astral-sh.uv
```

```bash
# Linux / macOS
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Install

### PowerShell (recommended on Windows)

```powershell
git clone https://github.com/LePies/ompy_docs.git
cd ompy_docs
.\Install.ps1
Import-Module OmpyDocs
Get-Command Init-OmpyDocs   # alias: ompy_docs
```

`Install.ps1` copies `OmpyDocs/` and `templates/` to  
`%USERPROFILE%\Documents\PowerShell\Modules\OmpyDocs\`.

Try without installing:

```powershell
Import-Module .\OmpyDocs\OmpyDocs.psd1 -Force
```

### Bash (Linux, macOS, Git Bash, WSL)

```bash
git clone https://github.com/LePies/ompy_docs.git
cd ompy_docs
chmod +x scripts/*.sh
./scripts/install.sh    # links into ~/.local/bin
# ensure ~/.local/bin is on PATH
```

### CMD (Windows Command Prompt)

```cmd
git clone https://github.com/LePies/ompy_docs.git
cd ompy_docs
scripts\install.cmd
```

Adds wrappers under `%USERPROFILE%\bin` (add to PATH if needed).

### Direct Python CLI (any OS)

From the cloned repo:

```bash
python scripts/ompy_docs_cli.py init --project-path /path/to/project
python scripts/ompy_docs_cli.py build --project-path /path/to/project
```

## Usage

### PowerShell

```powershell
Init-OmpyDocs -ProjectPath C:\dev\MyLibrary -ProjectName MyLibrary -IconPath .\logo.png
cd C:\dev\MyLibrary
Build-OmpyDocs
```

### Bash / Git Bash

```bash
init-ompy-docs --project-path ./MyLibrary --package-name mylib --icon-path ./logo.png
cd MyLibrary
build-ompy-docs
```

Or from the repo without installing:

```bash
./scripts/init-ompy-docs.sh --project-path ./MyLibrary
./scripts/build-ompy-docs.sh --project-path ./MyLibrary
```

### CMD

```cmd
init-ompy-docs --project-path .\MyLibrary --package-name mylib
cd MyLibrary
build-ompy-docs
```

Or:

```cmd
scripts\init-ompy-docs.cmd --project-path .
scripts\build-ompy-docs.cmd
```

### Existing project (`src/<package>/` already)

```powershell
Init-OmpyDocs -ProjectPath C:\dev\ExistingRepo -PackageName mypkg
```

```bash
init-ompy-docs --project-path ./ExistingRepo --package-name mypkg
```

### Docs only (skip uv bootstrap)

PowerShell: `-DocsOnly`  
CLI: `--docs-only`

### Common CLI flags (`init`)

| Flag | Description |
|------|-------------|
| `--project-path` | Repository root (default: `.`) |
| `--project-name` | Display name (default: folder name) |
| `--package-name` | Import name under `src/` |
| `--author` | Docs metadata |
| `--docs-only` | Skip uv / ruff / ty bootstrap |
| `--skip-examples` | Do not create `examples/` |
| `--skip-uv-sync` | Do not run `uv sync` at end of init |
| `--icon-path` | Logo → `docs/_static/`, Furo sidebar + home page |
| `--force` | Overwrite existing `docs/` and `examples/` |

PowerShell also supports `-UpdateReadme` (not in the Python CLI yet).

New projects include **Sphinx-Gallery**: scripts in `examples/` become the gallery at `docs/auto_examples/`.

## Build (one command)

| Shell | Command |
|-------|---------|
| PowerShell | `Build-OmpyDocs` |
| bash | `build-ompy-docs` |
| CMD | `build-ompy-docs` |

Runs `uv sync`, `ruff check`, `ty check`, `sphinx-build`, then opens `docs/_build/index.html` (unless skipped).

Skip steps: PowerShell `-SkipRuff` / `-SkipTy` / `-SkipOpenBrowser`; CLI `--skip-ruff` / `--skip-ty` / `--skip-open-browser`.

## Daily workflow (manual)

```bash
uv sync
uv run ruff check .
uv run ty check
uv run sphinx-build -b html docs docs/_build
```

On OneDrive or when hardlinks fail:

```bash
export UV_LINK_MODE=copy   # bash
set UV_LINK_MODE=copy      # cmd
```

## Repository layout

```
ompy_docs/
  OmpyDocs/              # PowerShell module
  scripts/
    ompy_docs_cli.py     # cross-platform init + build
    init-ompy-docs.sh / .cmd
    build-ompy-docs.sh / .cmd
    install.sh / install.cmd
  templates/             # scaffold for target projects
  Install.ps1            # PowerShell module install
```

## Updating

```powershell
cd ompy_docs
git pull
.\Install.ps1
```

```bash
git pull
./scripts/install.sh
```

## License

MIT — see [LICENSE](LICENSE).
