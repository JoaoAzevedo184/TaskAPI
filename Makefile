# ============================================================
# TaskAPI Helm Chart - Makefile
# ============================================================

CHART_DIR := ./helm
ENV_DIR   := ./helm/environments
KIND_CFG  := ./kind-config.yaml
IMAGE     := taskapi:latest

.PHONY: help cluster-create cluster-delete build-image load-image \
        deploy-dev deploy-staging deploy-prod \
        undeploy-dev undeploy-staging undeploy-prod \
        status lint template-dev template-staging template-prod \
        rollback-dev rollback-staging rollback-prod \
        all clean

help: ## Mostra esta mensagem de ajuda
	@echo ""
	@echo "  TaskAPI Helm Chart - Comandos Disponíveis"
	@echo "  =========================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""

cluster-create: ## Cria o cluster Kind com port mappings
	kind create cluster --config $(KIND_CFG)

cluster-delete: ## Remove o cluster Kind
	kind delete cluster --name taskapi-cluster

build-image: ## Builda a imagem Docker da TaskAPI
	docker build -t $(IMAGE) .

load-image: ## Carrega a imagem no cluster Kind
	kind load docker-image $(IMAGE) --name taskapi-cluster

lint: ## Valida a sintaxe do chart
	helm lint $(CHART_DIR)
	helm lint $(CHART_DIR) -f $(ENV_DIR)/values-dev.yaml
	helm lint $(CHART_DIR) -f $(ENV_DIR)/values-staging.yaml
	helm lint $(CHART_DIR) -f $(ENV_DIR)/values-production.yaml

template-dev: ## Renderiza os manifests para dev (dry-run)
	helm template taskapi-dev $(CHART_DIR) -f $(ENV_DIR)/values-dev.yaml

template-staging: ## Renderiza os manifests para staging (dry-run)
	helm template taskapi-stg $(CHART_DIR) -f $(ENV_DIR)/values-staging.yaml

template-prod: ## Renderiza os manifests para production (dry-run)
	helm template taskapi-prod $(CHART_DIR) -f $(ENV_DIR)/values-production.yaml

deploy-dev: ## Deploy no ambiente dev (localhost:30080)
	helm upgrade --install taskapi-dev $(CHART_DIR) \
		-f $(ENV_DIR)/values-dev.yaml \
		--create-namespace --namespace taskapi-dev

deploy-staging: ## Deploy no ambiente staging (localhost:30081)
	helm upgrade --install taskapi-stg $(CHART_DIR) \
		-f $(ENV_DIR)/values-staging.yaml \
		--create-namespace --namespace taskapi-staging

deploy-prod: ## Deploy no ambiente production (localhost:30082)
	helm upgrade --install taskapi-prod $(CHART_DIR) \
		-f $(ENV_DIR)/values-production.yaml \
		--create-namespace --namespace taskapi-prod

undeploy-dev: ## Remove deploy do dev
	helm uninstall taskapi-dev --namespace taskapi-dev

undeploy-staging: ## Remove deploy do staging
	helm uninstall taskapi-stg --namespace taskapi-staging

undeploy-prod: ## Remove deploy do production
	helm uninstall taskapi-prod --namespace taskapi-prod

rollback-dev: ## Rollback dev para revisão anterior
	helm rollback taskapi-dev --namespace taskapi-dev

rollback-staging: ## Rollback staging para revisão anterior
	helm rollback taskapi-stg --namespace taskapi-staging

rollback-prod: ## Rollback production para revisão anterior
	helm rollback taskapi-prod --namespace taskapi-prod

status: ## Mostra status de todos os ambientes
	@echo "\n Helm Releases:"
	@helm list --all-namespaces 2>/dev/null || echo "Nenhum release encontrado"
	@echo "\n Pods:"
	@kubectl get pods -n taskapi-dev 2>/dev/null || true
	@kubectl get pods -n taskapi-staging 2>/dev/null || true
	@kubectl get pods -n taskapi-prod 2>/dev/null || true

all: cluster-create build-image load-image deploy-dev deploy-staging deploy-prod status ## Setup completo

clean: undeploy-dev undeploy-staging undeploy-prod cluster-delete ## Remove tudo
