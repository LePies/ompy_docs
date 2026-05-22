#!/usr/bin/env python3
"""Cross-platform ompy_docs CLI (init + build). Used by bash/cmd wrappers and directly."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import webbrowser
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
TEMPLATES = REPO_ROOT / "templates"
GITIGNORE_MARKER = "# --- ompy_docs ---"


def repo_root() -> Path:
    return REPO_ROOT


def normalize_package_name(name: str) -> str:
    n = re.sub(r"[^a-zA-Z0-9]+", "_", name).strip("_").lower()
    if not n or n[0].isdigit():
        n = f"pkg_{n}" if n else "myproject"
    return n


def expand_tokens(text: str, tokens: dict[str, str]) -> str:
    for key, value in tokens.items():
        text = text.replace(f"{{{{{key}}}}}", value)
    return text


def build_tokens(
    project_name: str,
    package_name: str,
    author: str,
    version: str,
    todo_rel: str,
    icon_path: str | None = None,
    docs_dir: Path | None = None,
) -> dict[str, str]:
    year = str(datetime.now().year)
    short = version
    m = re.match(r"^(\d+\.\d+)", version)
    if m:
        short = m.group(1)
    author_bib = '"' + author.replace('"', "") + '"'
    tokens = {
        "PROJECT_NAME": project_name,
        "PACKAGE_NAME": package_name,
        "IMPORT_PREFIX": package_name,
        "AUTHOR": author,
        "AUTHOR_BIB": author_bib,
        "VERSION": version,
        "VERSION_SHORT": short,
        "COPYRIGHT_YEAR": year,
        "TODO_REL_PATH": todo_rel.replace("\\", "/"),
        "HTML_LOGO_LINE": "# html_logo not set — pass --icon-path to add a package icon",
        "HTML_FAVICON": "None",
        "PACKAGE_ICON_RST": "",
    }
    if icon_path and docs_dir is not None:
        apply_icon_tokens(tokens, Path(icon_path), docs_dir)
    return tokens


def apply_icon_tokens(tokens: dict[str, str], icon_path: Path, docs_dir: Path) -> None:
    if not icon_path.is_file():
        raise FileNotFoundError(f"Icon file not found: {icon_path}")
    ext = icon_path.suffix.lower()
    if ext not in {".png", ".jpg", ".jpeg", ".svg", ".ico", ".gif", ".webp"}:
        raise ValueError(f"Unsupported icon extension '{ext}'")
    static = docs_dir / "_static"
    static.mkdir(parents=True, exist_ok=True)
    dest_name = f"package_icon{ext}"
    shutil.copy2(icon_path, static / dest_name)
    ref = f"_static/{dest_name}"
    tokens["HTML_LOGO_LINE"] = f'html_logo = "{ref}"'
    tokens["HTML_FAVICON"] = f'"{ref}"'
    tokens["PACKAGE_ICON_RST"] = f"""
.. container:: package-icon-row

   .. image:: {ref}
      :alt: {tokens["PROJECT_NAME"]}
      :width: 120px
      :class: package-icon

