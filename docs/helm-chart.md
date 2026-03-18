# Helm Chart — Documentação Técnica

## Estrutura de Diretórios

```
helm/
├── Chart.yaml                 # Metadados do chart (nome, versão, autor)
├── values.yaml                # Valores padrão (base para todos os ambientes)
├── .helmignore                # Arquivos ignorados no empacotamento
├── environments/              # Overrides por ambiente
│   ├── values-dev.yaml        # Desenvolvimento
│   ├── values-staging.yaml    # Staging
│   └── values-production.yaml # Produção
└── templates/                 # Manifests Kubernetes parametrizados
    ├── _helpers.tpl            # Funções auxiliares (labels, nomes)
    ├── deployment.yaml         # Deployment da aplicação
    ├── service.yaml            # Service ClusterIP + NodePort
    ├── configmap.yaml          # Variáveis de ambiente
    ├── ingress.yaml            # Ingress (condicional)
    ├── hpa.yaml                # HorizontalPodAutoscaler (condicional)
    ├── pvc.yaml                # PersistentVolumeClaim (condicional)
    └── NOTES.txt               # Mensagem exibida após deploy
```

## Templates

### deployment.yaml

Gerencia os pods da aplicação. Principais recursos:

- **RollingUpdate:** `maxSurge=1, maxUnavailable=0` garante zero downtime durante upgrades
- **Health checks:** liveness probe (reinicia pods travados) e readiness probe (só recebe tráfego quando pronto), ambos no endpoint `/docs`
- **envFrom:** injeta variáveis do ConfigMap automaticamente
- **checksum/config:** annotation com sha256 do ConfigMap — quando o config muda, os pods são recriados automaticamente
- **Persistência condicional:** monta PVC apenas quando `persistence.enabled=true`

### service.yaml

Expõe a aplicação dentro do cluster (ClusterIP) e para localhost (NodePort):

- **ClusterIP:** comunicação interna entre serviços
- **NodePort:** acesso direto via `localhost:{porta}`, habilitado condicionalmente via `nodePort.enabled`

### configmap.yaml

Itera sobre `.Values.config` usando `range`, permitindo adicionar variáveis de ambiente sem modificar o template:

```yaml
data:
  {{- range $key, $value := .Values.config }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

### ingress.yaml

Criado condicionalmente quando `ingress.enabled=true` (staging e production). Suporta annotations dinâmicas para configurar rate limiting, rewrites, etc.

### hpa.yaml

HorizontalPodAutoscaler ativo apenas em production (`autoscaling.enabled=true`). Escala de 2 a 5 pods baseado em CPU (70%) e memória (80%).

### pvc.yaml

PersistentVolumeClaim para o banco SQLite. Ativo em staging (1Gi) e production (2Gi). Em dev, o SQLite fica no filesystem efêmero do pod (aceita perder dados no restart).

### _helpers.tpl

Funções Go template reutilizáveis:

- `taskapi.fullname` — nome completo do release (ex: `taskapi-dev-taskapi`)
- `taskapi.name` — nome curto do chart
- `taskapi.labels` — labels padrão (chart, version, managed-by, environment)
- `taskapi.selectorLabels` — labels de seleção (name, instance)
- `taskapi.chart` — label do chart com versão

## Estratégia de Values

O `values.yaml` base define todos os valores com defaults razoáveis. Cada ambiente sobrescreve apenas o necessário:

```
values.yaml (base)           → valores padrão para dev
  └── values-dev.yaml        → mínimas diferenças (pullPolicy: Always)
  └── values-staging.yaml    → 2 réplicas, PVC, Ingress
  └── values-production.yaml → 3 réplicas, PVC, HPA, Ingress, rate limit
```

O Helm faz merge: valores não especificados no override são herdados do base.

## Comparativo dos Ambientes

| Recurso | Dev | Staging | Production |
|---------|-----|---------|------------|
| Réplicas | 1 | 2 | 3 |
| APP_ENV | development | staging | production |
| LOG_LEVEL | DEBUG | WARNING | ERROR |
| Persistência | Desabilitada | PVC 1Gi | PVC 2Gi |
| Autoscaling | Desabilitado | Desabilitado | HPA 2-5 pods |
| Ingress | Desabilitado | Habilitado | Habilitado + rate limit |
| NodePort | 30080 | 30081 | 30082 |
| image.tag | latest | latest | 1.0.0 (versionada) |
| pullPolicy | Always | IfNotPresent | IfNotPresent |

## Comandos Úteis

```bash
# Validar chart
helm lint ./helm -f ./helm/environments/values-dev.yaml

# Ver manifests renderizados sem aplicar
helm template taskapi-dev ./helm -f ./helm/environments/values-dev.yaml

# Deploy
helm upgrade --install taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --create-namespace --namespace taskapi-dev

# Override inline (sem editar arquivo)
helm upgrade taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --set replicaCount=3 \
    --set config.LOG_LEVEL=INFO \
    -n taskapi-dev

# Histórico
helm history taskapi-dev -n taskapi-dev

# Rollback
helm rollback taskapi-dev -n taskapi-dev

# Rollback para revisão específica
helm rollback taskapi-dev 2 -n taskapi-dev
```
