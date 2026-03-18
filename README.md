# TaskAPI - Desafio DevOps

API REST de gerenciamento de tarefas desenvolvida com FastAPI + SQLite, com pipeline CI/CD completo via GitHub Actions e deploy orquestrado com Helm no Kubernetes.

## Stack Tecnológica

- **Backend:** Python 3.11, FastAPI, SQLModel
- **Banco de dados:** SQLite
- **Testes:** pytest + pytest-cov (cobertura ~99%)
- **Lint/Format:** flake8 + black
- **Container:** Docker multi-stage com Alpine
- **CI/CD:** GitHub Actions
- **Orquestração:** Kubernetes (Kind) + Helm Charts
- **Observabilidade:** Health check + métricas Prometheus

## Pipeline CI/CD

O workflow `.github/workflows/ci-cd.yml` é acionado a cada push ou PR na branch `main`:

**Job CI:** instalação de dependências, lint com flake8, verificação de formatação com black, execução de testes com cobertura mínima de 80%.

**Job Build & Push:** build da imagem Docker e push para o GitHub Container Registry (GHCR), executado apenas em push na main após CI verde.

**Job Deploy Staging:** deploy automatizado no ambiente de staging após build bem-sucedido.

**Job Deploy Production:** deploy para produção com aprovação manual via GitHub Environments.

## Deploy com Helm no Kubernetes

A aplicação pode ser deployada em um cluster Kubernetes local (Kind) com suporte a 3 ambientes independentes usando Helm Charts.

### Ambientes

| Ambiente | Réplicas | Log Level | Persistência | Autoscaling | Porta |
|----------|----------|-----------|-------------|-------------|-------|
| Dev | 1 | DEBUG | — | — | 30080 |
| Staging | 2 | WARNING | PVC 1Gi | — | 30081 |
| Production | 3 | ERROR | PVC 2Gi | HPA 2-5 | 30082 |

### Quick Start (Helm)

```bash
# Setup completo automatizado
./setup-homelab.sh

# Ou passo a passo com Makefile
make cluster-create
make build-image
make load-image
make deploy-dev
make deploy-staging
make deploy-prod
```

Acesse o Swagger UI:
- Dev: http://localhost:30080/docs
- Staging: http://localhost:30081/docs
- Production: http://localhost:30082/docs

### Upgrade e Rollback

```bash
# Upgrade com nova configuração
helm upgrade taskapi-dev ./helm -f ./helm/environments/values-dev.yaml --set config.LOG_LEVEL=INFO -n taskapi-dev

# Rollback para versão anterior
make rollback-dev

# Ver histórico de releases
helm history taskapi-dev -n taskapi-dev
```

### Testes de Validação

```bash
./test-upgrade-rollback.sh 2>&1 | tee test-results.txt
```

Para mais detalhes, consulte a documentação em [`docs/`](docs/) e o guia [`GETTING_STARTED.md`](GETTING_STARTED.md).

## Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | /tasks | Criar tarefa |
| GET | /tasks | Listar tarefas |
| GET | /tasks/{id} | Buscar por ID |
| PUT | /tasks/{id} | Atualizar |
| DELETE | /tasks/{id} | Deletar |
| GET | /health | Status da aplicação |
| GET | /metrics | Métricas Prometheus |

## Execução Local

Consulte o guia completo em [`GETTING_STARTED.md`](GETTING_STARTED.md) para todas as opções de execução (Python, Docker, Kubernetes).

```bash
# Python direto
pip install -r requirements.txt
uvicorn app.main:app --reload

# Docker
docker compose up --build

# Kubernetes (Kind + Helm)
./setup-homelab.sh
```

## Testes

```bash
pytest --cov=app --cov-report=term-missing --cov-fail-under=80
```

## Estrutura do Projeto

```
taskapi/
├── app/                         # Código da aplicação
│   ├── main.py                  # App FastAPI + health/metrics
│   ├── models.py                # Modelo Task (SQLModel)
│   ├── db.py                    # Engine e sessão SQLite
│   └── routes.py                # Endpoints CRUD
├── tests/                       # Testes automatizados
│   ├── conftest.py
│   └── test_tasks.py
├── helm/                        # Helm Chart (Kubernetes)
│   ├── Chart.yaml               # Metadados do chart
│   ├── values.yaml              # Valores base
│   ├── environments/            # Overrides por ambiente
│   │   ├── values-dev.yaml
│   │   ├── values-staging.yaml
│   │   └── values-production.yaml
│   └── templates/               # Manifests K8s
│       ├── _helpers.tpl
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       ├── ingress.yaml
│       ├── hpa.yaml
│       └── pvc.yaml
├── docs/                        # Documentação técnica
│   ├── arquitetura.md
│   ├── helm-chart.md
│   └── testes-validacao.md
├── .github/workflows/
│   └── ci-cd.yml                # Pipeline CI/CD
├── Dockerfile                   # Multi-stage Alpine
├── docker-compose.yml           # Ambiente local
├── kind-config.yaml             # Configuração do cluster Kind
├── Makefile                     # Automação Helm/K8s
├── setup-homelab.sh             # Setup automatizado completo
├── test-upgrade-rollback.sh     # Testes de upgrade/rollback
├── GETTING_STARTED.md           # Guia de primeiros passos
└── requirements.txt
```

## Autor

**João Victor Azevedo**
- GitHub: [@JoaoAzevedo184](https://github.com/JoaoAzevedo184)
- Curso: Análise e Desenvolvimento de Sistemas — UNINASSAU Olinda
- Disciplina: DevOps | Prof. Cloves Rocha
