# FYS5419 Project 1

Repository for FYS5419/FYS9419 Project 1 by Marius Torsheim, Department of Physics, University of Oslo.

The project studies one- and two-qubit Hamiltonians and the Lipkin model using exact diagonalization and self-written variational quantum eigensolver routines.

## Repository structure

```text
FYS5419_Project_1/
├── .github/workflows/      # Continuous integration
├── data/                   # Optional local data files
├── docs/                   # Project description and documentation
├── external/               # Optional local course-source clones, ignored by git
├── notebooks/              # Exploratory notebooks
├── report/                 # Final report PDF, LaTeX source, and figures
├── results/                # Generated data and figures
├── scripts/                # Python entry points for reproducibility
├── src/fys5419_project1/   # Python package
└── tests/                  # Unit and repository-polish tests
```

## Final report

The final report is available at:

- `report/project1_report.pdf`
- `report/project1_report.tex`

## Python workflow

```bash
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
python -m pytest
python scripts/run_all.py
python scripts/make_report_figures.py
python scripts/restricted_ansatz_check.py
```

No shell scripts are required for the project workflow.
