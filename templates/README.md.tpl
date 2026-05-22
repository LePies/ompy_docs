# {{PROJECT_NAME}}

Python project initialized with [init-python-sphinx-docs](https://github.com/LePies/init-python-sphinx-docs) (uv, ruff, ty, Sphinx + Furo).

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
uv sync
uv run sphinx-build -b html docs docs/_build
```

Open `docs/_build/index.html` in a browser.

<!-- init-python-sphinx-docs:development -->
