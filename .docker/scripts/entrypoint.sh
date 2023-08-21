#!/usr/bin/env bash

# let script exit if an unsed variable is used or if a command fails
set -o nounset
set -o errexit

# Location of the project directory
PROJECT_FOLDER="/project"

# Get the location (foldername) of this script; not the running one (don't use $0)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# The file we'll convert. Default one is called "index.qmd"
INPUT_FILE="${INPUT_FILE:-index.qmd}"

# The output format. Default will be html
OUTPUT_FORMAT="${OUTPUT_FORMAT:-html}"

# Our input file (index.qmd) but having the targeted extension (like index.html)
OUTPUT_FILE=${INPUT_FILE%.qmd}.${OUTPUT_FORMAT}

# Absolute name of the file we'll convert
INPUT_FILE_ABSOLUTE_PATH="${PROJECT_FOLDER}/input/${INPUT_FILE}"

# region - private function entrypoint::__initialize
#
# ## Description
#
# Import helpers
#
# ## Examples
#
# ```bash
# entrypoint::__initialize
# ```
#
# shellcheck disable=SC1090,SC2048,SC2086
#
# endregion
function entrypoint::__initialize() {
    local helpersDir
    helpersDir="$SCRIPT_DIR/helpers"

    source "${helpersDir}/opts.sh" $*
    source "${helpersDir}/assert.sh" $*
    source "${helpersDir}/string.sh" $*
    source "${helpersDir}/console.sh" $*

    return 0
}

# region - private function entrypoint::__checkPrerequisites
#
# ## Description
#
# Make sure the installation is correct. If an error occurs, display
# error message and exit
#
# ## Examples
#
# ```bash
# entrypoint::__checkPrerequisites
# ```
#
# shellcheck disable=SC1090,SC2048,SC2086
#
# endregion
function entrypoint::__checkPrerequisites() {

    if [ ! -d "${PROJECT_FOLDER}/input" ]; then
        console::printError "You don't have yet a ${PROJECT_FOLDER}/input folder; please make sure to mount it."
        console::printError "This can be done using this command line flag: \"-v \${PWD}/your_source_folder:/project/input\""
        console::printError "In the example above, \"your_source_folder\" is supposed to be the folder where you've save your .qmd file."
        console::printError "A valid call on the console can be \"docker run --rm -it -v \${PWD}/input:/project/input -v \${PWD}/output:/project/output bosa/quarto\"."
        exit 1
    fi

    if [ ! -d "${PROJECT_FOLDER}/output" ]; then
        console::printError "You don't have yet a ${PROJECT_FOLDER}/output folder; please make sure to mount it."
        console::printError "This can be done using this command line flag: \"-v \${PWD}/your_output_folder:/project/output\""
        console::printError "In the example above, \"your_output_folder\" will be where you wish to store rendered files."
        console::printError "A valid call on the console can be \"docker run --rm -it -v \${PWD}/input:/project/input -v \${PWD}/output:/project/output bosa/quarto\"."
        exit 1
    fi

    # Make sure the input file exists
    if [ ! -f "${INPUT_FILE_ABSOLUTE_PATH}" ]; then
        console::printError "The file ${INPUT_FILE_ABSOLUTE_PATH} didn't exist; please be sure to set the INPUT_FILE OS variable."
        console::printError "This can be done like this: \"docker run --rm -it -v \${PWD}/input:/project/input -v \${PWD}/output:/project/output -e INPUT_FILE=my_documentation.qmd bosa/quarto\"."
        console::printError "Make sure the specified input file exists."
        exit 1
    fi

    # All tests passed; we can continue
    return 0
}

# region - private function __main
#
# ## Description
#
# Run the installation script
#
# shellcheck disable=SC2048,2086
#
# endregion
function __main() {
    
    entrypoint::__initialize $*

    # http://patorjk.com/software/taag/#p=display&f=Big&t=Docker-quarto
    cat <<\EOF
  _____             _                     ____                   _        
 |  __ \           | |                   / __ \                 | |       
 | |  | | ___   ___| | _____ _ __ ______| |  | |_   _  __ _ _ __| |_ ___  
 | |  | |/ _ \ / __| |/ / _ \ '__|______| |  | | | | |/ _` | '__| __/ _ \ 
 | |__| | (_) | (__|   <  __/ |         | |__| | |_| | (_| | |  | || (_) |
 |_____/ \___/ \___|_|\_\___|_|          \___\_\\__,_|\__,_|_|   \__\___/ 
                                                                         

EOF
    printf "%s\n\n" "SPF BOSA IOD AS - PHP Dev Team"

    entrypoint::__checkPrerequisites

    # If the file _quarto.yml didn't exist yet, we are not in a Quarto
    # project so, just create one
    if [ ! -f "${PROJECT_FOLDER}/input/_quarto.yml" ]; then
        console::printCyan "Create the Quarto Project"
        quarto create
    fi

    CMD="quarto render "${INPUT_FILE_ABSOLUTE_PATH}" --to ${OUTPUT_FORMAT} --log-level info"

    console::printYellow "Rendering ${INPUT_FILE} to the ${PROJECT_FOLDER}/output folder"
    console::printGray "$CMD"

    ($CMD && mv "${OUTPUT_FILE}" "${PROJECT_FOLDER}/output")

    return 0
}

# shellcheck disable=SC2048,SC2086
__main $*
