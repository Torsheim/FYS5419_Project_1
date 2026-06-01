#!/usr/bin/env bash
set -euo pipefail

if [ ! -d "scripts" ]; then
  echo "Error: run this from the repository root, e.g. ~/projects/FYS5419_Project_1" >&2
  exit 1
fi

BACKUP="backup_before_plot_style_update_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP/scripts" "$BACKUP/report"

[ -f scripts/run_all.py ] && cp scripts/run_all.py "$BACKUP/scripts/run_all.py"
[ -f scripts/make_report_figures.py ] && cp scripts/make_report_figures.py "$BACKUP/scripts/make_report_figures.py"
[ -f report/project1_report.tex ] && cp report/project1_report.tex "$BACKUP/report/project1_report.tex"

mkdir -p scripts report

cat > scripts/run_all.py <<'PY_RUN_ALL'
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
from matplotlib.lines import Line2D
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

# The report is a 10 pt A4 two-column article with left/right margins of
# 1.65 cm and a column separation of 0.65 cm. This gives one column width
# (21.0 - 2*1.65 - 0.65)/2 = 8.525 cm = 3.356 inches.
# Figures are created at this physical width. When they are included with
# width=\linewidth in a report column, no rescaling is needed and the 10 pt
# matplotlib text matches the report text size.
REPORT_FONT_SIZE_PT = 10
REPORT_COLUMN_WIDTH_IN = 8.525 / 2.54
REPORT_FIGURE_HEIGHT_IN = 2.40
REPORT_TALL_FIGURE_HEIGHT_IN = 2.75
REPORT_VERY_TALL_FIGURE_HEIGHT_IN = 3.05


def configure_matplotlib_for_report() -> None:
    """Set a compact one-column plotting style for the two-column report."""
    plt.rcParams.update(
        {
            "font.size": REPORT_FONT_SIZE_PT,
            "axes.labelsize": REPORT_FONT_SIZE_PT,
            "axes.titlesize": REPORT_FONT_SIZE_PT,
            "xtick.labelsize": REPORT_FONT_SIZE_PT,
            "ytick.labelsize": REPORT_FONT_SIZE_PT,
            "legend.fontsize": REPORT_FONT_SIZE_PT,
            "figure.titlesize": REPORT_FONT_SIZE_PT,
            "font.family": "serif",
            "font.serif": ["Computer Modern Roman", "Latin Modern Roman", "DejaVu Serif"],
            "mathtext.fontset": "cm",
            "axes.grid": False,
            "figure.constrained_layout.use": True,
            "savefig.dpi": 300,
        }
    )


configure_matplotlib_for_report()


def new_figure(height: float = REPORT_FIGURE_HEIGHT_IN) -> plt.Figure:
    """Create a single standalone figure sized for one report column."""
    FIG.mkdir(parents=True, exist_ok=True)
    return plt.figure(figsize=(REPORT_COLUMN_WIDTH_IN, height), constrained_layout=True)


def savefig(name: str) -> None:
    """Save each plot as its own PDF and PNG file.

    The PDF is preferred in LaTeX because it is vector graphics. The PNG is
    kept for quick preview in the file browser.
    """
    FIG.mkdir(parents=True, exist_ok=True)
    stem = Path(name).stem
    fig = plt.gcf()
    fig.savefig(FIG / f"{stem}.pdf")
    fig.savefig(FIG / f"{stem}.png", dpi=300)
    plt.close(fig)


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

    new_figure()
    plt.plot(exact_df["lambda"], exact_df["E0_exact"], label="E0")
    plt.plot(exact_df["lambda"], exact_df["E1_exact"], label="E1")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.legend()
    savefig("part_b_one_qubit_eigenvalues.png")

    new_figure()
    plt.plot(exact_df["lambda"], exact_df["ground_weight_0"], label=r"$|\langle 0|\psi_0\rangle|^2$")
    plt.plot(exact_df["lambda"], exact_df["ground_weight_1"], label=r"$|\langle 1|\psi_0\rangle|^2$")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Weight")
    plt.legend()
    savefig("part_b_one_qubit_weights.png")

    new_figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
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

    new_figure(height=REPORT_TALL_FIGURE_HEIGHT_IN)
    for col in ["E0_exact", "E1_exact", "E2_exact", "E3_exact"]:
        plt.plot(exact_df["lambda"], exact_df[col], label=col.replace("_exact", ""))
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.legend()
    savefig("part_d_two_qubit_eigenvalues.png")

    new_figure()
    plt.plot(exact_df["lambda"], exact_df["entropy_A_ground"])
    plt.xlabel(r"$\lambda$")
    plt.ylabel(r"$S(\rho_A)$")
    savefig("part_d_two_qubit_entropy.png")

    new_figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
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

    new_figure()
    for col in [c for c in j1_df.columns if c.startswith("E")]:
        plt.plot(j1_df["V"], j1_df[col], label=col)
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.legend()
    savefig("part_f_lipkin_j1_exact.png")

    new_figure(height=REPORT_TALL_FIGURE_HEIGHT_IN)
    for col in [c for c in j2_df.columns if c.startswith("E")]:
        plt.plot(j2_df["V"], j2_df[col], label=col)
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.legend()
    savefig("part_f_lipkin_j2_exact.png")

    new_figure(height=REPORT_TALL_FIGURE_HEIGHT_IN)
    for level in range(3):
        line, = plt.plot(
            vqe_spectrum_j1_df["V"],
            vqe_spectrum_j1_df[f"exact_E{level}"],
            label=f"E{level}",
        )
        plt.scatter(
            vqe_spectrum_j1_df["V"],
            vqe_spectrum_j1_df[f"vqe_E{level}"],
            s=14,
            marker="x",
            color=line.get_color(),
        )
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    handles, labels = plt.gca().get_legend_handles_labels()
    handles.append(Line2D([], [], marker="x", linestyle="None", color="black", label="VQE"))
    labels.append("VQE")
    plt.legend(handles, labels, ncol=2)
    savefig("part_g_lipkin_j1_vqe_spectrum")

    new_figure(height=REPORT_VERY_TALL_FIGURE_HEIGHT_IN)
    for level in range(5):
        line, = plt.plot(
            vqe_spectrum_j2_df["V"],
            vqe_spectrum_j2_df[f"exact_E{level}"],
            label=f"E{level}",
        )
        plt.scatter(
            vqe_spectrum_j2_df["V"],
            vqe_spectrum_j2_df[f"vqe_E{level}"],
            s=14,
            marker="x",
            color=line.get_color(),
        )
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    handles, labels = plt.gca().get_legend_handles_labels()
    handles.append(Line2D([], [], marker="x", linestyle="None", color="black", label="VQE"))
    labels.append("VQE")
    plt.legend(handles, labels, ncol=2)
    savefig("part_g_lipkin_j2_vqe_spectrum")

    new_figure()
    plt.semilogy(vqe_spectrum_j1_df["V"], vqe_spectrum_j1_df["max_abs_error"] + 1e-16, label="J=1, all levels")
    plt.semilogy(vqe_spectrum_j2_df["V"], vqe_spectrum_j2_df["max_abs_error"] + 1e-16, label="J=2, all levels")
    plt.xlabel(r"$V$")
    plt.ylabel("Maximum absolute error")
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
PY_RUN_ALL

