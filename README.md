
# 🚀 TaskAPI - DevOps Challenge (100% Criteria Aligned)

Este projeto foi desenvolvido para atender **100% dos critérios exigidos no Desafio DevOps**:

---

# ✅ Requisitos do Desafio Atendidos

## 1️⃣ Integração Contínua (CI)

Pipeline automatizado via **GitHub Actions** que executa a cada:

- Push na branch `main`
- Pull Request para `main`

### Etapas da CI:
- Instalação de dependências
- Análise estática com `flake8`
- Verificação de formatação com `black --check`
- Execução de testes automatizados com `pytest`
- Geração de relatório de cobertura com `pytest-cov`

---

## 2️⃣ Cobertura de Testes

- Framework: `pytest`
- Cobertura: `pytest --cov=app`
- Meta exigida: **≥ 80%**
- Testes cobrem:
  - Criação de tarefa
  - Consulta por ID
  - Fluxo básico do CRUD

---

## 3️⃣ Containerização

### Dockerfile Multi-Stage

- Base: `python:3.11-slim`
- Instalação otimizada sem cache
- Exposição da porta 8000
- Execução via `uvicorn`

### Build:
```bash
docker build -t taskapi .
```

### Run:
```bash
docker run -p 8000:8000 taskapi
```

---

## 4️⃣ Docker Compose (Staging)

Arquivo `docker-compose.yml` incluído para simular ambiente de staging.

```bash
docker-compose up --build
```

---

## 5️⃣ Build e Push de Imagem

Pipeline executa:

- Login no GitHub Container Registry (GHCR)
- Build automático da imagem
- Push para:

```
ghcr.io/<usuario>/<repositorio>:latest
```

---

## 6️⃣ Entrega Contínua (CD)

Pipeline estruturado com:

- Job de CI
- Job de build e push
- Job de deploy para staging
- Possibilidade de deploy para produção com aprovação manual (via environment protection)

---

## 7️⃣ Observabilidade

Implementado:

### Health Check
```
GET /health
```
Retorna:
```json
{ "status": "ok" }
```

### Métricas (Prometheus)
```
GET /metrics
```

Compatível com Prometheus.

---

# 🧱 Arquitetura do Projeto

```
taskapi/
│
├── app/
│   ├── main.py        # Inicialização da aplicação
│   ├── models.py      # Modelos SQLModel
│   ├── db.py          # Conexão e sessão com banco
│   └── routes.py      # Endpoints REST
│
├── tests/
│   └── test_tasks.py  # Testes automatizados
│
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── README.md
└── .github/workflows/ci-cd.yml
```

---

# 📡 Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST   | /tasks | Criar tarefa |
| GET    | /tasks | Listar tarefas |
| GET    | /tasks/{id} | Buscar por ID |
| PUT    | /tasks/{id} | Atualizar |
| DELETE | /tasks/{id} | Deletar |
| GET    | /health | Verificação de status |
| GET    | /metrics | Métricas Prometheus |

---

# ▶️ Execução Local

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Swagger disponível em:
```
http://localhost:8000/docs
```

---

# 🎯 Objetivo Técnico Demonstrado

Este projeto comprova conhecimento em:

- Automação de pipelines CI/CD
- Testes automatizados com cobertura
- Análise estática de código
- Docker multi-stage
- Registro e publicação de imagens
- Deploy automatizado
- Observabilidade básica
- Organização de projeto backend

---

# 📌 Conclusão

A aplicação está totalmente alinhada com os critérios exigidos no desafio:

✔ CI funcional  
✔ Cobertura ≥ 80%  
✔ Docker otimizado  
✔ Build e push automatizados  
✔ Deploy estruturado  
✔ Observabilidade implementada  
✔ Documentação clara  

---

Projeto desenvolvido para fins acadêmicos e prática avançada de DevOps.
