#!/usr/bin/env python3
"""Generate platform priorities docs pages from todo markdown files."""

from __future__ import annotations

import sys
from pathlib import Path

try:
    import markdown
except ImportError:
    print(
        "Missing dependency: markdown\n"
        "Install with: python3 -m pip install -r scripts/requirements-docs.txt",
        file=sys.stderr,
    )
    sys.exit(1)


def render_priorities_page(source: Path, target: Path, page_title: str) -> None:
    markdown_text = source.read_text(encoding="utf-8")
    body = markdown.markdown(
        markdown_text,
        extensions=["extra", "toc", "sane_lists"],
        output_format="html5",
    )
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="robots" content="noindex, nofollow, noarchive" />
  <title>{page_title}</title>
</head>
<body>
  <!-- AUTO-GENERATED FROM {source.as_posix()}. DO NOT EDIT. -->
  {body}
</body>
</html>
"""
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(html, encoding="utf-8")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    source = root / "todo" / "todo.md"
    target = root / "docs" / "priorities" / "index.html"

    if not source.exists():
        print(f"Source file not found: {source}", file=sys.stderr)
        return 1

    render_priorities_page(source, target, "Haderach Platform - Priorities")
    print(f"Generated {target.relative_to(root)} from {source.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
