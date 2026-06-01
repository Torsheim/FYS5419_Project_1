#!/usr/bin/env bash
set -euo pipefail

# FYS5419 Project 1 polishing update.
# Run from the repository root: bash FYS5419_Project_1_polish_update.sh
# This does NOT run git add/commit/push.

echo "Applying FYS5419 Project 1 polish update in: $(pwd)"
if [ ! -d src/fys5419_project1 ]; then
  echo "ERROR: src/fys5419_project1 not found. Run this from ~/projects/FYS5419_Project_1" >&2
  exit 1
fi

backup_dir="backup_before_polish_update_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    mkdir -p "$backup_dir/$(dirname "$f")"
    cp "$f" "$backup_dir/$f"
  fi
}

backup_file src/fys5419_project1/__init__.py
backup_file src/fys5419_project1/quantum.py
backup_file src/fys5419_project1/hamiltonians.py
backup_file src/fys5419_project1/vqe.py
backup_file scripts/run_all.py
backup_file tests/test_polish_updates.py

cat > src/fys5419_project1/__init__.py <<'PY'
"""Utilities for FYS5419 Project 1."""

__version__ = "0.1.0"
PY

cat > src/fys5419_project1/quantum.py <<'PY'
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
PY

cat > src/fys5419_project1/hamiltonians.py <<'PY'
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
PY

