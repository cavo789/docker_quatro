CONTAINER_NAME :=$(or $(CONTAINER_NAME),quatro-render)
QUATRO_PORT_NUMBER :=$(or $(QUATRO_PORT_NUMBER),8080)
TIMEZONE :=$(or $(TIMEZONE),Europe/Brussels)

# When make is fired without arguments, we'll display the help screen.
# Should be defined before the first included.
default: help

.PHONY: help
help: ## Show the help with the list of commands
	@clear
    # Parse this file, search for `##` followed by a description
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[0;33m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""

##@ Quatro

.PHONY: bash
bash: ## Start an interactive shell session
# docker run -it bosa/quatro:20.04 /bin/bash
	COMPOSE_FILE=composer.yaml docker compose exec -it ${CONTAINER_NAME} /bin/bash

.PHONY: build
build: ## Build the Docker image that contains Quatro and required libraries
	docker build -f .docker/Dockerfile-quarto -t bosa/quatro:20.04 .

# .PHONY: render
# render: ## Convert the input file to the desired format
# 	docker build -f .docker/Dockerfile-render -t bosa/quatro:render . --no-cache

.PHONY: start
start: ## Open the web interface and show the document
# @-docker container rm --force ${CONTAINER_NAME} >/dev/null 2>&1 || true

# docker run -d --name ${CONTAINER_NAME} -p ${QUATRO_PORT_NUMBER}:8080 -e TZ=${TIMEZONE} bosa/quatro:static-file
	COMPOSE_FILE=composer.yaml docker compose up -d
# docker cp ${CONTAINER_NAME}:/app/ ${PWD}/output

# -@sensible-browser http://127.0.0.1:${QUATRO_PORT_NUMBER}/index.html
