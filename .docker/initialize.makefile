# --------------------------------------------------------------------
# Make some initializations like, based on command line arguments, 
# define the arguments to use for Docker (like the list of environment 
# variables to use)
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Docker flags
# --------------------------------------------------------------------

# The file we'll convert. When not specified, it'll be set to "index.qmd"
# by the entrypoint.sh script
DOCKER_INPUT_FILE=
ifneq ("$(INPUT_FILE)","")
	DOCKER_INPUT_FILE :=-e INPUT_FILE=${INPUT_FILE}
endif

# The targeted format. Empty to use the Quarto default one. Will be
# html except when the folder contains a _quarto.yml file. In that case,
# use the format defined in that configuration file.
DOCKER_FORMAT=
ifneq ("$(FORMAT)","")
	DOCKER_FORMAT :=-e OUTPUT_FORMAT=${FORMAT}
endif

# Once the generation has been completed, are there any files to be
# copied from the input folder to the one containing the generation result?
# Files are comma separated ("demo.pdf,samples.json,...")
DOCKER_FILES_TO_COPY=
ifneq ("$(FILES_TO_COPY)","")
	DOCKER_FILES_TO_COPY :=-e FILES_TO_COPY=${FILES_TO_COPY}
endif

# Once the generation has been completed, are there any folders to be
# copied from the input folder to the one containing the generation result?
# Folders are comma separated ("assets,images,...")
DOCKER_FOLDERS_TO_COPY=
ifneq ("$(FOLDERS_TO_COPY)","")
	DOCKER_FOLDERS_TO_COPY :=-e FOLDERS_TO_COPY=${FOLDERS_TO_COPY}
endif

# The log level for Quarto; possible values are info, warning, error or critical
# Empty for no log level
# LOG_LEVEL :=$(or $(LOG_LEVEL),"")
DOCKER_LOG_LEVEL=
ifneq ("$(LOG_LEVEL)","")
	DOCKER_LOG_LEVEL :=-e LOG_LEVEL=${LOG_LEVEL}
endif

# Did we need to show debug information's?
DOCKER_DEBUG=
ifeq ("$(DEBUG)","1")
	DOCKER_DEBUG :=-e DEBUG=${DEBUG}
endif

# Shorthand for the volumes we need to share with the Docker image
# By default, the input folder will be "./input" but the user can 
# force another one. Same for the output folder
DOCKER_VOLUMES=-v $(or $(INPUT_FOLDER),./input):/project/input -v $(or $(OUTPUT_FOLDER),./output):/project/output

# When SYNCHRO=1 is specified, enable synchronization between host and
# Docker for Bash scripts
DOCKER_SYNCHRO=
ifeq ($(SYNCHRO),1)
	DOCKER_SYNCHRO=-v ./.docker/scripts:/project/scripts
endif

# UserId/GroupId to use in the Docker container
# (same than the current, logged in, user) so files/folders created by
# the Docker container will be associated to the current, logged in, user
UID :=$(or $(UID),$(shell id -u))
GID :=$(or $(GID),$(shell id -g))
DOCKER_USER=-u ${UID}:${GID}

# --------------------------------------------------------------------
# Misc variables
# --------------------------------------------------------------------

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

# --------------------------------------------------------------------
# Some constants
# --------------------------------------------------------------------

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
