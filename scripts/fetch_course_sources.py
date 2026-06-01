"""Fetch the course repository into ``external/`` using Python.

The external directory is ignored by git and is only meant as a local
reference copy of the course material.
"""

from __future__ import annotations

import subprocess
from pathlib import Path


COURSE_URL = "https://github.com/CompPhysics/QuantumComputingMachineLearning.git"


def main() -> int:
    target = Path("external") / "QuantumComputingMachineLearning"
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        print(f"Course repository already exists at {target}")
        return 0
    return subprocess.run(["git", "clone", COURSE_URL, str(target)], check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
