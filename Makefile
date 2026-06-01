.PHONY: install test run clean

install:
	python -m pip install -e ".[dev]"

test:
	pytest

run:
	python scripts/run_all.py

clean:
	rm -rf build dist *.egg-info src/*.egg-info .pytest_cache
	find . -type d -name __pycache__ -prune -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
