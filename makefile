include .docker/initialize.makefile

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
	docker run ${ARGS} ${DOCKER_USER} --rm -it --name quarto ${DOCKER_VOLUMES} ${DOCKER_SYNCHRO} bosa/quarto /bin/bash

.PHONY: build
build: ## Build the Docker image that contains Quarto and required libraries. Use ARGS="..." to pass arguments to Docker build (f.i. ARGS="--no-cache")
	(cd .docker && docker build ${ARGS} --file Dockerfile --tag bosa/quarto:20.04 --tag bosa/quarto:latest . )

.PHONY: render
render: ## Convert the input file to the desired format. Use the INPUT_FILE argument to specify the filename (f.i. INPUT_FILE="readme.qmd").

ifeq ($(QUIET),false)
	@printf "[1;${COLOR_GRAY}m%s[0m\n\n" "Tips:"
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "1. You can define the name of the file to convert by using the \"INPUT_FILE\" argument and \"FORMAT\" to specify the targeted format."
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "   When INPUT_FILE is set to a folder name and only one .qmd file is present, that file will be converted."
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "2. Use the \"FOLDERS_TO_COPY\" argument if you need to copy folders from your input folder to the output one after the conversion. There is also a \"FILES_TO_COPY\" argument."
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "3. Add \"LOG_LEVEL=xxx\" to get more information during the execution of Quarto. Possible values are: info, warning, error or critical."
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "4. Add \"DEBUG=1\" to enable debug mode and get more information on the console."
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "5. Add \"QUIET=1\" to hide informations and reduce console verbosity."
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "6. Add \"SYNCHRO=1\" to enable synchronization between host and Docker for Bash scripts (located in .docker/scripts)."

	@echo
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "Somes examples:"
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "  * make render"
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "  * make render INPUT_FILE=\"my_documentation.qmd\" FORMAT=\"pdf\""
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "  * make render INPUT_FILE=\"my_project/index.qmd\" FOLDERS_TO_COPY=\"assets;images;publications\" LOG_LEVEL=\"info\" DEBUG=1"
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "  * make render INPUT_FILE=\"my_project/index.qmd\" FOLDERS_TO_COPY=\"assets;images;publications\" FILES_TO_COPY=\"demo.pdf\""
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "  * make render INPUT_FILE=\"index.qmd\" QUIET=1"
	@printf "[1;${COLOR_GRAY}m%s[0m\n" "  * make render SYNCHRO=1"

ifeq ($(DEBUG),1)
    # Everything from now will be echoed in gray
	@echo "\033[1;30m"
	@echo "[DEBUG] INPUT FILE      ==> ${DOCKER_INPUT_FILE}"
	@echo "[DEBUG] FORMAT          ==> ${DOCKER_FORMAT}"
	@echo "[DEBUG] FILES_TO_COPY   ==> ${DOCKER_FILES_TO_COPY}"
	@echo "[DEBUG] FOLDERS_TO_COPY ==> ${DOCKER_FOLDERS_TO_COPY}"
	@echo "[DEBUG] LOG_LEVEL       ==> ${DOCKER_LOG_LEVEL}"
	@echo "[DEBUG] DEBUG           ==> ${DOCKER_DEBUG}"
	@echo "[DEBUG] USER            ==> ${DOCKER_USER}"
	@echo "[DEBUG] VOLUMES         ==> ${DOCKER_VOLUMES}"
	@echo "[DEBUG] SYNCHRONIZATION ==> ${DOCKER_SYNCHRO}"
    # Reset to normal ANSI colors
	@echo "\033[0m"
endif

ifeq ($(SYNCHRO),1)
	@echo
	@printf "[1;${COLOR_CYAN}m%s[0m\n" "Synchronization mode will be enabled so you can modify bash scripts in .docker/scripts and synchronize them with the container."
endif

endif

	@echo ""

	docker run --rm -it --name quarto ${DOCKER_VOLUMES} ${DOCKER_SYNCHRO} ${DOCKER_USER} ${DOCKER_INPUT_FILE} ${DOCKER_FORMAT} ${DOCKER_FOLDERS_TO_COPY} ${DOCKER_FILES_TO_COPY} ${DOCKER_LOG_LEVEL} ${DOCKER_DEBUG} bosa/quarto

.PHONY: remove
remove: ## Remove the Docker image from your filesystem
	-docker image remove bosa/quarto:latest
	-docker image remove bosa/quarto:20.04
