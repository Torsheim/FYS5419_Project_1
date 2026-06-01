import numpy as np

from fys5419_project1.quantum import (
    HADAMARD,
    X,
    bell_state,
    ket0,
    ket1,
    prepare_bell_with_h_and_cnot,
    reduced_density_matrix,
    von_neumann_entropy,
)


def test_pauli_x_flips_basis_states():
    assert np.allclose(X @ ket0(), ket1())
    assert np.allclose(X @ ket1(), ket0())


def test_hadamard_normalized_actions():
    plus = HADAMARD @ ket0()
    minus = HADAMARD @ ket1()
    assert np.allclose(np.linalg.norm(plus), 1.0)
    assert np.allclose(np.linalg.norm(minus), 1.0)
    assert np.allclose(np.vdot(plus, minus), 0.0)


def test_bell_preparation_and_entropy():
    psi = prepare_bell_with_h_and_cnot()
    assert np.allclose(psi, bell_state("phi_plus"))
    rho_a = reduced_density_matrix(psi, keep=[0])
    assert np.allclose(rho_a, 0.5 * np.eye(2))
    assert np.isclose(von_neumann_entropy(rho_a), 1.0)