cat > scripts/make_report_figures.py <<'PY_MAKE_FIGS'
#!/usr/bin/env python3
"""Create standalone one-column figures for the two-column FYS5419 report.

This script only reads CSV files from results/data and rewrites the files in
results/figures. It does not rerun VQE or exact diagonalization. Each plot is
saved by itself as both PDF (for LaTeX) and PNG (for quick preview).
"""

from __future__ import annotations

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "results" / "data"
FIG = ROOT / "results" / "figures"

# Report setup: 10 pt A4 two-column article with margins 1.65 cm and
# column separation 0.65 cm. The column width is
# (21.0 - 2*1.65 - 0.65)/2 = 8.525 cm = 3.356 inches.
REPORT_FONT_SIZE_PT = 10
REPORT_COLUMN_WIDTH_IN = 8.525 / 2.54
REPORT_FIGURE_HEIGHT_IN = 2.40
REPORT_TALL_FIGURE_HEIGHT_IN = 2.75
REPORT_VERY_TALL_FIGURE_HEIGHT_IN = 3.05


def configure_matplotlib_for_report() -> None:
    """Use 10 pt report-sized text and compact one-column figures."""
    plt.rcParams.update(
        {
            "font.size": REPORT_FONT_SIZE_PT,
            "axes.labelsize": REPORT_FONT_SIZE_PT,
            "axes.titlesize": REPORT_FONT_SIZE_PT,
            "xtick.labelsize": REPORT_FONT_SIZE_PT,
            "ytick.labelsize": REPORT_FONT_SIZE_PT,
            "legend.fontsize": REPORT_FONT_SIZE_PT,
            "figure.titlesize": REPORT_FONT_SIZE_PT,
            "font.family": "serif",
            "font.serif": ["Computer Modern Roman", "Latin Modern Roman", "DejaVu Serif"],
            "mathtext.fontset": "cm",
            "axes.grid": False,
            "figure.constrained_layout.use": True,
            "savefig.dpi": 300,
        }
    )


def new_figure(height: float = REPORT_FIGURE_HEIGHT_IN) -> plt.Figure:
    FIG.mkdir(parents=True, exist_ok=True)
    return plt.figure(figsize=(REPORT_COLUMN_WIDTH_IN, height), constrained_layout=True)


def savefig(stem: str) -> None:
    """Save the current figure as vector PDF and preview PNG."""
    FIG.mkdir(parents=True, exist_ok=True)
    stem = Path(stem).stem
    fig = plt.gcf()
    fig.savefig(FIG / f"{stem}.pdf")
    fig.savefig(FIG / f"{stem}.png", dpi=300)
    plt.close(fig)


def require_csv(name: str) -> pd.DataFrame:
    path = DATA / name
    if not path.exists():
        raise FileNotFoundError(
            f"Missing {path}. Run `python scripts/run_all.py` once before "
            "running this plotting script."
        )
    return pd.read_csv(path)


def plot_parts_b_c() -> None:
    exact_df = require_csv("part_b_one_qubit_exact.csv")
    vqe_df = require_csv("part_c_one_qubit_vqe.csv")

    new_figure()
    plt.plot(exact_df["lambda"], exact_df["E0_exact"], label=r"$E_0$")
    plt.plot(exact_df["lambda"], exact_df["E1_exact"], label=r"$E_1$")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.legend()
    savefig("part_b_one_qubit_eigenvalues")

    new_figure()
    plt.plot(exact_df["lambda"], exact_df["ground_weight_0"], label=r"$|\langle 0|\psi_0\rangle|^2$")
    plt.plot(exact_df["lambda"], exact_df["ground_weight_1"], label=r"$|\langle 1|\psi_0\rangle|^2$")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Weight")
    plt.legend(loc="center right")
    savefig("part_b_one_qubit_weights")

    new_figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
    savefig("part_c_one_qubit_vqe_error")


def plot_parts_d_e() -> None:
    exact_df = require_csv("part_d_two_qubit_exact_entropy.csv")
    vqe_df = require_csv("part_e_two_qubit_vqe.csv")

    new_figure(height=REPORT_TALL_FIGURE_HEIGHT_IN)
    for i in range(4):
        plt.plot(exact_df["lambda"], exact_df[f"E{i}_exact"], label=rf"$E_{i}$")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.legend(ncol=2)
    savefig("part_d_two_qubit_eigenvalues")

    new_figure()
    plt.plot(exact_df["lambda"], exact_df["entropy_A_ground"])
    plt.xlabel(r"$\lambda$")
    plt.ylabel(r"$S(\rho_A)$")
    savefig("part_d_two_qubit_entropy")

    new_figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
    savefig("part_e_two_qubit_vqe_error")


