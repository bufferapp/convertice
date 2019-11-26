IMAGE_NAME := gcr.io/buffer-data/convertice-job:0.2.0

.DEFAULT_GOAL := run

.PHONY: run
run: build
	docker run -it --env-file .env -v $(PWD):/app --rm $(IMAGE_NAME)

.PHONY: build
build:
	 docker build . -t $(IMAGE_NAME)

.PHONY: dev
dev: build
	docker run -it --env-file .env --rm -v $(PWD):/app $(IMAGE_NAME) /bin/bash
