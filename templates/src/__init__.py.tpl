"""{{PROJECT_NAME}} package."""

__version__ = "{{VERSION}}"

__all__ = ["hello"]


def hello() -> str:
    """Return a short greeting (used by ``examples/hello.py``)."""
    return "Hello from {{IMPORT_PREFIX}}!"
