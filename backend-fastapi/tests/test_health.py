from fastapi.testclient import TestClient

from app.main import app

# Use FastAPI's TestClient for simple integration-style checks.
client = TestClient(app)


def test_healthz():
    """Health endpoint should respond 200 with status ok."""
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

