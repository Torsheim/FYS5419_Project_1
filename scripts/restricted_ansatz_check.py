"""Restricted-circuit check for the Lipkin J=2 ground state.

The full real-amplitude Lipkin VQE used in the report is an ideal
variational-state benchmark. This script compares it with restricted
hardware-inspired ansatz families for the J=2 ground state, illustrating how
ansatz expressivity changes the attainable error.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import minimize

from fys5419_project1.hamiltonians import lipkin_j2, pad_to_power_of_two, sorted_eigh
from fys5419_project1.vqe import expectation_value, hardware_efficient_state


def optimize_hardware_ansatz(
    hamiltonian: np.ndarray,
    n_qubits: int = 3,
    layers: int = 0,
    seed: int = 1234,
    n_restarts: int = 10,
) -> float:
    """Minimize the energy of ``hardware_efficient_state``."""
    n_parameters = (layers + 1) * n_qubits
    rng = np.random.default_rng(seed)

    def objective(parameters: np.ndarray) -> float:
        state = hardware_efficient_state(parameters, n_qubits=n_qubits, layers=layers)
        return expectation_value(state, hamiltonian)

    starts: list[np.ndarray] = [
        np.zeros(n_parameters),
        0.1 * np.ones(n_parameters),
        np.ones(n_parameters),
    ]
    starts.extend(rng.uniform(-np.pi, np.pi, size=n_parameters) for _ in range(n_restarts))

    best_energy = float("inf")
    for start in starts:
        opt = minimize(
            objective,
            x0=start,
            method="BFGS",
            options={"gtol": 1e-10, "maxiter": 2000},
        )
        best_energy = min(best_energy, float(opt.fun))
    return best_energy


def main() -> None:
    out_dir = Path("results/data")
    out_dir.mkdir(parents=True, exist_ok=True)

    rows: list[dict[str, float | int | str]] = []
    v_values = np.linspace(0.0, 2.0, 9)
    for layers, label in [
        (0, "Product Ry only"),
        (1, "One-layer Ry-CNOT-Ry"),
    ]:
        for index, v_strength in enumerate(v_values):
            hamiltonian = pad_to_power_of_two(lipkin_j2(epsilon=1.0, V=float(v_strength), W=0.0))
            exact = sorted_eigh(hamiltonian)[0][0]
            energy = optimize_hardware_ansatz(
                hamiltonian,
                n_qubits=3,
                layers=layers,
                seed=4321 + 17 * index + layers,
                n_restarts=8,
            )
            rows.append(
                {
                    "ansatz": label,
                    "layers": layers,
                    "V": float(v_strength),
                    "exact_E0": float(exact),
                    "vqe_E0": float(energy),
                    "abs_error": float(abs(energy - exact)),
                }
            )

    df = pd.DataFrame(rows)
    csv_path = out_dir / "part_g_lipkin_restricted_ansatz_check.csv"
    df.to_csv(csv_path, index=False)

    summary = df.groupby("ansatz", as_index=False)["abs_error"].max()
    summary_path = out_dir / "part_g_lipkin_restricted_ansatz_summary.csv"
    summary.to_csv(summary_path, index=False)

    print(f"Wrote {csv_path}")
    print(f"Wrote {summary_path}")
    print(summary.to_string(index=False))


if __name__ == "__main__":
    main()
