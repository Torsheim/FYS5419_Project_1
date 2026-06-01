"""Minimal VQE tools written from scratch for the project.

The module has two kinds of variational states:

1. Small circuit-inspired ansatz states for one- and two-qubit Hamiltonians.
2. A normalized real-amplitude ansatz for arbitrary real symmetric Hamiltonians.

The second ansatz is useful for the embedded Lipkin Hamiltonians because it spans
the full real Hilbert space and therefore gives a clean VQE-vs-exact comparison.
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
    """Run one-parameter VQE in the even and odd parity sectors.

    The two-qubit Hamiltonian in this project has two uncoupled 2x2 blocks, so the
    lower of these two sector optimizations is the full ground state.
    """

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
        # Avoid division by zero during optimizer trial steps.
        vec = np.ones_like(vec)
        norm = np.linalg.norm(vec)
    return (vec / norm).astype(complex)


def vqe_normalized_real(
    hamiltonian: ComplexArray,
    n_restarts: int = 12,
    seed: int = 1234,
    initial_parameters: RealArray | None = None,
    maxiter: int = 2000,
) -> VQEResult:
    """VQE with a normalized real-amplitude ansatz.

    This spans every real state in the Hilbert space. Since all Hamiltonians in the
    project are real symmetric, this ansatz is sufficient for the exact ground
    state. The optimizer still finds the state variationally by minimizing the
    Rayleigh quotient.
    """
    hamiltonian = np.asarray(hamiltonian, dtype=complex)
    dim = hamiltonian.shape[0]
    rng = np.random.default_rng(seed)

    h_real = np.real_if_close(hamiltonian).astype(float)

    def objective(params: RealArray) -> float:
        x = np.asarray(params, dtype=float)
        denom = float(np.dot(x, x))
        if denom < 1e-28:
            return float("inf")
        return float(np.dot(x, h_real @ x) / denom)

    def gradient(params: RealArray) -> RealArray:
        x = np.asarray(params, dtype=float)
        denom = float(np.dot(x, x))
        if denom < 1e-28:
            return np.zeros_like(x)
        hx = h_real @ x
        energy = float(np.dot(x, hx) / denom)
        return 2.0 * (hx - energy * x) / denom

    starts: list[RealArray] = []
    if initial_parameters is not None:
        starts.append(np.asarray(initial_parameters, dtype=float))
    starts.append(np.ones(dim, dtype=float))
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
        success=bool(best.success),
        n_iterations=int(getattr(best, "nit", 0)),
        message=str(best.message),
    )


def hardware_efficient_state(
    parameters: RealArray, n_qubits: int, layers: int = 1
) -> ComplexArray:
    """Simple real-amplitude circuit ansatz using R_y rotations and a CNOT chain.

    This function is included to document a circuit style ansatz. It starts in
    |00...0>. Each layer applies R_y to all qubits followed by nearest-neighbour
    CNOTs 0->1->2... . A final set of R_y gates is then applied.
    """
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
