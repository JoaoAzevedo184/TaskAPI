# conftest.py - Arquivo de configuração global do pytest
#
# O pytest detecta esse arquivo automaticamente antes de rodar os testes.
# Fixtures definidas aqui ficam disponíveis para TODOS os arquivos de teste
# sem precisar importar nada.

import pytest
from app.db import init_db


# @pytest.fixture → define uma "fixture", que é um bloco de preparação
#                   que roda antes dos testes
#
# autouse=True → essa fixture roda AUTOMATICAMENTE antes de CADA teste,
#                sem precisar passar como parâmetro na função de teste.
#                Sem autouse, você teria que fazer:
#                    def test_algo(setup_db):  ← passando a fixture manualmente
#
# Por que isso é necessário?
# A aplicação chama init_db() no evento @app.on_event("startup"),
# que só dispara quando o servidor FastAPI sobe de verdade (uvicorn).
# Nos testes, usamos TestClient, que nem sempre dispara esse evento.
# Resultado: os testes tentavam inserir dados numa tabela que não existia
# e dava erro "no such table: task".
# Essa fixture garante que o SQLModel.metadata.create_all() rode antes
# de cada teste, criando as tabelas no SQLite se ainda não existirem.
@pytest.fixture(autouse=True)
def setup_db():
    """Ensure database tables exist before each test."""
    init_db()