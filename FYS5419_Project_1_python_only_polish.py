"""Python-only repository polish for FYS5419 Project 1.

Run this from the repository root with

    python FYS5419_Project_1_python_only_polish.py

The script avoids shell scripts and shell execution. It:
- replaces unfinished skeleton modules with wrappers to the implemented modules;
- replaces shell helpers with Python helpers;
- removes *.sh files from the repository working tree, except ignored folders;
- adds tests that catch TODO/NotImplemented skeletons and shell scripts;
- refreshes README files with Python-based workflow commands;
- adds a restricted Lipkin ansatz check script.

No git add/commit/push is performed.
"""

from __future__ import annotations

import datetime as _dt
import os
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path

ROOT = Path.cwd()
PACKAGE_DIR = ROOT / "src" / "fys5419_project1"


def fail(message: str) -> None:
    raise SystemExit(message)


def ensure_repo_root() -> None:
    if not PACKAGE_DIR.is_dir():
        fail(
            "Run this from the repository root, for example:\n"
            "  cd ~/projects/FYS5419_Project_1\n"
            "  python FYS5419_Project_1_python_only_polish.py"
        )


def backup(paths: list[Path]) -> Path:
    stamp = _dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = ROOT / f"backup_before_python_only_polish_{stamp}"
    backup_dir.mkdir(exist_ok=True)
    for path in paths:
        if path.exists():
            target = backup_dir / path.relative_to(ROOT)
            target.parent.mkdir(parents=True, exist_ok=True)
            if path.is_dir():
                shutil.copytree(path, target, dirs_exist_ok=True)
            else:
                shutil.copy2(path, target)
    return backup_dir


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(textwrap.dedent(content).lstrip(), encoding="utf-8")


def append_gitignore_entries(entries: list[str]) -> None:
    gitignore = ROOT / ".gitignore"
    current = gitignore.read_text(encoding="utf-8") if gitignore.exists() else ""
    with gitignore.open("a", encoding="utf-8") as f:
        for entry in entries:
            if entry not in current.splitlines():
                if current and not current.endswith("\n"):
                    f.write("\n")
                f.write(entry + "\n")
                current += ("\n" if current and not current.endswith("\n") else "") + entry + "\n"


def remove_tree_or_file(path: Path) -> None:
    if not path.exists():
        return
    if path.is_dir():
        shutil.rmtree(path)
    else:
        path.unlink()


def is_ignored_area(path: Path) -> bool:
    parts = set(path.parts)
    return bool({".git", ".venv", "venv", "external", "__pycache__"} & parts) or any(
        part.startswith("backup_before") for part in path.parts
    )


def remove_shell_scripts() -> list[Path]:
    removed: list[Path] = []
    for path in ROOT.rglob("*.sh"):
        if is_ignored_area(path.relative_to(ROOT)):
            continue
        try:
            path.unlink()
            removed.append(path.relative_to(ROOT))
        except OSError as exc:
            print(f"Could not remove {path}: {exc}")
    return removed


