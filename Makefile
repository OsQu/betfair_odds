REPO ?= osqu/betfair_odds
IMAGE_TAG ?= $(shell git rev-parse HEAD)

.PHONY: release
release: build push

.PHONY: build
build:
	docker build -t ${REPO}:latest .
	docker tag ${REPO}:latest ${REPO}:${IMAGE_TAG}

.PHONY: push
push:
	docker push ${REPO}:${IMAGE_TAG}