def plot_part_f() -> None:
    j1_df = require_csv("part_f_lipkin_j1_exact.csv")
    j2_df = require_csv("part_f_lipkin_j2_exact.csv")

    new_figure()
    for col in [c for c in j1_df.columns if c.startswith("E")]:
        level = col[1:]
        plt.plot(j1_df["V"], j1_df[col], label=rf"$E_{level}$")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.legend()
    savefig("part_f_lipkin_j1_exact")

    new_figure(height=REPORT_TALL_FIGURE_HEIGHT_IN)
    for col in [c for c in j2_df.columns if c.startswith("E")]:
        level = col[1:]
        plt.plot(j2_df["V"], j2_df[col], label=rf"$E_{level}$")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.legend(ncol=2)
    savefig("part_f_lipkin_j2_exact")


def plot_part_g() -> None:
    j1_df = require_csv("part_g_lipkin_j1_vqe_spectrum.csv")
    j2_df = require_csv("part_g_lipkin_j2_vqe_spectrum.csv")

    new_figure(height=REPORT_TALL_FIGURE_HEIGHT_IN)
    for level in range(3):
        line, = plt.plot(j1_df["V"], j1_df[f"exact_E{level}"], label=rf"$E_{level}$")
        plt.scatter(j1_df["V"], j1_df[f"vqe_E{level}"], s=14, marker="x", color=line.get_color())
    handles, labels = plt.gca().get_legend_handles_labels()
    handles.append(Line2D([], [], marker="x", linestyle="None", color="black", label="VQE"))
    labels.append("VQE")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.legend(handles, labels, ncol=2)
    savefig("part_g_lipkin_j1_vqe_spectrum")

    new_figure(height=REPORT_VERY_TALL_FIGURE_HEIGHT_IN)
    for level in range(5):
        line, = plt.plot(j2_df["V"], j2_df[f"exact_E{level}"], label=rf"$E_{level}$")
        plt.scatter(j2_df["V"], j2_df[f"vqe_E{level}"], s=14, marker="x", color=line.get_color())
    handles, labels = plt.gca().get_legend_handles_labels()
    handles.append(Line2D([], [], marker="x", linestyle="None", color="black", label="VQE"))
    labels.append("VQE")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.legend(handles, labels, ncol=2)
    savefig("part_g_lipkin_j2_vqe_spectrum")

    new_figure()
    plt.semilogy(j1_df["V"], j1_df["max_abs_error"] + 1e-16, label=r"$J=1$")
    plt.semilogy(j2_df["V"], j2_df["max_abs_error"] + 1e-16, label=r"$J=2$")
    plt.xlabel(r"$V$")
    plt.ylabel("Maximum absolute error")
    plt.legend()
    savefig("part_g_lipkin_vqe_error")


def main() -> None:
    configure_matplotlib_for_report()
    plot_parts_b_c()
    plot_parts_d_e()
    plot_part_f()
    plot_part_g()
    print(f"Wrote standalone one-column figures to {FIG}")
    print("Each figure was saved as both .pdf and .png.")


if __name__ == "__main__":
    main()
PY_MAKE_FIGS

cat > report/project1_report.tex <<'TEX_REPORT'
\documentclass[10pt,a4paper]{article}

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
\usepackage{microtype}
\usepackage{amsmath,amssymb,bm}
\usepackage{graphicx}
\graphicspath{{../results/figures/}{}}
\usepackage{booktabs}
\usepackage{array}
\usepackage{siunitx}
\usepackage{geometry}
\usepackage{hyperref}
\usepackage{cleveref}
\usepackage{xcolor}
\usepackage{enumitem}
\usepackage{listings}
\usepackage{float}
\usepackage{placeins}
\usepackage{dblfloatfix}

\geometry{left=1.65cm,right=1.65cm,top=1.9cm,bottom=2.0cm}
\hypersetup{
    colorlinks=true,
    linkcolor=blue!50!black,
    citecolor=blue!50!black,
    urlcolor=blue!50!black,
    pdftitle={FYS5419 Project 1: VQE and the Lipkin model},
    pdfauthor={Torsheim}
}
\setlength{\parindent}{1em}
\setlength{\parskip}{0.15em}
\setlength{\columnsep}{0.65cm}
\setlist[itemize]{topsep=0.2em,itemsep=0.1em}
\setlist[enumerate]{topsep=0.2em,itemsep=0.1em}
\sisetup{scientific-notation=true,round-mode=figures,round-precision=3}

\lstset{
  basicstyle=\ttfamily\footnotesize,
  breaklines=true,
  frame=single,
  columns=fullflexible,
  backgroundcolor=\color{gray!6},
  keywordstyle=\color{blue!60!black},
  commentstyle=\color{green!35!black},
  stringstyle=\color{red!50!black}
}

