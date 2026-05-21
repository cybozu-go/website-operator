SHELL := /bin/bash
TAG ?= latest
IMG ?= controller:latest
CRD_OPTIONS = "crd:crdVersions=v1"

WEBSITE_OPERATOR = bin/website-operator
REPO_CHECKER = bin/repo-checker
WEBSITE_OPERATOR_UI = bin/website-operator-ui
GO_FILES := $(shell find . -type f -name '*.go')
GOOS := $(shell go env GOOS)
GOARCH := $(shell go env GOARCH)


all: $(WEBSITE_OPERATOR) $(REPO_CHECKER) $(WEBSITE_OPERATOR_UI)

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: manifests
manifests: ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
	controller-gen $(CRD_OPTIONS) rbac:roleName=manager-role webhook paths="./..." output:crd:artifacts:config=config/crd/bases
	kustomize build config/crd | yq e "." - > charts/website-operator/crds/website-crd.yaml

.PHONY: generate-chart
generate-chart:
	kustomize build config/release | helmify -crd-dir charts/website-operator

.PHONY: generate
generate: ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."

.PHONY: build-installer
build-installer: ## Generate dist/install.yaml from kustomize config/release output
	mkdir -p dist
	kustomize build config/release > dist/install.yaml
.PHONY: install
install: manifests ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	kustomize build config/crd | kubectl apply -f -

.PHONY: uninstall
uninstall: manifests ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config. Call with ignore-not-found=true to ignore resource not found errors during deletion.
	kustomize build config/crd | kubectl delete --ignore-not-found=$(ignore-not-found) -f -

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

.PHONY: test
test: manifests generate setup-envtest ## fmt vet ## Run tests.
	source <($(SETUP_ENVTEST) use -p env); go test -v -count 1 ./...

.PHONY: dev
dev:
	ctlptl apply -f ./cluster.yaml
	$(MAKE) -C ./e2e/ setup-cluster

.PHONY: stop-dev
stop-dev:
	ctlptl delete -f ./cluster.yaml

##@ Build

.PHONY: docker-build
docker-build: ## Build docker image with the manager.
	mkdir -p linux/$(GOARCH)
	CGO_ENABLED=0 GOOS=linux go build -o linux/$(GOARCH)/website-operator ./cmd/website-operator
	CGO_ENABLED=0 GOOS=linux go build -o linux/$(GOARCH)/repo-checker ./cmd/repo-checker
	CGO_ENABLED=0 GOOS=linux go build -o linux/$(GOARCH)/website-operator-ui ./cmd/website-operator-ui
	docker build --build-arg TARGETPLATFORM=linux/$(GOARCH) --target website-operator -t ${IMG} .

$(WEBSITE_OPERATOR): $(GO_FILES) generate
	mkdir -p bin
	CGO_ENABLED=0 GOOS=linux go build -o $@ ./cmd/website-operator

$(REPO_CHECKER): $(GO_FILES)
	mkdir -p bin
	CGO_ENABLED=0 GOOS=linux go build -o $@ ./cmd/repo-checker

$(WEBSITE_OPERATOR_UI): $(GO_FILES)
	mkdir -p bin
	CGO_ENABLED=0 GOOS=linux go build -o $@ ./cmd/website-operator-ui

.PHONY: frontend
frontend:
	cd ui/frontend && pnpm install && pnpm run build

.PHONY: setup
setup: setup-envtest

SETUP_ENVTEST := aqua exec -- setup-envtest
.PHONY: setup-envtest
setup-envtest: ## Download setup-envtest locally if necessary
	aqua i

.PHONY: clean
clean:
	rm -rf ./bin

##@ Helm Deployment

## Helm binary to use for deploying the chart
HELM ?= helm
## Namespace to deploy the Helm release
HELM_NAMESPACE ?= website-operator-system
## Name of the Helm release
HELM_RELEASE ?= website-operator
## Path to the Helm chart directory
HELM_CHART_DIR ?= dist/chart
## Additional arguments to pass to helm commands
HELM_EXTRA_ARGS ?=

.PHONY: install-helm
install-helm: ## Install the latest version of Helm.
	@command -v $(HELM) >/dev/null 2>&1 || { \
		echo "Installing Helm..." && \
		curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash; \
	}

.PHONY: helm-deploy
helm-deploy: install-helm ## Deploy manager to the K8s cluster via Helm. Specify an image with IMG.
	$(HELM) upgrade --install $(HELM_RELEASE) $(HELM_CHART_DIR) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--set manager.image.repository=$${IMG%:*} \
		--set manager.image.tag=$${IMG##*:} \
		--wait \
		--timeout 5m \
		$(HELM_EXTRA_ARGS)

.PHONY: helm-uninstall
helm-uninstall: ## Uninstall the Helm release from the K8s cluster.
	$(HELM) uninstall $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)

.PHONY: helm-status
helm-status: ## Show Helm release status.
	$(HELM) status $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)

.PHONY: helm-history
helm-history: ## Show Helm release history.
	$(HELM) history $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)

.PHONY: helm-rollback
helm-rollback: ## Rollback to previous Helm release.
	$(HELM) rollback $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)
