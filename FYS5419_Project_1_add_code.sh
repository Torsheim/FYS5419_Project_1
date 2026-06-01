#!/usr/bin/env bash
set -euo pipefail

echo "Adding FYS5419 Project 1 code files to: $(pwd)"
echo "No git add/commit/push will be performed."

mkdir -p src/fys5419_project1 scripts tests report results/data results/figures

backup_dir="backup_before_project_code_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    mkdir -p "$backup_dir/$(dirname "$f")"
    cp "$f" "$backup_dir/$f"
  fi
}

backup_file .gitignore
mkdir -p .
cat > .gitignore <<'EOF__gitignore'
.venv/
__pycache__/
*.pyc
.ipynb_checkpoints/
.DS_Store

external/
results/raw/
build/
dist/
*.egg-info/

report/*.aux
report/*.log
report/*.out
report/*.toc
report/*.bbl
report/*.blg
report/*.synctex.gz
EOF__gitignore

backup_file Makefile
mkdir -p .
cat > Makefile <<'EOF_Makefile'
.PHONY: install test run clean

install:
	python -m pip install -e ".[dev]"

test:
	pytest

run:
	python scripts/run_all.py

clean:
	rm -rf build dist *.egg-info src/*.egg-info .pytest_cache
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
EOF_Makefile

backup_file README.md
mkdir -p .
cat > README.md <<'EOF_README_md'
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
EOF_README_md

backup_file pyproject.toml
mkdir -p .
cat > pyproject.toml <<'EOF_pyproject_toml'
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "fys5419-project1"
version = "0.1.0"
description = "Code for FYS5419 Project 1: VQE and Lipkin model"
readme = "README.md"
requires-python = ">=3.10"
dependencies = [
    "numpy>=1.24",
    "scipy>=1.10",
    "matplotlib>=3.7",
    "pandas>=2.0",
]

[project.optional-dependencies]
dev = ["pytest>=7.0", "jupyterlab>=4.0"]

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
pythonpath = ["src"]
testpaths = ["tests"]
addopts = "-q"
EOF_pyproject_toml

backup_file report/README.md
mkdir -p report
cat > report/README.md <<'EOF_report_README_md'
# Report folder

After running

```bash
python scripts/run_all.py
```

compile the draft report from the repository root with:

```bash
cd report
pdflatex main.tex
pdflatex main.tex
cd ..
```

Edit `main.tex` with your own explanations, numerical discussion, and final conclusions.
EOF_report_README_md

backup_file report/main.tex
mkdir -p report
cat > report/main.tex <<'EOF_report_main_tex'
\documentclass[11pt,a4paper]{article}
\usepackage[margin=1in]{geometry}
\usepackage{amsmath,amssymb,bm}
\usepackage{graphicx}
\usepackage{booktabs}
\usepackage{hyperref}
\usepackage{siunitx}
\hypersetup{colorlinks=true,linkcolor=blue,citecolor=blue,urlcolor=blue}

\title{FYS5419 Project 1: VQE and the Lipkin Model}
\author{Your Name}
\date{Spring 2026}

\begin{document}
\maketitle

\begin{abstract}
This report studies one- and two-qubit Hamiltonians and the Lipkin model using classical diagonalization and a variational quantum eigensolver implemented from scratch. Replace this text with a concise summary of your final numerical findings.
\end{abstract}

\section{Introduction}
Explain the physical problem, the role of the interaction strength, and why VQE is relevant for small Hamiltonians written in terms of Pauli matrices.

\section{Methods}
Describe the state-vector simulator, measurements, density matrices, partial traces, von Neumann entropy, standard diagonalization, Pauli decompositions, and VQE ansatz choices.

\section{Part a: one-qubit gates and Bell states}
Discuss the action of $X$, $Y$, $Z$, $H$, and $S$ on $|0\rangle$ and $|1\rangle$. Discuss Bell-state preparation and the measured average outcomes. Include the reduced density matrix and entropy.

\section{Parts b--c: one-qubit Hamiltonian and VQE}
The Hamiltonian is
\[
H(\lambda)=H_0+\lambda H_I.
\]
Include the Pauli form and compare exact diagonalization with the one-parameter VQE.

\begin{figure}[h]
\centering
\includegraphics[width=0.72\linewidth]{../results/figures/part_b_one_qubit_eigenvalues.png}
\caption{Exact eigenvalues of the one-qubit Hamiltonian as functions of $\lambda$.}
\end{figure}

\begin{figure}[h]
\centering
\includegraphics[width=0.72\linewidth]{../results/figures/part_c_one_qubit_vqe_error.png}
\caption{Absolute error of the one-qubit VQE ground-state energy.}
\end{figure}

\section{Parts d--e: two-qubit Hamiltonian, entanglement, and VQE}
Discuss the two-qubit Hamiltonian, exact eigenvalues, the reduced density matrix of the ground state, and the entropy $S(\rho_A)$.

\begin{figure}[h]
\centering
\includegraphics[width=0.72\linewidth]{../results/figures/part_d_two_qubit_entropy.png}
\caption{Ground-state entanglement entropy for subsystem $A$.}
\end{figure}

\section{Parts f--g: Lipkin model and VQE}
Present the $J=1$ and $J=2$ Lipkin Hamiltonians, their Pauli decompositions after padding to qubit Hilbert spaces, exact spectra, and VQE comparison.

\begin{figure}[h]
\centering
\includegraphics[width=0.72\linewidth]{../results/figures/part_f_lipkin_j1_exact.png}
\caption{Exact eigenvalues of the Lipkin $J=1$ Hamiltonian.}
\end{figure}

\begin{figure}[h]
\centering
\includegraphics[width=0.72\linewidth]{../results/figures/part_f_lipkin_j2_exact.png}
\caption{Exact eigenvalues of the Lipkin $J=2$ Hamiltonian.}
\end{figure}

\begin{figure}[h]
\centering
\includegraphics[width=0.72\linewidth]{../results/figures/part_g_lipkin_vqe_error.png}
\caption{VQE ground-state energy error for the embedded Lipkin Hamiltonians.}
\end{figure}

\section{Conclusion}
Summarize the main observations: level mixing, entanglement growth, VQE agreement with exact diagonalization, and limitations of the chosen ansatz.

\appendix
\section{Reproducibility}
The numerical results were generated with:
\begin{verbatim}
python scripts/run_all.py
\end{verbatim}

\section{AI/LLM declaration}
State clearly how AI tools were used, which parts were checked by you, and which calculations/results were generated by your own code.

\end{document}
EOF_report_main_tex

backup_file scripts/run_all.py
mkdir -p scripts
cat > scripts/run_all.py <<'EOF_scripts_run_all_py'
#!/usr/bin/env python3
"""Run all numerical experiments for FYS5419 Project 1.

The script creates CSV files and figures for the report. It does not require
Qiskit/PennyLane; the VQE code used here is the small implementation in src/.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from fys5419_project1.hamiltonians import (
    format_pauli_decomposition,
    lipkin_j1,
    lipkin_j2,
    one_qubit_hamiltonian,
    one_qubit_pauli_coefficients,
    pad_to_power_of_two,
    pauli_decomposition,
    sorted_eigh,
    two_qubit_hamiltonian,
)
from fys5419_project1.quantum import (
    HADAMARD,
    PHASE_S,
    X,
    Y,
    Z,
    bell_state,
    density_matrix,
    ket0,
    ket1,
    marginal_probabilities_for_qubit,
    measure_full_state,
    measure_qubit,
    prepare_bell_with_h_and_cnot,
    reduced_density_matrix,
    von_neumann_entropy,
)
from fys5419_project1.vqe import (
    vqe_normalized_real,
    vqe_one_qubit_ry,
    vqe_two_qubit_parity,
)

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "results" / "data"
FIG = ROOT / "results" / "figures"


def savefig(name: str) -> None:
    FIG.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(FIG / name, dpi=200)
    plt.close()


def run_part_a() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    zero, one = ket0(), ket1()
    gates = {"X": X, "Y": Y, "Z": Z, "H": HADAMARD, "S": PHASE_S}

    lines: list[str] = []
    lines.append("Part a: one-qubit gate actions")
    for gate_name, gate in gates.items():
        lines.append(f"{gate_name}|0> = {gate @ zero}")
        lines.append(f"{gate_name}|1> = {gate @ one}")

    prepared = prepare_bell_with_h_and_cnot()
    phi_plus = bell_state("phi_plus")
    lines.append("\nBell-state preparation")
    lines.append(f"Prepared state from H+CNOT = {prepared}")
    lines.append(f"Target |Phi+>              = {phi_plus}")
    lines.append(f"Overlap                    = {np.vdot(phi_plus, prepared)}")

    counts_full = measure_full_state(prepared, shots=5000, seed=2026)
    counts_q0 = measure_qubit(prepared, qubit=0, shots=5000, seed=2027)
    counts_q1 = measure_qubit(prepared, qubit=1, shots=5000, seed=2028)
    lines.append("\nMeasurement results with 5000 shots")
    lines.append(f"Full bitstrings: {counts_full}")
    lines.append(f"Qubit 0: {counts_q0}; exact probabilities {marginal_probabilities_for_qubit(prepared, 0)}")
    lines.append(f"Qubit 1: {counts_q1}; exact probabilities {marginal_probabilities_for_qubit(prepared, 1)}")

    rho = density_matrix(prepared)
    rho_a = reduced_density_matrix(prepared, keep=[0])
    rho_b = reduced_density_matrix(prepared, keep=[1])
    lines.append("\nDensity matrices and entropy")
    lines.append(f"rho =\n{rho}")
    lines.append(f"rho_A =\n{rho_a}")
    lines.append(f"rho_B =\n{rho_b}")
    lines.append(f"S(rho_A) = {von_neumann_entropy(rho_a):.12f}")
    lines.append(f"S(rho_B) = {von_neumann_entropy(rho_b):.12f}")

    (DATA / "part_a_summary.txt").write_text("\n".join(lines), encoding="utf-8")


def run_parts_b_c() -> None:
    lambdas = np.linspace(0.0, 1.0, 101)
    exact_rows = []
    vqe_rows = []
    for lam in lambdas:
        H = one_qubit_hamiltonian(lam)
        evals, evecs = sorted_eigh(H)
        ground = evecs[:, 0]
        coeffs = one_qubit_pauli_coefficients(lam)
        exact_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E1_exact": evals[1],
                "ground_weight_0": abs(ground[0]) ** 2,
                "ground_weight_1": abs(ground[1]) ** 2,
                "c_I": coeffs["I"],
                "c_X": coeffs["X"],
                "c_Z": coeffs["Z"],
            }
        )
        vqe = vqe_one_qubit_ry(H)
        vqe_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E0_vqe": vqe.energy,
                "abs_error": abs(vqe.energy - evals[0]),
                "theta": vqe.parameters[0],
                "success": vqe.success,
            }
        )

    exact_df = pd.DataFrame(exact_rows)
    vqe_df = pd.DataFrame(vqe_rows)
    exact_df.to_csv(DATA / "part_b_one_qubit_exact.csv", index=False)
    vqe_df.to_csv(DATA / "part_c_one_qubit_vqe.csv", index=False)

    plt.figure()
    plt.plot(exact_df["lambda"], exact_df["E0_exact"], label="E0")
    plt.plot(exact_df["lambda"], exact_df["E1_exact"], label="E1")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.title("One-qubit Hamiltonian: exact eigenvalues")
    plt.legend()
    savefig("part_b_one_qubit_eigenvalues.png")

    plt.figure()
    plt.plot(exact_df["lambda"], exact_df["ground_weight_0"], label=r"$|\langle 0|\psi_0\rangle|^2$")
    plt.plot(exact_df["lambda"], exact_df["ground_weight_1"], label=r"$|\langle 1|\psi_0\rangle|^2$")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Weight")
    plt.title("One-qubit ground-state composition")
    plt.legend()
    savefig("part_b_one_qubit_weights.png")

    plt.figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
    plt.title("One-qubit VQE error")
    savefig("part_c_one_qubit_vqe_error.png")


def run_parts_d_e() -> None:
    lambdas = np.linspace(0.0, 1.0, 101)
    exact_rows = []
    vqe_rows = []
    for lam in lambdas:
        H = two_qubit_hamiltonian(lam)
        evals, evecs = sorted_eigh(H)
        ground = evecs[:, 0]
        rho_a = reduced_density_matrix(ground, keep=[0])
        entropy_a = von_neumann_entropy(rho_a)
        exact_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E1_exact": evals[1],
                "E2_exact": evals[2],
                "E3_exact": evals[3],
                "entropy_A_ground": entropy_a,
                "weight_00": abs(ground[0]) ** 2,
                "weight_01": abs(ground[1]) ** 2,
                "weight_10": abs(ground[2]) ** 2,
                "weight_11": abs(ground[3]) ** 2,
            }
        )
        best, even, odd = vqe_two_qubit_parity(H)
        vqe_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E0_vqe": best.energy,
                "E_even": even.energy,
                "E_odd": odd.energy,
                "abs_error": abs(best.energy - evals[0]),
                "best_sector": "even" if even.energy <= odd.energy else "odd",
            }
        )

    exact_df = pd.DataFrame(exact_rows)
    vqe_df = pd.DataFrame(vqe_rows)
    exact_df.to_csv(DATA / "part_d_two_qubit_exact_entropy.csv", index=False)
    vqe_df.to_csv(DATA / "part_e_two_qubit_vqe.csv", index=False)

    plt.figure()
    for col in ["E0_exact", "E1_exact", "E2_exact", "E3_exact"]:
        plt.plot(exact_df["lambda"], exact_df[col], label=col.replace("_exact", ""))
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.title("Two-qubit Hamiltonian: exact eigenvalues")
    plt.legend()
    savefig("part_d_two_qubit_eigenvalues.png")

    plt.figure()
    plt.plot(exact_df["lambda"], exact_df["entropy_A_ground"])
    plt.xlabel(r"$\lambda$")
    plt.ylabel(r"$S(\rho_A)$")
    plt.title("Two-qubit ground-state entanglement entropy")
    savefig("part_d_two_qubit_entropy.png")

    plt.figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
    plt.title("Two-qubit VQE error")
    savefig("part_e_two_qubit_vqe_error.png")


def run_parts_f_g() -> None:
    epsilon = 1.0
    W = 0.0
    V_values = np.linspace(0.0, 2.0, 31)

    j1_rows = []
    j2_rows = []
    vqe_j1_rows = []
    vqe_j2_rows = []

    previous_j1_params = None
    previous_j2_params = None
    for i, V in enumerate(V_values):
        H1 = lipkin_j1(epsilon=epsilon, V=V)
        H2 = lipkin_j2(epsilon=epsilon, V=V, W=W)
        e1, _ = sorted_eigh(H1)
        e2, _ = sorted_eigh(H2)
        j1_rows.append({"V": V, **{f"E{k}": value for k, value in enumerate(e1)}})
        j2_rows.append({"V": V, **{f"E{k}": value for k, value in enumerate(e2)}})

        # Embedded Hamiltonians for qubit/state-vector VQE.
        H1_pad = pad_to_power_of_two(H1)
        H2_pad = pad_to_power_of_two(H2)
        vqe1 = vqe_normalized_real(
            H1_pad,
            n_restarts=4,
            seed=1000 + i,
            initial_parameters=previous_j1_params,
        )
        vqe2 = vqe_normalized_real(
            H2_pad,
            n_restarts=5,
            seed=2000 + i,
            initial_parameters=previous_j2_params,
        )
        previous_j1_params = vqe1.parameters
        previous_j2_params = vqe2.parameters
        vqe_j1_rows.append(
            {
                "V": V,
                "E0_exact": e1[0],
                "E0_vqe": vqe1.energy,
                "abs_error": abs(vqe1.energy - e1[0]),
                "success": vqe1.success,
            }
        )
        vqe_j2_rows.append(
            {
                "V": V,
                "E0_exact": e2[0],
                "E0_vqe": vqe2.energy,
                "abs_error": abs(vqe2.energy - e2[0]),
                "success": vqe2.success,
            }
        )

    j1_df = pd.DataFrame(j1_rows)
    j2_df = pd.DataFrame(j2_rows)
    vqe_j1_df = pd.DataFrame(vqe_j1_rows)
    vqe_j2_df = pd.DataFrame(vqe_j2_rows)
    j1_df.to_csv(DATA / "part_f_lipkin_j1_exact.csv", index=False)
    j2_df.to_csv(DATA / "part_f_lipkin_j2_exact.csv", index=False)
    vqe_j1_df.to_csv(DATA / "part_g_lipkin_j1_vqe.csv", index=False)
    vqe_j2_df.to_csv(DATA / "part_g_lipkin_j2_vqe.csv", index=False)

    # Pauli decompositions at one representative interaction strength.
    sample_V = 0.5
    decompositions = []
    for name, H in [
        ("J=1, W=0, padded to 2 qubits", pad_to_power_of_two(lipkin_j1(epsilon, sample_V))),
        ("J=2, W=0, padded to 3 qubits", pad_to_power_of_two(lipkin_j2(epsilon, sample_V, W=0.0))),
        ("J=2, W=0.2, padded to 3 qubits", pad_to_power_of_two(lipkin_j2(epsilon, sample_V, W=0.2))),
    ]:
        coeffs = pauli_decomposition(H)
        decompositions.append(f"{name}\n{format_pauli_decomposition(coeffs)}\n")
    (DATA / "part_f_lipkin_pauli_decompositions.txt").write_text("\n".join(decompositions), encoding="utf-8")

    plt.figure()
    for col in [c for c in j1_df.columns if c.startswith("E")]:
        plt.plot(j1_df["V"], j1_df[col], label=col)
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=1$: exact eigenvalues")
    plt.legend()
    savefig("part_f_lipkin_j1_exact.png")

    plt.figure()
    for col in [c for c in j2_df.columns if c.startswith("E")]:
        plt.plot(j2_df["V"], j2_df[col], label=col)
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=2$: exact eigenvalues")
    plt.legend()
    savefig("part_f_lipkin_j2_exact.png")

    plt.figure()
    plt.semilogy(vqe_j1_df["V"], vqe_j1_df["abs_error"] + 1e-16, label="J=1")
    plt.semilogy(vqe_j2_df["V"], vqe_j2_df["abs_error"] + 1e-16, label="J=2")
    plt.xlabel(r"$V$")
    plt.ylabel("Absolute error")
    plt.title("Lipkin VQE ground-state error")
    plt.legend()
    savefig("part_g_lipkin_vqe_error.png")


def main() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    FIG.mkdir(parents=True, exist_ok=True)
    run_part_a()
    run_parts_b_c()
    run_parts_d_e()
    run_parts_f_g()
    print(f"Wrote data to {DATA}")
    print(f"Wrote figures to {FIG}")


if __name__ == "__main__":
    main()
EOF_scripts_run_all_py

backup_file src/fys5419_project1/__init__.py
mkdir -p src/fys5419_project1
cat > src/fys5419_project1/__init__.py <<'EOF_src_fys5419_project1___init___py'

EOF_src_fys5419_project1___init___py

backup_file src/fys5419_project1/hamiltonians.py
mkdir -p src/fys5419_project1
cat > src/fys5419_project1/hamiltonians.py <<'EOF_src_fys5419_project1_hamiltonians_py'
"""Hamiltonians and Pauli decompositions for FYS5419 Project 1."""

from __future__ import annotations

from itertools import product
from math import ceil, log2, sqrt

import numpy as np
from numpy.typing import NDArray

from .quantum import I2, PAULI_MATRICES, X, Z, kron_n

ComplexArray = NDArray[np.complex128]


def sorted_eigh(matrix: ComplexArray) -> tuple[np.ndarray, ComplexArray]:
    """Eigenvalues/eigenvectors sorted from lowest to highest eigenvalue."""
    evals, evecs = np.linalg.eigh(np.asarray(matrix, dtype=complex))
    order = np.argsort(np.real(evals))
    return np.real_if_close(evals[order]).astype(float), evecs[:, order]


def one_qubit_hamiltonian(
    lam: float,
    E1: float = 0.0,
    E2: float = 4.0,
    V11: float = 3.0,
    V22: float = -3.0,
    V12: float = 0.2,
) -> ComplexArray:
    """Part b/c Hamiltonian H = H0 + lambda HI in the |0>, |1> basis."""
    h0 = np.array([[E1, 0.0], [0.0, E2]], dtype=complex)
    hi = np.array([[V11, V12], [V12, V22]], dtype=complex)
    return h0 + lam * hi


def one_qubit_pauli_coefficients(
    lam: float,
    E1: float = 0.0,
    E2: float = 4.0,
    V11: float = 3.0,
    V22: float = -3.0,
    V12: float = 0.2,
) -> dict[str, float]:
    """Coefficients in H = a_I I + a_X X + a_Z Z for the one-qubit model."""
    energy_bar = 0.5 * (E1 + E2)
    omega = 0.5 * (E1 - E2)
    c = 0.5 * (V11 + V22)
    omega_z = 0.5 * (V11 - V22)
    omega_x = V12
    return {
        "I": float(energy_bar + lam * c),
        "X": float(lam * omega_x),
        "Y": 0.0,
        "Z": float(omega + lam * omega_z),
    }


def one_qubit_from_pauli(lam: float) -> ComplexArray:
    coeffs = one_qubit_pauli_coefficients(lam)
    return coeffs["I"] * I2 + coeffs["X"] * X + coeffs["Z"] * Z


def two_qubit_hamiltonian(
    lam: float,
    Hx: float = 2.0,
    Hz: float = 3.0,
    eps00: float = 0.0,
    eps10: float = 2.5,
    eps01: float = 6.5,
    eps11: float = 7.0,
) -> ComplexArray:
    """Part d/e two-qubit Hamiltonian in standard basis |00>, |01>, |10>, |11>.

    The project text lists the non-interacting energies as
    [epsilon00, epsilon10, epsilon01, epsilon11]. This function accepts them with
    those names but returns the matrix in the usual computational order
    |00>, |01>, |10>, |11>, which is convenient for state-vector simulation and
    partial traces.
    """
    h0 = np.diag([eps00, eps01, eps10, eps11]).astype(complex)
    hi = Hx * kron_n(X, X) + Hz * kron_n(Z, Z)
    return h0 + lam * hi


def lipkin_j1(epsilon: float = 1.0, V: float = 0.0) -> ComplexArray:
    """Lipkin Hamiltonian for J=1 and W=0 in the project basis."""
    return np.array(
        [[-epsilon, 0.0, -V], [0.0, 0.0, 0.0], [-V, 0.0, epsilon]],
        dtype=complex,
    )


def lipkin_j2(epsilon: float = 1.0, V: float = 0.0, W: float = 0.0) -> ComplexArray:
    """Lipkin Hamiltonian for J=2 from the project text.

    W defaults to zero, but the W term is included so the challenge part can also
    be explored.
    """
    root6 = sqrt(6.0)
    return np.array(
        [
            [-2.0 * epsilon, 0.0, root6 * V, 0.0, 0.0],
            [0.0, -epsilon + 3.0 * W, 0.0, 3.0 * V, 0.0],
            [root6 * V, 0.0, 4.0 * W, 0.0, root6 * V],
            [0.0, 3.0 * V, 0.0, epsilon + 3.0 * W, 0.0],
            [0.0, 0.0, root6 * V, 0.0, 2.0 * epsilon],
        ],
        dtype=complex,
    )


def next_power_of_two(n: int) -> int:
    if n < 1:
        raise ValueError("n must be positive")
    return 1 << ceil(log2(n))


def pad_to_power_of_two(matrix: ComplexArray, penalty: float | None = None) -> ComplexArray:
    """Embed a dxd Hamiltonian in the next 2^n-dimensional Hilbert space.

    Extra basis states are assigned a large positive diagonal penalty so VQE does
    not choose unphysical padded states as the ground state.
    """
    matrix = np.asarray(matrix, dtype=complex)
    d = matrix.shape[0]
    if matrix.shape != (d, d):
        raise ValueError("matrix must be square")
    target = next_power_of_two(d)
    if target == d:
        return matrix.copy()
    evals = np.linalg.eigvalsh(matrix)
    if penalty is None:
        penalty = float(np.max(np.real(evals)) + 10.0 + abs(np.min(np.real(evals))))
    padded = np.eye(target, dtype=complex) * penalty
    padded[:d, :d] = matrix
    return padded


def pauli_decomposition(
    matrix: ComplexArray, tol: float = 1e-10
) -> dict[str, complex]:
    """Return coefficients c_P in H = sum_P c_P P for a 2^n x 2^n matrix."""
    matrix = np.asarray(matrix, dtype=complex)
    dim = matrix.shape[0]
    if matrix.shape != (dim, dim):
        raise ValueError("matrix must be square")
    n_float = log2(dim)
    if abs(n_float - round(n_float)) > 1e-12:
        raise ValueError("matrix dimension must be a power of two")
    n_qubits = int(round(n_float))
    coeffs: dict[str, complex] = {}
    for label_tuple in product("IXYZ", repeat=n_qubits):
        label = "".join(label_tuple)
        pauli = kron_n(*(PAULI_MATRICES[ch] for ch in label))
        coeff = np.trace(pauli.conj().T @ matrix) / dim
        if abs(coeff) > tol:
            coeffs[label] = complex(np.real_if_close(coeff))
    return coeffs


def format_pauli_decomposition(coeffs: dict[str, complex], precision: int = 8) -> str:
    """Human-readable Pauli decomposition."""
    parts: list[str] = []
    for label in sorted(coeffs):
        coeff = coeffs[label]
        if abs(coeff.imag) < 10 ** (-(precision - 2)):
            value = f"{coeff.real:.{precision}g}"
        else:
            value = f"({coeff.real:.{precision}g}{coeff.imag:+.{precision}g}j)"
        parts.append(f"{value} {label}")
    return " + ".join(parts) if parts else "0"
EOF_src_fys5419_project1_hamiltonians_py

backup_file src/fys5419_project1/quantum.py
mkdir -p src/fys5419_project1
cat > src/fys5419_project1/quantum.py <<'EOF_src_fys5419_project1_quantum_py'
"""Small state-vector quantum utilities for FYS5419 Project 1.

Conventions
-----------
Qubit 0 is the leftmost / most significant qubit. For two qubits the basis order is
|00>, |01>, |10>, |11>.
"""

from __future__ import annotations

from collections import Counter
from typing import Iterable

import numpy as np
from numpy.typing import NDArray

ComplexArray = NDArray[np.complex128]
RealArray = NDArray[np.float64]

I2: ComplexArray = np.array([[1, 0], [0, 1]], dtype=complex)
X: ComplexArray = np.array([[0, 1], [1, 0]], dtype=complex)
Y: ComplexArray = np.array([[0, -1j], [1j, 0]], dtype=complex)
Z: ComplexArray = np.array([[1, 0], [0, -1]], dtype=complex)
HADAMARD: ComplexArray = (1.0 / np.sqrt(2.0)) * np.array([[1, 1], [1, -1]], dtype=complex)
PHASE_S: ComplexArray = np.array([[1, 0], [0, 1j]], dtype=complex)

PAULI_MATRICES: dict[str, ComplexArray] = {
    "I": I2,
    "X": X,
    "Y": Y,
    "Z": Z,
}


def ket0() -> ComplexArray:
    return np.array([1, 0], dtype=complex)


def ket1() -> ComplexArray:
    return np.array([0, 1], dtype=complex)


def one_qubit_basis() -> tuple[ComplexArray, ComplexArray]:
    return ket0(), ket1()


def basis_state(bitstring: str) -> ComplexArray:
    """Return computational basis vector for a bitstring such as '010'."""
    if any(bit not in "01" for bit in bitstring):
        raise ValueError("bitstring must contain only 0 and 1")
    index = int(bitstring, 2) if bitstring else 0
    state = np.zeros(2 ** len(bitstring), dtype=complex)
    state[index] = 1.0
    return state


def kron_n(*operators: ComplexArray) -> ComplexArray:
    """Kronecker product of all input arrays."""
    if not operators:
        raise ValueError("at least one operator is required")
    out = np.asarray(operators[0], dtype=complex)
    for op in operators[1:]:
        out = np.kron(out, np.asarray(op, dtype=complex))
    return out


def normalize(state: ComplexArray) -> ComplexArray:
    norm = np.linalg.norm(state)
    if norm == 0:
        raise ValueError("cannot normalize the zero vector")
    return np.asarray(state, dtype=complex) / norm


def density_matrix(state: ComplexArray) -> ComplexArray:
    state = normalize(state).reshape(-1)
    return np.outer(state, state.conj())


def apply_single_qubit_gate(
    state: ComplexArray, gate: ComplexArray, qubit: int, n_qubits: int
) -> ComplexArray:
    """Apply a one-qubit gate to a state vector.

    Qubit 0 is the leftmost qubit. For example, in a two-qubit state, qubit 0 acts
    on the first bit in |q0 q1>.
    """
    if not 0 <= qubit < n_qubits:
        raise ValueError("qubit index out of range")
    ops = [I2] * n_qubits
    ops[qubit] = np.asarray(gate, dtype=complex)
    return kron_n(*ops) @ np.asarray(state, dtype=complex)


def cnot_matrix(control: int, target: int, n_qubits: int) -> ComplexArray:
    """Return the CNOT matrix with the given control and target qubits."""
    if control == target:
        raise ValueError("control and target must be different")
    if not 0 <= control < n_qubits or not 0 <= target < n_qubits:
        raise ValueError("qubit index out of range")

    dim = 2**n_qubits
    matrix = np.zeros((dim, dim), dtype=complex)
    for integer in range(dim):
        bits = list(format(integer, f"0{n_qubits}b"))
        if bits[control] == "1":
            bits[target] = "0" if bits[target] == "1" else "1"
        new_integer = int("".join(bits), 2)
        matrix[new_integer, integer] = 1.0
    return matrix


def bell_state(label: str = "phi_plus") -> ComplexArray:
    """Return one of the four Bell states in basis |00>, |01>, |10>, |11>."""
    label = label.lower()
    states = {
        "phi_plus": basis_state("00") + basis_state("11"),
        "phi_minus": basis_state("00") - basis_state("11"),
        "psi_plus": basis_state("01") + basis_state("10"),
        "psi_minus": basis_state("01") - basis_state("10"),
    }
    if label not in states:
        raise ValueError(f"unknown Bell state {label!r}")
    return normalize(states[label])


def prepare_bell_with_h_and_cnot() -> ComplexArray:
    """Prepare |Phi+> from |00> using H on qubit 0 followed by CNOT 0->1."""
    state = basis_state("00")
    state = apply_single_qubit_gate(state, HADAMARD, qubit=0, n_qubits=2)
    state = cnot_matrix(control=0, target=1, n_qubits=2) @ state
    return normalize(state)


def bit_probabilities(state: ComplexArray) -> RealArray:
    state = normalize(np.asarray(state, dtype=complex))
    return np.abs(state) ** 2


def measure_full_state(
    state: ComplexArray, shots: int = 1024, seed: int | None = None
) -> dict[str, int]:
    """Sample complete computational-basis bitstrings from a state vector."""
    state = normalize(state)
    n_qubits = int(np.log2(state.size))
    if 2**n_qubits != state.size:
        raise ValueError("state length must be a power of two")
    labels = [format(i, f"0{n_qubits}b") for i in range(state.size)]
    rng = np.random.default_rng(seed)
    draws = rng.choice(labels, size=shots, p=bit_probabilities(state))
    return dict(Counter(draws))


def marginal_probabilities_for_qubit(state: ComplexArray, qubit: int) -> dict[str, float]:
    """Exact marginal probabilities for measuring a selected qubit."""
    state = normalize(state)
    n_qubits = int(np.log2(state.size))
    if not 0 <= qubit < n_qubits:
        raise ValueError("qubit index out of range")
    probs = {"0": 0.0, "1": 0.0}
    for integer, probability in enumerate(bit_probabilities(state)):
        bit = format(integer, f"0{n_qubits}b")[qubit]
        probs[bit] += float(probability)
    return probs


def measure_qubit(
    state: ComplexArray, qubit: int, shots: int = 1024, seed: int | None = None
) -> dict[str, int]:
    """Sample measurements of a selected qubit without state collapse between shots."""
    probabilities = marginal_probabilities_for_qubit(state, qubit)
    rng = np.random.default_rng(seed)
    labels = np.array(["0", "1"])
    p = np.array([probabilities["0"], probabilities["1"]])
    draws = rng.choice(labels, size=shots, p=p)
    return dict(Counter(draws))


def partial_trace(
    rho: ComplexArray, dims: Iterable[int], keep: Iterable[int]
) -> ComplexArray:
    """Trace out all subsystems except those listed in keep.

    Parameters
    ----------
    rho:
        Density matrix of the full system.
    dims:
        Dimensions of subsystems, e.g. [2, 2] for two qubits.
    keep:
        Indices of subsystems to keep. With two qubits, keep=[0] returns rho_A.
    """
    dims = list(dims)
    keep = list(keep)
    n = len(dims)
    if sorted(keep) != keep:
        raise ValueError("keep must be sorted")
    if any(k < 0 or k >= n for k in keep):
        raise ValueError("subsystem index out of range")

    trace_over = [i for i in range(n) if i not in keep]
    reshaped = np.asarray(rho, dtype=complex).reshape(dims + dims)

    # Trace from high subsystem index to low so axis numbers remain valid.
    current_dims = list(dims)
    current_n = n
    for subsystem in sorted(trace_over, reverse=True):
        reshaped = np.trace(reshaped, axis1=subsystem, axis2=subsystem + current_n)
        current_dims.pop(subsystem)
        current_n -= 1

    kept_dims = [dims[i] for i in keep]
    final_dim = int(np.prod(kept_dims))
    return reshaped.reshape((final_dim, final_dim))


def reduced_density_matrix(
    state: ComplexArray, keep: Iterable[int], dims: Iterable[int] | None = None
) -> ComplexArray:
    state = normalize(state)
    if dims is None:
        n_qubits = int(np.log2(state.size))
        dims = [2] * n_qubits
    return partial_trace(density_matrix(state), dims=dims, keep=keep)


def von_neumann_entropy(rho: ComplexArray, base: float = 2.0, tol: float = 1e-12) -> float:
    """Compute S(rho) = -Tr rho log_base(rho)."""
    eigenvalues = np.linalg.eigvalsh(np.asarray(rho, dtype=complex))
    eigenvalues = np.real_if_close(eigenvalues).astype(float)
    eigenvalues = eigenvalues[eigenvalues > tol]
    if eigenvalues.size == 0:
        return 0.0
    return float(-np.sum(eigenvalues * np.log(eigenvalues) / np.log(base)))


def ry(theta: float) -> ComplexArray:
    c = np.cos(theta / 2.0)
    s = np.sin(theta / 2.0)
    return np.array([[c, -s], [s, c]], dtype=complex)


def rz(theta: float) -> ComplexArray:
    return np.array(
        [[np.exp(-0.5j * theta), 0], [0, np.exp(0.5j * theta)]], dtype=complex
    )
EOF_src_fys5419_project1_quantum_py

backup_file src/fys5419_project1/vqe.py
mkdir -p src/fys5419_project1
cat > src/fys5419_project1/vqe.py <<'EOF_src_fys5419_project1_vqe_py'
"""Minimal VQE tools written from scratch for the project.

The module has two kinds of variational states:

1. Small circuit-inspired ansatz states for one- and two-qubit Hamiltonians.
2. A normalized real-amplitude ansatz for arbitrary real symmetric Hamiltonians.

The second ansatz is useful for the embedded Lipkin Hamiltonians because it spans
the full real Hilbert space and therefore gives a clean VQE-vs-exact comparison.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

import numpy as np
from numpy.typing import NDArray
from scipy.optimize import minimize, minimize_scalar

from .quantum import basis_state, cnot_matrix, apply_single_qubit_gate, ry

ComplexArray = NDArray[np.complex128]
RealArray = NDArray[np.float64]


@dataclass(frozen=True)
class VQEResult:
    energy: float
    parameters: RealArray
    state: ComplexArray
    success: bool
    n_iterations: int
    message: str


def expectation_value(state: ComplexArray, hamiltonian: ComplexArray) -> float:
    state = np.asarray(state, dtype=complex).reshape(-1)
    norm = np.vdot(state, state)
    if abs(norm) == 0:
        raise ValueError("zero state has no expectation value")
    energy = np.vdot(state, np.asarray(hamiltonian, dtype=complex) @ state) / norm
    return float(np.real_if_close(energy))


def one_qubit_ry_state(theta: float) -> ComplexArray:
    """Circuit: R_y(theta)|0>."""
    return np.array([np.cos(theta / 2.0), np.sin(theta / 2.0)], dtype=complex)


def vqe_one_qubit_ry(hamiltonian: ComplexArray) -> VQEResult:
    """Exact one-parameter VQE for a real one-qubit Hamiltonian."""

    def objective(theta: float) -> float:
        return expectation_value(one_qubit_ry_state(theta), hamiltonian)

    opt = minimize_scalar(objective, bounds=(-2.0 * np.pi, 2.0 * np.pi), method="bounded")
    theta = float(opt.x)
    state = one_qubit_ry_state(theta)
    return VQEResult(
        energy=float(opt.fun),
        parameters=np.array([theta], dtype=float),
        state=state,
        success=bool(opt.success),
        n_iterations=int(getattr(opt, "nit", 0)),
        message=str(opt.message),
    )


def two_qubit_even_state(theta: float) -> ComplexArray:
    """Circuit: R_y(theta) on q0, then CNOT(0,1), starting from |00>.

    Produces cos(theta/2)|00> + sin(theta/2)|11>.
    """
    state = basis_state("00")
    state = apply_single_qubit_gate(state, ry(theta), qubit=0, n_qubits=2)
    state = cnot_matrix(0, 1, 2) @ state
    return state


def two_qubit_odd_state(theta: float) -> ComplexArray:
    """Circuit: start |01>, R_y(theta) on q0, CNOT(0,1).

    Produces cos(theta/2)|01> + sin(theta/2)|10>.
    """
    state = basis_state("01")
    state = apply_single_qubit_gate(state, ry(theta), qubit=0, n_qubits=2)
    state = cnot_matrix(0, 1, 2) @ state
    return state


def vqe_two_qubit_parity(hamiltonian: ComplexArray) -> tuple[VQEResult, VQEResult, VQEResult]:
    """Run one-parameter VQE in the even and odd parity sectors.

    The two-qubit Hamiltonian in this project has two uncoupled 2x2 blocks, so the
    lower of these two sector optimizations is the full ground state.
    """

    def optimize(ansatz: Callable[[float], ComplexArray]) -> VQEResult:
        def objective(theta: float) -> float:
            return expectation_value(ansatz(theta), hamiltonian)

        opt = minimize_scalar(objective, bounds=(-2.0 * np.pi, 2.0 * np.pi), method="bounded")
        theta = float(opt.x)
        state = ansatz(theta)
        return VQEResult(
            energy=float(opt.fun),
            parameters=np.array([theta], dtype=float),
            state=state,
            success=bool(opt.success),
            n_iterations=int(getattr(opt, "nit", 0)),
            message=str(opt.message),
        )

    even = optimize(two_qubit_even_state)
    odd = optimize(two_qubit_odd_state)
    best = even if even.energy <= odd.energy else odd
    return best, even, odd


def normalized_real_state(parameters: RealArray) -> ComplexArray:
    """Full real-amplitude variational ansatz: |psi(a)> = a / ||a||."""
    vec = np.asarray(parameters, dtype=float).reshape(-1)
    norm = np.linalg.norm(vec)
    if norm < 1e-14:
        # Avoid division by zero during optimizer trial steps.
        vec = np.ones_like(vec)
        norm = np.linalg.norm(vec)
    return (vec / norm).astype(complex)


def vqe_normalized_real(
    hamiltonian: ComplexArray,
    n_restarts: int = 12,
    seed: int = 1234,
    initial_parameters: RealArray | None = None,
    maxiter: int = 2000,
) -> VQEResult:
    """VQE with a normalized real-amplitude ansatz.

    This spans every real state in the Hilbert space. Since all Hamiltonians in the
    project are real symmetric, this ansatz is sufficient for the exact ground
    state. The optimizer still finds the state variationally by minimizing the
    Rayleigh quotient.
    """
    hamiltonian = np.asarray(hamiltonian, dtype=complex)
    dim = hamiltonian.shape[0]
    rng = np.random.default_rng(seed)

    h_real = np.real_if_close(hamiltonian).astype(float)

    def objective(params: RealArray) -> float:
        x = np.asarray(params, dtype=float)
        denom = float(np.dot(x, x))
        if denom < 1e-28:
            return float("inf")
        return float(np.dot(x, h_real @ x) / denom)

    def gradient(params: RealArray) -> RealArray:
        x = np.asarray(params, dtype=float)
        denom = float(np.dot(x, x))
        if denom < 1e-28:
            return np.zeros_like(x)
        hx = h_real @ x
        energy = float(np.dot(x, hx) / denom)
        return 2.0 * (hx - energy * x) / denom

    starts: list[RealArray] = []
    if initial_parameters is not None:
        starts.append(np.asarray(initial_parameters, dtype=float))
    starts.append(np.ones(dim, dtype=float))
    for _ in range(max(0, n_restarts - len(starts))):
        starts.append(rng.normal(size=dim))

    best = None
    for x0 in starts:
        opt = minimize(
            objective,
            x0=x0,
            jac=gradient,
            method="BFGS",
            options={"gtol": 1e-10, "maxiter": maxiter},
        )
        if best is None or float(opt.fun) < float(best.fun):
            best = opt

    assert best is not None
    state = normalized_real_state(best.x)
    return VQEResult(
        energy=float(best.fun),
        parameters=np.asarray(best.x, dtype=float),
        state=state,
        success=bool(best.success),
        n_iterations=int(getattr(best, "nit", 0)),
        message=str(best.message),
    )


def hardware_efficient_state(
    parameters: RealArray, n_qubits: int, layers: int = 1
) -> ComplexArray:
    """Simple real-amplitude circuit ansatz using R_y rotations and a CNOT chain.

    This function is included to document a circuit style ansatz. It starts in
    |00...0>. Each layer applies R_y to all qubits followed by nearest-neighbour
    CNOTs 0->1->2... . A final set of R_y gates is then applied.
    """
    expected = (layers + 1) * n_qubits
    parameters = np.asarray(parameters, dtype=float)
    if parameters.size != expected:
        raise ValueError(f"expected {expected} parameters, got {parameters.size}")

    state = basis_state("0" * n_qubits)
    index = 0
    for _layer in range(layers):
        for q in range(n_qubits):
            state = apply_single_qubit_gate(state, ry(parameters[index]), q, n_qubits)
            index += 1
        for q in range(n_qubits - 1):
            state = cnot_matrix(q, q + 1, n_qubits) @ state
    for q in range(n_qubits):
        state = apply_single_qubit_gate(state, ry(parameters[index]), q, n_qubits)
        index += 1
    return state
EOF_src_fys5419_project1_vqe_py

backup_file src/fys5419_project1.egg-info/PKG-INFO
mkdir -p src/fys5419_project1.egg-info
cat > src/fys5419_project1.egg-info/PKG-INFO <<'EOF_src_fys5419_project1_egg_info_PKG_INFO'
Metadata-Version: 2.4
Name: fys5419-project1
Version: 0.1.0
Summary: Code for FYS5419 Project 1: VQE and Lipkin model
Requires-Python: >=3.10
Description-Content-Type: text/markdown
Requires-Dist: numpy>=1.24
Requires-Dist: scipy>=1.10
Requires-Dist: matplotlib>=3.7
Requires-Dist: pandas>=2.0
Provides-Extra: dev
Requires-Dist: pytest>=7.0; extra == "dev"
Requires-Dist: jupyterlab>=4.0; extra == "dev"

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
EOF_src_fys5419_project1_egg_info_PKG_INFO

backup_file src/fys5419_project1.egg-info/SOURCES.txt
mkdir -p src/fys5419_project1.egg-info
cat > src/fys5419_project1.egg-info/SOURCES.txt <<'EOF_src_fys5419_project1_egg_info_SOURCES_txt'
README.md
pyproject.toml
src/fys5419_project1/__init__.py
src/fys5419_project1/hamiltonians.py
src/fys5419_project1/quantum.py
src/fys5419_project1/vqe.py
src/fys5419_project1.egg-info/PKG-INFO
src/fys5419_project1.egg-info/SOURCES.txt
src/fys5419_project1.egg-info/dependency_links.txt
src/fys5419_project1.egg-info/requires.txt
src/fys5419_project1.egg-info/top_level.txt
tests/test_hamiltonians_vqe.py
tests/test_quantum.py
EOF_src_fys5419_project1_egg_info_SOURCES_txt

backup_file src/fys5419_project1.egg-info/dependency_links.txt
mkdir -p src/fys5419_project1.egg-info
cat > src/fys5419_project1.egg-info/dependency_links.txt <<'EOF_src_fys5419_project1_egg_info_dependency_links_txt'

EOF_src_fys5419_project1_egg_info_dependency_links_txt

backup_file src/fys5419_project1.egg-info/requires.txt
mkdir -p src/fys5419_project1.egg-info
cat > src/fys5419_project1.egg-info/requires.txt <<'EOF_src_fys5419_project1_egg_info_requires_txt'
numpy>=1.24
scipy>=1.10
matplotlib>=3.7
pandas>=2.0

[dev]
pytest>=7.0
jupyterlab>=4.0
EOF_src_fys5419_project1_egg_info_requires_txt

backup_file src/fys5419_project1.egg-info/top_level.txt
mkdir -p src/fys5419_project1.egg-info
cat > src/fys5419_project1.egg-info/top_level.txt <<'EOF_src_fys5419_project1_egg_info_top_level_txt'
fys5419_project1
EOF_src_fys5419_project1_egg_info_top_level_txt

backup_file tests/test_hamiltonians_vqe.py
mkdir -p tests
cat > tests/test_hamiltonians_vqe.py <<'EOF_tests_test_hamiltonians_vqe_py'
import numpy as np

from fys5419_project1.hamiltonians import (
    lipkin_j1,
    one_qubit_from_pauli,
    one_qubit_hamiltonian,
    pad_to_power_of_two,
    sorted_eigh,
    two_qubit_hamiltonian,
)
from fys5419_project1.vqe import vqe_normalized_real, vqe_one_qubit_ry, vqe_two_qubit_parity


def test_one_qubit_pauli_form_matches_matrix():
    for lam in [0.0, 0.25, 0.7, 1.0]:
        assert np.allclose(one_qubit_hamiltonian(lam), one_qubit_from_pauli(lam))


def test_one_qubit_vqe_matches_exact_ground_state():
    for lam in [0.0, 0.5, 1.0]:
        H = one_qubit_hamiltonian(lam)
        evals, _ = sorted_eigh(H)
        vqe = vqe_one_qubit_ry(H)
        assert abs(vqe.energy - evals[0]) < 1e-8


def test_two_qubit_vqe_matches_exact_ground_state():
    for lam in [0.0, 0.25, 0.75, 1.0]:
        H = two_qubit_hamiltonian(lam)
        evals, _ = sorted_eigh(H)
        best, even, odd = vqe_two_qubit_parity(H)
        assert abs(best.energy - evals[0]) < 1e-8
        assert min(even.energy, odd.energy) == best.energy


def test_lipkin_normalized_vqe_matches_exact_ground_state():
    H = pad_to_power_of_two(lipkin_j1(epsilon=1.0, V=0.7))
    evals, _ = sorted_eigh(H)
    vqe = vqe_normalized_real(H, n_restarts=5, seed=99)
    assert abs(vqe.energy - evals[0]) < 1e-7
EOF_tests_test_hamiltonians_vqe_py

backup_file tests/test_quantum.py
mkdir -p tests
cat > tests/test_quantum.py <<'EOF_tests_test_quantum_py'
import numpy as np

from fys5419_project1.quantum import (
    HADAMARD,
    X,
    bell_state,
    ket0,
    ket1,
    prepare_bell_with_h_and_cnot,
    reduced_density_matrix,
    von_neumann_entropy,
)


def test_pauli_x_flips_basis_states():
    assert np.allclose(X @ ket0(), ket1())
    assert np.allclose(X @ ket1(), ket0())


def test_hadamard_normalized_actions():
    plus = HADAMARD @ ket0()
    minus = HADAMARD @ ket1()
    assert np.allclose(np.linalg.norm(plus), 1.0)
    assert np.allclose(np.linalg.norm(minus), 1.0)
    assert np.allclose(np.vdot(plus, minus), 0.0)


def test_bell_preparation_and_entropy():
    psi = prepare_bell_with_h_and_cnot()
    assert np.allclose(psi, bell_state("phi_plus"))
    rho_a = reduced_density_matrix(psi, keep=[0])
    assert np.allclose(rho_a, 0.5 * np.eye(2))
    assert np.isclose(von_neumann_entropy(rho_a), 1.0)
EOF_tests_test_quantum_py

rmdir "$backup_dir" 2>/dev/null || true
echo "Done. Files written. Existing overwritten files, if any, were copied to $backup_dir."
echo "Next commands:"
echo "  python3 -m venv .venv"
echo "  source .venv/bin/activate"
echo "  python -m pip install --upgrade pip"
echo "  pip install -e \".[dev]\""
echo "  pytest"
echo "  python scripts/run_all.py"
git status || true