\newcommand{\ket}[1]{\left|#1\right\rangle}
\newcommand{\bra}[1]{\left\langle #1\right|}
\newcommand{\braket}[2]{\left\langle #1 \middle| #2 \right\rangle}
\newcommand{\Tr}{\operatorname{Tr}}
\newcommand{\ii}{\mathrm{i}}
\newcommand{\eps}{\varepsilon}
\newcommand{\repo}{\texttt{FYS5419\_Project\_1}}

\title{\textbf{Variational Quantum Eigensolver Calculations for the Lipkin Model}\\[0.3em]
\large FYS5419 Project 1}
\author{Torsheim\\
\small University of Oslo, FYS5419/9419: Quantum Computing and Quantum Machine Learning}
\date{Spring 2026}

\begin{document}
\makeatletter
\twocolumn[
\begin{@twocolumnfalse}
\maketitle
\begin{abstract}
This project studies small quantum systems and the Lipkin-Meshkov-Glick model with exact diagonalization and self-written variational quantum eigensolver (VQE) routines. I first verify basic one-qubit gates, Bell-state preparation, projective measurements, reduced density matrices, and von Neumann entanglement entropy. I then solve a one-qubit two-level Hamiltonian and a two-qubit Hamiltonian as functions of an interaction strength $\lambda$, comparing exact eigenvalues with noiseless VQE simulations. Finally, I diagonalize the Lipkin Hamiltonian for total spin $J=1$ and $J=2$, rewrite the embedded Hamiltonians as Pauli strings, and reproduce the Lipkin spectra using an orthogonality-constrained excited-state VQE procedure. The one- and two-qubit VQE errors are at most $1.65\times 10^{-12}$ and $4.61\times 10^{-12}$, respectively. For the Lipkin spectra the maximum absolute errors are $4.44\times 10^{-16}$ for $J=1$ and $2.67\times 10^{-15}$ for $J=2$. These near-machine-precision errors occur because the simulations are noiseless and the chosen variational families span the relevant real eigenspaces of these small Hamiltonians. The results confirm the expected avoided crossing in the one-qubit problem, the entropy jump in the two-qubit model near a level crossing, and the symmetric Lipkin spectra for $W=0$.
\end{abstract}
\vspace{1.1em}
\end{@twocolumnfalse}
]
\makeatother

\section{Introduction}

The aim of this project is to study simplified quantum Hamiltonians, with particular emphasis on the Lipkin model, using both exact diagonalization and VQE. The project statement asks for a progression from elementary one-qubit operations to the one-qubit and two-qubit Hamiltonian problems, and finally to the $J=1$ and $J=2$ Lipkin matrices. The final numerical task is to compare Lipkin eigenvalues from exact diagonalization with eigenvalues obtained by VQE \cite{project1assignment}.

The Lipkin-Meshkov-Glick model is useful because it is small enough to solve exactly in selected symmetry sectors, but still contains the ingredients of an interacting many-body problem: non-commuting terms, level rearrangements, and entanglement generated by the Hamiltonian. This makes it a good testbed for quantum algorithms. VQE is especially relevant for such problems because it replaces long coherent phase-estimation circuits by a hybrid loop: prepare a parameterized quantum state, estimate its energy, and use a classical optimizer to update the parameters \cite{peruzzo2014vqe}. In this report all quantum simulations are noiseless state-vector simulations, so the purpose is to test the mathematics, circuits, and software implementation rather than hardware noise.

The report is organized as follows. \Cref{sec:formalism} gives the theoretical background for gates, density matrices, Hamiltonians, Pauli decompositions, and VQE. \Cref{sec:implementation} describes the code structure and validation strategy. \Cref{sec:results} presents the numerical results for project parts a--g. \Cref{sec:conclusion} summarizes the findings and limitations. Additional Pauli-decomposition details and the AI declaration are placed in the appendices.

\section{Theory and methods}
\label{sec:formalism}

\subsection{One-qubit gates and Bell states}

The computational one-qubit basis is
\begin{equation}
\ket{0}=\begin{pmatrix}1\\0\end{pmatrix}, \qquad
\ket{1}=\begin{pmatrix}0\\1\end{pmatrix}.
\end{equation}
The elementary gates used in part a are
\begin{equation}
X=\begin{pmatrix}0&1\\1&0\end{pmatrix}, \quad
Y=\begin{pmatrix}0&-\ii\\\ii&0\end{pmatrix}, \quad
Z=\begin{pmatrix}1&0\\0&-1\end{pmatrix},
\end{equation}
with the Hadamard and phase gates
\begin{equation}
H=\frac{1}{\sqrt{2}}\begin{pmatrix}1&1\\1&-1\end{pmatrix}, \qquad
S=\begin{pmatrix}1&0\\0&\ii\end{pmatrix}.
\end{equation}
Starting from $\ket{00}$, applying $H$ to the first qubit followed by a CNOT gate produces
\begin{equation}
\mathrm{CNOT}_{0,1}\,(H\otimes I)\ket{00}
= \frac{\ket{00}+\ket{11}}{\sqrt{2}}
\equiv \ket{\Phi^+}.
\end{equation}
The density matrix of a pure state is $\rho=\ket{\psi}\bra{\psi}$. For a bipartite system, the reduced density matrix of subsystem $A$ is obtained by tracing out subsystem $B$,
\begin{equation}
\rho_A = \Tr_B(\rho).
\end{equation}
The von Neumann entropy,
\begin{equation}
S(\rho_A) = -\Tr\left(\rho_A \log_2 \rho_A\right),
\label{eq:entropy}
\end{equation}
is zero for a pure product state and positive for an entangled pure state. For a Bell state, $\rho_A=I/2$ and $S(\rho_A)=1$.

\subsection{One-qubit Hamiltonian}

The one-qubit Hamiltonian is
\begin{equation}
H(\lambda)=H_0+\lambda H_I,
\end{equation}
where the project parameters are
\begin{align}
E_1&=0, & E_2&=4,\\
V_{11}&=-V_{22}=3, & V_{12}&=V_{21}=0.2.
\end{align}
In the computational basis this gives
\begin{equation}
H(\lambda)=
\begin{pmatrix}
3\lambda & 0.2\lambda\\
0.2\lambda & 4-3\lambda
\end{pmatrix}.
\label{eq:one_qubit_matrix}
\end{equation}
The same matrix can be written as a Pauli expansion
\begin{equation}
H(\lambda) = 2I + 0.2\lambda X + (3\lambda-2)Z.
\end{equation}
Since this is a $2\times2$ matrix, the exact eigenvalues can also be written in closed form,
\begin{equation}
E_{\pm}(\lambda) = 2 \pm \sqrt{(3\lambda-2)^2 + (0.2\lambda)^2}.
\label{eq:one_qubit_exact_evals}
\end{equation}
The diagonal terms become equal at $\lambda=2/3$, while the off-diagonal coupling gives an avoided crossing.

\subsection{Two-qubit Hamiltonian and entanglement}

The two-qubit Hamiltonian uses the computational basis $\{\ket{00},\ket{01},\ket{10},\ket{11}\}$. With non-interacting energies
\begin{equation}
(\epsilon_{00},\epsilon_{01},\epsilon_{10},\epsilon_{11})=(0.0,2.5,6.5,7.0),
\end{equation}
and interaction strengths $H_x=2.0$ and $H_z=3.0$, the matrix is
\begin{equation}
H(\lambda)=H_0 + \lambda \left( H_x X\otimes X + H_z Z\otimes Z \right).
\end{equation}
Written out explicitly,
\begin{equation}
\resizebox{\columnwidth}{!}{$
H(\lambda)=
\begin{pmatrix}
\epsilon_{00}+\lambda H_z & 0 & 0 & \lambda H_x\\
0 & \epsilon_{01}-\lambda H_z & \lambda H_x & 0\\
0 & \lambda H_x & \epsilon_{10}-\lambda H_z & 0\\
\lambda H_x & 0 & 0 & \epsilon_{11}+\lambda H_z
\end{pmatrix}$}.
\label{eq:two_qubit_hamiltonian}
\end{equation}
The interaction only mixes $\ket{00}$ with $\ket{11}$ and $\ket{01}$ with $\ket{10}$. The Hamiltonian therefore splits into even- and odd-parity two-dimensional sectors. This structure is useful both for exact diagonalization and for constructing a compact VQE ansatz.

For the entropy calculation the ground-state vector $\ket{\psi_0}$ is converted to the pure-state density matrix $\rho_0=\ket{\psi_0}\bra{\psi_0}$. I then trace out qubit $B$ and compute $S(\rho_A)$ with \cref{eq:entropy}.

\subsection{Lipkin Hamiltonian}

The Lipkin Hamiltonian is written in terms of quasispin operators as
\begin{equation}
H = \epsilon J_z + \frac{V}{2}(J_+^2+J_-^2) + \frac{W}{2}\left(-N+J_+J_-+J_-J_+\right).
\label{eq:lipkin_quasispin}
\end{equation}
For $J=1$ and $W=0$, the matrix used here is
\begin{equation}
H_{J=1}=\begin{pmatrix}
-\epsilon & 0 & -V\\
0&0&0\\
-V&0&\epsilon
\end{pmatrix}.
\label{eq:lipkin_j1}
\end{equation}
For $J=2$, the matrix is
\begin{equation}
\resizebox{\columnwidth}{!}{$
H_{J=2}=\begin{pmatrix}
-2\epsilon & 0 & \sqrt{6}V & 0 & 0\\
0 & -\epsilon+3W & 0 & 3V & 0\\
\sqrt{6}V & 0 & 4W & 0 & \sqrt{6}V\\
0 & 3V & 0 & \epsilon+3W & 0\\
0 & 0 & \sqrt{6}V & 0 & 2\epsilon
\end{pmatrix}$}.
\label{eq:lipkin_j2}
\end{equation}
The numerical results below use $\epsilon=1$ and $W=0$ unless otherwise stated.

Because quantum circuits require Hilbert spaces of dimension $2^n$, the $3\times3$ $J=1$ matrix is embedded in a two-qubit $4\times4$ space and the $5\times5$ $J=2$ matrix is embedded in a three-qubit $8\times8$ space. Extra basis states are unphysical padding states. For Pauli decompositions I write the embedding with a symbolic positive penalty $\Delta$ on the padded subspace. For example, the $J=1$ embedded Hamiltonian can be written as
\begin{align}
H_{J=1}^{(2q)}={}& -\frac{V}{2}(XI+XZ)-\frac{\epsilon}{2}(ZI+ZZ)\\
&+\frac{\Delta}{4}(II-IZ-ZI+ZZ).
\label{eq:j1_pauli}
\end{align}
The longer $J=2$ decomposition is listed in \cref{app:pauli}.

\subsection{VQE algorithms}

The VQE objective is the Rayleigh quotient
\begin{equation}
E(\bm{\theta}) = \frac{\bra{\psi(\bm{\theta})}H\ket{\psi(\bm{\theta})}}{\braket{\psi(\bm{\theta})}{\psi(\bm{\theta})}},
\end{equation}
which is minimized over a parameterized family of states. The one-qubit calculation uses
\begin{equation}
\ket{\psi(\theta)} = R_y(\theta)\ket{0}
= \cos\left(\frac{\theta}{2}\right)\ket{0}
+ \sin\left(\frac{\theta}{2}\right)\ket{1}.
\end{equation}
This ansatz spans all real one-qubit states, which is enough because the Hamiltonian is real symmetric.

For the two-qubit Hamiltonian I used two one-parameter parity-sector ansätze,
\begin{align}
\ket{\psi_e(\theta)} &= \cos\left(\frac{\theta}{2}\right)\ket{00}
+ \sin\left(\frac{\theta}{2}\right)\ket{11},\\
\ket{\psi_o(\theta)} &= \cos\left(\frac{\theta}{2}\right)\ket{01}
+ \sin\left(\frac{\theta}{2}\right)\ket{10}.
\end{align}
Both are implementable with one $R_y$ rotation and one CNOT gate. The lower of the optimized even- and odd-sector energies is selected as the VQE ground-state energy.

For the embedded Lipkin matrices I used a normalized real-amplitude variational state,
\begin{equation}
\ket{\psi(\bm{a})}=\frac{\bm{a}}{\|\bm{a}\|}, \qquad \bm{a}\in\mathbb{R}^{2^n}.
\end{equation}
This ansatz spans the full real embedded Hilbert space. For excited states I used sequential orthogonality constraints. After obtaining lower states $\{\ket{\phi_0},\ldots,\ket{\phi_{k-1}}\}$, the next trial vector is projected with
\begin{equation}
P_k = I - \sum_{j=0}^{k-1}\ket{\phi_j}\bra{\phi_j},
\end{equation}
and the Rayleigh quotient is minimized in the orthogonal subspace. This is a variational deflation strategy. Since the Hamiltonians are small and real symmetric, this procedure reproduces the exact eigenvalues up to numerical precision.

\section{Implementation and verification}
\label{sec:implementation}

All core routines were written in Python using \texttt{numpy} and \texttt{scipy}. The implementation is organized as follows:
\begin{itemize}
    \item \texttt{quantum.py}: basis states, Pauli gates, Hadamard and phase gates, CNOT, Bell states, measurement sampling, density matrices, partial traces, and entropies.
    \item \texttt{hamiltonians.py}: construction of one-qubit, two-qubit, and Lipkin Hamiltonians, exact diagonalization, power-of-two embeddings, and Pauli-string decompositions.
    \item \texttt{vqe.py}: self-written VQE energy functions, ansätze, BFGS optimization for real-amplitude states, and orthogonality-constrained excited-state VQE.
    \item \texttt{scripts/run\_all.py}: a reproducible driver that generates all tables and figures.
    \item \texttt{tests/}: unit tests for gates, Bell-state entropy, Hamiltonian construction, Pauli decompositions, and VQE agreement with exact diagonalization.
\end{itemize}

Several checks were used to validate the code. The one-qubit Hamiltonian was checked against the analytic eigenvalues in \cref{eq:one_qubit_exact_evals}. The $J=1$ Lipkin spectrum was checked against
\begin{equation}
E_0=-\sqrt{\epsilon^2+V^2},\qquad E_1=0,\qquad E_2=+\sqrt{\epsilon^2+V^2}
\end{equation}
for $W=0$. Bell-state preparation was checked by computing the overlap with $\ket{\Phi^+}$ and by tracing out one subsystem to obtain $S(\rho_A)=S(\rho_B)=1$.

The VQE calculations are ideal state-vector calculations. They do not include quantum hardware noise or finite-shot energy-estimation noise. This explains why the VQE errors below are close to machine precision. The measurement sampling in part a is the only place where finite-shot sampling is explicitly simulated.

\section{Results and discussion}
\label{sec:results}

\subsection{Part a: gates, Bell measurements, and entropy}

The gate tests reproduce the expected algebraic actions. For example, $X\ket{0}=\ket{1}$, $Z\ket{1}=-\ket{1}$, and $H\ket{0}=(\ket{0}+\ket{1})/\sqrt{2}$. The Bell-state circuit gives
\begin{equation}
\mathrm{CNOT}_{0,1}(H\otimes I)\ket{00}=\ket{\Phi^+},
\end{equation}
with an overlap probability of $1.000000000000$ with the target Bell state.

Using $5000$ measurement shots, the full two-qubit measurements gave the results in \cref{tab:bell_measurements}. Only the bit strings $00$ and $11$ appear, as expected for $\ket{\Phi^+}$. The small difference between the two frequencies is sampling noise.

\begin{table*}[t]
\centering
\caption{Measurement results for the Bell state $\ket{\Phi^+}$ using $5000$ shots.}
\label{tab:bell_measurements}
\begin{tabular}{cccc}
\toprule
State & Counts & Sample frequency & Exact probability\\
\midrule
$00$ & 2469 & 0.4938 & 0.5\\
$11$ & 2531 & 0.5062 & 0.5\\
\bottomrule
\end{tabular}
\end{table*}

The reduced density matrices are
\begin{equation}
\rho_A=\rho_B=\frac{1}{2}\begin{pmatrix}1&0\\0&1\end{pmatrix},
\end{equation}
which gives
\begin{equation}
S(\rho_A)=S(\rho_B)=1.
\end{equation}
This confirms that the Bell state is maximally entangled with respect to either one-qubit subsystem.

\subsection{Parts b and c: one-qubit exact solution and VQE}

\Cref{fig:one_qubit_eigenvalues,fig:one_qubit_weights,fig:one_qubit_vqe_error} summarize the one-qubit Hamiltonian results. The exact eigenvalues show an avoided crossing near $\lambda=2/3$, consistent with \cref{eq:one_qubit_exact_evals}. The ground-state composition changes rapidly in the same region. At $\lambda=1$, the weight of $\ket{0}$ in the ground state is $9.71\times 10^{-3}$, while the weight of $\ket{1}$ is $0.9903$. Thus the lower eigenstate has changed character from mostly $\ket{0}$ to mostly $\ket{1}$.

The one-qubit VQE reproduces the exact ground-state energy with a maximum absolute error of $1.65\times10^{-12}$. This is expected because the $R_y(\theta)\ket{0}$ ansatz can represent any real one-qubit ground state.

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_b_one_qubit_eigenvalues.pdf}
\caption{Exact one-qubit eigenvalues. The off-diagonal coupling produces an avoided crossing near $\lambda\approx2/3$.}
\label{fig:one_qubit_eigenvalues}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_b_one_qubit_weights.pdf}
\caption{One-qubit ground-state composition. The ground state changes from mostly $\ket{0}$ to mostly $\ket{1}$ near the avoided crossing.}
\label{fig:one_qubit_weights}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_c_one_qubit_vqe_error.pdf}
\caption{Absolute one-qubit VQE error. The error is at numerical roundoff level for the noiseless state-vector calculation.}
\label{fig:one_qubit_vqe_error}
\end{figure}

