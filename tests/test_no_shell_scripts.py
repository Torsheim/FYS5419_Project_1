from pathlib import Path


IGNORED_DIRS = {".git", ".venv", "venv", "external", "__pycache__"}


def ignored(path: Path) -> bool:
    return bool(IGNORED_DIRS.intersection(path.parts)) or any(
        part.startswith("backup_before") for part in path.parts
    )


def test_no_shell_scripts_in_repository() -> None:
    offenders = [path for path in Path(".").rglob("*.sh") if not ignored(path)]
    assert offenders == [], f"Shell scripts should not be committed: {offenders}"