cat > src/fys5419_project1/vqe.py <<'PY'
"""Minimal VQE tools written from scratch for the project.

The module has two kinds of variational states:

1. Small circuit-inspired ansatz states for one- and two-qubit Hamiltonians.
2. A normalized real-amplitude ansatz for arbitrary real symmetric Hamiltonians.

The second ansatz is useful for the embedded Lipkin Hamiltonians because it spans
all real states in the chosen Hilbert space. Since the project Hamiltonians are
real symmetric, this gives a clean VQE-vs-exact comparison. Excited Lipkin states
are found by sequential orthogonality constraints, which is a variational
excited-state/deflation strategy.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

import numpy as np
from numpy.typing import NDArray
from scipy.optimize import minimize, minimize_scalar

from .quantum import basis_state, cnot_matrix, apply_single_qubit_gate, ry

ComplexArray = NDArray[np.complex128]
RealArray = NDArray[np.float64]


@dataclass(frozen=True)
class VQEResult:
    energy: float
    parameters: RealArray
    state: ComplexArray
    success: bool
    n_iterations: int
    message: str


def expectation_value(state: ComplexArray, hamiltonian: ComplexArray) -> float:
    state = np.asarray(state, dtype=complex).reshape(-1)
    norm = np.vdot(state, state)
    if abs(norm) == 0:
        raise ValueError("zero state has no expectation value")
    energy = np.vdot(state, np.asarray(hamiltonian, dtype=complex) @ state) / norm
    return float(np.real_if_close(energy))


def one_qubit_ry_state(theta: float) -> ComplexArray:
    """Circuit: R_y(theta)|0>."""
    return np.array([np.cos(theta / 2.0), np.sin(theta / 2.0)], dtype=complex)


def vqe_one_qubit_ry(hamiltonian: ComplexArray) -> VQEResult:
    """Exact one-parameter VQE for a real one-qubit Hamiltonian."""

    def objective(theta: float) -> float:
        return expectation_value(one_qubit_ry_state(theta), hamiltonian)

    opt = minimize_scalar(objective, bounds=(-2.0 * np.pi, 2.0 * np.pi), method="bounded")
    theta = float(opt.x)
    state = one_qubit_ry_state(theta)
    return VQEResult(
        energy=float(opt.fun),
        parameters=np.array([theta], dtype=float),
        state=state,
        success=bool(opt.success),
        n_iterations=int(getattr(opt, "nit", 0)),
        message=str(opt.message),
    )


def two_qubit_even_state(theta: float) -> ComplexArray:
    """Circuit: R_y(theta) on q0, then CNOT(0,1), starting from |00>.

    Produces cos(theta/2)|00> + sin(theta/2)|11>.
    """
    state = basis_state("00")
    state = apply_single_qubit_gate(state, ry(theta), qubit=0, n_qubits=2)
    state = cnot_matrix(0, 1, 2) @ state
    return state


def two_qubit_odd_state(theta: float) -> ComplexArray:
    """Circuit: start |01>, R_y(theta) on q0, CNOT(0,1).

    Produces cos(theta/2)|01> + sin(theta/2)|10>.
    """
    state = basis_state("01")
    state = apply_single_qubit_gate(state, ry(theta), qubit=0, n_qubits=2)
    state = cnot_matrix(0, 1, 2) @ state
    return state


def vqe_two_qubit_parity(hamiltonian: ComplexArray) -> tuple[VQEResult, VQEResult, VQEResult]:
    """Run one-parameter VQE in the even and odd parity sectors."""

    def optimize(ansatz: Callable[[float], ComplexArray]) -> VQEResult:
        def objective(theta: float) -> float:
            return expectation_value(ansatz(theta), hamiltonian)

        opt = minimize_scalar(objective, bounds=(-2.0 * np.pi, 2.0 * np.pi), method="bounded")
        theta = float(opt.x)
        state = ansatz(theta)
        return VQEResult(
            energy=float(opt.fun),
            parameters=np.array([theta], dtype=float),
            state=state,
            success=bool(opt.success),
            n_iterations=int(getattr(opt, "nit", 0)),
            message=str(opt.message),
        )

    even = optimize(two_qubit_even_state)
    odd = optimize(two_qubit_odd_state)
    best = even if even.energy <= odd.energy else odd
    return best, even, odd


def normalized_real_state(parameters: RealArray) -> ComplexArray:
    """Full real-amplitude variational ansatz: |psi(a)> = a / ||a||."""
    vec = np.asarray(parameters, dtype=float).reshape(-1)
    norm = np.linalg.norm(vec)
    if norm < 1e-14:
        vec = np.ones_like(vec)
        norm = np.linalg.norm(vec)
    return (vec / norm).astype(complex)


def _rayleigh_objective_and_gradient(h_real: np.ndarray, x: np.ndarray) -> tuple[float, np.ndarray]:
    denom = float(np.dot(x, x))
    if denom < 1e-28:
        return float("inf"), np.zeros_like(x)
    hx = h_real @ x
    energy = float(np.dot(x, hx) / denom)
    gradient = 2.0 * (hx - energy * x) / denom
    return energy, gradient


def vqe_normalized_real(
    hamiltonian: ComplexArray,
    n_restarts: int = 12,
    seed: int = 1234,
    initial_parameters: RealArray | None = None,
    maxiter: int = 2000,
) -> VQEResult:
    """VQE with a normalized real-amplitude ansatz for the ground state."""
    hamiltonian = np.asarray(hamiltonian, dtype=complex)
    dim = hamiltonian.shape[0]
    rng = np.random.default_rng(seed)
    h_real = np.real_if_close(hamiltonian).astype(float)

    def objective(params: RealArray) -> float:
        energy, _gradient = _rayleigh_objective_and_gradient(h_real, np.asarray(params, dtype=float))
        return energy

    def gradient(params: RealArray) -> RealArray:
        _energy, grad = _rayleigh_objective_and_gradient(h_real, np.asarray(params, dtype=float))
        return grad

    starts: list[RealArray] = []
    if initial_parameters is not None:
        starts.append(np.asarray(initial_parameters, dtype=float))
    starts.append(np.ones(dim, dtype=float))
    for basis_index in range(dim):
        if len(starts) >= n_restarts:
            break
        basis_vec = np.zeros(dim, dtype=float)
        basis_vec[basis_index] = 1.0
        starts.append(basis_vec)
    for _ in range(max(0, n_restarts - len(starts))):
        starts.append(rng.normal(size=dim))

    best = None
    for x0 in starts:
        opt = minimize(
            objective,
            x0=x0,
            jac=gradient,
            method="BFGS",
            options={"gtol": 1e-10, "maxiter": maxiter},
        )
        if best is None or float(opt.fun) < float(best.fun):
            best = opt

    assert best is not None
    state = normalized_real_state(best.x)
    return VQEResult(
        energy=float(best.fun),
        parameters=np.asarray(best.x, dtype=float),
        state=state,
        success=bool(best.success) or np.linalg.norm(gradient(best.x)) < 1e-6,
        n_iterations=int(getattr(best, "nit", 0)),
        message=str(best.message),
    )


def _orthogonal_projector(states: list[ComplexArray], dim: int) -> np.ndarray:
    """Projector onto the subspace orthogonal to already found states."""
    if not states:
        return np.eye(dim)
    q_columns: list[np.ndarray] = []
    for state in states:
        vec = np.real_if_close(state).astype(float).reshape(dim)
        for q in q_columns:
            vec = vec - np.dot(q, vec) * q
        norm = np.linalg.norm(vec)
        if norm > 1e-10:
            q_columns.append(vec / norm)
    if not q_columns:
        return np.eye(dim)
    q = np.column_stack(q_columns)
    return np.eye(dim) - q @ q.T


def vqe_orthogonal_real_spectrum(
    hamiltonian: ComplexArray,
    n_levels: int,
    n_restarts: int = 16,
    seed: int = 1234,
    maxiter: int = 3000,
) -> list[VQEResult]:
    """Sequential variational solver for several eigenvalues.

    For level k, the ansatz vector is projected to the subspace orthogonal to the
    already optimized lower states. Minimizing the Rayleigh quotient in this
    subspace is a standard deflation/orthogonality-constrained VQE strategy. For
    these small real symmetric Hamiltonians, the ansatz spans the full embedded
    Hilbert space, so the result should match exact diagonalization up to roundoff.
    """
    hamiltonian = np.asarray(hamiltonian, dtype=complex)
    if hamiltonian.shape[0] != hamiltonian.shape[1]:
        raise ValueError("hamiltonian must be square")
    dim = hamiltonian.shape[0]
    if not 1 <= n_levels <= dim:
        raise ValueError("n_levels must be between 1 and the Hilbert-space dimension")
    h_real = np.real_if_close(hamiltonian).astype(float)
    rng = np.random.default_rng(seed)

    results: list[VQEResult] = []
    previous_states: list[ComplexArray] = []

    for level in range(n_levels):
        projector = _orthogonal_projector(previous_states, dim)

        def project(params: RealArray) -> np.ndarray:
            return projector @ np.asarray(params, dtype=float)

        def objective(params: RealArray) -> float:
            y = project(params)
            energy, _grad_y = _rayleigh_objective_and_gradient(h_real, y)
            return energy

        def gradient(params: RealArray) -> RealArray:
            y = project(params)
            _energy, grad_y = _rayleigh_objective_and_gradient(h_real, y)
            return projector @ grad_y

        starts: list[np.ndarray] = []
        for basis_index in range(dim):
            basis_vec = np.zeros(dim, dtype=float)
            basis_vec[basis_index] = 1.0
            projected = project(basis_vec)
            if np.linalg.norm(projected) > 1e-8:
                starts.append(projected)
        while len(starts) < n_restarts:
            candidate = project(rng.normal(size=dim))
            if np.linalg.norm(candidate) > 1e-8:
                starts.append(candidate)

        best = None
        for x0 in starts[:n_restarts]:
            opt = minimize(
                objective,
                x0=x0,
                jac=gradient,
                method="BFGS",
                options={"gtol": 1e-10, "maxiter": maxiter},
            )
            if best is None or float(opt.fun) < float(best.fun):
                best = opt

        assert best is not None
        projected_best = project(best.x)
        state = normalized_real_state(projected_best)
        energy = expectation_value(state, hamiltonian)
        grad_norm = np.linalg.norm(gradient(best.x))
        result = VQEResult(
            energy=energy,
            parameters=np.asarray(best.x, dtype=float),
            state=state,
            success=bool(best.success) or grad_norm < 1e-6,
            n_iterations=int(getattr(best, "nit", 0)),
            message=str(best.message),
        )
        results.append(result)
        previous_states.append(state)

    return results


def hardware_efficient_state(
    parameters: RealArray, n_qubits: int, layers: int = 1
) -> ComplexArray:
    """Simple real-amplitude circuit ansatz using R_y rotations and a CNOT chain."""
    expected = (layers + 1) * n_qubits
    parameters = np.asarray(parameters, dtype=float)
    if parameters.size != expected:
        raise ValueError(f"expected {expected} parameters, got {parameters.size}")

    state = basis_state("0" * n_qubits)
    index = 0
    for _layer in range(layers):
        for q in range(n_qubits):
            state = apply_single_qubit_gate(state, ry(parameters[index]), q, n_qubits)
            index += 1
        for q in range(n_qubits - 1):
            state = cnot_matrix(q, q + 1, n_qubits) @ state
    for q in range(n_qubits):
        state = apply_single_qubit_gate(state, ry(parameters[index]), q, n_qubits)
        index += 1
    return state
PY

cat > scripts/run_all.py <<'PY'
#!/usr/bin/env python3
"""Run all numerical experiments for FYS5419 Project 1.

