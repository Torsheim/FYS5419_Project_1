.PHONY: help install test report clean fetch-course

help:
	@echo "Targets:"
	@echo "  install       Install the local package in editable mode"
	@echo "  test          Run pytest"
	@echo "  report        Build report/main.tex with latexmk"
	@echo "  fetch-course  Fetch course source material into external/"
	@echo "  clean         Remove LaTeX build files"

install:
	python -m pip install --upgrade pip
	pip install -e ".[dev]"

test:
	pytest

report:
	cd report && latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex

fetch-course:
	bash scripts/fetch_course_sources.sh

clean:
	cd report && latexmk -C main.tex || true
	find . -type d -name "__pycache__" -prune -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -prune -exec rm -rf {} +
