"""Hamiltonians and Pauli decompositions for FYS5419 Project 1."""

from __future__ import annotations

from itertools import product
from math import ceil, log2, sqrt

import numpy as np
from numpy.typing import NDArray

from .quantum import I2, PAULI_MATRICES, X, Z, kron_n

ComplexArray = NDArray[np.complex128]


def sorted_eigh(matrix: ComplexArray) -> tuple[np.ndarray, ComplexArray]:
    """Eigenvalues/eigenvectors sorted from lowest to highest eigenvalue."""
    evals, evecs = np.linalg.eigh(np.asarray(matrix, dtype=complex))
    order = np.argsort(np.real(evals))
    return np.real_if_close(evals[order]).astype(float), evecs[:, order]


def one_qubit_hamiltonian(
    lam: float,
    E1: float = 0.0,
    E2: float = 4.0,
    V11: float = 3.0,
    V22: float = -3.0,
    V12: float = 0.2,
) -> ComplexArray:
    """Part b/c Hamiltonian H = H0 + lambda HI in the |0>, |1> basis."""
    h0 = np.array([[E1, 0.0], [0.0, E2]], dtype=complex)
    hi = np.array([[V11, V12], [V12, V22]], dtype=complex)
    return h0 + lam * hi


def one_qubit_pauli_coefficients(
    lam: float,
    E1: float = 0.0,
    E2: float = 4.0,
    V11: float = 3.0,
    V22: float = -3.0,
    V12: float = 0.2,
) -> dict[str, float]:
    """Coefficients in H = a_I I + a_X X + a_Z Z for the one-qubit model."""
    energy_bar = 0.5 * (E1 + E2)
    omega = 0.5 * (E1 - E2)
    c = 0.5 * (V11 + V22)
    omega_z = 0.5 * (V11 - V22)
    omega_x = V12
    return {
        "I": float(energy_bar + lam * c),
        "X": float(lam * omega_x),
        "Y": 0.0,
        "Z": float(omega + lam * omega_z),
    }


def one_qubit_from_pauli(lam: float) -> ComplexArray:
    coeffs = one_qubit_pauli_coefficients(lam)
    return coeffs["I"] * I2 + coeffs["X"] * X + coeffs["Z"] * Z


def two_qubit_hamiltonian(
    lam: float,
    Hx: float = 2.0,
    Hz: float = 3.0,
    eps00: float = 0.0,
    eps10: float = 2.5,
    eps01: float = 6.5,
    eps11: float = 7.0,
) -> ComplexArray:
    """Part d/e two-qubit Hamiltonian in standard basis |00>, |01>, |10>, |11>.

    The project text lists non-interacting energies as epsilon00, epsilon10,
    epsilon01, epsilon11. Here the returned matrix uses the standard simulation
    ordering |00>, |01>, |10>, |11>, so the diagonal is [epsilon00, epsilon01,
    epsilon10, epsilon11].
    """
    h0 = np.diag([eps00, eps01, eps10, eps11]).astype(complex)
    hi = Hx * kron_n(X, X) + Hz * kron_n(Z, Z)
    return h0 + lam * hi


def lipkin_j1(epsilon: float = 1.0, V: float = 0.0) -> ComplexArray:
    """Lipkin Hamiltonian for J=1 and W=0 in the project basis."""
    return np.array(
        [[-epsilon, 0.0, -V], [0.0, 0.0, 0.0], [-V, 0.0, epsilon]],
        dtype=complex,
    )


def lipkin_j2(epsilon: float = 1.0, V: float = 0.0, W: float = 0.0) -> ComplexArray:
    """Lipkin Hamiltonian for J=2 from the project text, including W."""
    root6 = sqrt(6.0)
    return np.array(
        [
            [-2.0 * epsilon, 0.0, root6 * V, 0.0, 0.0],
            [0.0, -epsilon + 3.0 * W, 0.0, 3.0 * V, 0.0],
            [root6 * V, 0.0, 4.0 * W, 0.0, root6 * V],
            [0.0, 3.0 * V, 0.0, epsilon + 3.0 * W, 0.0],
            [0.0, 0.0, root6 * V, 0.0, 2.0 * epsilon],
        ],
        dtype=complex,
    )