The script creates CSV files and figures for the report. It does not require
Qiskit/PennyLane; the VQE code used here is the small implementation in src/.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from fys5419_project1.hamiltonians import (
    format_pauli_decomposition,
    lipkin_j1,
    lipkin_j2,
    one_qubit_hamiltonian,
    one_qubit_pauli_coefficients,
    pad_to_power_of_two,
    padding_projector,
    pauli_decomposition,
    sorted_eigh,
    two_qubit_hamiltonian,
)
from fys5419_project1.quantum import (
    HADAMARD,
    PHASE_S,
    X,
    Y,
    Z,
    bell_state,
    density_matrix,
    format_state_vector,
    ket0,
    ket1,
    marginal_probabilities_for_qubit,
    measure_full_state,
    measure_qubit,
    measurement_average_from_counts,
    prepare_bell_with_h_and_cnot,
    reduced_density_matrix,
    von_neumann_entropy,
)
from fys5419_project1.vqe import (
    vqe_normalized_real,
    vqe_one_qubit_ry,
    vqe_orthogonal_real_spectrum,
    vqe_two_qubit_parity,
)

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "results" / "data"
FIG = ROOT / "results" / "figures"


def savefig(name: str) -> None:
    FIG.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(FIG / name, dpi=200)
    plt.close()


