#!/bin/bash
# ============================================================
# TaskAPI - Testes de Upgrade e Rollback
# ============================================================
# Executa após o setup: ./test-upgrade-rollback.sh
# Salve evidências: ./test-upgrade-rollback.sh 2>&1 | tee test-results.txt
# ============================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[TEST]${NC} $1"; }

echo ""
echo "=========================================="
echo "  TaskAPI - Testes de Upgrade & Rollback"
echo "=========================================="

# ============================================================
# TESTE 1: Verificar estado inicial
# ============================================================
echo ""
warn "TESTE 1: Estado inicial dos releases"
echo "--------------------------------------"
helm list --all-namespaces
echo ""

warn "Histórico do release dev:"
helm history taskapi-dev -n taskapi-dev
echo ""

# ============================================================
# TESTE 2: Upgrade com mudança de config
# ============================================================
warn "TESTE 2: Upgrade do dev (mudando LOG_LEVEL para INFO)"
echo "--------------------------------------"

helm upgrade taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --set config.LOG_LEVEL=INFO \
    --namespace taskapi-dev

info "Aguardando rollout..."
kubectl rollout status deployment -n taskapi-dev --timeout=60s

ok "Upgrade realizado!"
echo ""

info "Verificando novo ConfigMap:"
kubectl get configmap -n taskapi-dev -o yaml | grep LOG_LEVEL
echo ""

warn "Histórico após upgrade:"
helm history taskapi-dev -n taskapi-dev
echo ""

# ============================================================
# TESTE 3: Rollback
# ============================================================
warn "TESTE 3: Rollback do dev para revisão anterior"
echo "--------------------------------------"

helm rollback taskapi-dev -n taskapi-dev

info "Aguardando rollout..."
kubectl rollout status deployment -n taskapi-dev --timeout=60s

ok "Rollback realizado!"
echo ""

info "Verificando ConfigMap restaurado:"
kubectl get configmap -n taskapi-dev -o yaml | grep LOG_LEVEL
echo ""

warn "Histórico após rollback:"
helm history taskapi-dev -n taskapi-dev
echo ""

# ============================================================
# TESTE 4: Scaling manual
# ============================================================
warn "TESTE 4: Scaling do dev (1 → 3 réplicas)"
echo "--------------------------------------"

helm upgrade taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --set replicaCount=3 \
    --namespace taskapi-dev

info "Aguardando 3 pods..."
kubectl rollout status deployment -n taskapi-dev --timeout=60s

kubectl get pods -n taskapi-dev
echo ""
ok "Scaling OK — 3 pods rodando"

info "Revertendo para 1 réplica..."
helm rollback taskapi-dev -n taskapi-dev
kubectl rollout status deployment -n taskapi-dev --timeout=60s
ok "Revertido para 1 réplica"
echo ""

# ============================================================
# TESTE 5: Upgrade de versão da imagem
# ============================================================
warn "TESTE 5: Upgrade de versão da imagem (tag v2.0.0)"
echo "--------------------------------------"

info "Taggeando imagem como v2.0.0..."
docker tag taskapi:latest taskapi:v2.0.0
kind load docker-image taskapi:v2.0.0 --name taskapi-cluster

helm upgrade taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --set image.tag=v2.0.0 \
    --namespace taskapi-dev

kubectl rollout status deployment -n taskapi-dev --timeout=60s
ok "Deploy com v2.0.0!"

info "Verificando imagem do pod:"
kubectl get pods -n taskapi-dev -o jsonpath='{.items[0].spec.containers[0].image}'
echo ""
echo ""

info "Rollback para latest..."
helm rollback taskapi-dev -n taskapi-dev
kubectl rollout status deployment -n taskapi-dev --timeout=60s
ok "Revertido para latest"
echo ""

# ============================================================
# TESTE 6: Helm lint
# ============================================================
warn "TESTE 6: Validação com helm lint"
echo "--------------------------------------"

helm lint ./helm
helm lint ./helm -f ./helm/environments/values-dev.yaml
helm lint ./helm -f ./helm/environments/values-staging.yaml
helm lint ./helm -f ./helm/environments/values-production.yaml
ok "Lint passou em todos os ambientes!"
echo ""

# ============================================================
# TESTE 7: Recursos por namespace
# ============================================================
warn "TESTE 7: Recursos Kubernetes por ambiente"
echo "--------------------------------------"

for ns in taskapi-dev taskapi-staging taskapi-prod; do
    echo ""
    info "Namespace: $ns"
    echo "  Pods:"
    kubectl get pods -n $ns --no-headers 2>/dev/null | sed 's/^/    /'
    echo "  Services:"
    kubectl get svc -n $ns --no-headers 2>/dev/null | sed 's/^/    /'
    echo "  ConfigMaps:"
    kubectl get configmap -n $ns --no-headers 2>/dev/null | sed 's/^/    /'
    
    pvc=$(kubectl get pvc -n $ns --no-headers 2>/dev/null)
    if [ -n "$pvc" ]; then
        echo "  PVC:"
        echo "$pvc" | sed 's/^/    /'
    fi
    
    hpa=$(kubectl get hpa -n $ns --no-headers 2>/dev/null)
    if [ -n "$hpa" ]; then
        echo "  HPA:"
        echo "$hpa" | sed 's/^/    /'
    fi
done

# ============================================================
# TESTE 8: Acesso HTTP
# ============================================================
echo ""
warn "TESTE 8: Teste HTTP em todos os ambientes"
echo "--------------------------------------"

for port in 30080 30081 30082; do
    env_name="dev"
    [ "$port" = "30081" ] && env_name="staging"
    [ "$port" = "30082" ] && env_name="production"
    
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/docs 2>/dev/null || echo "000")
    if [ "$status" = "200" ]; then
        ok "$env_name → http://localhost:$port/docs → HTTP $status"
    else
        warn "$env_name → http://localhost:$port/docs → HTTP $status"
    fi
done

echo ""
echo "=========================================="
echo -e "  ${GREEN}Todos os testes concluídos!${NC}"
echo "=========================================="
echo ""
echo "  Dica: salve a saída como evidência:"
echo "  ./test-upgrade-rollback.sh 2>&1 | tee test-results.txt"
echo ""
