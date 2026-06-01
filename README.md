# FYS5419 Project 1

Repository for **FYS5419/FYS9419 Project 1** by Marius Torsheim,
Department of Physics, University of Oslo.

The project studies small Hamiltonians and the Lipkin model with exact
diagonalization and self-written variational quantum eigensolver routines.
The repository contains the Python package, reproducibility scripts, tests,
selected numerical results, figures, and the final report.

## Repository contents

- `src/fys5419_project1/`: implemented Python package.
- `scripts/`: Python scripts for running calculations and checks.
- `tests/`: unit tests and repository-polish tests.
- `results/data/`: selected CSV/TXT outputs.
- `results/figures/`: report figures.
- `report/project1_report.pdf`: final report PDF.
- `report/project1_report.tex`: report source.

## Python workflow

Create and activate a virtual environment in your normal terminal, then run:

```text
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
python -m pytest
python scripts/run_all.py
python scripts/make_report_figures.py
python scripts/restricted_ansatz_check.py
```

The final report PDF is included. If a local LaTeX installation is available,
the report can be compiled through the Python helper:

```text
python scripts/compile_report.py
```

No shell scripts are required for the project workflow.
