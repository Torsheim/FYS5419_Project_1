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
