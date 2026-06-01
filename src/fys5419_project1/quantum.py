"""Small state-vector quantum utilities for FYS5419 Project 1.

Conventions
-----------
Qubit 0 is the leftmost / most significant qubit. For two qubits the basis order is
|00>, |01>, |10>, |11>.
"""

from __future__ import annotations

from collections import Counter
from typing import Iterable

import numpy as np
from numpy.typing import NDArray

ComplexArray = NDArray[np.complex128]
RealArray = NDArray[np.float64]

I2: ComplexArray = np.array([[1, 0], [0, 1]], dtype=complex)
X: ComplexArray = np.array([[0, 1], [1, 0]], dtype=complex)
Y: ComplexArray = np.array([[0, -1j], [1j, 0]], dtype=complex)
Z: ComplexArray = np.array([[1, 0], [0, -1]], dtype=complex)
HADAMARD: ComplexArray = (1.0 / np.sqrt(2.0)) * np.array([[1, 1], [1, -1]], dtype=complex)
PHASE_S: ComplexArray = np.array([[1, 0], [0, 1j]], dtype=complex)

PAULI_MATRICES: dict[str, ComplexArray] = {
    "I": I2,
    "X": X,
    "Y": Y,
    "Z": Z,
}


def ket0() -> ComplexArray:
    return np.array([1, 0], dtype=complex)


def ket1() -> ComplexArray:
    return np.array([0, 1], dtype=complex)


def one_qubit_basis() -> tuple[ComplexArray, ComplexArray]:
    return ket0(), ket1()


def basis_state(bitstring: str) -> ComplexArray:
    """Return computational basis vector for a bitstring such as '010'."""
    if any(bit not in "01" for bit in bitstring):
        raise ValueError("bitstring must contain only 0 and 1")
    index = int(bitstring, 2) if bitstring else 0
    state = np.zeros(2 ** len(bitstring), dtype=complex)
    state[index] = 1.0
    return state


def kron_n(*operators: ComplexArray) -> ComplexArray:
    """Kronecker product of all input arrays."""
    if not operators:
        raise ValueError("at least one operator is required")
    out = np.asarray(operators[0], dtype=complex)
    for op in operators[1:]:
        out = np.kron(out, np.asarray(op, dtype=complex))
    return out


def normalize(state: ComplexArray) -> ComplexArray:
    norm = np.linalg.norm(state)
    if norm == 0:
        raise ValueError("cannot normalize the zero vector")
    return np.asarray(state, dtype=complex) / norm


def density_matrix(state: ComplexArray) -> ComplexArray:
    state = normalize(state).reshape(-1)
    return np.outer(state, state.conj())


def apply_single_qubit_gate(
    state: ComplexArray, gate: ComplexArray, qubit: int, n_qubits: int
) -> ComplexArray:
    """Apply a one-qubit gate to a state vector.

    Qubit 0 is the leftmost qubit. For example, in a two-qubit state, qubit 0 acts
    on the first bit in |q0 q1>.
    """
    if not 0 <= qubit < n_qubits:
        raise ValueError("qubit index out of range")
    ops = [I2] * n_qubits
    ops[qubit] = np.asarray(gate, dtype=complex)
    return kron_n(*ops) @ np.asarray(state, dtype=complex)


def cnot_matrix(control: int, target: int, n_qubits: int) -> ComplexArray:
    """Return the CNOT matrix with the given control and target qubits."""
    if control == target:
        raise ValueError("control and target must be different")
    if not 0 <= control < n_qubits or not 0 <= target < n_qubits:
        raise ValueError("qubit index out of range")

    dim = 2**n_qubits
    matrix = np.zeros((dim, dim), dtype=complex)
    for integer in range(dim):
        bits = list(format(integer, f"0{n_qubits}b"))
        if bits[control] == "1":
            bits[target] = "0" if bits[target] == "1" else "1"
        new_integer = int("".join(bits), 2)
        matrix[new_integer, integer] = 1.0
    return matrix


def bell_state(label: str = "phi_plus") -> ComplexArray:
    """Return one of the four Bell states in basis |00>, |01>, |10>, |11>."""
    label = label.lower()
    states = {
        "phi_plus": basis_state("00") + basis_state("11"),
        "phi_minus": basis_state("00") - basis_state("11"),
        "psi_plus": basis_state("01") + basis_state("10"),
        "psi_minus": basis_state("01") - basis_state("10"),
    }
    if label not in states:
        raise ValueError(f"unknown Bell state {label!r}")
    return normalize(states[label])


def prepare_bell_with_h_and_cnot() -> ComplexArray:
    """Prepare |Phi+> from |00> using H on qubit 0 followed by CNOT 0->1."""
    state = basis_state("00")
    state = apply_single_qubit_gate(state, HADAMARD, qubit=0, n_qubits=2)
    state = cnot_matrix(control=0, target=1, n_qubits=2) @ state
    return normalize(state)


def bit_probabilities(state: ComplexArray) -> RealArray:
    state = normalize(np.asarray(state, dtype=complex))
    return np.abs(state) ** 2