def _format_count_dict(counts: dict[str, int]) -> str:
    return "{" + ", ".join(f"'{key}': {value}" for key, value in sorted(counts.items())) + "}"


def _stringify_coeff(value: complex, tol: float = 1e-12) -> str:
    value = complex(value)
    if abs(value.imag) < tol:
        return f"{value.real:.12g}"
    return f"{value.real:.12g}{value.imag:+.12g}j"


def _linear_expression(coeffs: dict[str, complex], symbols: dict[str, str], tol: float = 1e-12) -> str:
    parts: list[str] = []
    for key, symbol in symbols.items():
        coeff = complex(coeffs.get(key, 0.0))
        if abs(coeff) <= tol:
            continue
        value = coeff.real if abs(coeff.imag) <= tol else coeff
        if isinstance(value, complex):
            parts.append(f"({_stringify_coeff(value)}) {symbol}")
        else:
            if abs(value - 1.0) <= tol:
                parts.append(symbol)
            elif abs(value + 1.0) <= tol:
                parts.append(f"-{symbol}")
            else:
                parts.append(f"{value:.12g} {symbol}")
    return " + ".join(parts).replace("+ -", "- ") if parts else "0"


def run_part_a() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    zero, one = ket0(), ket1()
    gates = {"X": X, "Y": Y, "Z": Z, "H": HADAMARD, "S": PHASE_S}

    lines: list[str] = []
    lines.append("Part a: one-qubit gate actions")
    for gate_name, gate in gates.items():
        lines.append(f"{gate_name}|0> = {format_state_vector(gate @ zero)}")
        lines.append(f"{gate_name}|1> = {format_state_vector(gate @ one)}")

    prepared = prepare_bell_with_h_and_cnot()
    phi_plus = bell_state("phi_plus")
    overlap_probability = abs(np.vdot(phi_plus, prepared)) ** 2
    lines.append("\nBell-state preparation")
    lines.append(f"Prepared state from H+CNOT = {format_state_vector(prepared)}")
    lines.append(f"Target |Phi+>              = {format_state_vector(phi_plus)}")
    lines.append(f"Overlap probability        = {overlap_probability:.12f}")

    shots = 5000
    counts_full = measure_full_state(prepared, shots=shots, seed=2026)
    counts_q0 = measure_qubit(prepared, qubit=0, shots=shots, seed=2027)
    counts_q1 = measure_qubit(prepared, qubit=1, shots=shots, seed=2028)
    exact_q0 = marginal_probabilities_for_qubit(prepared, 0)
    exact_q1 = marginal_probabilities_for_qubit(prepared, 1)

    lines.append(f"\nMeasurement results with {shots} shots")
    lines.append(f"Full bitstrings: {_format_count_dict(counts_full)}")
    lines.append(
        f"Qubit 0: {_format_count_dict(counts_q0)}; "
        f"sample mean = {measurement_average_from_counts(counts_q0):.6f}; "
        f"exact probabilities = {exact_q0}"
    )
    lines.append(
        f"Qubit 1: {_format_count_dict(counts_q1)}; "
        f"sample mean = {measurement_average_from_counts(counts_q1):.6f}; "
        f"exact probabilities = {exact_q1}"
    )
    lines.append(
        f"Full-count means: <q0> = {measurement_average_from_counts(counts_full, qubit=0):.6f}, "
        f"<q1> = {measurement_average_from_counts(counts_full, qubit=1):.6f}"
    )

    measurement_rows = []
    for label, count in sorted(counts_full.items()):
        measurement_rows.append(
            {
                "basis_state": label,
                "counts": count,
                "frequency": count / shots,
                "exact_probability": float(abs(prepared[int(label, 2)]) ** 2),
            }
        )
    pd.DataFrame(measurement_rows).to_csv(DATA / "part_a_measurements.csv", index=False)

    rho = density_matrix(prepared)
    rho_a = reduced_density_matrix(prepared, keep=[0])
    rho_b = reduced_density_matrix(prepared, keep=[1])
    lines.append("\nDensity matrices and entropy")
    lines.append(f"rho =\n{np.array2string(rho, precision=6, suppress_small=True)}")
    lines.append(f"rho_A =\n{np.array2string(rho_a, precision=6, suppress_small=True)}")
    lines.append(f"rho_B =\n{np.array2string(rho_b, precision=6, suppress_small=True)}")
    lines.append(f"S(rho_A) = {von_neumann_entropy(rho_a):.12f}")
    lines.append(f"S(rho_B) = {von_neumann_entropy(rho_b):.12f}")

    (DATA / "part_a_summary.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_parts_b_c() -> None:
    lambdas = np.linspace(0.0, 1.0, 101)
    exact_rows = []
    vqe_rows = []
    for lam in lambdas:
        H = one_qubit_hamiltonian(lam)
        evals, evecs = sorted_eigh(H)
        ground = evecs[:, 0]
        coeffs = one_qubit_pauli_coefficients(lam)
        exact_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E1_exact": evals[1],
                "ground_weight_0": abs(ground[0]) ** 2,
                "ground_weight_1": abs(ground[1]) ** 2,
                "c_I": coeffs["I"],
                "c_X": coeffs["X"],
                "c_Z": coeffs["Z"],
            }
        )
        vqe = vqe_one_qubit_ry(H)
        vqe_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E0_vqe": vqe.energy,
                "abs_error": abs(vqe.energy - evals[0]),
                "theta": vqe.parameters[0],
                "success": vqe.success,
            }
        )

    exact_df = pd.DataFrame(exact_rows)
    vqe_df = pd.DataFrame(vqe_rows)
    exact_df.to_csv(DATA / "part_b_one_qubit_exact.csv", index=False)
    vqe_df.to_csv(DATA / "part_c_one_qubit_vqe.csv", index=False)

    plt.figure()
    plt.plot(exact_df["lambda"], exact_df["E0_exact"], label="E0")
    plt.plot(exact_df["lambda"], exact_df["E1_exact"], label="E1")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.title("One-qubit Hamiltonian: exact eigenvalues")
    plt.legend()
    savefig("part_b_one_qubit_eigenvalues.png")

    plt.figure()
    plt.plot(exact_df["lambda"], exact_df["ground_weight_0"], label=r"$|\langle 0|\psi_0\rangle|^2$")
    plt.plot(exact_df["lambda"], exact_df["ground_weight_1"], label=r"$|\langle 1|\psi_0\rangle|^2$")
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Weight")
    plt.title("One-qubit ground-state composition")
    plt.legend()
    savefig("part_b_one_qubit_weights.png")

    plt.figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
    plt.title("One-qubit VQE error")
    savefig("part_c_one_qubit_vqe_error.png")


