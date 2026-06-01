# FYS5419 Project 1

This repository contains Python code for FYS5419 Project 1: one-qubit gates,
Bell-state measurements, density matrices, standard diagonalization, VQE, two-qubit
Hamiltonians, and the Lipkin model.

The code is intentionally written without depending on Qiskit or PennyLane, so the
VQE implementation is our own small state-vector implementation. External packages
are only used for linear algebra, optimization, data files and plotting.

## Typical workflow

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -e ".[dev]"
pytest
python scripts/run_all.py
```

Generated numerical data are placed in `results/data/` and figures in
`results/figures/`.
