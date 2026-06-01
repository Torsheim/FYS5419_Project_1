"""Compatibility wrappers for Lipkin Hamiltonians and Pauli decompositions.

The final implementations are in :mod:`fys5419_project1.hamiltonians`.
"""

from __future__ import annotations

from .hamiltonians import (
    format_pauli_decomposition,
    lipkin_j1,
    lipkin_j2,
    pad_to_power_of_two,
    pad_with_fixed_penalty,
    padding_projector,
    pauli_decomposition,
    reconstruct_from_pauli,
    sorted_eigh,
)

__all__ = [
    "format_pauli_decomposition",
    "lipkin_j1",
    "lipkin_j2",
    "pad_to_power_of_two",
    "pad_with_fixed_penalty",
    "padding_projector",
    "pauli_decomposition",
    "reconstruct_from_pauli",
    "sorted_eigh",
]