def run_parts_d_e() -> None:
    lambdas = np.linspace(0.0, 1.0, 101)
    exact_rows = []
    vqe_rows = []
    for lam in lambdas:
        H = two_qubit_hamiltonian(lam)
        evals, evecs = sorted_eigh(H)
        ground = evecs[:, 0]
        rho_a = reduced_density_matrix(ground, keep=[0])
        entropy_a = von_neumann_entropy(rho_a)
        exact_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E1_exact": evals[1],
                "E2_exact": evals[2],
                "E3_exact": evals[3],
                "entropy_A_ground": entropy_a,
                "weight_00": abs(ground[0]) ** 2,
                "weight_01": abs(ground[1]) ** 2,
                "weight_10": abs(ground[2]) ** 2,
                "weight_11": abs(ground[3]) ** 2,
            }
        )
        best, even, odd = vqe_two_qubit_parity(H)
        vqe_rows.append(
            {
                "lambda": lam,
                "E0_exact": evals[0],
                "E0_vqe": best.energy,
                "E_even": even.energy,
                "E_odd": odd.energy,
                "abs_error": abs(best.energy - evals[0]),
                "best_sector": "even" if even.energy <= odd.energy else "odd",
            }
        )

    exact_df = pd.DataFrame(exact_rows)
    vqe_df = pd.DataFrame(vqe_rows)
    exact_df.to_csv(DATA / "part_d_two_qubit_exact_entropy.csv", index=False)
    vqe_df.to_csv(DATA / "part_e_two_qubit_vqe.csv", index=False)

    plt.figure()
    for col in ["E0_exact", "E1_exact", "E2_exact", "E3_exact"]:
        plt.plot(exact_df["lambda"], exact_df[col], label=col.replace("_exact", ""))
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Energy")
    plt.title("Two-qubit Hamiltonian: exact eigenvalues")
    plt.legend()
    savefig("part_d_two_qubit_eigenvalues.png")

    plt.figure()
    plt.plot(exact_df["lambda"], exact_df["entropy_A_ground"])
    plt.xlabel(r"$\lambda$")
    plt.ylabel(r"$S(\rho_A)$")
    plt.title("Two-qubit ground-state entanglement entropy")
    savefig("part_d_two_qubit_entropy.png")

    plt.figure()
    plt.semilogy(vqe_df["lambda"], vqe_df["abs_error"] + 1e-16)
    plt.xlabel(r"$\lambda$")
    plt.ylabel("Absolute error")
    plt.title("Two-qubit VQE error")
    savefig("part_e_two_qubit_vqe_error.png")


