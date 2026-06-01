"""VQE helpers for Parts c, e, and g."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

import numpy as np

Array = np.ndarray


@dataclass
class VQEResult:
    """Container for VQE optimization results."""

    energy: float
    parameters: Array
    n_iterations: int
    converged: bool


def expectation_value(state: Array, operator: Array) -> float:
    """Return ``<psi|operator|psi>``.

    TODO: implement and ensure the real part is returned for Hermitian operators.
    """
    raise NotImplementedError


def one_qubit_ansatz(theta: float) -> Array:
    """Return a one-qubit trial state for Part c.

    TODO: implement, for example using a rotation around the y axis.
    """
    raise NotImplementedError


def two_qubit_ansatz(params: Array) -> Array:
    """Return a two-qubit trial state for Part e.

    TODO: implement an ansatz capable of representing entangled states.
    """
    raise NotImplementedError


def minimize_energy(energy_fn: Callable[[Array], float], initial_parameters: Array) -> VQEResult:
    """Minimize an energy function over variational parameters.

    TODO: implement with scipy.optimize.minimize.
    """
    raise NotImplementedError