"""


def run_uv(args: list[str], cwd: Path) -> None:
    env = os.environ.copy()
    env.setdefault("UV_LINK_MODE", "copy")
    subprocess.run(["uv", *args], cwd=cwd, check=True, env=env)


def ensure_uv() -> None:
    if shutil.which("uv"):
        return
    raise RuntimeError(
        "uv is not on PATH. Install from https://docs.astral.sh/uv/getting-started/installation/"
    )


def detect_package(project_path: Path, package_name: str | None) -> str:
    src = project_path / "src"
    if not src.is_dir():
        raise FileNotFoundError(f"No src/ under {project_path}")
    pkgs = [d for d in src.iterdir() if d.is_dir() and (d / "__init__.py").is_file()]
    if package_name:
        if not (src / package_name / "__init__.py").is_file():
            raise FileNotFoundError(f"Package '{package_name}' not found under src/")
        return package_name
    if not pkgs:
        raise FileNotFoundError("No Python package under src/ (need src/<name>/__init__.py)")
    if len(pkgs) > 1:
        names = ", ".join(p.name for p in pkgs)
        raise ValueError(f"Multiple packages under src/: {names}. Pass --package-name")
    return pkgs[0].name


def ensure_package_src(
    project_path: Path,
    project_name: str,
    package_name: str,
    tokens: dict[str, str],
    force: bool,
) -> None:
    src_root = project_path / "src"
    pkg_dir = src_root / package_name
    init_py = pkg_dir / "__init__.py"
    typed = pkg_dir / "py.typed"
    src_root.mkdir(parents=True, exist_ok=True)
    if src_root.is_dir():
        dirs = [d for d in src_root.iterdir() if d.is_dir()]
        if len(dirs) == 1 and dirs[0].name != package_name and not pkg_dir.exists():
            dirs[0].rename(pkg_dir)
    pkg_dir.mkdir(parents=True, exist_ok=True)
    tpl = TEMPLATES / "src" / "__init__.py.tpl"
    if not init_py.exists() or force:
        if tpl.is_file():
            init_py.write_text(expand_tokens(tpl.read_text(encoding="utf-8"), tokens), encoding="utf-8")
        else:
            init_py.write_text(
                f'"""{project_name} package."""\n\n\ndef hello() -> str:\n'
                f'    return "Hello from {package_name}!"\n',
                encoding="utf-8",
            )
    typed.touch(exist_ok=True)
    if not init_py.is_file():
        raise RuntimeError(f"Could not create {init_py}")


def merge_pyproject_tooling(pyproject: Path) -> None:
    fragment = TEMPLATES / "pyproject.tooling.toml"
    if not fragment.is_file() or not pyproject.is_file():
        return
    content = pyproject.read_text(encoding="utf-8")
    if "[tool.uv]" in content and "[tool.ruff]" in content:
        return
    with pyproject.open("a", encoding="utf-8") as f:
        f.write("\n" if not content.endswith("\n") else "")
        f.write(fragment.read_text(encoding="utf-8"))
        if not content.endswith("\n"):
            f.write("\n")


def append_gitignore(project_path: Path) -> None:
    append_file = TEMPLATES / "gitignore.append.txt"
    gi = project_path / ".gitignore"
    marker = GITIGNORE_MARKER
    text = append_file.read_text(encoding="utf-8")
    if gi.is_file():
        if marker in gi.read_text(encoding="utf-8"):
            return
        with gi.open("a", encoding="utf-8") as f:
            f.write(text if text.startswith("\n") else "\n" + text)
    else:
        gi.write_text(text.lstrip("\n"), encoding="utf-8")


def copy_template_tree(src_dir: Path, dest_dir: Path, tokens: dict[str, str]) -> None:
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    dest_dir.mkdir(parents=True, exist_ok=True)

    def should_skip(path: Path) -> bool:
        return path.name == "__pycache__" or path.suffix == ".pyc"

    for path in src_dir.rglob("*"):
        if should_skip(path):
            continue
        rel = path.relative_to(src_dir)
        out = dest_dir / rel
        if path.is_dir():
            out.mkdir(parents=True, exist_ok=True)
        else:
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(expand_tokens(path.read_text(encoding="utf-8"), tokens), encoding="utf-8")


def api_module_group(leaf: str) -> str:
    leaf = leaf.lower()
    if leaf in {"run", "__main__", "cli", "main", "app"}:
        return "EntryPoints"
    if leaf in {"constants", "config", "settings"}:
        return "Configuration"
    if re.search(r"solver|numeric|fvm", leaf):
        return "Numerics"
    if leaf in {"objects", "models", "model"}:
        return "Modelling"
    if leaf in {"scripts", "utils", "helpers", "plotting"}:
        return "Utilities"
    return "Other"


def api_page_title(dotted: str) -> str:
    parts = dotted.split(".")
    leaf = parts[-1]
    if leaf == "__init__" and len(parts) > 1:
        leaf = parts[-2]
    return leaf.replace("_", " ").title() if leaf else "Package"


@dataclass
class ApiModule:
    import_path: str
    rst_rel: str
    title: str
    group: str


def collect_api_modules(pkg_root: Path, package_name: str) -> list[ApiModule]:
    modules: list[ApiModule] = []
    for py in pkg_root.rglob("*.py"):
        if "__pycache__" in py.parts:
            continue
        if py.name.startswith("test_") or py.name == "conftest.py":
            continue
        rel = py.relative_to(pkg_root).as_posix()
        dotted = rel.removesuffix(".py").replace("/", ".")
        if py.name == "__init__.py":
            raw = py.read_text(encoding="utf-8").strip()
            if len(raw) <= 80:
                continue
            import_path = package_name
            rst_rel = "package"
        elif dotted.endswith(".__init__"):
            sub = dotted[: -len(".__init__")]
            import_path = f"{package_name}.{sub}"
            rst_rel = sub.replace(".", "/")
        else:
            import_path = f"{package_name}.{dotted}"
            rst_rel = dotted.replace(".", "/")
        modules.append(
            ApiModule(
                import_path=import_path,
                rst_rel=rst_rel,
                title=api_page_title(dotted),
                group=api_module_group(dotted.split(".")[-1]),
            )
        )
    return modules


def write_api_rst_tree(project_path: Path, package_name: str, docs_api: Path) -> str:
    if docs_api.exists():
        for f in docs_api.rglob("*.rst"):
            if f.name != "index.rst":
                f.unlink()
    docs_api.mkdir(parents=True, exist_ok=True)
    pkg_root = project_path / "src" / package_name
    modules = collect_api_modules(pkg_root, package_name)
    group_order = [
        ("EntryPoints", "Entry points"),
        ("Modelling", "Modelling"),
        ("Configuration", "Configuration"),
        ("Numerics", "Numerics"),
        ("Utilities", "Utilities"),
        ("Other", "Other"),
    ]
    index_lines: list[str] = []
    menu_links: list[str] = []
    for key, title in group_order:
        items = sorted((m for m in modules if m.group == key), key=lambda m: m.rst_rel)
        if not items:
            continue
        index_lines.extend([title, "-" * len(title), ".. toctree::", "   :maxdepth: 2", ""])
        for m in items:
            rst_file = docs_api / f"{m.rst_rel}.rst"
            rst_file.parent.mkdir(parents=True, exist_ok=True)
            depth = len(m.rst_rel.split("/")) - 1 if "/" in m.rst_rel else 0
            include = ".. include:: _api_menu.rst" if depth == 0 else ".. include:: " + "../" * depth + "_api_menu.rst"
            menu_doc = m.rst_rel.replace("\\", "/")
            menu_links.append(f":doc:`{m.title} </api/{menu_doc}>`")
            anchor = "api-" + m.import_path.replace(".", "-")
            ul = "=" * len(m.title)
            body = "\n".join(
                [
                    f".. _{anchor}:",
                    "",
                    m.title,
                    ul,
                    "",
                    ".. rst-class:: api-subtitle",
                    "",
                    f"   ``{m.import_path}``",
                    "",
                    include,
                    "",
                    f".. automodule:: {m.import_path}",
                    "   :members:",
                    "   :undoc-members:",
                    "   :show-inheritance:",
                    "   :noindex:",
                    "",
                ]
            )
            rst_file.write_text(body, encoding="utf-8")
            index_lines.append(f"   {m.rst_rel}")
        index_lines.append("")
    menu = "**API reference:** " + " \u00b7 ".join(menu_links) + "\n"
    (docs_api / "_api_menu.rst").write_text(menu, encoding="utf-8")
    return "\n".join(index_lines)


def uv_bootstrap(
    project_path: Path,
    project_name: str,
    package_name: str,
    author: str,
    version: str,
    todo_rel: str,
    python_version: str,
    docs_only: bool,
    skip_uv_sync: bool,
    force: bool,
    tokens: dict[str, str],
) -> None:
    if docs_only:
        return
    ensure_uv()
    pyproject = project_path / "pyproject.toml"
    greenfield = not pyproject.is_file()
    if greenfield:
        run_uv(["init", "--lib", "--name", package_name], project_path)
    ensure_package_src(project_path, project_name, package_name, tokens, force)
    run_uv(["add", "--dev", "ruff", "ty"], project_path)
    run_uv(
        [
            "add",
            "--group",
            "docs",
            "sphinx>=7,<9",
            "furo>=2024.1",
            "sphinxcontrib-bibtex",
            "sphinx-gallery>=0.16",
        ],
        project_path,
    )
    merge_pyproject_tooling(pyproject)
    pv = project_path / ".python-version"
    if not pv.is_file():
        pv.write_text(f"{python_version}\n", encoding="utf-8")
    if not skip_uv_sync:
        run_uv(["sync"], project_path)


def write_requirements_mirror(docs_dir: Path) -> None:
    (docs_dir / "requirements-docs.txt").write_text(
        """# Sphinx and extensions (mirrors [dependency-groups] docs in pyproject.toml)
