# List of ANSI colors
COLOR_BLUE:=34
COLOR_CYAN:=36
COLOR_GRAY:=30
COLOR_GREEN:=32
COLOR_PURPLE:=35
COLOR_RED:=31
COLOR_WHITE:=37
COLOR_YELLOW:=33

# Some helpers
_CYAN   := "[1;${COLOR_CYAN}m%s\033[0m %s\n"   # F.i. printf $(_CYAN)   "Info xxx"
_GRAY   := "[1;${COLOR_GRAY}m%s\033[0m %s\n"   # F.i. printf $(_GRAY)   "ipso lorem"
_GREEN  := "[1;${COLOR_GREEN}m%s\033[0m %s\n"  # F.i. printf $(_GREEN)  "Success - xxx"
_RED    := "[1;${COLOR_RED}m%s\033[0m %s\n"    # F.i. printf $(_RED)    "Error - xxx"
_WHITE  := "[1;${COLOR_WHITE}m%s\033[0m %s\n"  # F.i. printf $(_WHITE)  "ispo lorem"
_YELLOW := "[1;${COLOR_YELLOW}m%s\033[0m %s\n" # F.i. printf $(_YELLOW) "ispo lorem"

# Define a QUIET global variable that will be set to true when the user
# run `make something ARGS="--quiet"` i.e. with the `--quiet` argument
# Can be, too `make something ARGS="--force --quiet --no-interaction ..."`
# i.e. the presence of the `--quiet` argument is enough
#
# Sample usage:
# ifeq ($(QUIET),false)
# 	@printf '\e[1;30m%s\n\e[m' "QUIET MODE NOT ENABLED - We'll show any informative text."
# endif
# 	@printf '\e[1;32m%s\n\n\e[m' "This is an important message"
QUIET=$(if $(findstring --quiet,${ARGS}),true,false)

# The file we'll convert. Default one is called "index.qmd"
INPUT_FILE :=$(or $(INPUT_FILE),index.qmd)

# The output format. There is no default since the _quarto.yml file,
# if present in the input folder, probably mentionned the expected format
OUTPUT_FORMAT :=$(or $(OUTPUT_FORMAT),)

# The log level for Quarto; possible values are info, warning, error or critical
# Empty for no log level
LOG_LEVEL :=$(or $(LOG_LEVEL),)

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
render: ## Convert the input file to the desired format. Use the INPUT_FILE argument to specify the filename (f.i. INPUT_FILE="readme.qmd").
ifeq ($(QUIET),false)
	@printf "[1;${COLOR_CYAN}m%s[0m\n" "Tip: You can define the name of the file to convert by using the INPUT_FILE argument and OUTPUT_FORMAT to specify the targeted format (html is the default)"
	@printf "[1;${COLOR_CYAN}m%s[0m\n\n" "     For instance: make render INPUT_FILE=\"my_documentation.qmd\" OUTPUT_FORMAT=\"pdf\""
endif

	docker run --rm -it --name quarto ${VOLUMES} -u ${UID}:${GID} -e INPUT_FILE="${INPUT_FILE}" -e OUTPUT_FORMAT="${OUTPUT_FORMAT}" -e LOG_LEVEL="${LOG_LEVEL}" bosa/quarto
# -@sensible-browser output/index.html

.PHONY: remove
remove: ## Remove the Docker image from your filesystem
	-docker image remove bosa/quarto:latest
	-docker image remove bosa/quarto:20.04