def _clean_counter(draws: Iterable[object]) -> dict[str, int]:
    """Return a sorted Counter with plain Python str/int entries.

    NumPy random sampling can otherwise produce keys displayed as np.str_('00'),
    which is correct but ugly in the report.
    """
    counter = Counter(str(draw) for draw in draws)
    return {key: int(counter[key]) for key in sorted(counter)}


def measure_full_state(
    state: ComplexArray, shots: int = 1024, seed: int | None = None
) -> dict[str, int]:
    """Sample complete computational-basis bitstrings from a state vector."""
    state = normalize(state)
    n_qubits = int(np.log2(state.size))
    if 2**n_qubits != state.size:
        raise ValueError("state length must be a power of two")
    labels = np.array([format(i, f"0{n_qubits}b") for i in range(state.size)], dtype=str)
    rng = np.random.default_rng(seed)
    draws = rng.choice(labels, size=shots, p=bit_probabilities(state))
    return _clean_counter(draws)


def marginal_probabilities_for_qubit(state: ComplexArray, qubit: int) -> dict[str, float]:
    """Exact marginal probabilities for measuring a selected qubit."""
    state = normalize(state)
    n_qubits = int(np.log2(state.size))
    if not 0 <= qubit < n_qubits:
        raise ValueError("qubit index out of range")
    probs = {"0": 0.0, "1": 0.0}
    for integer, probability in enumerate(bit_probabilities(state)):
        bit = format(integer, f"0{n_qubits}b")[qubit]
        probs[bit] += float(probability)
    return probs


def measure_qubit(
    state: ComplexArray, qubit: int, shots: int = 1024, seed: int | None = None
) -> dict[str, int]:
    """Sample measurements of a selected qubit without state collapse between shots."""
    probabilities = marginal_probabilities_for_qubit(state, qubit)
    rng = np.random.default_rng(seed)
    labels = np.array(["0", "1"], dtype=str)
    p = np.array([probabilities["0"], probabilities["1"]])
    draws = rng.choice(labels, size=shots, p=p)
    return _clean_counter(draws)


def measurement_average_from_counts(counts: dict[str, int], qubit: int | None = None) -> float:
    """Average measured bit value from bitstring or single-qubit counts.

    If qubit is None, the keys are expected to be '0'/'1'. If qubit is an integer,
    the keys are full bitstrings and the selected bit is averaged.
    """
    total = sum(counts.values())
    if total <= 0:
        raise ValueError("counts must contain at least one shot")
    acc = 0.0
    for outcome, count in counts.items():
        bit = outcome if qubit is None else outcome[qubit]
        acc += int(bit) * count
    return acc / total


def partial_trace(
    rho: ComplexArray, dims: Iterable[int], keep: Iterable[int]
) -> ComplexArray:
    """Trace out all subsystems except those listed in keep.

    Parameters
    ----------
    rho:
        Density matrix of the full system.
    dims:
        Dimensions of subsystems, e.g. [2, 2] for two qubits.
    keep:
        Indices of subsystems to keep. With two qubits, keep=[0] returns rho_A.
    """
    dims = list(dims)
    keep = list(keep)
    n = len(dims)
    if sorted(keep) != keep:
        raise ValueError("keep must be sorted")
    if any(k < 0 or k >= n for k in keep):
        raise ValueError("subsystem index out of range")

    trace_over = [i for i in range(n) if i not in keep]
    reshaped = np.asarray(rho, dtype=complex).reshape(dims + dims)

    current_dims = list(dims)
    current_n = n
    for subsystem in sorted(trace_over, reverse=True):
        reshaped = np.trace(reshaped, axis1=subsystem, axis2=subsystem + current_n)
        current_dims.pop(subsystem)
        current_n -= 1

    kept_dims = [dims[i] for i in keep]
    final_dim = int(np.prod(kept_dims))
    return reshaped.reshape((final_dim, final_dim))


def reduced_density_matrix(
    state: ComplexArray, keep: Iterable[int], dims: Iterable[int] | None = None
) -> ComplexArray:
    state = normalize(state)
    if dims is None:
        n_qubits = int(np.log2(state.size))
        dims = [2] * n_qubits
    return partial_trace(density_matrix(state), dims=dims, keep=keep)


def von_neumann_entropy(rho: ComplexArray, base: float = 2.0, tol: float = 1e-12) -> float:
    """Compute S(rho) = -Tr rho log_base(rho)."""
    eigenvalues = np.linalg.eigvalsh(np.asarray(rho, dtype=complex))
    eigenvalues = np.real_if_close(eigenvalues).astype(float)
    eigenvalues = eigenvalues[eigenvalues > tol]
    if eigenvalues.size == 0:
        return 0.0
    return float(-np.sum(eigenvalues * np.log(eigenvalues) / np.log(base)))


def ry(theta: float) -> ComplexArray:
    c = np.cos(theta / 2.0)
    s = np.sin(theta / 2.0)
    return np.array([[c, -s], [s, c]], dtype=complex)


def rz(theta: float) -> ComplexArray:
    return np.array(
        [[np.exp(-0.5j * theta), 0], [0, np.exp(0.5j * theta)]], dtype=complex
    )


def format_state_vector(state: ComplexArray, precision: int = 6) -> str:
    """Compact state-vector string for report tables."""
    state = np.asarray(state, dtype=complex)
    return np.array2string(state, precision=precision, suppress_small=True)
