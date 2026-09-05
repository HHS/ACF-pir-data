import pytest

from pir_pipeline.hses.HSES import HSES


@pytest.fixture
def hses_env(monkeypatch):
    monkeypatch.setenv("HSES_API_USER", "test-user")
    monkeypatch.setenv("HSES_API_KEY_PROD", "test-key")


def test_clean_up_tempdir_before_unzip_is_a_safe_noop(hses_env):
    # A freshly constructed HSES has no temporary directory yet (unzip was
    # never called). Cleaning up should be a no-op instead of raising
    # AttributeError. This also protects __del__, which calls this method on
    # garbage collection.
    hses = HSES()
    hses.clean_up_tempdir()