\subsection{Parts d and e: two-qubit spectrum, entropy, and VQE}

\Cref{fig:two_qubit_eigenvalues,fig:two_qubit_entropy,fig:two_qubit_vqe_error} show the two-qubit exact spectrum, ground-state entanglement entropy, and VQE error. At $\lambda=0$, the eigenvalues are simply the non-interacting energies $0,2.5,6.5,7.0$. As the interaction is increased, the even and odd parity sectors move differently. The ground-state branch changes sector between $\lambda=0.40$ and $\lambda=0.41$.

The entropy starts at zero because the non-interacting ground state is $\ket{00}$. As $\lambda$ increases, the interaction mixes basis states and the entropy grows. The visible jump in $S(\rho_A)$ near the level crossing is physically meaningful: the identity of the lowest eigenvector changes from one parity sector to the other. At $\lambda=1$, the entropy is approximately $0.601$.

The two-qubit VQE calculation optimizes the even and odd ansätze separately. It reproduces the exact ground-state branch with maximum absolute error $4.61\times10^{-12}$. The sector-adapted ansatz is exact for this Hamiltonian because each sector is two-dimensional.

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_d_two_qubit_eigenvalues.pdf}
\caption{Exact two-qubit eigenvalues. The ground-state branch changes near $\lambda\approx0.4$.}
\label{fig:two_qubit_eigenvalues}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_d_two_qubit_entropy.pdf}
\caption{Ground-state entanglement entropy of subsystem $A$ for the two-qubit Hamiltonian. The jump reflects the change in the lowest-energy branch.}
\label{fig:two_qubit_entropy}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_e_two_qubit_vqe_error.pdf}
\caption{Absolute two-qubit VQE error. The sector-adapted ansatz reproduces the exact ground state to numerical precision.}
\label{fig:two_qubit_vqe_error}
\end{figure}