def _pauli_component_table(J: int) -> pd.DataFrame:
    """General Pauli coefficient table for embedded Lipkin Hamiltonians.

    The returned coefficients define
      c_P = c_epsilon*epsilon + c_V*V + c_W*W + c_padding*Delta.
    Delta is the fixed energy assigned to padded/unphysical basis states.
    """
    if J == 1:
        target_dim = 4
        components = {
            "epsilon": np.pad(lipkin_j1(epsilon=1.0, V=0.0), ((0, 1), (0, 1))),
            "V": np.pad(lipkin_j1(epsilon=0.0, V=1.0), ((0, 1), (0, 1))),
            "W": np.zeros((4, 4), dtype=complex),
            "padding": padding_projector(physical_dim=3, target_dim=4),
        }
    elif J == 2:
        target_dim = 8
        components = {
            "epsilon": np.pad(lipkin_j2(epsilon=1.0, V=0.0, W=0.0), ((0, 3), (0, 3))),
            "V": np.pad(lipkin_j2(epsilon=0.0, V=1.0, W=0.0), ((0, 3), (0, 3))),
            "W": np.pad(lipkin_j2(epsilon=0.0, V=0.0, W=1.0), ((0, 3), (0, 3))),
            "padding": padding_projector(physical_dim=5, target_dim=8),
        }
    else:
        raise ValueError("Only J=1 and J=2 are implemented")

    decomposed = {name: pauli_decomposition(matrix, tol=1e-12) for name, matrix in components.items()}
    labels = sorted(set().union(*(coeffs.keys() for coeffs in decomposed.values())))
    rows = []
    for label in labels:
        coeffs_for_label = {name: decomposed[name].get(label, 0.0) for name in components}
        if all(abs(value) < 1e-12 for value in coeffs_for_label.values()):
            continue
        row = {"pauli": label}
        row.update({f"c_{name}": float(np.real_if_close(value).real) for name, value in coeffs_for_label.items()})
        row["coefficient_expression"] = _linear_expression(
            coeffs_for_label,
            {"epsilon": "epsilon", "V": "V", "W": "W", "padding": "Delta"},
        )
        rows.append(row)
    return pd.DataFrame(rows)


def _write_pauli_tables() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    for J in (1, 2):
        table = _pauli_component_table(J)
        table.to_csv(DATA / f"part_f_lipkin_j{J}_pauli_symbolic.csv", index=False)

    lines = []
    for J in (1, 2):
        table = pd.read_csv(DATA / f"part_f_lipkin_j{J}_pauli_symbolic.csv")
        lines.append(f"J={J}: embedded Hamiltonian Pauli coefficients")
        lines.append("H = sum_P c_P P, c_P = c_epsilon*epsilon + c_V*V + c_W*W + c_padding*Delta")
        for _, row in table.iterrows():
            lines.append(f"{row['pauli']:>3s}: {row['coefficient_expression']}")
        lines.append("")
    (DATA / "part_f_lipkin_pauli_symbolic.txt").write_text("\n".join(lines), encoding="utf-8")

    # Keep a compact numerical example too, but label the padding energy explicitly.
    epsilon = 1.0
    sample_V = 0.5
    sample_W = 0.2
    padding_delta = 20.0
    numerical_examples = []
    examples = [
        ("J=1, W=0, Delta=20, padded to 2 qubits", np.pad(lipkin_j1(epsilon, sample_V), ((0, 1), (0, 1))) + padding_delta * padding_projector(3, 4)),
        ("J=2, W=0, Delta=20, padded to 3 qubits", np.pad(lipkin_j2(epsilon, sample_V, W=0.0), ((0, 3), (0, 3))) + padding_delta * padding_projector(5, 8)),
        ("J=2, W=0.2, Delta=20, padded to 3 qubits", np.pad(lipkin_j2(epsilon, sample_V, W=sample_W), ((0, 3), (0, 3))) + padding_delta * padding_projector(5, 8)),
    ]
    for name, H in examples:
        numerical_examples.append(f"{name}\n{format_pauli_decomposition(pauli_decomposition(H))}\n")
    (DATA / "part_f_lipkin_pauli_decompositions.txt").write_text("\n".join(numerical_examples), encoding="utf-8")


