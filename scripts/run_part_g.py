"""Convenience wrapper for the reproducible project pipeline.

The final project is generated through ``scripts/run_all.py``, which writes
all selected CSV/TXT results and figures used in the report.
"""

from __future__ import annotations

from run_all import main


if __name__ == "__main__":
    main()
