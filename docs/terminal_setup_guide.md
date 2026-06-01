# Terminal setup guide for `FYS5419_Project_1`

This guide assumes you have already created an empty GitHub repository named `FYS5419_Project_1` in your own GitHub account.

Replace `<YOUR-GITHUB-USERNAME>` with your actual GitHub username.

## 1. Unpack the scaffold

From the directory where you downloaded the scaffold zip:

```bash
unzip FYS5419_Project_1_scaffold.zip
cd FYS5419_Project_1
```

## 2. Initialize Git locally

```bash
git init
git branch -M main
git status
```

## 3. Connect to your GitHub repository

Using SSH:

```bash
git remote add origin git@github.com:<YOUR-GITHUB-USERNAME>/FYS5419_Project_1.git
```

Or using HTTPS:

```bash
git remote add origin https://github.com/<YOUR-GITHUB-USERNAME>/FYS5419_Project_1.git
```

Check that the remote was added correctly:

```bash
git remote -v
```

## 4. Create the Python environment

Using `venv`:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -e ".[dev]"
```

Optional, only if you want to compare your own code with Qiskit or PennyLane:

```bash
pip install -r requirements-quantum.txt
```

Using conda/mamba instead:

```bash
mamba env create -f environment.yml
mamba activate fys5419-project1
```

If you use conda instead of mamba:

```bash
conda env create -f environment.yml
conda activate fys5419-project1
```

## 5. Fetch the course repository locally

This downloads selected course material into `external/QuantumComputingMachineLearning`. The `external/` directory is ignored by Git, so you can use it locally without pushing copied course files.

```bash
bash scripts/fetch_course_sources.sh
```

## 6. Make the first commit

```bash
git add .
git status
git commit -m "Initial scaffold for FYS5419 Project 1"
```

## 7. Push to GitHub

```bash
git push -u origin main
```

## 8. Normal daily workflow

```bash
source .venv/bin/activate
pytest
make report
git status
git add src notebooks report results docs tests
git commit -m "Describe what you changed"
git push
```

## 9. Useful checks before submission

```bash
pytest
make report
git status
```

Make sure that:

- `report/main.pdf` builds and contains your final report.
- `results/figures/` and `results/tables/` contain selected outputs used in the report.
- Your code can reproduce the selected results.
- The AI/LLM declaration appendix is filled in if you used AI tools.
