# Arquitetura da Solução

## Visão Geral

A TaskAPI é deployada em um cluster Kubernetes local (Kind) com 3 ambientes independentes, cada um em seu próprio namespace. O deploy é orquestrado pelo Helm, que gerencia os manifests Kubernetes de forma parametrizada.

## Diagrama

```
┌──────────────────────────────────────────────────────────┐
│                   Kind Cluster                           │
│                (taskapi-cluster)                          │
│                                                          │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────┐  │
│  │  ns: taskapi- │ │  ns: taskapi- │ │  ns: taskapi- │  │
│  │      dev      │ │    staging    │ │      prod     │  │
│  │               │ │               │ │               │  │
│  │  1 Pod        │ │  2 Pods       │ │  3 Pods       │  │
│  │  ClusterIP    │ │  ClusterIP    │ │  ClusterIP    │  │
│  │  NodePort     │ │  NodePort     │ │  NodePort     │  │
│  │  ConfigMap    │ │  ConfigMap    │ │  ConfigMap    │  │
│  │               │ │  PVC 1Gi     │ │  PVC 2Gi      │  │
│  │               │ │  Ingress     │ │  Ingress      │  │
│  │               │ │               │ │  HPA (2-5)    │  │
│  └───────┬───────┘ └───────┬───────┘ └───────┬───────┘  │
│          │                 │                 │           │
│     :30080            :30081            :30082           │
└──────────┼─────────────────┼─────────────────┼───────────┘
           │                 │                 │
     localhost:30080   localhost:30081   localhost:30082
```

## Componentes

### Aplicação (TaskAPI)

- **Framework:** FastAPI (Python 3.11)
- **Banco de dados:** SQLite (arquivo local)
- **Imagem Docker:** Multi-stage build com Alpine Linux
- **Porta do container:** 8000

### Cluster Kubernetes

- **Ferramenta:** Kind (Kubernetes in Docker)
- **Nodes:** 1 control-plane
- **Port mappings:** 30080, 30081, 30082 expostos para localhost
- **Motivo da escolha:** leve, rápido de criar/destruir, ideal para ambiente de estudo e desenvolvimento

### Helm Chart

O chart está em `./helm/` e contém templates parametrizados que geram os manifests Kubernetes. Os valores base ficam em `values.yaml` e cada ambiente sobrescreve apenas o necessário via `environments/values-{env}.yaml`.

## Fluxo de Deploy

1. **Build:** `docker build` gera a imagem `taskapi:latest` a partir do Dockerfile multi-stage
2. **Carregamento:** `kind load docker-image` transfere a imagem para dentro do cluster Kind (necessário porque Kind não acessa o Docker registry local)
3. **Deploy:** `helm upgrade --install` renderiza os templates com os values do ambiente e aplica no namespace correspondente
4. **Verificação:** Kubernetes executa liveness/readiness probes para garantir que os pods estão saudáveis

## Isolamento por Namespace

Cada ambiente roda em seu próprio namespace Kubernetes:

- `taskapi-dev` — desenvolvimento, iteração rápida
- `taskapi-staging` — validação, simula produção
- `taskapi-prod` — produção, alta disponibilidade

Isso garante isolamento total de recursos: pods, services, configmaps e PVCs de um ambiente não interferem no outro.

## Decisões Técnicas

**Por que Kind e não Minikube?** Kind é mais leve (roda dentro do Docker), mais rápido para criar/destruir clusters, e suporta port mappings nativos. Para um ambiente de estudo com 24GB RAM, é a melhor opção.

**Por que SQLite e não PostgreSQL?** A TaskAPI é um projeto de estudo focado em DevOps, não em banco de dados. SQLite simplifica o deploy (não precisa de StatefulSet adicional) e permite focar no Helm/Kubernetes.

**Por que NodePort e não LoadBalancer?** Kind não suporta LoadBalancer nativamente. NodePort é a forma mais direta de expor serviços para localhost em um cluster local.

**Por que Helm e não kubectl apply?** Helm permite parametrizar os manifests, gerenciar múltiplos ambientes com um único chart, e fazer upgrade/rollback com versionamento automático.
