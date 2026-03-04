# TaskAPI - Desafio DevOps

API REST de gerenciamento de tarefas desenvolvida com FastAPI + SQLite, com pipeline CI/CD completo via GitHub Actions.

## Stack Tecnológica

- **Backend:** Python 3.11, FastAPI, SQLModel
- **Banco de dados:** SQLite
- **Testes:** pytest + pytest-cov (cobertura ~99%)
- **Lint/Format:** flake8 + black
- **Container:** Docker multi-stage com Alpine
- **CI/CD:** GitHub Actions
- **Observabilidade:** Health check + métricas Prometheus

## Pipeline CI/CD

O workflow `.github/workflows/ci-cd.yml` é acionado a cada push ou PR na branch `main`:

**Job CI:** instalação de dependências, lint com flake8, verificação de formatação com black, execução de testes com cobertura mínima de 80%.

**Job Build & Push:** build da imagem Docker e push para o GitHub Container Registry (GHCR), executado apenas em push na main após CI verde.

**Job Deploy Staging:** deploy automatizado no ambiente de staging após build bem-sucedido.

**Job Deploy Production:** deploy para produção com aprovação manual via GitHub Environments.

## Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------:|
| POST | /tasks | Criar tarefa |
| GET | /tasks | Listar tarefas |
| GET | /tasks/{id} | Buscar por ID |
| PUT | /tasks/{id} | Atualizar |
| DELETE | /tasks/{id} | Deletar |
| GET | /health | Status da aplicação |
| GET | /metrics | Métricas Prometheus |

## Execução Local

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Swagger: http://localhost:8000/docs

## Docker

```bash
# Build
docker build -t taskapi .

# Run
docker run -p 8000:8000 taskapi

# Ou via Docker Compose
docker compose up --build
```

## Testes

```bash
pytest --cov=app --cov-report=term-missing --cov-fail-under=80
```

## Estrutura do Projeto

```
taskapi/
├── app/
│   ├── main.py          # App FastAPI + health/metrics
│   ├── models.py         # Modelo Task (SQLModel)
│   ├── db.py             # Engine e sessão SQLite
│   └── routes.py         # Endpoints CRUD
├── tests/
│   ├── conftest.py       # Setup do banco para testes
│   └── test_tasks.py     # 10 testes automatizados
├── .github/workflows/
│   └── ci-cd.yml         # Pipeline CI/CD
├── Dockerfile            # Multi-stage Alpine
├── docker-compose.yml    # Ambiente staging
├── .flake8               # Configuração do linter
├── .dockerignore
├── .gitignore
└── requirements.txt
```