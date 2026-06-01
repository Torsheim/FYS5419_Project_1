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
