#!/bin/bash
# ============================================================
# TaskAPI Helm Chart - Setup Completo para Homelab
# ============================================================
# Homelab = laboratório caseiro de TI. Um computador pessoal
# usado para praticar infraestrutura, containers e DevOps.
#
# Executa: ./setup-homelab.sh
# Pré-requisito: Docker instalado e rodando
# ============================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERRO]${NC} $1"; }

echo ""
echo "=========================================="
echo "  TaskAPI - Setup Project"
echo "=========================================="
echo ""

# ============================================================
# FASE 0: Verificações
# ============================================================
info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker não encontrado. Instale primeiro."
    exit 1
fi

if ! docker info &> /dev/null 2>&1; then
    error "Docker não está rodando. Inicie com: sudo systemctl start docker"
    exit 1
fi
ok "Docker OK"

# ============================================================
# FASE 1: Instalar ferramentas
# ============================================================
echo ""
info "=== FASE 1: Instalando ferramentas ==="

# kubectl
if ! command -v kubectl &> /dev/null; then
    info "Instalando kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    ok "kubectl instalado"
else
    ok "kubectl já instalado"
fi

# Kind
if ! command -v kind &> /dev/null; then
    info "Instalando Kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    ok "Kind instalado: $(kind version)"
else
    ok "Kind já instalado"
fi

# Helm
if ! command -v helm &> /dev/null; then
    info "Instalando Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ok "Helm instalado: $(helm version --short)"
else
    ok "Helm já instalado"
fi

echo ""
info "Todas as ferramentas prontas!"

# ============================================================
# FASE 2: Criar cluster Kind
# ============================================================
echo ""
info "=== FASE 2: Criando cluster Kind ==="

if kind get clusters 2>/dev/null | grep -q "taskapi-cluster"; then
    warn "Cluster 'taskapi-cluster' já existe. Removendo..."
    kind delete cluster --name taskapi-cluster
fi

info "Criando cluster com port mappings (30080, 30081, 30082)..."
kind create cluster --config kind-config.yaml --wait 60s
ok "Cluster criado!"

info "Verificando nodes..."
kubectl get nodes
echo ""

# ============================================================
# FASE 3: Build e carregamento da imagem
# ============================================================
echo ""
info "=== FASE 3: Build e carregamento da imagem ==="

info "Buildando imagem Docker..."
docker build -t taskapi:latest .
ok "Imagem buildada!"

info "Carregando imagem no cluster Kind..."
kind load docker-image taskapi:latest --name taskapi-cluster
ok "Imagem carregada no cluster!"

# ============================================================
# FASE 4: Deploy nos 3 ambientes
# ============================================================
echo ""
info "=== FASE 4: Deploy nos 3 ambientes ==="

info "Deploying DEV..."
helm upgrade --install taskapi-dev ./helm \
    -f ./helm/environments/values-dev.yaml \
    --create-namespace --namespace taskapi-dev \
    --wait --timeout 120s
ok "Dev deployado!"

info "Deploying STAGING..."
helm upgrade --install taskapi-stg ./helm \
    -f ./helm/environments/values-staging.yaml \
    --create-namespace --namespace taskapi-staging \
    --wait --timeout 120s
ok "Staging deployado!"

info "Deploying PRODUCTION..."
helm upgrade --install taskapi-prod ./helm \
    -f ./helm/environments/values-production.yaml \
    --create-namespace --namespace taskapi-prod \
    --wait --timeout 120s
ok "Production deployado!"

# ============================================================
# FASE 5: Verificação
# ============================================================
echo ""
info "=== FASE 5: Verificação ==="

echo ""
info "Helm Releases:"
helm list --all-namespaces
echo ""

info "Pods - Dev:"
kubectl get pods -n taskapi-dev -o wide
echo ""

info "Pods - Staging:"
kubectl get pods -n taskapi-staging -o wide
echo ""

info "Pods - Production:"
kubectl get pods -n taskapi-prod -o wide
echo ""

info "Services (NodePort):"
kubectl get svc -n taskapi-dev | grep -i nodeport || true
kubectl get svc -n taskapi-staging | grep -i nodeport || true
kubectl get svc -n taskapi-prod | grep -i nodeport || true
echo ""

# ============================================================
# FASE 6: Teste de acesso
# ============================================================
echo ""
info "=== FASE 6: Testando acesso ==="

sleep 5

for port in 30080 30081 30082; do
    env_name="dev"
    [ "$port" = "30081" ] && env_name="staging"
    [ "$port" = "30082" ] && env_name="production"
    
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/docs 2>/dev/null || echo "000")
    if [ "$status" = "200" ]; then
        ok "$env_name (localhost:$port) → HTTP $status"
    else
        warn "$env_name (localhost:$port) → HTTP $status (pode estar ainda subindo)"
    fi
done

echo ""
echo "=========================================="
echo -e "  ${GREEN}Deploy concluído com sucesso!${NC}"
echo "=========================================="
echo ""
echo "  Acesse os ambientes:"
echo -e "  ${CYAN}Dev:${NC}        http://localhost:30080/docs"
echo -e "  ${CYAN}Staging:${NC}    http://localhost:30081/docs"
echo -e "  ${CYAN}Production:${NC} http://localhost:30082/docs"
echo ""
echo "  Comandos úteis:"
echo "  make status          → ver pods e releases"
echo "  make rollback-dev    → rollback do dev"
echo "  make clean           → remover tudo"
echo ""