def _vqe_spectrum_dataframe(J: int, V_values: np.ndarray, epsilon: float, W: float) -> pd.DataFrame:
    rows = []
    physical_dim = 2 * J + 1
    for i, V in enumerate(V_values):
        H = lipkin_j1(epsilon=epsilon, V=V) if J == 1 else lipkin_j2(epsilon=epsilon, V=V, W=W)
        exact, _ = sorted_eigh(H)
        H_pad = pad_to_power_of_two(H)
        vqe_results = vqe_orthogonal_real_spectrum(
            H_pad,
            n_levels=physical_dim,
            n_restarts=18 if J == 1 else 24,
            seed=4000 + 100 * J + i,
        )
        row = {"J": J, "V": V}
        errors = []
        for level in range(physical_dim):
            error = abs(vqe_results[level].energy - exact[level])
            errors.append(error)
            row[f"exact_E{level}"] = exact[level]
            row[f"vqe_E{level}"] = vqe_results[level].energy
            row[f"abs_error_E{level}"] = error
            row[f"success_E{level}"] = vqe_results[level].success
            row[f"iterations_E{level}"] = vqe_results[level].n_iterations
        row["max_abs_error"] = max(errors)
        rows.append(row)
    return pd.DataFrame(rows)


def run_parts_f_g() -> None:
    epsilon = 1.0
    W = 0.0
    V_values = np.linspace(0.0, 2.0, 31)

    j1_rows = []
    j2_rows = []
    vqe_ground_j1_rows = []
    vqe_ground_j2_rows = []

    previous_j1_params = None
    previous_j2_params = None
    for i, V in enumerate(V_values):
        H1 = lipkin_j1(epsilon=epsilon, V=V)
        H2 = lipkin_j2(epsilon=epsilon, V=V, W=W)
        e1, _ = sorted_eigh(H1)
        e2, _ = sorted_eigh(H2)
        j1_rows.append({"V": V, **{f"E{k}": value for k, value in enumerate(e1)}})
        j2_rows.append({"V": V, **{f"E{k}": value for k, value in enumerate(e2)}})

        H1_pad = pad_to_power_of_two(H1)
        H2_pad = pad_to_power_of_two(H2)
        vqe1 = vqe_normalized_real(
            H1_pad,
            n_restarts=4,
            seed=1000 + i,
            initial_parameters=previous_j1_params,
        )
        vqe2 = vqe_normalized_real(
            H2_pad,
            n_restarts=5,
            seed=2000 + i,
            initial_parameters=previous_j2_params,
        )
        previous_j1_params = vqe1.parameters
        previous_j2_params = vqe2.parameters
        vqe_ground_j1_rows.append(
            {
                "V": V,
                "E0_exact": e1[0],
                "E0_vqe": vqe1.energy,
                "abs_error": abs(vqe1.energy - e1[0]),
                "success": vqe1.success,
            }
        )
        vqe_ground_j2_rows.append(
            {
                "V": V,
                "E0_exact": e2[0],
                "E0_vqe": vqe2.energy,
                "abs_error": abs(vqe2.energy - e2[0]),
                "success": vqe2.success,
            }
        )

    j1_df = pd.DataFrame(j1_rows)
    j2_df = pd.DataFrame(j2_rows)
    vqe_ground_j1_df = pd.DataFrame(vqe_ground_j1_rows)
    vqe_ground_j2_df = pd.DataFrame(vqe_ground_j2_rows)
    j1_df.to_csv(DATA / "part_f_lipkin_j1_exact.csv", index=False)
    j2_df.to_csv(DATA / "part_f_lipkin_j2_exact.csv", index=False)
    vqe_ground_j1_df.to_csv(DATA / "part_g_lipkin_j1_vqe.csv", index=False)
    vqe_ground_j2_df.to_csv(DATA / "part_g_lipkin_j2_vqe.csv", index=False)

    # New for part g: VQE estimates for the same eigenvalues as in part f.
    vqe_spectrum_j1_df = _vqe_spectrum_dataframe(J=1, V_values=V_values, epsilon=epsilon, W=W)
    vqe_spectrum_j2_df = _vqe_spectrum_dataframe(J=2, V_values=V_values, epsilon=epsilon, W=W)
    vqe_spectrum_j1_df.to_csv(DATA / "part_g_lipkin_j1_vqe_spectrum.csv", index=False)
    vqe_spectrum_j2_df.to_csv(DATA / "part_g_lipkin_j2_vqe_spectrum.csv", index=False)

    _write_pauli_tables()

    plt.figure()
    for col in [c for c in j1_df.columns if c.startswith("E")]:
        plt.plot(j1_df["V"], j1_df[col], label=col)
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=1$: exact eigenvalues")
    plt.legend()
    savefig("part_f_lipkin_j1_exact.png")

    plt.figure()
    for col in [c for c in j2_df.columns if c.startswith("E")]:
        plt.plot(j2_df["V"], j2_df[col], label=col)
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=2$: exact eigenvalues")
    plt.legend()
    savefig("part_f_lipkin_j2_exact.png")

    plt.figure()
    for level in range(3):
        plt.plot(vqe_spectrum_j1_df["V"], vqe_spectrum_j1_df[f"exact_E{level}"], label=f"Exact E{level}")
        plt.scatter(vqe_spectrum_j1_df["V"], vqe_spectrum_j1_df[f"vqe_E{level}"], s=10, marker="x", label=f"VQE E{level}")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=1$: excited-state VQE spectrum")
    plt.legend(ncol=2, fontsize=8)
    savefig("part_g_lipkin_j1_vqe_spectrum.png")

    plt.figure()
    for level in range(5):
        plt.plot(vqe_spectrum_j2_df["V"], vqe_spectrum_j2_df[f"exact_E{level}"], label=f"Exact E{level}")
        plt.scatter(vqe_spectrum_j2_df["V"], vqe_spectrum_j2_df[f"vqe_E{level}"], s=10, marker="x", label=f"VQE E{level}")
    plt.xlabel(r"$V$")
    plt.ylabel("Energy")
    plt.title(r"Lipkin $J=2$: excited-state VQE spectrum")
    plt.legend(ncol=2, fontsize=7)
    savefig("part_g_lipkin_j2_vqe_spectrum.png")

    plt.figure()
    plt.semilogy(vqe_spectrum_j1_df["V"], vqe_spectrum_j1_df["max_abs_error"] + 1e-16, label="J=1, all levels")
    plt.semilogy(vqe_spectrum_j2_df["V"], vqe_spectrum_j2_df["max_abs_error"] + 1e-16, label="J=2, all levels")
    plt.xlabel(r"$V$")
    plt.ylabel("Maximum absolute error")
    plt.title("Lipkin VQE spectrum error")
    plt.legend()
    savefig("part_g_lipkin_vqe_error.png")