\subsection{Part f: exact Lipkin spectra and Pauli decompositions}

\Cref{fig:lipkin_j1_exact,fig:lipkin_j2_exact} show the exact $J=1$ and $J=2$ Lipkin spectra for $\epsilon=1$ and $W=0$ as functions of $V$. The $J=1$ result follows the analytic expression
\begin{equation}
E=0,\qquad E=\pm\sqrt{1+V^2},
\end{equation}
which explains the flat central level and the two symmetric branches. For $J=2$, the spectrum is also symmetric about zero for $W=0$. At $V=0$, the eigenvalues are $-2,-1,0,1,2$. At $V=2$, the numerical eigenvalues are approximately
\begin{equation}
(-7.211,\ -6.083,\ 0,\ 6.083,\ 7.211).
\end{equation}
The exact spectra are therefore consistent with the matrix structure in \cref{eq:lipkin_j1,eq:lipkin_j2}.

The Pauli decomposition is necessary because a quantum computer measures Hamiltonians through Pauli strings. The $J=1$ result was given in \cref{eq:j1_pauli}. The $J=2$ decomposition contains 16 nonzero Pauli strings for the embedded three-qubit Hamiltonian and is listed in \cref{app:pauli}. The $W$-dependent coefficients are included there, so the same table also covers the challenge case with the $W$ term.

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_f_lipkin_j1_exact.pdf}
\caption{Exact Lipkin spectrum for $J=1$, $\epsilon=1$, and $W=0$. The spectrum is $0$ and $\pm\sqrt{1+V^2}$.}
\label{fig:lipkin_j1_exact}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_f_lipkin_j2_exact.pdf}
\caption{Exact Lipkin spectrum for $J=2$, $\epsilon=1$, and $W=0$. The spectrum is symmetric about zero.}
\label{fig:lipkin_j2_exact}
\end{figure}

