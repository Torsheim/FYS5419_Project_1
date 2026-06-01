"""Compatibility wrappers for density matrices and entropies.

The final implementations are in :mod:`fys5419_project1.quantum`.
"""

from __future__ import annotations

from .quantum import density_matrix, partial_trace, reduced_density_matrix, von_neumann_entropy

__all__ = [
    "density_matrix",
    "partial_trace",
    "reduced_density_matrix",
    "von_neumann_entropy",
]