def write_compatibility_modules() -> None:
    write_text(
        PACKAGE_DIR / "gates.py",
        r'''
        """Compatibility wrappers for gate and measurement utilities.

        The final state-vector implementation is in :mod:`fys5419_project1.quantum`.
        This module exists so older notebooks or exploratory scripts importing
        ``fys5419_project1.gates`` still call the implemented routines.
        """

        from __future__ import annotations

        import numpy as np

        from .quantum import (
            HADAMARD,
            I2,
            PHASE_S,
            X,
            Y,
            Z,
            apply_single_qubit_gate,
            basis_state as _basis_state_from_bits,
            bell_state,
            bit_probabilities,
            cnot_matrix,
            measure_full_state,
            one_qubit_basis,
        )

        Array = np.ndarray


        def basis_state(index: int, n_qubits: int = 1) -> Array:
            """Return computational basis state ``|index>`` for ``n_qubits``."""
            if index < 0 or index >= 2**n_qubits:
                raise ValueError("basis index out of range")
            return _basis_state_from_bits(format(index, f"0{n_qubits}b"))


        def pauli_matrices() -> dict[str, Array]:
            """Return identity and Pauli matrices."""
            return {"I": I2.copy(), "X": X.copy(), "Y": Y.copy(), "Z": Z.copy()}


        def hadamard() -> Array:
            """Return the one-qubit Hadamard matrix."""
            return HADAMARD.copy()


        def phase(phi: float = np.pi / 2.0) -> Array:
            """Return a one-qubit phase gate ``diag(1, exp(i phi))``."""
            return np.array([[1.0, 0.0], [0.0, np.exp(1j * phi)]], dtype=complex)


        def cnot(control: int = 0, target: int = 1) -> Array:
            """Return a two-qubit CNOT matrix."""
            return cnot_matrix(control=control, target=target, n_qubits=2)


        def bell_states() -> dict[str, Array]:
            """Return the four Bell states in the |00>, |01>, |10>, |11> ordering."""
            return {
                "phi_plus": bell_state("phi_plus"),
                "phi_minus": bell_state("phi_minus"),
                "psi_plus": bell_state("psi_plus"),
                "psi_minus": bell_state("psi_minus"),
            }


        def measurement_probabilities(state: Array, n_qubits: int | None = None) -> dict[str, float]:
            """Return computational-basis probabilities for ``state``."""
            probs = bit_probabilities(state)
            if n_qubits is None:
                n_qubits = int(np.log2(len(probs)))
            return {format(i, f"0{n_qubits}b"): float(p) for i, p in enumerate(probs)}


        def sample_measurements(
            state: Array,
            n_qubits: int | None = None,
            shots: int = 1024,
            seed: int | None = None,
        ) -> dict[str, int]:
            """Sample computational-basis measurements."""
            return measure_full_state(state, shots=shots, seed=seed)


        __all__ = [
            "Array",
            "HADAMARD",
            "I2",
            "PHASE_S",
            "X",
            "Y",
            "Z",
            "apply_single_qubit_gate",
            "basis_state",
            "bell_state",
            "bell_states",
            "bit_probabilities",
            "cnot",
            "cnot_matrix",
            "hadamard",
            "measure_full_state",
            "measurement_probabilities",
            "one_qubit_basis",
            "pauli_matrices",
            "phase",
            "sample_measurements",
        ]
        ''',
    )

    write_text(
        PACKAGE_DIR / "density.py",
        r'''
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
        ''',
    )

    write_text(
        PACKAGE_DIR / "lipkin.py",
        r'''
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
        ''',
    )

    write_text(
        PACKAGE_DIR / "plotting.py",
        r'''
        """Small plotting helper functions for exploratory project figures."""

        from __future__ import annotations

        from pathlib import Path

        import matplotlib.pyplot as plt
        import numpy as np

        Array = np.ndarray


        def save_eigenvalue_plot(
            x_values: Array,
            eigenvalues: Array,
            output_path: str | Path,
            xlabel: str = r"$\lambda$",
            ylabel: str = "Energy",
        ) -> None:
            """Save a compact eigenvalue plot."""
            x_values = np.asarray(x_values, dtype=float)
            values = np.asarray(eigenvalues, dtype=float)
            if values.ndim == 1:
                values = values[:, None]

            output_path = Path(output_path)
            output_path.parent.mkdir(parents=True, exist_ok=True)

            fig, ax = plt.subplots(figsize=(3.35, 2.55))
            for index in range(values.shape[1]):
                ax.plot(x_values, values[:, index], label=fr"$E_{index}$")
            ax.set_xlabel(xlabel)
            ax.set_ylabel(ylabel)
            if values.shape[1] <= 6:
                ax.legend(frameon=True)
            fig.tight_layout()
            fig.savefig(output_path)
            plt.close(fig)
        ''',
    )


