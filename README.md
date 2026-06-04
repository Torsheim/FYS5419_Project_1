# FYS5419 Project 1 - VQE and Lipkin model

Repository for **FYS5419/FYS9419 Project 1** by Marius Torsheim, Department of Physics, University of Oslo.

This project studies small quantum Hamiltonians and the Lipkin-Meshkov-Glick model using exact diagonalization and self-written variational quantum eigensolver (VQE) routines. The implementation uses noiseless NumPy/SciPy state-vector simulations rather than high-level Qiskit or PennyLane abstractions. The code includes elementary quantum-state utilities, gate operations, density matrices, reduced density matrices, Pauli decompositions, exact spectra, ground-state VQE, and orthogonality-constrained excited-state VQE.

## Main results

The report studies:

- Bell-state preparation, measurement sampling, density matrices, and entanglement entropy.
- A one-qubit Hamiltonian with an avoided crossing near `lambda = 2/3`.
- A two-qubit Hamiltonian with competing parity sectors and a ground-state entropy jump near `lambda ≈ 0.4`.
- The Lipkin Hamiltonian for `J = 1` and `J = 2`, including qubit embeddings and Pauli-string decompositions.
- Ground-state VQE for the one- and two-qubit systems.
- Excited-state VQE for the full `J = 1` and `J = 2` Lipkin spectra using sequential orthogonality constraints.
- A restricted-ansatz check for the `J = 2` Lipkin ground state.

In the noiseless benchmark setting, the VQE calculations reproduce the exact spectra to numerical precision. The largest absolute VQE errors reported in the scans are approximately

- `1.65e-12` for the one-qubit ground state,
- `4.61e-12` for the two-qubit ground state,
- `4.44e-16` for the full `J = 1` Lipkin spectrum,
- `2.67e-15` for the full `J = 2` Lipkin spectrum.

These values should be interpreted as ideal state-vector benchmark results, not as predictions of noisy hardware performance.

## Repository layout

```text
FYS5419_Project_1/
├── .github/workflows/          Continuous integration
├── data/                       Optional local data files
├── docs/                       Project description and documentation
├── external/                   Optional external course-source clones
├── notebooks/                  Exploratory notebooks
├── report/                     LaTeX report source and compiled PDF
├── results/
│   ├── data/                   Generated CSV/TXT result files
│   └── figures/                Generated PDF/PNG figures used in the report
├── scripts/
│   ├── run_all.py              Regenerates selected data and figures
│   ├── make_report_figures.py  Recreates report figures from CSV files
│   ├── restricted_ansatz_check.py
│   ├── compile_report.py       Compiles the LaTeX report from Python
│   └── run_part_*.py           Convenience wrappers for the main pipeline
├── src/fys5419_project1/
│   ├── density.py              Density-matrix utilities
│   ├── gates.py                Basic quantum gates
│   ├── hamiltonians.py         Hamiltonians and Pauli decompositions
│   ├── lipkin.py               Lipkin-model helpers
│   ├── plotting.py             Plotting utilities
│   ├── quantum.py              State-vector and measurement utilities
│   └── vqe.py                  VQE ansaetze and optimizers
├── tests/                      Unit tests and repository checks
├── environment.yml             Conda environment specification
├── pyproject.toml              Package metadata and dev dependencies
├── requirements.txt            Pip requirements
└── README.md
```

## Setup

From the repository root:

```bash
python3 -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
```

The project requires Python `>=3.10`. The main dependencies are `numpy`, `scipy`, `matplotlib`, and `pandas`.

Alternatively, with conda:

```bash
conda env create -f environment.yml
conda activate fys5419-project1
```

## Tests

Run the test suite with:

```bash
python -m pytest
```

## Reproduce the selected results

The complete selected numerical pipeline is run with:

```bash
python scripts/run_all.py
```

This writes selected CSV/TXT data files to `results/data/` and figures to `results/figures/`.

To recreate only the report figures from already generated CSV files, run:

```bash
python scripts/make_report_figures.py
```

To run the restricted hardware-inspired ansatz comparison for the `J = 2` Lipkin ground state, run:

```bash
python scripts/restricted_ansatz_check.py
```

The `run_part_a.py` through `run_part_g.py` scripts are convenience wrappers for the reproducible project pipeline.

## Report

The final report is available at:

```text
report/project1_report.pdf
report/project1_report.tex
```

To compile the report locally with Python:

```bash
python scripts/compile_report.py
```

or manually with LaTeX:

```bash
cd report
pdflatex project1_report.tex
pdflatex project1_report.tex
cd ..
```

## Interpretation

The project is a transparent benchmark implementation of exact diagonalization and VQE for small Hamiltonians. The roundoff-level VQE errors occur because the simulations are noiseless and the main variational ansaetze are expressive enough for the small real Hamiltonians studied here. The restricted-ansatz check illustrates that this idealized result depends strongly on ansatz expressivity. A more hardware-oriented extension would include finite-shot sampling, noise models, circuit-depth constraints, and systematic comparisons of hardware-efficient ansaetze.
