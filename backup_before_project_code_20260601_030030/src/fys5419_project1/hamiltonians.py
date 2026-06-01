"""Hamiltonians for Parts b-e."""

from __future__ import annotations

import numpy as np

Array = np.ndarray


def one_qubit_hamiltonian(lmbda: float, *, e1: float = 0.0, e2: float = 4.0,
                          v11: float = 3.0, v22: float = -3.0,
                          v12: float = 0.2) -> Array:
    """Return the `2 x 2` Hamiltonian from Part b.

    TODO: implement ``H = H0 + lambda * HI``.
    """
    raise NotImplementedError


def one_qubit_pauli_coefficients(lmbda: float, *, e1: float = 0.0, e2: float = 4.0,
                                  v11: float = 3.0, v22: float = -3.0,
                                  v12: float = 0.2) -> dict[str, float]:
    """Return coefficients for ``I``, ``Z`` and ``X`` in the one-qubit Hamiltonian.

    TODO: implement from the formulas in the assignment.
    """
    raise NotImplementedError


def two_qubit_hamiltonian(lmbda: float, hx: float = 2.0, hz: float = 3.0,
                          energies: tuple[float, float, float, float] = (0.0, 2.5, 6.5, 7.0)) -> Array:
    """Return the `4 x 4` Hamiltonian from Part d.

    TODO: implement with interaction strength multiplied by ``lmbda``.
    """
    raise NotImplementedError


def diagonalize(H: Array) -> tuple[Array, Array]:
    """Return sorted eigenvalues and eigenvectors of a real symmetric/Hermitian Hamiltonian.

    TODO: implement using ``numpy.linalg.eigh`` and sort by energy.
    """
    raise NotImplementedError
