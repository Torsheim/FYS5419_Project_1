"""Lipkin model matrices and Pauli decompositions for Parts f-g."""

from __future__ import annotations

import numpy as np

Array = np.ndarray


def lipkin_j1(epsilon: float, V: float, W: float = 0.0) -> Array:
    """Return the `J=1` Lipkin Hamiltonian matrix.

    TODO: implement the `W=0` case first, then consider the challenge term.
    """
    raise NotImplementedError


def lipkin_j2(epsilon: float, V: float, W: float = 0.0) -> Array:
    """Return the `J=2` Lipkin Hamiltonian matrix.

    TODO: implement the matrix from the assignment.
    """
    raise NotImplementedError


def pauli_decomposition(matrix: Array, n_qubits: int, tol: float = 1e-12) -> dict[str, complex]:
    """Decompose a matrix into Pauli strings.

    The returned dictionary should map strings such as ``"IXZ"`` to coefficients.

    TODO: implement a general Pauli-basis projection helper.
    """
    raise NotImplementedError
