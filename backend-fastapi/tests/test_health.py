"""
Health check tests that don't require database connection.
These tests can run in CI without a database.
"""
import os
import sys

# Set a dummy DATABASE_URL BEFORE importing app modules
# This prevents database connection attempts during import
# The health endpoint doesn't need database, so this is safe
os.environ["DATABASE_URL"] = "postgresql+psycopg://test:test@localhost:5432/test"

from fastapi.testclient import TestClient

# Import after setting environment variable
from app.main import app

# Use FastAPI's TestClient for simple integration-style checks.
client = TestClient(app)


def test_healthz():
    """
    Health endpoint should respond 200 with status ok.
    This endpoint doesn't require database connection.
    """
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