def write_python_helper_scripts() -> None:
    for part in "abcdefg":
        write_text(
            ROOT / "scripts" / f"run_part_{part}.py",
            r'''
            """Convenience wrapper for the reproducible project pipeline.

            The final project is generated through ``scripts/run_all.py``, which writes
            all selected CSV/TXT results and figures used in the report.
            """

            from __future__ import annotations

            from run_all import main


            if __name__ == "__main__":
                main()
            ''',
        )

    write_text(
        ROOT / "scripts" / "restricted_ansatz_check.py",
        r'''
        """Restricted-circuit check for the Lipkin J=2 ground state.

        The full real-amplitude Lipkin VQE used in the report is an ideal
        variational-state benchmark. This script compares it with restricted
        hardware-inspired ansatz families for the J=2 ground state, illustrating how
        ansatz expressivity changes the attainable error.
        """

        from __future__ import annotations

        from pathlib import Path

        import numpy as np
        import pandas as pd
        from scipy.optimize import minimize

        from fys5419_project1.hamiltonians import lipkin_j2, pad_to_power_of_two, sorted_eigh
        from fys5419_project1.vqe import expectation_value, hardware_efficient_state


        def optimize_hardware_ansatz(
            hamiltonian: np.ndarray,
            n_qubits: int = 3,
            layers: int = 0,
            seed: int = 1234,
            n_restarts: int = 10,
        ) -> float:
            """Minimize the energy of ``hardware_efficient_state``."""
            n_parameters = (layers + 1) * n_qubits
            rng = np.random.default_rng(seed)

            def objective(parameters: np.ndarray) -> float:
                state = hardware_efficient_state(parameters, n_qubits=n_qubits, layers=layers)
                return expectation_value(state, hamiltonian)

            starts: list[np.ndarray] = [
                np.zeros(n_parameters),
                0.1 * np.ones(n_parameters),
                np.ones(n_parameters),
            ]
            starts.extend(rng.uniform(-np.pi, np.pi, size=n_parameters) for _ in range(n_restarts))

            best_energy = float("inf")
            for start in starts:
                opt = minimize(
                    objective,
                    x0=start,
                    method="BFGS",
                    options={"gtol": 1e-10, "maxiter": 2000},
                )
                best_energy = min(best_energy, float(opt.fun))
            return best_energy


        def main() -> None:
            out_dir = Path("results/data")
            out_dir.mkdir(parents=True, exist_ok=True)

            rows: list[dict[str, float | int | str]] = []
            v_values = np.linspace(0.0, 2.0, 9)
            for layers, label in [
                (0, "Product Ry only"),
                (1, "One-layer Ry-CNOT-Ry"),
            ]:
                for index, v_strength in enumerate(v_values):
                    hamiltonian = pad_to_power_of_two(lipkin_j2(epsilon=1.0, V=float(v_strength), W=0.0))
                    exact = sorted_eigh(hamiltonian)[0][0]
                    energy = optimize_hardware_ansatz(
                        hamiltonian,
                        n_qubits=3,
                        layers=layers,
                        seed=4321 + 17 * index + layers,
                        n_restarts=8,
                    )
                    rows.append(
                        {
                            "ansatz": label,
                            "layers": layers,
                            "V": float(v_strength),
                            "exact_E0": float(exact),
                            "vqe_E0": float(energy),
                            "abs_error": float(abs(energy - exact)),
                        }
                    )

            df = pd.DataFrame(rows)
            csv_path = out_dir / "part_g_lipkin_restricted_ansatz_check.csv"
            df.to_csv(csv_path, index=False)

            summary = df.groupby("ansatz", as_index=False)["abs_error"].max()
            summary_path = out_dir / "part_g_lipkin_restricted_ansatz_summary.csv"
            summary.to_csv(summary_path, index=False)

            print(f"Wrote {csv_path}")
            print(f"Wrote {summary_path}")
            print(summary.to_string(index=False))


        if __name__ == "__main__":
            main()
        ''',
    )

    write_text(
        ROOT / "scripts" / "compile_report.py",
        r'''
        """Compile the LaTeX report from Python.

        This helper keeps the repository workflow Python-driven. It requires a local
        LaTeX installation with ``pdflatex`` available on PATH. The already compiled
        PDF is included in ``report/project1_report.pdf``.
        """

        from __future__ import annotations

        import subprocess
        import sys
        from pathlib import Path


        def main() -> int:
            report_dir = Path(__file__).resolve().parents[1] / "report"
            tex_file = report_dir / "project1_report.tex"
            if not tex_file.exists():
                print(f"Missing {tex_file}", file=sys.stderr)
                return 1

            for _ in range(2):
                result = subprocess.run(
                    ["pdflatex", "-interaction=nonstopmode", tex_file.name],
                    cwd=report_dir,
                    check=False,
                )
                if result.returncode != 0:
                    return result.returncode
            return 0


        if __name__ == "__main__":
            raise SystemExit(main())
        ''',
    )

    write_text(
        ROOT / "scripts" / "fetch_course_sources.py",
        r'''
        """Fetch the course repository into ``external/`` using Python.

        The external directory is ignored by git and is only meant as a local
        reference copy of the course material.
        """

        from __future__ import annotations

        import subprocess
        from pathlib import Path


        COURSE_URL = "https://github.com/CompPhysics/QuantumComputingMachineLearning.git"


        def main() -> int:
            target = Path("external") / "QuantumComputingMachineLearning"
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                print(f"Course repository already exists at {target}")
                return 0
            return subprocess.run(["git", "clone", COURSE_URL, str(target)], check=False).returncode


        if __name__ == "__main__":
            raise SystemExit(main())
        ''',
    )


def write_tests() -> None:
    write_text(
        ROOT / "tests" / "test_no_placeholders.py",
        r'''
        from pathlib import Path


        def test_no_unimplemented_skeletons_in_package() -> None:
            package_dir = Path("src/fys5419_project1")
            forbidden = ["NotImplementedError", "TODO: implement"]
            for path in package_dir.glob("*.py"):
                text = path.read_text(encoding="utf-8")
                for token in forbidden:
                    assert token not in text, f"{token!r} remains in {path}"
        ''',
    )

    write_text(
        ROOT / "tests" / "test_no_shell_scripts.py",
        r'''
        from pathlib import Path


        IGNORED_DIRS = {".git", ".venv", "venv", "external", "__pycache__"}


        def ignored(path: Path) -> bool:
            return bool(IGNORED_DIRS.intersection(path.parts)) or any(
                part.startswith("backup_before") for part in path.parts
            )


        def test_no_shell_scripts_in_repository() -> None:
            offenders = [path for path in Path(".").rglob("*.sh") if not ignored(path)]
            assert offenders == [], f"Shell scripts should not be committed: {offenders}"
        ''',
    )


