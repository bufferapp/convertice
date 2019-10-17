IMAGE_NAME := bufferapp/convertice-job:0.1.0

.DEFAULT_GOAL := run

.PHONY: run
run: build
	docker run -it --env-file .env --rm $(IMAGE_NAME)

.PHONY: build
build:
	 docker build . -t $(IMAGE_NAME)

.PHONY: dev
dev: build
	docker run -it --env-file .env --rm -v $(PWD):/app $(IMAGE_NAME) /bin/bash
