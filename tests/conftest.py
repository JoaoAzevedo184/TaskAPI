import pytest
from app.db import init_db


@pytest.fixture(autouse=True)
def setup_db():
    """Ensure database tables exist before each test."""
    init_db()

