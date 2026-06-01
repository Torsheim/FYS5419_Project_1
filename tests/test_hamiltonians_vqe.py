import numpy as np

from fys5419_project1.hamiltonians import (
    lipkin_j1,
    one_qubit_from_pauli,
    one_qubit_hamiltonian,
    pad_to_power_of_two,
    sorted_eigh,
    two_qubit_hamiltonian,
)
from fys5419_project1.vqe import vqe_normalized_real, vqe_one_qubit_ry, vqe_two_qubit_parity


def test_one_qubit_pauli_form_matches_matrix():
    for lam in [0.0, 0.25, 0.7, 1.0]:
        assert np.allclose(one_qubit_hamiltonian(lam), one_qubit_from_pauli(lam))


def test_one_qubit_vqe_matches_exact_ground_state():
    for lam in [0.0, 0.5, 1.0]:
        H = one_qubit_hamiltonian(lam)
        evals, _ = sorted_eigh(H)
        vqe = vqe_one_qubit_ry(H)
        assert abs(vqe.energy - evals[0]) < 1e-8


def test_two_qubit_vqe_matches_exact_ground_state():
    for lam in [0.0, 0.25, 0.75, 1.0]:
        H = two_qubit_hamiltonian(lam)
        evals, _ = sorted_eigh(H)
        best, even, odd = vqe_two_qubit_parity(H)
        assert abs(best.energy - evals[0]) < 1e-8
        assert min(even.energy, odd.energy) == best.energy


def test_lipkin_normalized_vqe_matches_exact_ground_state():
    H = pad_to_power_of_two(lipkin_j1(epsilon=1.0, V=0.7))
    evals, _ = sorted_eigh(H)
    vqe = vqe_normalized_real(H, n_restarts=5, seed=99)
    assert abs(vqe.energy - evals[0]) < 1e-7
