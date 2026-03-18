# Primeiros Passos — TaskAPI

Este guia apresenta as 3 formas de executar a TaskAPI, do mais simples ao mais completo.

---

## Opção 1: Python (desenvolvimento local)

A forma mais rápida para desenvolver e testar a API diretamente na sua máquina.

### Pré-requisitos

- Python 3.11+
- pip

### Passos

```bash
# 1. Clonar o repositório
git clone https://github.com/JoaoAzevedo184/TaskAPI.git
cd TaskAPI

# 2. Criar ambiente virtual (recomendado)
python -m venv venv
source venv/bin/activate

# 3. Instalar dependências
pip install -r requirements.txt

# 4. Rodar a aplicação
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Acessar

- Swagger UI: http://localhost:8000/docs
- Health check: http://localhost:8000/health

### Rodar testes

```bash
# Instalar dependências de teste
pip install pytest pytest-cov black flake8

# Lint
flake8 .

# Formatação
black --check .

# Testes com cobertura
pytest --cov=app --cov-report=term-missing --cov-fail-under=80
```

---

## Opção 2: Docker (ambiente isolado)

Executa a aplicação em um container, sem instalar Python na máquina.

### Pré-requisitos

- Docker

### Com Docker Compose (recomendado)

```bash
# 1. Clonar o repositório
git clone https://github.com/JoaoAzevedo184/TaskAPI.git
cd TaskAPI

# 2. Subir com Docker Compose
docker compose up --build

# Para rodar em background
docker compose up --build -d

# Para parar
docker compose down
```

### Com Docker direto

```bash
# 1. Build da imagem
docker build -t taskapi:latest .

# 2. Rodar o container
docker run -p 8000:8000 taskapi:latest

# Rodar em background
docker run -d -p 8000:8000 --name taskapi taskapi:latest

# Ver logs
docker logs -f taskapi

# Parar
docker stop taskapi && docker rm taskapi
```

### Acessar

- Swagger UI: http://localhost:8000/docs
- Health check: http://localhost:8000/health

---

## Opção 3: Kubernetes com Helm (deploy orquestrado)

Deploy completo com 3 ambientes (dev, staging, production) em um cluster Kubernetes local usando Kind e Helm Charts. Esta é a opção mais avançada e a que demonstra os conceitos do Desafio Técnico 3.

### Pré-requisitos

- Docker (único requisito manual — o script instala o resto)

### Setup automatizado

```bash
# 1. Clonar o repositório
git clone https://github.com/JoaoAzevedo184/TaskAPI.git
cd TaskAPI

# 2. Dar permissão aos scripts
chmod +x setup-project.sh test-upgrade-rollback.sh

# 3. Executar o setup completo
./setup-project.sh
```

O script faz automaticamente:
1. Instala **kubectl**, **Kind** e **Helm** (se não estiverem instalados)
2. Cria um cluster Kind com 3 port mappings
3. Builda a imagem Docker da TaskAPI
4. Carrega a imagem no cluster
5. Deploya nos 3 ambientes (dev, staging, production)
6. Testa o acesso HTTP

### Setup manual (passo a passo)

Se preferir entender cada etapa:

```bash
# 1. Criar cluster Kind
kind create cluster --config kind-config.yaml

# 2. Build da imagem
docker build -t taskapi:latest .

# 3. Carregar imagem no Kind
kind load docker-image taskapi:latest --name taskapi-cluster

# 4. Deploy por ambiente
helm upgrade --install taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --create-namespace --namespace taskapi-dev

helm upgrade --install taskapi-stg ./helm \
    -f ./helm/environments/values-staging.yaml \
    --create-namespace --namespace taskapi-staging

helm upgrade --install taskapi-prod ./helm \
    -f ./helm/environments/values-production.yaml \
    --create-namespace --namespace taskapi-prod
```

### Ou usando o Makefile

```bash
# Setup completo (um comando)
make all

# Ou individualmente
make cluster-create
make build-image
make load-image
make deploy-dev
make deploy-staging
make deploy-prod

# Ver todos os comandos disponíveis
make help
```

### Acessar

| Ambiente | URL | Porta |
|----------|-----|-------|
| Dev | http://localhost:30080/docs | 30080 |
| Staging | http://localhost:30081/docs | 30081 |
| Production | http://localhost:30082/docs | 30082 |

### Operações com Helm

```bash
# Ver status de todos os ambientes
make status

# Upgrade (exemplo: mudar log level)
helm upgrade taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --set config.LOG_LEVEL=INFO \
    --namespace taskapi-dev

# Rollback
make rollback-dev

# Ver histórico de releases
helm history taskapi-dev -n taskapi-dev

# Validar chart
make lint

# Ver manifests sem aplicar (dry-run)
make template-dev
```

### Testes de validação

Executa 8 testes automatizados (upgrade, rollback, scaling, lint, HTTP):

```bash
./test-upgrade-rollback.sh 2>&1 | tee test-results.txt
```

### Limpeza

```bash
# Remover tudo (undeploy + cluster)
make clean

# Ou individualmente
make undeploy-dev
make undeploy-staging
make undeploy-prod
make cluster-delete
```

---

## Resumo

| Opção | Quando usar | Comando |
|-------|-------------|---------|
| **Python** | Desenvolvimento e debug rápido | `uvicorn app.main:app --reload` |
| **Docker** | Testar em container isolado | `docker compose up --build` |
| **Kubernetes** | Deploy orquestrado multi-ambiente | `./setup-homelab.sh` |
