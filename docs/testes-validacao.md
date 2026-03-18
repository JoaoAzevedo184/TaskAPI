# Testes e Validação

## Visão Geral

O script `test-upgrade-rollback.sh` executa 8 testes automatizados que validam o ciclo de vida completo do deploy com Helm no Kubernetes.

## Como Executar

```bash
# Pré-requisito: setup já executado (./setup-homelab.sh)

# Rodar testes e salvar evidências
./test-upgrade-rollback.sh 2>&1 | tee test-results.txt
```

O arquivo `test-results.txt` serve como evidência para o relatório e apresentação.

## Testes Executados

### Teste 1: Estado inicial

Verifica se todos os releases Helm foram instalados corretamente e exibe o histórico do release dev.

**Comandos:** `helm list --all-namespaces`, `helm history taskapi-dev -n taskapi-dev`

**Resultado esperado:** 3 releases listados (taskapi-dev, taskapi-stg, taskapi-prod), todos com status `deployed`.

### Teste 2: Upgrade de configuração

Altera o `LOG_LEVEL` do ambiente dev de `DEBUG` para `INFO` usando `--set`.

**Comandos:**
```bash
helm upgrade taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --set config.LOG_LEVEL=INFO \
    --namespace taskapi-dev
```

**Resultado esperado:** ConfigMap atualizado com `LOG_LEVEL: "INFO"`, nova revisão criada no histórico.

**O que demonstra:** Helm permite alterar configurações sem editar arquivos, e a annotation `checksum/config` no Deployment força a recriação dos pods quando o ConfigMap muda.

### Teste 3: Rollback

Reverte o ambiente dev para a revisão anterior (LOG_LEVEL volta para DEBUG).

**Comando:** `helm rollback taskapi-dev -n taskapi-dev`

**Resultado esperado:** ConfigMap restaurado com `LOG_LEVEL: "DEBUG"`, nova revisão no histórico com status `superseded` para a anterior.

**O que demonstra:** Helm mantém histórico completo e permite reverter qualquer mudança com um comando.

### Teste 4: Scaling manual

Escala o ambiente dev de 1 para 3 réplicas via `--set replicaCount=3`, depois reverte.

**Resultado esperado:** 3 pods rodando durante o teste, voltando para 1 após rollback.

**O que demonstra:** Helm permite escalar a aplicação sem editar manifests, e o rollback restaura o estado anterior completo.

### Teste 5: Upgrade de versão da imagem

Simula deploy de nova versão taggeando a imagem como `v2.0.0` e deployando.

**Comandos:**
```bash
docker tag taskapi:latest taskapi:v2.0.0
kind load docker-image taskapi:v2.0.0 --name taskapi-cluster
helm upgrade taskapi-dev ./helm --set image.tag=v2.0.0 -n taskapi-dev
```

**Resultado esperado:** Pod rodando com imagem `taskapi:v2.0.0`, revertido para `taskapi:latest` após rollback.

**O que demonstra:** Fluxo completo de deploy de nova versão com possibilidade de rollback imediato em caso de problemas.

### Teste 6: Helm lint

Valida a sintaxe do chart e de todos os values por ambiente.

**Comandos:**
```bash
helm lint ./helm
helm lint ./helm -f ./helm/environments/values-dev.yaml
helm lint ./helm -f ./helm/environments/values-staging.yaml
helm lint ./helm -f ./helm/environments/values-production.yaml
```

**Resultado esperado:** Sem erros em nenhum ambiente.

### Teste 7: Recursos por namespace

Lista todos os recursos Kubernetes (pods, services, configmaps, PVCs, HPAs) em cada namespace.

**Resultado esperado:**
- `taskapi-dev`: 1 pod, 2 services, 1 configmap
- `taskapi-staging`: 2 pods, 2 services, 1 configmap, 1 PVC
- `taskapi-prod`: 3 pods, 2 services, 1 configmap, 1 PVC, 1 HPA

### Teste 8: Teste HTTP

Faz requisição HTTP ao Swagger UI de cada ambiente.

**Resultado esperado:** HTTP 200 nas 3 portas (30080, 30081, 30082).

## Resolução de Problemas

### Pods em CrashLoopBackOff

```bash
# Ver logs do pod
kubectl logs -n taskapi-dev -l app.kubernetes.io/name=taskapi

# Descrever pod para ver eventos
kubectl describe pod -n taskapi-dev -l app.kubernetes.io/name=taskapi
```

### Porta já em uso

```bash
# Verificar o que está usando a porta
sudo lsof -i :30080

# Solução: deletar cluster e recriar
make cluster-delete
make cluster-create
```

### Imagem não encontrada pelo Kind

```bash
# Verificar imagens carregadas
docker exec taskapi-cluster-control-plane crictl images | grep taskapi

# Recarregar
kind load docker-image taskapi:latest --name taskapi-cluster
```
