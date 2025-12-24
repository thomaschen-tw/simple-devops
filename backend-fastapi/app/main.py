"""
Application entrypoint for the FastAPI server.
Creates tables on startup (for dev), registers CORS, and mounts routes.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from . import models
from .routes import router

# Note: Table creation is deferred to avoid database connection during import.
# Tables will be created by start.sh script or on first request.
# For production, prefer migrations (Alembic).

app = FastAPI(title="Blog API", version="0.1.0")

# Allow the Vite dev server to call the API from localhost.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/healthz")
def health_check():
    """Lightweight readiness probe for containers and tests."""
    return {"status": "ok"}


# Mount all API routes defined in app/routes.py.
app.include_router(router)

