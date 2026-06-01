"""Compile the LaTeX report from Python.

This helper keeps the repository workflow Python-driven. It requires a local
LaTeX installation with ``pdflatex`` available on PATH. The already compiled
PDF is included in ``report/project1_report.pdf``.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def main() -> int:
    report_dir = Path(__file__).resolve().parents[1] / "report"
    tex_file = report_dir / "project1_report.tex"
    if not tex_file.exists():
        print(f"Missing {tex_file}", file=sys.stderr)
        return 1

    for _ in range(2):
        result = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", tex_file.name],
            cwd=report_dir,
            check=False,
        )
        if result.returncode != 0:
            return result.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