def next_power_of_two(n: int) -> int:
    if n < 1:
        raise ValueError("n must be positive")
    return 1 << ceil(log2(n))


def pad_to_power_of_two(matrix: ComplexArray, penalty: float | None = None) -> ComplexArray:
    """Embed a dxd Hamiltonian in the next 2^n-dimensional Hilbert space.

    Extra basis states are assigned a large positive diagonal penalty so VQE does
    not choose unphysical padded states as the ground state.
    """
    matrix = np.asarray(matrix, dtype=complex)
    d = matrix.shape[0]
    if matrix.shape != (d, d):
        raise ValueError("matrix must be square")
    target = next_power_of_two(d)
    if target == d:
        return matrix.copy()
    evals = np.linalg.eigvalsh(matrix)
    if penalty is None:
        penalty = float(np.max(np.real(evals)) + 10.0 + abs(np.min(np.real(evals))))
    padded = np.eye(target, dtype=complex) * penalty
    padded[:d, :d] = matrix
    return padded


def pad_with_fixed_penalty(matrix: ComplexArray, target_dim: int, penalty: float) -> ComplexArray:
    """Embed a matrix in a chosen larger dimension with a fixed padding penalty.

    This is useful for Pauli-decomposition tables because the physical Lipkin
    Hamiltonian is linear in epsilon, V and W, while an automatically chosen
    penalty would introduce unnecessary parameter dependence.
    """
    matrix = np.asarray(matrix, dtype=complex)
    d = matrix.shape[0]
    if matrix.shape != (d, d):
        raise ValueError("matrix must be square")
    if target_dim < d:
        raise ValueError("target_dim must be at least the matrix dimension")
    padded = np.eye(target_dim, dtype=complex) * penalty
    padded[:d, :d] = matrix
    return padded


def padding_projector(physical_dim: int, target_dim: int) -> ComplexArray:
    """Projector onto padded/unphysical states."""
    if target_dim < physical_dim:
        raise ValueError("target_dim must be at least physical_dim")
    projector = np.zeros((target_dim, target_dim), dtype=complex)
    if target_dim > physical_dim:
        projector[physical_dim:, physical_dim:] = np.eye(target_dim - physical_dim)
    return projector


def pauli_decomposition(matrix: ComplexArray, tol: float = 1e-10) -> dict[str, complex]:
    """Return coefficients c_P in H = sum_P c_P P for a 2^n x 2^n matrix."""
    matrix = np.asarray(matrix, dtype=complex)
    dim = matrix.shape[0]
    if matrix.shape != (dim, dim):
        raise ValueError("matrix must be square")
    n_float = log2(dim)
    if abs(n_float - round(n_float)) > 1e-12:
        raise ValueError("matrix dimension must be a power of two")
    n_qubits = int(round(n_float))
    coeffs: dict[str, complex] = {}
    for label_tuple in product("IXYZ", repeat=n_qubits):
        label = "".join(label_tuple)
        pauli = kron_n(*(PAULI_MATRICES[ch] for ch in label))
        coeff = np.trace(pauli.conj().T @ matrix) / dim
        if abs(coeff) > tol:
            coeffs[label] = complex(np.real_if_close(coeff))
    return coeffs


def reconstruct_from_pauli(coeffs: dict[str, complex]) -> ComplexArray:
    """Reconstruct a matrix from a Pauli-coefficient dictionary."""
    if not coeffs:
        raise ValueError("empty coefficient dictionary")
    first_label = next(iter(coeffs))
    n_qubits = len(first_label)
    dim = 2**n_qubits
    matrix = np.zeros((dim, dim), dtype=complex)
    for label, coeff in coeffs.items():
        matrix += coeff * kron_n(*(PAULI_MATRICES[ch] for ch in label))
    return matrix


def format_pauli_decomposition(coeffs: dict[str, complex], precision: int = 8) -> str:
    """Human-readable Pauli decomposition."""
    parts: list[str] = []
    for label in sorted(coeffs):
        coeff = coeffs[label]
        if abs(coeff.imag) < 10 ** (-(precision - 2)):
            value = f"{coeff.real:.{precision}g}"
        else:
            value = f"({coeff.real:.{precision}g}{coeff.imag:+.{precision}g}j)"
        parts.append(f"{value} {label}")
    return " + ".join(parts) if parts else "0"
