# Simple make helpers for building and pushing t247hb images

REGISTRY ?= pampadev
# Default TAG to today's date (YYYY-MM-DD)
TAG ?= $(shell date +%F)
# Optional suffix to distinguish environments (e.g., -dev, -prod). Empty by default.
TAG_SUFFIX ?=
# Common suffix presets
DEV_SUFFIX ?= -dev
PROD_SUFFIX ?= -prod

# Effective tag including suffix
TAG_WITH_SUFFIX := $(TAG)$(TAG_SUFFIX)

.PHONY: all build build-dashboard build-api build-launcher push push-dashboard push-api push-launcher smoke
.PHONY: build-dev build-prod push-dev push-prod date smoke-prod

all: build

build: build-dashboard build-api build-launcher

build-dashboard:
	docker build -f Dockerfile.t247hb-dashboard -t $(REGISTRY)/t247hb-dashboard:$(TAG_WITH_SUFFIX) .

build-api:
	docker build -f Dockerfile.t247hb-api -t $(REGISTRY)/t247hb-api:$(TAG_WITH_SUFFIX) .

build-launcher:
	docker build -f stack/Dockerfile -t $(REGISTRY)/t247hb-stack-launcher:$(TAG_WITH_SUFFIX) stack

push: push-dashboard push-api push-launcher

push-dashboard:
	docker push $(REGISTRY)/t247hb-dashboard:$(TAG_WITH_SUFFIX)

push-api:
	docker push $(REGISTRY)/t247hb-api:$(TAG_WITH_SUFFIX)

push-launcher:
	docker push $(REGISTRY)/t247hb-stack-launcher:$(TAG_WITH_SUFFIX)

date:
	@echo Using TAG=$(TAG) TAG_SUFFIX=$(TAG_SUFFIX) => TAG_WITH_SUFFIX=$(TAG_WITH_SUFFIX)

# Convenience targets for dev/prod builds and pushes
build-dev:
	$(MAKE) TAG_SUFFIX=$(DEV_SUFFIX) build

build-prod:
	$(MAKE) TAG_SUFFIX=$(PROD_SUFFIX) build

push-dev:
	$(MAKE) TAG_SUFFIX=$(DEV_SUFFIX) push

push-prod:
	$(MAKE) TAG_SUFFIX=$(PROD_SUFFIX) push

smoke:
	bash stack/smoke_test.sh

smoke-prod:
	SKIP_DASHBOARD_CHECK=1 bash stack/smoke_test.sh