def main() -> None:
    DATA.mkdir(parents=True, exist_ok=True)
    FIG.mkdir(parents=True, exist_ok=True)
    run_part_a()
    run_parts_b_c()
    run_parts_d_e()
    run_parts_f_g()
    print(f"Wrote data to {DATA}")
    print(f"Wrote figures to {FIG}")
    print("New/updated important files:")
    print("  results/data/part_a_summary.txt")
    print("  results/data/part_f_lipkin_j1_pauli_symbolic.csv")
    print("  results/data/part_f_lipkin_j2_pauli_symbolic.csv")
    print("  results/data/part_g_lipkin_j1_vqe_spectrum.csv")
    print("  results/data/part_g_lipkin_j2_vqe_spectrum.csv")
    print("  results/figures/part_g_lipkin_j1_vqe_spectrum.png")
    print("  results/figures/part_g_lipkin_j2_vqe_spectrum.png")


if __name__ == "__main__":
    main()
PY

cat > tests/test_polish_updates.py <<'PY'
import numpy as np

from fys5419_project1.hamiltonians import lipkin_j1, pad_to_power_of_two, sorted_eigh
from fys5419_project1.quantum import bell_state, measure_full_state, measure_qubit
from fys5419_project1.vqe import vqe_orthogonal_real_spectrum


def test_measurement_keys_are_plain_python_strings() -> None:
    state = bell_state("phi_plus")
    counts_full = measure_full_state(state, shots=20, seed=1)
    counts_single = measure_qubit(state, qubit=0, shots=20, seed=2)
    assert all(type(key) is str for key in counts_full)
    assert all(type(key) is str for key in counts_single)


def test_orthogonal_vqe_lipkin_j1_spectrum_matches_exact() -> None:
    H = lipkin_j1(epsilon=1.0, V=0.7)
    exact, _ = sorted_eigh(H)
    H_pad = pad_to_power_of_two(H)
    results = vqe_orthogonal_real_spectrum(H_pad, n_levels=3, n_restarts=12, seed=17)
    vqe_values = np.array([result.energy for result in results])
    assert np.allclose(vqe_values, exact, atol=1e-7)
PY

chmod +x scripts/run_all.py

echo "Update complete. Backups are in: $backup_dir"
echo "No git add/commit/push was run."
