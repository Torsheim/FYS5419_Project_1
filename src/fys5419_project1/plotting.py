"""Plotting helpers for project figures."""

from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

Array = np.ndarray


def save_eigenvalue_plot(lambdas: Array, eigenvalues: Array, output_path: str | Path) -> None:
    """Save a plot of eigenvalues versus interaction strength.

    TODO: implement after eigenvalue code is ready.
    """
    raise NotImplementedError
