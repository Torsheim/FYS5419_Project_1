"""One-qubit and two-qubit gate utilities for Part a.

Add implementations here rather than leaving final logic inside notebooks.
"""

from __future__ import annotations

import numpy as np

Array = np.ndarray


def basis_state(index: int, n_qubits: int = 1) -> Array:
    """Return computational basis state ``|index>`` for ``n_qubits``.

    TODO: implement and add tests.
    """
    raise NotImplementedError


def pauli_matrices() -> dict[str, Array]:
    """Return the Pauli matrices and the identity matrix.

    TODO: implement matrices I, X, Y, Z.
    """
    raise NotImplementedError


def hadamard() -> Array:
    """Return the one-qubit Hadamard matrix.

    TODO: implement.
    """
    raise NotImplementedError


def phase(phi: float) -> Array:
    """Return a one-qubit phase gate with phase angle ``phi``.

    TODO: implement.
    """
    raise NotImplementedError


def cnot(control: int = 0, target: int = 1) -> Array:
    """Return a two-qubit CNOT matrix.

    TODO: implement for the chosen computational-basis ordering.
    """
    raise NotImplementedError


def bell_states() -> dict[str, Array]:
    """Return the four Bell states.

    TODO: implement.
    """
    raise NotImplementedError


def measurement_probabilities(state: Array, n_qubits: int) -> dict[str, float]:
    """Return computational-basis measurement probabilities.

    TODO: implement.
    """
    raise NotImplementedError


def sample_measurements(state: Array, n_qubits: int, shots: int, seed: int | None = None) -> dict[str, int]:
    """Sample projective computational-basis measurements.

    TODO: implement and compare averages with exact probabilities.
    """
    raise NotImplementedError
