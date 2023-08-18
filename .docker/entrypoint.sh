#!/usr/bin/env bash

# let script exit if an unsed variable is used or if a command fails
set -o nounset
set -o errexit

# Location of the project directory
PROJECT_FOLDER="/project"

# Get the location (foldername) of this script; not the running one (don't use $0)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# The file we'll convert. Default one is called "index.qmd"
QMD_FILE="${QMD_FILE:-index.qmd}"

# Absolute name of the file we'll convert
INPUT_FILE="${PROJECT_FOLDER}/input/${QMD_FILE}"

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
        console::printError "This can be done using this command line flag: '-v ${PWD}/input:/project/input'"
        console::printError "Make sure to specify the folder where you've your input are located."
        exit 1
    fi

    if [ ! -d "${PROJECT_FOLDER}/output" ]; then
        console::printError "You don't have yet a ${PROJECT_FOLDER}/output folder; please make sure to mount it."
        console::printError "This can be done using this command line flag: '-v ${PWD}/output:/project/output'"
        console::printError "Make sure to specify the folder where you wish to obtain the rendered output."
        exit 1
    fi

    # Make sure the input file exists
    if [ ! -f "${INPUT_FILE}" ]; then
        console::printError "The file ${INPUT_FILE} didn't exists; please use the QMD_FILE argument"
        console::printError "and specify an existing file like f.i. 'make render QMD_FILE=\"my_documentation.qmd\"'"
        console::printError "where \"my_documentation.qmd\" exists and is indeed the file you wish to convert."
        exit 1
    fi

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

    # If the .quarto directory didn't exists yet, we are not in a Quarto
    # project so, just create one
    if [ ! -d "${PROJECT_FOLDER}/input/.quarto" ]; then
        console::printCyan "Create the Quarto Project"
        quarto create
    fi

    console::printYellow "Rendering ${INPUT_FILE} to the ${PROJECT_FOLDER}/output folder"

    (cd "${PROJECT_FOLDER}/output" && quarto render "${INPUT_FILE}" --output-dir "${PROJECT_FOLDER}/output" --log-level info)

    return 0
}

# shellcheck disable=SC2048,SC2086
__main $*
