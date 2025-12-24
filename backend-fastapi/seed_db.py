"""
Utility script to generate 100 deterministic test articles.
Handy for local dev, docker-compose, or preview environments.
"""

from datetime import datetime, timedelta

from app.models import Article, Base, SessionLocal, engine


def seed():
    """Populate the database with sample articles."""
    # Create tables if they don't exist (safe for local/dev).
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Clear existing rows to keep the data set deterministic.
        db.query(Article).delete()
        now = datetime.utcnow()
        for i in range(100):
            article = Article(
                title=f"Sample Article {i + 1}",
                content=(
                    "This is a placeholder article for testing search and post APIs. "
                    f"Entry number {i + 1}."
                ),
                created_at=now - timedelta(minutes=i),
            )
            db.add(article)
        db.commit()
        print("Seeded 100 articles.")
    finally:
        db.close()


if __name__ == "__main__":
    seed()

