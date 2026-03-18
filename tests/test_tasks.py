# Importa o TestClient do Starlette (usado pelo FastAPI)
# Ele simula requisições HTTP sem precisar subir o servidor de verdade
from fastapi.testclient import TestClient

# Importa a instância da aplicação FastAPI definida em app/main.py
from app.main import app

# Cria um cliente de teste que vai fazer requisições à nossa API
# Funciona como se fosse um "Postman automatizado"
client = TestClient(app)


# ==================== TESTES DE OBSERVABILIDADE ====================


def test_health():
    """Testa o endpoint de health check (GET /health).
    Esse endpoint é usado para verificar se a aplicação está rodando.
    Ferramentas de monitoramento e o Docker healthcheck chamam essa rota.
    """
    res = client.get("/health")

    # Verifica se retornou status 200 (OK)
    assert res.status_code == 200

    # Verifica se o corpo da resposta é exatamente {"status": "ok"}
    assert res.json() == {"status": "ok"}


def test_metrics():
    """Testa o endpoint de métricas Prometheus (GET /metrics).
    Esse endpoint expõe métricas da aplicação em formato texto,
    que podem ser coletadas pelo Prometheus para monitoramento.
    """
    res = client.get("/metrics")

    # Verifica se retornou status 200 (OK)
    assert res.status_code == 200

    # Verifica se o content-type é text/plain (formato padrão do Prometheus)
    assert "text/plain" in res.headers["content-type"]


# ==================== TESTES DE CRIAÇÃO (POST) ====================


def test_create_task():
    """Testa a criação de uma nova tarefa (POST /tasks).
    Envia um JSON com título, descrição e status,
    e verifica se a API retorna os dados corretos com um ID gerado.
    """
    # Envia uma requisição POST com os dados da tarefa no corpo (JSON)
    res = client.post(
        "/tasks",
        json={"title": "Test Task", "description": "desc", "done": False},
    )

    # Status 201 = Created (recurso criado com sucesso)
    assert res.status_code == 201

    # Converte a resposta JSON em dicionário Python
    body = res.json()

    # Verifica se os campos retornados batem com o que foi enviado
    assert body["title"] == "Test Task"
    assert body["description"] == "desc"
    assert body["done"] is False

    # Verifica se a API gerou um ID automático para a tarefa
    assert "id" in body


# ==================== TESTES DE LISTAGEM (GET) ====================


def test_list_tasks():
    """Testa a listagem de todas as tarefas (GET /tasks).
    Primeiro cria uma tarefa para garantir que existe pelo menos uma,
    depois verifica se a listagem retorna um array não vazio.
    """
    # Cria uma tarefa antes de listar (garante que a lista não está vazia)
    client.post("/tasks", json={"title": "List Test", "done": False})

    # Faz GET para buscar todas as tarefas
    res = client.get("/tasks")

    # Verifica se retornou 200 (OK)
    assert res.status_code == 200

    # Verifica se a resposta é uma lista (array JSON)
    assert isinstance(res.json(), list)

    # Verifica se tem pelo menos 1 tarefa na lista
    assert len(res.json()) >= 1


# ==================== TESTES DE BUSCA POR ID (GET) ====================


def test_get_task_by_id():
    """Testa a busca de uma tarefa específica pelo ID (GET /tasks/{id}).
    Cria uma tarefa, pega o ID retornado, e depois busca por esse ID.
    """
    # Cria uma tarefa e armazena a resposta
    create = client.post("/tasks", json={"title": "Get Test", "done": False})

    # Extrai o ID da tarefa criada
    task_id = create.json()["id"]

    # Busca a tarefa pelo ID
    res = client.get(f"/tasks/{task_id}")

    # Verifica se encontrou (200 OK)
    assert res.status_code == 200

    # Verifica se o título bate com o que foi criado
    assert res.json()["title"] == "Get Test"


def test_get_task_not_found():
    """Testa a busca por um ID que não existe (GET /tasks/99999).
    A API deve retornar 404 (Not Found) quando o recurso não é encontrado.
    Esse teste garante que o tratamento de erro está funcionando.
    """
    # Busca um ID que certamente não existe
    res = client.get("/tasks/99999")

    # Verifica se retornou 404 (Not Found)
    assert res.status_code == 404


# ==================== TESTES DE ATUALIZAÇÃO (PUT) ====================


def test_update_task():
    """Testa a atualização de uma tarefa existente (PUT /tasks/{id}).
    Cria uma tarefa, depois atualiza o título, descrição e status,
    e verifica se os novos valores foram persistidos.
    """
    # Cria uma tarefa com título "Before Update"
    create = client.post(
        "/tasks", json={"title": "Before Update", "done": False}
    )
    task_id = create.json()["id"]

    # Atualiza a tarefa com novos valores
    res = client.put(
        f"/tasks/{task_id}",
        json={"title": "After Update", "description": "updated", "done": True},
    )

    # Verifica se a atualização foi bem-sucedida (200 OK)
    assert res.status_code == 200

    # Verifica se os campos foram realmente atualizados
    assert res.json()["title"] == "After Update"
    assert res.json()["done"] is True


def test_update_task_not_found():
    """Testa a atualização de uma tarefa que não existe (PUT /tasks/99999).
    Deve retornar 404, não pode dar erro 500 ou atualizar algo inexistente.
    """
    res = client.put(
        "/tasks/99999",
        json={"title": "Nope", "description": "", "done": False},
    )

    # Verifica se retornou 404 (Not Found)
    assert res.status_code == 404


# ==================== TESTES DE DELEÇÃO (DELETE) ====================


def test_delete_task():
    """Testa a deleção de uma tarefa existente (DELETE /tasks/{id}).
    Cria uma tarefa, deleta ela, e depois tenta buscar de novo
    para confirmar que foi realmente removida do banco.
    """
    # Cria uma tarefa para ser deletada
    create = client.post(
        "/tasks", json={"title": "To Delete", "done": False}
    )
    task_id = create.json()["id"]

    # Deleta a tarefa
    res = client.delete(f"/tasks/{task_id}")

    # Status 204 = No Content (deletado com sucesso, sem corpo na resposta)
    assert res.status_code == 204

    # Tenta buscar a tarefa deletada para confirmar que não existe mais
    get_res = client.get(f"/tasks/{task_id}")

    # Deve retornar 404, pois a tarefa foi removida
    assert get_res.status_code == 404


def test_delete_task_not_found():
    """Testa a deleção de uma tarefa que não existe (DELETE /tasks/99999).
    Deve retornar 404. Garante que a API não ignora silenciosamente
    a tentativa de deletar algo inexistente.
    """
    res = client.delete("/tasks/99999")

    # Verifica se retornou 404 (Not Found)
    assert res.status_code == 404
