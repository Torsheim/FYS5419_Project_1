# Setup guide

Create and activate a Python virtual environment, then run:

```bash
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
python -m pytest
python scripts/run_all.py
python scripts/make_report_figures.py
python scripts/restricted_ansatz_check.py
```

The final report is stored in `report/project1_report.pdf`.
