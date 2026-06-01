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
    padding_projector,
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
    format_state_vector,
    ket0,
    ket1,
    marginal_probabilities_for_qubit,
    measure_full_state,
    measure_qubit,
    measurement_average_from_counts,
    prepare_bell_with_h_and_cnot,
    reduced_density_matrix,
    von_neumann_entropy,
)
from fys5419_project1.vqe import (
    vqe_normalized_real,
    vqe_one_qubit_ry,
    vqe_orthogonal_real_spectrum,
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


def _format_count_dict(counts: dict[str, int]) -> str:
    return "{" + ", ".join(f"'{key}': {value}" for key, value in sorted(counts.items())) + "}"


def _stringify_coeff(value: complex, tol: float = 1e-12) -> str:
    value = complex(value)
    if abs(value.imag) < tol:
        return f"{value.real:.12g}"
    return f"{value.real:.12g}{value.imag:+.12g}j"


def _linear_expression(coeffs: dict[str, complex], symbols: dict[str, str], tol: float = 1e-12) -> str:
    parts: list[str] = []
    for key, symbol in symbols.items():
        coeff = complex(coeffs.get(key, 0.0))
        if abs(coeff) <= tol:
            continue
        value = coeff.real if abs(coeff.imag) <= tol else coeff
        if isinstance(value, complex):
            parts.append(f"({_stringify_coeff(value)}) {symbol}")
        else:
            if abs(value - 1.0) <= tol:
                parts.append(symbol)
            elif abs(value + 1.0) <= tol:
                parts.append(f"-{symbol}")
            else:
                parts.append(f"{value:.12g} {symbol}")
    return " + ".join(parts).replace("+ -", "- ") if parts else "0"


def run_part_a() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    zero, one = ket0(), ket1()
    gates = {"X": X, "Y": Y, "Z": Z, "H": HADAMARD, "S": PHASE_S}

    lines: list[str] = []
    lines.append("Part a: one-qubit gate actions")
    for gate_name, gate in gates.items():
        lines.append(f"{gate_name}|0> = {format_state_vector(gate @ zero)}")
        lines.append(f"{gate_name}|1> = {format_state_vector(gate @ one)}")

    prepared = prepare_bell_with_h_and_cnot()
    phi_plus = bell_state("phi_plus")
    overlap_probability = abs(np.vdot(phi_plus, prepared)) ** 2
    lines.append("\nBell-state preparation")
    lines.append(f"Prepared state from H+CNOT = {format_state_vector(prepared)}")
    lines.append(f"Target |Phi+>              = {format_state_vector(phi_plus)}")
    lines.append(f"Overlap probability        = {overlap_probability:.12f}")

    shots = 5000
    counts_full = measure_full_state(prepared, shots=shots, seed=2026)
    counts_q0 = measure_qubit(prepared, qubit=0, shots=shots, seed=2027)
    counts_q1 = measure_qubit(prepared, qubit=1, shots=shots, seed=2028)
    exact_q0 = marginal_probabilities_for_qubit(prepared, 0)
    exact_q1 = marginal_probabilities_for_qubit(prepared, 1)

    lines.append(f"\nMeasurement results with {shots} shots")
    lines.append(f"Full bitstrings: {_format_count_dict(counts_full)}")
    lines.append(
        f"Qubit 0: {_format_count_dict(counts_q0)}; "
        f"sample mean = {measurement_average_from_counts(counts_q0):.6f}; "
        f"exact probabilities = {exact_q0}"
    )
    lines.append(
        f"Qubit 1: {_format_count_dict(counts_q1)}; "
        f"sample mean = {measurement_average_from_counts(counts_q1):.6f}; "
        f"exact probabilities = {exact_q1}"
    )
    lines.append(
        f"Full-count means: <q0> = {measurement_average_from_counts(counts_full, qubit=0):.6f}, "
        f"<q1> = {measurement_average_from_counts(counts_full, qubit=1):.6f}"
    )

    measurement_rows = []
    for label, count in sorted(counts_full.items()):
        measurement_rows.append(
            {
                "basis_state": label,
                "counts": count,
                "frequency": count / shots,
                "exact_probability": float(abs(prepared[int(label, 2)]) ** 2),
            }
        )
    pd.DataFrame(measurement_rows).to_csv(DATA / "part_a_measurements.csv", index=False)

    rho = density_matrix(prepared)
    rho_a = reduced_density_matrix(prepared, keep=[0])
    rho_b = reduced_density_matrix(prepared, keep=[1])
    lines.append("\nDensity matrices and entropy")
    lines.append(f"rho =\n{np.array2string(rho, precision=6, suppress_small=True)}")
    lines.append(f"rho_A =\n{np.array2string(rho_a, precision=6, suppress_small=True)}")
    lines.append(f"rho_B =\n{np.array2string(rho_b, precision=6, suppress_small=True)}")
    lines.append(f"S(rho_A) = {von_neumann_entropy(rho_a):.12f}")
    lines.append(f"S(rho_B) = {von_neumann_entropy(rho_b):.12f}")

    (DATA / "part_a_summary.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


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


def _pauli_component_table(J: int) -> pd.DataFrame:
    """General Pauli coefficient table for embedded Lipkin Hamiltonians.

    The returned coefficients define
      c_P = c_epsilon*epsilon + c_V*V + c_W*W + c_padding*Delta.
    Delta is the fixed energy assigned to padded/unphysical basis states.
    """
    if J == 1:
        target_dim = 4
        components = {
            "epsilon": np.pad(lipkin_j1(epsilon=1.0, V=0.0), ((0, 1), (0, 1))),
            "V": np.pad(lipkin_j1(epsilon=0.0, V=1.0), ((0, 1), (0, 1))),
            "W": np.zeros((4, 4), dtype=complex),
            "padding": padding_projector(physical_dim=3, target_dim=4),
        }
    elif J == 2:
        target_dim = 8
        components = {
            "epsilon": np.pad(lipkin_j2(epsilon=1.0, V=0.0, W=0.0), ((0, 3), (0, 3))),
            "V": np.pad(lipkin_j2(epsilon=0.0, V=1.0, W=0.0), ((0, 3), (0, 3))),
            "W": np.pad(lipkin_j2(epsilon=0.0, V=0.0, W=1.0), ((0, 3), (0, 3))),
            "padding": padding_projector(physical_dim=5, target_dim=8),
        }
    else:
        raise ValueError("Only J=1 and J=2 are implemented")

    decomposed = {name: pauli_decomposition(matrix, tol=1e-12) for name, matrix in components.items()}
    labels = sorted(set().union(*(coeffs.keys() for coeffs in decomposed.values())))
    rows = []
    for label in labels:
        coeffs_for_label = {name: decomposed[name].get(label, 0.0) for name in components}
        if all(abs(value) < 1e-12 for value in coeffs_for_label.values()):
            continue
        row = {"pauli": label}
        row.update({f"c_{name}": float(np.real_if_close(value).real) for name, value in coeffs_for_label.items()})
        row["coefficient_expression"] = _linear_expression(
            coeffs_for_label,
            {"epsilon": "epsilon", "V": "V", "W": "W", "padding": "Delta"},
        )
        rows.append(row)
    return pd.DataFrame(rows)


def _write_pauli_tables() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    for J in (1, 2):
        table = _pauli_component_table(J)
        table.to_csv(DATA / f"part_f_lipkin_j{J}_pauli_symbolic.csv", index=False)

    lines = []
    for J in (1, 2):
        table = pd.read_csv(DATA / f"part_f_lipkin_j{J}_pauli_symbolic.csv")
        lines.append(f"J={J}: embedded Hamiltonian Pauli coefficients")
        lines.append("H = sum_P c_P P, c_P = c_epsilon*epsilon + c_V*V + c_W*W + c_padding*Delta")
        for _, row in table.iterrows():
            lines.append(f"{row['pauli']:>3s}: {row['coefficient_expression']}")
        lines.append("")
    (DATA / "part_f_lipkin_pauli_symbolic.txt").write_text("\n".join(lines), encoding="utf-8")

    # Keep a compact numerical example too, but label the padding energy explicitly.
    epsilon = 1.0
    sample_V = 0.5
    sample_W = 0.2
    padding_delta = 20.0
    numerical_examples = []
    examples = [
        ("J=1, W=0, Delta=20, padded to 2 qubits", np.pad(lipkin_j1(epsilon, sample_V), ((0, 1), (0, 1))) + padding_delta * padding_projector(3, 4)),
        ("J=2, W=0, Delta=20, padded to 3 qubits", np.pad(lipkin_j2(epsilon, sample_V, W=0.0), ((0, 3), (0, 3))) + padding_delta * padding_projector(5, 8)),
        ("J=2, W=0.2, Delta=20, padded to 3 qubits", np.pad(lipkin_j2(epsilon, sample_V, W=sample_W), ((0, 3), (0, 3))) + padding_delta * padding_projector(5, 8)),
    ]
    for name, H in examples:
        numerical_examples.append(f"{name}\n{format_pauli_decomposition(pauli_decomposition(H))}\n")
    (DATA / "part_f_lipkin_pauli_decompositions.txt").write_text("\n".join(numerical_examples), encoding="utf-8")


def _vqe_spectrum_dataframe(J: int, V_values: np.ndarray, epsilon: float, W: float) -> pd.DataFrame:
    rows = []
    physical_dim = 2 * J + 1
    for i, V in enumerate(V_values):
        H = lipkin_j1(epsilon=epsilon, V=V) if J == 1 else lipkin_j2(epsilon=epsilon, V=V, W=W)
        exact, _ = sorted_eigh(H)
        H_pad = pad_to_power_of_two(H)
        vqe_results = vqe_orthogonal_real_spectrum(
            H_pad,
            n_levels=physical_dim,
            n_restarts=18 if J == 1 else 24,
            seed=4000 + 100 * J + i,
        )
        row = {"J": J, "V": V}
        errors = []
        for level in range(physical_dim):
            error = abs(vqe_results[level].energy - exact[level])
            errors.append(error)
            row[f"exact_E{level}"] = exact[level]
            row[f"vqe_E{level}"] = vqe_results[level].energy
            row[f"abs_error_E{level}"] = error
            row[f"success_E{level}"] = vqe_results[level].success
            row[f"iterations_E{level}"] = vqe_results[level].n_iterations
        row["max_abs_error"] = max(errors)
        rows.append(row)
    return pd.DataFrame(rows)


def run_parts_f_g() -> None:
    epsilon = 1.0
    W = 0.0
    V_values = np.linspace(0.0, 2.0, 31)

    j1_rows = []
    j2_rows = []
    vqe_ground_j1_rows = []
    vqe_ground_j2_rows = []

    previous_j1_params = None
    previous_j2_params = None
    for i, V in enumerate(V_values):
        H1 = lipkin_j1(epsilon=epsilon, V=V)
        H2 = lipkin_j2(epsilon=epsilon, V=V, W=W)
        e1, _ = sorted_eigh(H1)
        e2, _ = sorted_eigh(H2)
        j1_rows.append({"V": V, **{f"E{k}": value for k, value in enumerate(e1)}})
        j2_rows.append({"V": V, **{f"E{k}": value for k, value in enumerate(e2)}})

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
        vqe_ground_j1_rows.append(
            {
                "V": V,
                "E0_exact": e1[0],
                "E0_vqe": vqe1.energy,
                "abs_error": abs(vqe1.energy - e1[0]),
                "success": vqe1.success,
            }
        )
        vqe_ground_j2_rows.append(
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
    vqe_ground_j1_df = pd.DataFrame(vqe_ground_j1_rows)
    vqe_ground_j2_df = pd.DataFrame(vqe_ground_j2_rows)
    j1_df.to_csv(DATA / "part_f_lipkin_j1_exact.csv", index=False)
    j2_df.to_csv(DATA / "part_f_lipkin_j2_exact.csv", index=False)
    vqe_ground_j1_df.to_csv(DATA / "part_g_lipkin_j1_vqe.csv", index=False)
    vqe_ground_j2_df.to_csv(DATA / "part_g_lipkin_j2_vqe.csv", index=False)

    # New for part g: VQE estimates for the same eigenvalues as in part f.
    vqe_spectrum_j1_df = _vqe_spectrum_dataframe(J=1, V_values=V_values, epsilon=epsilon, W=W)
    vqe_spectrum_j2_df = _vqe_spectrum_dataframe(J=2, V_values=V_values, epsilon=epsilon, W=W)
    vqe_spectrum_j1_df.to_csv(DATA / "part_g_lipkin_j1_vqe_spectrum.csv", index=False)
    vqe_spectrum_j2_df.to_csv(DATA / "part_g_lipkin_j2_vqe_spectrum.csv", index=False)

    _write_pauli_tables()

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
    for level in range(3):
        plt.plot(vqe_spectrum_j1_df["V"], vqe_spectrum_j1_df[f"exact_E{level}"], label=f"Exact E{level}")
        plt.scatter(vqe_spectrum_j1_df["V"], vqe_spectrum_j1_df[f"vqe_E{level}"], s=10, marker="x", label=f"VQE E{level}")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=1$: excited-state VQE spectrum")
    plt.legend(ncol=2, fontsize=8)
    savefig("part_g_lipkin_j1_vqe_spectrum.png")

    plt.figure()
    for level in range(5):
        plt.plot(vqe_spectrum_j2_df["V"], vqe_spectrum_j2_df[f"exact_E{level}"], label=f"Exact E{level}")
        plt.scatter(vqe_spectrum_j2_df["V"], vqe_spectrum_j2_df[f"vqe_E{level}"], s=10, marker="x", label=f"VQE E{level}")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=2$: excited-state VQE spectrum")
    plt.legend(ncol=2, fontsize=7)
    savefig("part_g_lipkin_j2_vqe_spectrum.png")

    plt.figure()
    plt.semilogy(vqe_spectrum_j1_df["V"], vqe_spectrum_j1_df["max_abs_error"] + 1e-16, label="J=1, all levels")
    plt.semilogy(vqe_spectrum_j2_df["V"], vqe_spectrum_j2_df["max_abs_error"] + 1e-16, label="J=2, all levels")
    plt.xlabel(r"$V$")
    plt.ylabel("Maximum absolute error")
    plt.title("Lipkin VQE spectrum error")
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
    print("New/updated important files:")
    print("  results/data/part_a_summary.txt")
    print("  results/data/part_f_lipkin_j1_pauli_symbolic.csv")
    print("  results/data/part_f_lipkin_j2_pauli_symbolic.csv")
    print("  results/data/part_g_lipkin_j1_vqe_spectrum.csv")
    print("  results/data/part_g_lipkin_j2_vqe_spectrum.csv")
    print("  results/figures/part_g_lipkin_j1_vqe_spectrum.png")
    print("  results/figures/part_g_lipkin_j2_vqe_spectrum.png")


if __name__ == "__main__":
    main()