\subsection{Part g: Lipkin VQE spectra}

The updated Lipkin VQE calculation estimates the same eigenvalues as in part f, not only the ground state. \Cref{fig:lipkin_j1_vqe_spectrum,fig:lipkin_j2_vqe_spectrum} compare exact and VQE spectra for $J=1$ and $J=2$. The VQE markers lie on top of the exact curves on the scale of the plot. \Cref{fig:lipkin_vqe_error} shows the maximum absolute error over all levels at each $V$. The largest errors are $4.44\times10^{-16}$ for $J=1$ and $2.67\times10^{-15}$ for $J=2$.

These errors are extremely small because the Lipkin VQE uses a full normalized real-amplitude ansatz in the embedded Hilbert space, together with sequential orthogonality constraints for excited states. This is a strong ideal-simulation benchmark. It should not be interpreted as a claim that the same accuracy would be obtained on noisy hardware with finite shots and a shallow hardware-efficient ansatz.

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_g_lipkin_j1_vqe_spectrum.pdf}
\caption{Excited-state VQE spectrum for the $J=1$ Lipkin Hamiltonian. Crosses show VQE results and lines show exact diagonalization.}
\label{fig:lipkin_j1_vqe_spectrum}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_g_lipkin_j2_vqe_spectrum.pdf}
\caption{Excited-state VQE spectrum for the $J=2$ Lipkin Hamiltonian. Crosses show VQE results and lines show exact diagonalization.}
\label{fig:lipkin_j2_vqe_spectrum}
\end{figure}

\begin{figure}[t]
\centering
\includegraphics[width=\linewidth]{part_g_lipkin_vqe_error.pdf}
\caption{Maximum absolute Lipkin VQE error over all computed levels. The error is at roundoff level for both $J=1$ and $J=2$.}
\label{fig:lipkin_vqe_error}
\end{figure}
\clearpage

\subsection{Numerical accuracy summary}

\Cref{tab:error_summary} summarizes the main VQE comparisons. The one- and two-qubit VQE routines use compact circuit-inspired ansätze, while the Lipkin calculations use a full real-amplitude ansatz with orthogonality constraints. All errors are small compared with the energy scale of the Hamiltonians.

\begin{table*}[t]
\centering
\caption{Maximum absolute VQE errors in the numerical scans.}
\label{tab:error_summary}
\begin{tabular}{lcc}
\toprule
Problem & Compared quantity & Maximum absolute error\\
\midrule
One-qubit Hamiltonian & ground-state energy & $1.65\times10^{-12}$\\
Two-qubit Hamiltonian & ground-state energy & $4.61\times10^{-12}$\\
Lipkin $J=1$ & all three levels & $4.44\times10^{-16}$\\
Lipkin $J=2$ & all five levels & $2.67\times10^{-15}$\\
\bottomrule
\end{tabular}
\end{table*}

\section{Conclusion}
\label{sec:conclusion}

The elementary gate and Bell-state calculations verify that the code correctly handles basis states, gates, measurements, density matrices, partial traces, and von Neumann entropy. The Bell state gives the expected perfectly correlated measurement outcomes and one bit of subsystem entropy.

The one-qubit Hamiltonian shows an avoided crossing near $\lambda=2/3$. Around this point the ground state changes from mostly $\ket{0}$ to mostly $\ket{1}$, and the VQE reproduces the exact ground-state energy to roundoff precision. The two-qubit Hamiltonian separates into parity sectors. Its ground state changes sector near $\lambda\approx0.41$, which produces a jump in the entanglement entropy. The sector-adapted two-qubit VQE again agrees with exact diagonalization at roundoff level.

For the Lipkin Hamiltonian, the $J=1$ and $J=2$ exact spectra behave as expected for $W=0$. The $J=1$ case has the analytic spectrum $0$ and $\pm\sqrt{1+V^2}$, while the $J=2$ spectrum is symmetric about zero. The Hamiltonians were embedded into qubit Hilbert spaces and decomposed into Pauli strings, including the $W$-dependent terms for the $J=2$ challenge. The excited-state VQE method reproduces all requested Lipkin levels with errors of order $10^{-15}$.

The main limitation is that these are ideal simulations. The VQE ansätze were chosen to be expressive enough for the small real Hamiltonians studied here. A more hardware-realistic extension would use a fixed shallow gate ansatz, finite-shot energy estimation, and noise models. It would also be interesting to compare the deflation-based excited-state VQE with methods such as the quantum equation-of-motion approach used in recent Lipkin-model quantum simulations \cite{hlatshwayo2022lipkin}.

