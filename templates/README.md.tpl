# {{PROJECT_NAME}}

Python project initialized with [ompy_docs](https://github.com/LePies/ompy_docs) (uv, ruff, ty, Sphinx + Furo).

## Development

```powershell
uv sync
uv run ruff check .
uv run ruff format .
uv run ty check
```

## Examples

```powershell
uv run python examples/hello.py
```

## Documentation

```powershell
Build-OmpyDocs
```

Or manually: `uv sync`, `uv run ruff check .`, `uv run ty check`, `uv run sphinx-build -b html docs docs/_build` (requires [ompy_docs](https://github.com/LePies/ompy_docs) module for `Build-OmpyDocs`).

<!-- ompy_docs:development -->
