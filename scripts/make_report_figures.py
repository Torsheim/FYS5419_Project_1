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
