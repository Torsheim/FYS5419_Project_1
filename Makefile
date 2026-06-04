.RECIPEPREFIX := >
.PHONY: install test report clean

install:
> python -m pip install --upgrade pip
> if [ -f requirements.txt ]; then python -m pip install -r requirements.txt; fi
> python -m pip install -e .

test:
> pytest -q

report:
> cd report && pdflatex project1_report.tex && pdflatex project1_report.tex

clean:
> rm -rf .pytest_cache **/__pycache__ *.egg-info src/*.egg-info
> find report -type f \( -name "*.aux" -o -name "*.log" -o -name "*.out" -o -name "*.toc" \) -delete