\appendix

\section{Pauli decomposition of the embedded Lipkin Hamiltonians}
\label{app:pauli}

For a qubit Hamiltonian I write
\begin{equation}
H = \sum_P c_P P,
\end{equation}
where $P$ is a tensor product of Pauli matrices and identities. The coefficients below are for the embedded Hamiltonians. The symbol $\Delta$ denotes the positive penalty on unphysical padding states.

\subsection*{$J=1$ embedded in two qubits}

\begin{table*}[t]
\centering
\caption{Pauli coefficients for the $J=1$ Lipkin Hamiltonian embedded in two qubits.}
\begin{tabular}{cc}
\toprule
Pauli string & Coefficient $c_P$\\
\midrule
$II$ & $\frac{1}{4}\Delta$\\
$IZ$ & $-\frac{1}{4}\Delta$\\
$XI$ & $-\frac{1}{2}V$\\
$XZ$ & $-\frac{1}{2}V$\\
$ZI$ & $-\frac{1}{2}\epsilon-\frac{1}{4}\Delta$\\
$ZZ$ & $-\frac{1}{2}\epsilon+\frac{1}{4}\Delta$\\
\bottomrule
\end{tabular}
\end{table*}

\subsection*{$J=2$ embedded in three qubits}

\begin{table*}[t]
\centering
\caption{Pauli coefficients for the $J=2$ Lipkin Hamiltonian embedded in three qubits. This table includes the $W$ term.}
\small
\begin{tabular}{cc}
\toprule
Pauli string & Coefficient $c_P$\\
\midrule
$III$ & $1.25W + 0.375\Delta$\\
$IIZ$ & $-0.25W - 0.125\Delta$\\
$IXI$ & $1.3623724357V$\\
$IXZ$ & $-0.1376275643V$\\
$IZI$ & $-0.25\epsilon -0.5W -0.125\Delta$\\
$IZZ$ & $0.25\epsilon -0.5W -0.125\Delta$\\
$XXI$ & $0.6123724357V$\\
$XXZ$ & $0.6123724357V$\\
$YYI$ & $0.6123724357V$\\
$YYZ$ & $0.6123724357V$\\
$ZII$ & $-0.5\epsilon +1.25W -0.375\Delta$\\
$ZIZ$ & $-0.5\epsilon -0.25W +0.125\Delta$\\
$ZXI$ & $1.3623724357V$\\
$ZXZ$ & $-0.1376275643V$\\
$ZZI$ & $-0.75\epsilon -0.5W +0.125\Delta$\\
$ZZZ$ & $-0.25\epsilon -0.5W +0.125\Delta$\\
\bottomrule
\end{tabular}
\end{table*}
\clearpage

\section{Reproducibility commands}
\label{app:reproducibility}

The following commands reproduce the numerical results from the project repository:
\begin{lstlisting}[language=bash]
cd FYS5419_Project_1
source .venv/bin/activate
pytest
python scripts/run_all.py
cd report
pdflatex FYS5419_Project_1_report.tex
pdflatex FYS5419_Project_1_report.tex
\end{lstlisting}
The generated CSV files are stored in \path{results/data/}, and the figures are stored in \path{results/figures/}.

\section{AI assistance declaration}
\label{app:ai}

ChatGPT (GPT-5.5 Pro through the OpenAI ChatGPT interface, June 2026) was used during the project. The assistance included repository scaffolding, drafting Python modules and tests, plotting scripts, report organization, and first-pass report prose. The final author is responsible for understanding, testing, editing, and validating all code and text before submission.

The text assistance was used for the abstract, introduction, formalism, results discussion, and conclusion. Code assistance was used for \texttt{quantum.py}, \texttt{hamiltonians.py}, \texttt{vqe.py}, \texttt{scripts/run\_all.py}, and selected tests. The numerical values, plots, and conclusions in the report were checked against exact diagonalization, analytic limits, and unit tests.

The repository is structured so that the numerical results can be regenerated with
\begin{lstlisting}[language=bash]
source .venv/bin/activate
pytest
python scripts/run_all.py
cd report
pdflatex project1_report.tex
pdflatex project1_report.tex
\end{lstlisting}
\clearpage
\begin{thebibliography}{4}

\bibitem{project1assignment}
FYS5419/9419, University of Oslo. \emph{Quantum Computing and Quantum Machine Learning, Project 1}. Spring semester 2026.

\bibitem{lmg1965}
H. J. Lipkin, N. Meshkov, and A. J. Glick. Validity of many-body approximation methods for a solvable model: (I). Exact solutions and perturbation theory. \emph{Nuclear Physics} \textbf{62}, 188--198 (1965). doi: \href{https://doi.org/10.1016/0029-5582(65)90862-X}{10.1016/0029-5582(65)90862-X}.

\bibitem{peruzzo2014vqe}
A. Peruzzo, J. McClean, P. Shadbolt, M.-H. Yung, X.-Q. Zhou, P. J. Love, A. Aspuru-Guzik, and J. L. O'Brien. A variational eigenvalue solver on a photonic quantum processor. \emph{Nature Communications} \textbf{5}, 4213 (2014). doi: \href{https://doi.org/10.1038/ncomms5213}{10.1038/ncomms5213}.

\bibitem{hlatshwayo2022lipkin}
M. Q. Hlatshwayo, Y. Zhang, H. Wibowo, R. LaRose, D. Lacroix, and E. Litvinova. Simulating excited states of the Lipkin model on a quantum computer. \emph{Physical Review C} \textbf{106}, 024319 (2022). doi: \href{https://doi.org/10.1103/PhysRevC.106.024319}{10.1103/PhysRevC.106.024319}.

\end{thebibliography}

\end{document}
TEX_REPORT

chmod +x scripts/run_all.py scripts/make_report_figures.py

echo "Updated plotting/report files. Backups are in: $BACKUP"
echo "Next commands:"
echo "  python scripts/make_report_figures.py"
echo "  cd report && pdflatex project1_report.tex && pdflatex project1_report.tex && cd .."
echo "This update does not run git add, git commit, or git push."
