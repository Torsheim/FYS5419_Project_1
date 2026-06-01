from pathlib import Path


def test_no_unimplemented_skeletons_in_package() -> None:
    package_dir = Path("src/fys5419_project1")
    forbidden = ["NotImplementedError", "TODO: implement"]
    for path in package_dir.glob("*.py"):
        text = path.read_text(encoding="utf-8")
        for token in forbidden:
            assert token not in text, f"{token!r} remains in {path}"
