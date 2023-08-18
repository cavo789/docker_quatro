
# The file we'll convert. Default one is called "index.qmd"
QMD_FILE :=$(or $(QMD_FILE),index.qmd)

# Shorthand for the volumes we need to share with the Docker image
VOLUMES=-v ${PWD}/input:/project/input -v ${PWD}/output:/project/output

# When make is fired without arguments, we'll display the help screen.
# Should be defined before the first included.
default: help

.PHONY: help
help: ## Show the help with the list of commands
	@clear
    # Parse this file, search for `##` followed by a description
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-7s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[0;33m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""

##@ Quarto

.PHONY: bash
bash: ## Start an interactive shell session. Use ARGS="..." to pass arguments
	docker run ${ARGS} --rm -it --name quarto ${VOLUMES} bosa/quarto /bin/bash

.PHONY: build
build: ## Build the Docker image that contains Quarto and required libraries. Use ARGS="..." to pass arguments to Docker build (f.i. ARGS="--no-cache")
	(cd .docker && docker build ${ARGS} --file Dockerfile --tag bosa/quarto:20.04 --tag bosa/quarto:latest . )

.PHONY: render
render: ## Convert the input file to the desired format. Use the QMD_FILE argument to specify the filename (f.i. QMD_FILE="readme.qmd").
	docker run --rm -it --name quarto ${VOLUMES} -u ${UID}:${GID} -e QMD_FILE="${QMD_FILE}"  bosa/quarto

.PHONY: remove
remove: ## Remove the Docker image from your filesystem
	-docker image remove bosa/quarto:latest
	-docker image remove bosa/quarto:20.04
