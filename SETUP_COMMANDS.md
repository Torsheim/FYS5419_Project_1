# Minimal terminal commands

After creating an empty GitHub repository named `FYS5419_Project_1`, run:

```bash
unzip FYS5419_Project_1_scaffold.zip
cd FYS5419_Project_1

git init
git branch -M main
git remote add origin git@github.com:<YOUR-GITHUB-USERNAME>/FYS5419_Project_1.git

python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -e ".[dev]"

bash scripts/fetch_course_sources.sh
pytest
make report

git add .
git commit -m "Initial scaffold for FYS5419 Project 1"
git push -u origin main
```

Use the HTTPS remote instead if you do not use SSH:

```bash
git remote add origin https://github.com/<YOUR-GITHUB-USERNAME>/FYS5419_Project_1.git
```
