"""Smoke tests for the initial scaffold."""


def test_package_imports() -> None:
    import fys5419_project1

    assert fys5419_project1.__version__
