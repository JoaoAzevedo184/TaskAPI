from sqlmodel import create_engine, SQLModel, Session
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Criar pasta data para guardar banco
DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(exist_ok=True)

DB_PATH = DATA_DIR / "tasks.db"

DATABASE_URL = f"sqlite:///{DB_PATH}"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})


def init_db():
    SQLModel.metadata.create_all(engine)


def get_session():
    with Session(engine) as session:
        yield session