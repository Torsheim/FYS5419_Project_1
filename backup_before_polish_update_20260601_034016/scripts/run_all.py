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