sphinx>=7.0,<9
furo>=2024.1
sphinxcontrib-bibtex>=2.6
sphinx-gallery>=0.16
""",
        encoding="utf-8",
    )


def cmd_init(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    project_name = args.project_name or project_path.name
    package_name = normalize_package_name(args.package_name or project_name)
    docs_dir = project_path / "docs"
    examples_dir = project_path / "examples"

    if docs_dir.exists() and not args.force:
        print("docs/ already exists. Use --force to overwrite.", file=sys.stderr)
        return 1
    if not args.skip_examples and examples_dir.exists() and not args.force:
        print("examples/ already exists. Use --force or --skip-examples.", file=sys.stderr)
        return 1

    docs_dir_for_icon = project_path / "docs"
    if args.icon_path and not docs_dir_for_icon.exists():
        docs_dir_for_icon.mkdir(parents=True, exist_ok=True)
    tokens = build_tokens(
        project_name,
        package_name,
        args.author,
        args.version,
        args.todo_path,
        args.icon_path,
        docs_dir_for_icon if args.icon_path else None,
    )

    if not args.docs_only:
        uv_bootstrap(
            project_path,
            project_name,
            package_name,
            args.author,
            args.version,
            args.todo_path,
            args.python_version,
            args.docs_only,
            args.skip_uv_sync,
            args.force,
            tokens,
        )
        package_name = detect_package(project_path, args.package_name)

    todo = project_path / args.todo_path
    if not todo.is_file():
        tpl = TEMPLATES / "todo.md"
        todo.write_text(expand_tokens(tpl.read_text(encoding="utf-8"), tokens), encoding="utf-8")
    append_gitignore(project_path)

    if docs_dir.exists() and args.force:
        shutil.rmtree(docs_dir)
    copy_template_tree(TEMPLATES / "docs", docs_dir, tokens)

    api_body = write_api_rst_tree(project_path, package_name, docs_dir / "api")
    api_index_tpl = expand_tokens((TEMPLATES / "docs" / "api" / "index.rst").read_text(encoding="utf-8"), tokens)
    api_index_tpl = api_index_tpl.replace("{{API_INDEX_BODY}}", api_body)
    (docs_dir / "api" / "index.rst").write_text(api_index_tpl, encoding="utf-8")

    if not args.skip_examples:
        if examples_dir.exists() and args.force:
            shutil.rmtree(examples_dir)
        copy_template_tree(TEMPLATES / "examples", examples_dir, tokens)

    write_requirements_mirror(docs_dir)

    print(f"\nInitialized: {project_path}")
    print(f"  Package: {package_name} (src/{package_name}/)")
    print("  Docs:    docs/ -> docs/_build/index.html")
    if not args.skip_examples:
        print("  Examples: examples/ -> Sphinx-Gallery (docs/auto_examples/)")
    if args.icon_path:
        print("  Icon:     docs/_static/package_icon*")
    print("\nNext: build-ompy-docs  (or: python scripts/ompy_docs_cli.py build)")
    return 0


def cmd_build(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    pyproject = project_path / "pyproject.toml"
    docs_dir = project_path / "docs"
    index_html = docs_dir / "_build" / "index.html"

    if not pyproject.is_file():
        print(f"No pyproject.toml in {project_path}", file=sys.stderr)
        return 1
    if not docs_dir.is_dir():
        print(f"No docs/ in {project_path}", file=sys.stderr)
        return 1

    ensure_uv()
    print(f"Project: {project_path}\n")

    print("[1/4] uv sync")
    run_uv(["sync"], project_path)

    if not args.skip_ruff:
        print("[2/4] uv run ruff check .")
        run_uv(["run", "ruff", "check", "."], project_path)
    else:
        print("[2/4] ruff check (skipped)")

    if not args.skip_ty:
        print("[3/4] uv run ty check")
        run_uv(["run", "ty", "check"], project_path)
    else:
        print("[3/4] ty check (skipped)")

    print("[4/4] uv run sphinx-build -b html docs docs/_build")
    run_uv(["run", "sphinx-build", "-b", "html", "docs", "docs/_build"], project_path)

    if not index_html.is_file():
        print(f"Build finished but missing {index_html}", file=sys.stderr)
        return 1

    print(f"\nBuild succeeded: {index_html}")
    if not args.skip_open_browser:
        print("Opening in default browser...")
        webbrowser.open(index_html.resolve().as_uri())
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="ompy_docs",
        description="Initialize and build Python projects with uv, ruff, ty, and Sphinx/Furo docs.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_init = sub.add_parser("init", help="Scaffold project (like Init-OmpyDocs)")
    p_init.add_argument("--project-path", default=".", help="Project root")
    p_init.add_argument("--project-name", default=None)
    p_init.add_argument("--package-name", default=None)
    p_init.add_argument("--author", default=os.environ.get("USER", os.environ.get("USERNAME", "Author")))
    p_init.add_argument("--version", default="0.1.0")
    p_init.add_argument("--python-version", default="3.12")
    p_init.add_argument("--todo-path", default="todo.md")
    p_init.add_argument("--icon-path", default=None, help="Logo image (.png/.svg/...)")
    p_init.add_argument("--docs-only", action="store_true")
    p_init.add_argument("--skip-examples", action="store_true")
    p_init.add_argument("--skip-uv-sync", action="store_true")
    p_init.add_argument("--force", action="store_true")

    p_build = sub.add_parser("build", help="Sync, lint, typecheck, sphinx, open browser")
    p_build.add_argument("--project-path", default=".")
    p_build.add_argument("--skip-ruff", action="store_true")
    p_build.add_argument("--skip-ty", action="store_true")
    p_build.add_argument("--skip-open-browser", action="store_true")

    ns = parser.parse_args(argv)
    if ns.command == "init":
        return cmd_init(ns)
    if ns.command == "build":
        return cmd_build(ns)
    return 1


if __name__ == "__main__":
    sys.exit(main())
