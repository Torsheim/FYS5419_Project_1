# Project checklist

Use this file as a working checklist. Replace the status marks as you complete each item.

## Part a - Gates, Bell states, measurements, entropy

- [ ] Define one-qubit basis states `|0>` and `|1>`.
- [ ] Implement Pauli matrices `I`, `X`, `Y`, `Z`.
- [ ] Apply Pauli matrices to the one-qubit basis and summarize the action.
- [ ] Apply Hadamard and phase gates to the same basis.
- [ ] Define Bell states.
- [ ] Apply a Hadamard gate and then a CNOT gate to a Bell-state setup of your choice.
- [ ] Perform repeated measurements on qubit 1 and qubit 2.
- [ ] Report average measurement results and compare with theoretical probabilities.
- [ ] Construct the Bell-state density matrix.
- [ ] Trace out one subsystem.
- [ ] Compute and discuss the von Neumann entropy.

## Part b - Classical one-qubit Hamiltonian

- [ ] Implement the `2 x 2` Hamiltonian with the given parameters.
- [ ] Solve the eigenvalue problem for `lambda in [0, 1]`.
- [ ] Plot both eigenvalues as functions of interaction strength.
- [ ] Study eigenvector composition versus `lambda`.
- [ ] Discuss the interchange of state character near the avoided crossing.

## Part c - One-qubit VQE

- [ ] Derive or implement the Pauli-matrix decomposition.
- [ ] Choose and document a one-qubit ansatz.
- [ ] Implement expectation values from state vectors and/or measurements.
- [ ] Minimize the energy for multiple `lambda` values.
- [ ] Compare VQE energies with part b.
- [ ] Add Qiskit/PennyLane comparison only as a validation check, not as the main implementation.

## Part d - Classical two-qubit Hamiltonian and entanglement

- [ ] Implement the `4 x 4` Hamiltonian.
- [ ] Solve for eigenvalues as functions of `lambda`.
- [ ] Extract the lowest two-body eigenstate.
- [ ] Build the density matrix.
- [ ] Compute reduced density matrices using partial traces.
- [ ] Compute von Neumann entropy for one subsystem.
- [ ] Discuss entanglement and the level crossing/avoided-crossing behavior.

## Part e - Two-qubit VQE

- [ ] Choose a two-qubit ansatz capable of entanglement.
- [ ] Implement expectation values for Pauli strings.
- [ ] Optimize the lowest-state energy for each `lambda`.
- [ ] Compare with part d.
- [ ] Discuss ansatz expressivity and optimizer stability.

## Part f - Lipkin model, classical diagonalization

- [ ] Show the `J=1`, `W=0` Hamiltonian matrix.
- [ ] Rewrite the `J=1` Hamiltonian in terms of Pauli matrices and identity operators.
- [ ] Implement the `J=1` matrix.
- [ ] Implement the `J=2`, `W=0` matrix.
- [ ] Find the `J=2` Pauli-string representation.
- [ ] Optional challenge: include the `W` term in the Pauli decomposition.
- [ ] Diagonalize both Hamiltonians as functions of `V` for fixed single-particle energy.
- [ ] Plot and discuss spectra.

## Part g - Lipkin VQE

- [ ] Choose qubit encodings for `J=1` and `J=2`.
- [ ] Build VQE circuits/ansatz states.
- [ ] Implement Hamiltonian expectation values.
- [ ] Compare VQE spectra with classical diagonalization.
- [ ] Discuss limitations, convergence, and possible ansatz improvements.

## General report requirements

- [ ] Explain the problem and numerical methods.
- [ ] Describe algorithms clearly, with pseudocode where useful.
- [ ] Include relevant source code or reference repository paths.
- [ ] Use analytic limits and known limits to test the code.
- [ ] Include figures/tables with labels and captions.
- [ ] Discuss numerical reliability and stability.
- [ ] Interpret the results.
- [ ] Add a short critique/reflection section.
- [ ] Fill in the AI/LLM usage appendix if applicable.
