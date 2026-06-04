KUBERNETES_VERSION := v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f # renovate: kindest/node
REGISTRY := ghcr.io/cybozu-go/
KIND_CLUSTER_NAME=website-e2e

GO_FILES := $(shell find .. -path ../vendor -prune -o -path ../e2e -prune -o -name '*.go' -print)
HOST_ARCH := $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

launch-kind:
	if [ ! "$(shell kind get clusters | grep $(KIND_CLUSTER_NAME))" ]; then \
		kind create cluster --name=$(KIND_CLUSTER_NAME) --config kind-config.yaml --image kindest/node:$(KUBERNETES_VERSION) --wait 180s; \
	fi

shutdown-kind:
	if [ "$(shell kind get clusters | grep $(KIND_CLUSTER_NAME))" ]; then \
		kind delete cluster --name=$(KIND_CLUSTER_NAME) || true; \
	fi

setup-cluster:
	kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
	kubectl wait -n projectcontour --for condition=available --all deployments --timeout 180s

test: launch-kind load-images setup-cluster
	kubectl config use-context kind-$(KIND_CLUSTER_NAME)
	kustomize build ./manifests/manager | kubectl apply -f -
	kubectl wait pod -l control-plane=controller-manager -n website-operator-system --for condition=Ready --timeout 180s
	kustomize build ./manifests/website | kubectl apply -f -
	env E2E_TEST=1 go test -count=1 -v . -args -ginkgo.v -ginkgo.fail-fast

# Build all artifacts for the architecture of the host machine and load them into the kind cluster.
.PHONY: load-images
load-images:
	cd ../containers && for d in */Dockerfile; do \
	  img=$$(dirname $${d%/}); \
	  echo "Loading $${d} image into kind cluster..."; \
	  docker buildx build -t $(REGISTRY)website-operator-$${img}:dev \
	    --build-arg BASE_TAG=$$(cat BASE_TAG) \
		$${img}; \
	  kind load docker-image --name=$(KIND_CLUSTER_NAME) $(REGISTRY)website-operator-$${img}:dev; \
	done

	cd ../ && cat .goreleaser.yml \
	  | ARCH="$(HOST_ARCH)" \
	    yq '(.builds[].goarch) |= map(select(. == env(ARCH)))' \
	  | PLATFORM="linux/$(HOST_ARCH)" \
	    yq '(.dockers_v2[].platforms) |= map(select(. == env(PLATFORM)))' \
	  | goreleaser release -f - --clean --snapshot --skip=publish,before

	docker tag $(REGISTRY)website-operator:dev-$(HOST_ARCH) $(REGISTRY)website-operator:dev
	kind load docker-image --name=$(KIND_CLUSTER_NAME) $(REGISTRY)website-operator:dev
	docker tag $(REGISTRY)website-operator-repo-checker:dev-$(HOST_ARCH) $(REGISTRY)website-operator-repo-checker:dev
	kind load docker-image --name=$(KIND_CLUSTER_NAME) $(REGISTRY)website-operator-repo-checker:dev
	docker tag $(REGISTRY)website-operator-ui:dev-$(HOST_ARCH) $(REGISTRY)website-operator-ui:dev
	kind load docker-image --name=$(KIND_CLUSTER_NAME) $(REGISTRY)website-operator-ui:dev