def write_readmes() -> None:
    write_text(
        ROOT / "README.md",
        r'''
        # FYS5419 Project 1

        Repository for **FYS5419/FYS9419 Project 1** by Marius Torsheim,
        Department of Physics, University of Oslo.

        The project studies small Hamiltonians and the Lipkin model with exact
        diagonalization and self-written variational quantum eigensolver routines.
        The repository contains the Python package, reproducibility scripts, tests,
        selected numerical results, figures, and the final report.

        ## Repository contents

        - `src/fys5419_project1/`: implemented Python package.
        - `scripts/`: Python scripts for running calculations and checks.
        - `tests/`: unit tests and repository-polish tests.
        - `results/data/`: selected CSV/TXT outputs.
        - `results/figures/`: report figures.
        - `report/project1_report.pdf`: final report PDF.
        - `report/project1_report.tex`: report source.

        ## Python workflow

        Create and activate a virtual environment in your normal terminal, then run:

        ```text
        python -m pip install --upgrade pip
        python -m pip install -e ".[dev]"
        python -m pytest
        python scripts/run_all.py
        python scripts/make_report_figures.py
        python scripts/restricted_ansatz_check.py
        ```

        The final report PDF is included. If a local LaTeX installation is available,
        the report can be compiled through the Python helper:

        ```text
        python scripts/compile_report.py
        ```

        No shell scripts are required for the project workflow.
        ''',
    )

    write_text(
        ROOT / "report" / "README.md",
        r'''
        # Final report

        Main files:

        - `project1_report.pdf`: final compiled report.
        - `project1_report.tex`: LaTeX source.
        - `figures/`: figure files used by the report.

        The PDF is included directly for delivery. The TeX source can also be used
        in Overleaf. For a local Python-driven compile, run this from the repository
        root after installing a LaTeX distribution:

        ```text
        python scripts/compile_report.py
        ```
        ''',
    )


def remove_template_clutter() -> None:
    for path in [
        ROOT / "tests" / "test_todos.py",
        ROOT / "report" / "main.tex",
        ROOT / "report" / "main.pdf",
        ROOT / "report" / "references.bib",
        ROOT / "Makefile",
        ROOT / "src" / "fys5419_project1.egg-info",
    ]:
        remove_tree_or_file(path)
    remove_tree_or_file(ROOT / "report" / "sections")


def run_optional_restricted_check() -> None:
    try:
        import numpy  # noqa: F401
        import pandas  # noqa: F401
        import scipy  # noqa: F401
    except Exception:
        print("Skipping restricted ansatz check because numpy/scipy/pandas are not all installed.")
        return

    env = dict(os.environ)
    src_path = str(ROOT / "src")
    env["PYTHONPATH"] = src_path + os.pathsep + env.get("PYTHONPATH", "")
    result = subprocess.run(
        [sys.executable, "scripts/restricted_ansatz_check.py"],
        cwd=ROOT,
        env=env,
        check=False,
    )
    if result.returncode != 0:
        print("restricted_ansatz_check.py did not complete successfully; run it manually after tests.")


def main() -> None:
    ensure_repo_root()
    paths_to_backup = [
        PACKAGE_DIR / "gates.py",
        PACKAGE_DIR / "density.py",
        PACKAGE_DIR / "lipkin.py",
        PACKAGE_DIR / "plotting.py",
        ROOT / "scripts",
        ROOT / "tests",
        ROOT / "README.md",
        ROOT / "report" / "README.md",
        ROOT / ".gitignore",
        ROOT / "Makefile",
    ]
    backup_dir = backup(paths_to_backup)

    write_compatibility_modules()
    write_python_helper_scripts()
    write_tests()
    write_readmes()
    remove_template_clutter()

    removed_shell = remove_shell_scripts()
    append_gitignore_entries(
        [
            "*.sh",
            "*.egg-info/",
            "src/*.egg-info/",
            "backup_before*/",
            "*.aux",
            "*.log",
            "*.out",
            "*.toc",
            "*.fls",
            "*.fdb_latexmk",
        ]
    )

    run_optional_restricted_check()

    print("\nPython-only polish complete.")
    print(f"Backup folder: {backup_dir.relative_to(ROOT)}")
    if removed_shell:
        print("Removed shell scripts:")
        for path in removed_shell:
            print(f"  - {path}")
    else:
        print("No shell scripts needed removal.")
    print("\nRecommended checks:")
    print("  python -m pytest")
    print("  python scripts/run_all.py")
    print("  python scripts/make_report_figures.py")
    print("  python scripts/restricted_ansatz_check.py")
    print("  git status")


if __name__ == "__main__":
    main()
