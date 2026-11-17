import pytest, requests

@pytest.mark.spec("SPEC-000.1")
def test_page_accueil_repond(app_url):
    assert requests.get(app_url, timeout=5).status_code == 200
