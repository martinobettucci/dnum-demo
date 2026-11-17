import os, pytest
def pytest_configure(config):
    config.addinivalue_line("markers", "spec(id): identifiant de la spécification couverte")
@pytest.fixture
def app_url():
    return os.environ.get("APP_URL", "http://app")
