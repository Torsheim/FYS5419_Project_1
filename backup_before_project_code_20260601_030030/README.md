# FYS5419 Project 1: VQE and the Lipkin model

Repository scaffold for **FYS5419/9419 Project 1**. The assignment asks for a study of one-qubit and two-qubit gates, simple Hamiltonians, density matrices and entanglement, VQE implementations, and the Lipkin model for the `J=1` and `J=2` cases.

The original course source repository is:

<https://github.com/CompPhysics/QuantumComputingMachineLearning>

The readable assignment PDF is included at:

```text
report/assignment/FYS5419_Project_1_assignment.pdf
```

## Suggested workflow

1. Read the project description in `report/assignment/`.
2. Read the task map in `docs/project_checklist.md`.
3. Set up the Python environment.
4. Add your implementations in `src/fys5419_project1/`.
5. Use notebooks only for exploration; move final reusable code into `src/`.
6. Save generated figures in `results/figures/` and tables in `results/tables/`.
7. Write the final report in `report/main.tex`.

## Repository tree

```text
FYS5419_Project_1/
├── README.md
├── pyproject.toml
├── requirements.txt
├── requirements-quantum.txt
├── environment.yml
├── Makefile
├── data/
├── docs/
├── external/                       # ignored, local copy of course sources if fetched
├── notebooks/
├── references/
├── report/
│   ├── assignment/                 # assignment PDF and LaTeX source
│   ├── sections/                   # report section templates
│   └── main.tex
├── results/
├── scripts/
├── src/fys5419_project1/
└── tests/
```

## Quick start

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -e ".[dev]"
```

Optional quantum software for comparisons with your own VQE implementation:

```bash
pip install -r requirements-quantum.txt
```

Fetch a local, ignored copy of the course material:

```bash
bash scripts/fetch_course_sources.sh
```

Run the current placeholder test suite:

```bash
pytest
```

Build the report template:

```bash
make report
```

## Where to put code

| Project part | Main files to edit |
|---|---|
| a: one-qubit gates, Bell states, measurements, entropy | `src/fys5419_project1/gates.py`, `src/fys5419_project1/density.py`, `notebooks/part_a_gates_entropy.ipynb` |
| b: classical one-qubit Hamiltonian eigenproblem | `src/fys5419_project1/hamiltonians.py`, `scripts/run_part_b.py` |
| c: one-qubit VQE | `src/fys5419_project1/vqe.py`, `scripts/run_part_c.py` |
| d: two-qubit Hamiltonian and entropy | `src/fys5419_project1/hamiltonians.py`, `src/fys5419_project1/density.py`, `scripts/run_part_d.py` |
| e: two-qubit VQE | `src/fys5419_project1/vqe.py`, `scripts/run_part_e.py` |
| f: Lipkin `J=1` and `J=2`, classical diagonalization, Pauli decompositions | `src/fys5419_project1/lipkin.py`, `scripts/run_part_f.py` |
| g: Lipkin VQE | `src/fys5419_project1/vqe.py`, `src/fys5419_project1/lipkin.py`, `scripts/run_part_g.py` |

## Notes on academic integrity and LLM use

The course repository contains an LLM declaration guideline. This scaffold includes an appendix template in `report/sections/appendix_ai.tex` and a Markdown helper in `docs/ai_usage_declaration_template.md`. Fill it honestly before submission.

## Submission reminder

The assignment text asks for a PDF report and a link to your GitHub/GitLab repository. Keep selected numerical outputs and figures in `results/` so the submitted repository is reproducible.
