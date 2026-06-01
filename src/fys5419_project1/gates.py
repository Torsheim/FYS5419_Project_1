"""Compatibility wrappers for gate and measurement utilities.

The final state-vector implementation is in :mod:`fys5419_project1.quantum`.
This module exists so older notebooks or exploratory scripts importing
``fys5419_project1.gates`` still call the implemented routines.
"""

from __future__ import annotations

import numpy as np

from .quantum import (
    HADAMARD,
    I2,
    PHASE_S,
    X,
    Y,
    Z,
    apply_single_qubit_gate,
    basis_state as _basis_state_from_bits,
    bell_state,
    bit_probabilities,
    cnot_matrix,
    measure_full_state,
    one_qubit_basis,
)

Array = np.ndarray


def basis_state(index: int, n_qubits: int = 1) -> Array:
    """Return computational basis state ``|index>`` for ``n_qubits``."""
    if index < 0 or index >= 2**n_qubits:
        raise ValueError("basis index out of range")
    return _basis_state_from_bits(format(index, f"0{n_qubits}b"))


def pauli_matrices() -> dict[str, Array]:
    """Return identity and Pauli matrices."""
    return {"I": I2.copy(), "X": X.copy(), "Y": Y.copy(), "Z": Z.copy()}


def hadamard() -> Array:
    """Return the one-qubit Hadamard matrix."""
    return HADAMARD.copy()


def phase(phi: float = np.pi / 2.0) -> Array:
    """Return a one-qubit phase gate ``diag(1, exp(i phi))``."""
    return np.array([[1.0, 0.0], [0.0, np.exp(1j * phi)]], dtype=complex)


def cnot(control: int = 0, target: int = 1) -> Array:
    """Return a two-qubit CNOT matrix."""
    return cnot_matrix(control=control, target=target, n_qubits=2)


def bell_states() -> dict[str, Array]:
    """Return the four Bell states in the |00>, |01>, |10>, |11> ordering."""
    return {
        "phi_plus": bell_state("phi_plus"),
        "phi_minus": bell_state("phi_minus"),
        "psi_plus": bell_state("psi_plus"),
        "psi_minus": bell_state("psi_minus"),
    }


def measurement_probabilities(state: Array, n_qubits: int | None = None) -> dict[str, float]:
    """Return computational-basis probabilities for ``state``."""
    probs = bit_probabilities(state)
    if n_qubits is None:
        n_qubits = int(np.log2(len(probs)))
    return {format(i, f"0{n_qubits}b"): float(p) for i, p in enumerate(probs)}


def sample_measurements(
    state: Array,
    n_qubits: int | None = None,
    shots: int = 1024,
    seed: int | None = None,
) -> dict[str, int]:
    """Sample computational-basis measurements."""
    return measure_full_state(state, shots=shots, seed=seed)


__all__ = [
    "Array",
    "HADAMARD",
    "I2",
    "PHASE_S",
    "X",
    "Y",
    "Z",
    "apply_single_qubit_gate",
    "basis_state",
    "bell_state",
    "bell_states",
    "bit_probabilities",
    "cnot",
    "cnot_matrix",
    "hadamard",
    "measure_full_state",
    "measurement_probabilities",
    "one_qubit_basis",
    "pauli_matrices",
    "phase",
    "sample_measurements",
]
