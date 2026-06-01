"""Small plotting helper functions for exploratory project figures."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

Array = np.ndarray


def save_eigenvalue_plot(
    x_values: Array,
    eigenvalues: Array,
    output_path: str | Path,
    xlabel: str = r"$\lambda$",
    ylabel: str = "Energy",
) -> None:
    """Save a compact eigenvalue plot."""
    x_values = np.asarray(x_values, dtype=float)
    values = np.asarray(eigenvalues, dtype=float)
    if values.ndim == 1:
        values = values[:, None]

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(3.35, 2.55))
    for index in range(values.shape[1]):
        ax.plot(x_values, values[:, index], label=fr"$E_{index}$")
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    if values.shape[1] <= 6:
        ax.legend(frameon=True)
    fig.tight_layout()
    fig.savefig(output_path)
    plt.close(fig)
