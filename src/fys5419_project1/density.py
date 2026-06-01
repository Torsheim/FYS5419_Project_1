"""Density matrices, partial traces, and von Neumann entropy."""

from __future__ import annotations

import numpy as np

Array = np.ndarray


def density_matrix(state: Array) -> Array:
    """Return ``|psi><psi|`` for a pure state.

    TODO: implement.
    """
    raise NotImplementedError


def partial_trace(rho: Array, dims: tuple[int, ...], keep: tuple[int, ...]) -> Array:
    """Trace out all subsystems except those listed in ``keep``.

    Parameters
    ----------
    rho:
        Full density matrix.
    dims:
        Dimensions of each subsystem, e.g. ``(2, 2)`` for two qubits.
    keep:
        Subsystem indices to keep.

    TODO: implement carefully and test on Bell states.
    """
    raise NotImplementedError


def von_neumann_entropy(rho: Array, base: float = 2.0, tol: float = 1e-12) -> float:
    """Compute ``-Tr(rho log_base rho)``.

    TODO: implement using eigenvalues of the Hermitian density matrix.
    """
    raise NotImplementedError
