.. _getting_started:

===============
Getting started
===============

Environment
-----------

This project uses `uv <https://docs.astral.sh/uv/>`_ for dependencies and virtual environments.
From the project root:

.. code-block:: bash

   uv sync

Linting and type checking
-------------------------

.. code-block:: bash

   uv run ruff check .
   uv run ruff format .
   uv run ty check

Run an example
--------------

.. code-block:: bash

   uv run python examples/hello.py

Using the package
-----------------

After ``uv sync``, import the installed package:

.. code-block:: python

   from {{IMPORT_PREFIX}} import hello
   print(hello())

Building this documentation
---------------------------

.. code-block:: bash

   uv sync
   uv run sphinx-build -b html docs docs/_build

Open :file:`docs/_build/index.html` in a browser.

Alternatively, from :file:`docs/` run ``make html`` (or ``make.bat`` on Windows).
