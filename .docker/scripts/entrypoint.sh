#!/usr/bin/env bash

# let script exit if an unsed variable is used or if a command fails
set -o nounset
set -o errexit

# Location of the project directory
PROJECT_FOLDER="/project"

# Get the location (foldername) of this script; not the running one (don't use $0)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# List of files we'll convert. Default one is called "index.qmd"
# Using an array will allow to convert more than just one at a time
# There is just one condition: all files have to be in the same folder
# Note: INPUT_FILE is the name of the OS variable; we'll stored it in an 
# array that why we'll use the plural form
INPUT_FILE=("${INPUT_FILE:-index.qmd}")
INPUT_FILES=("${INPUT_FILE}")

# The log level for Quarto; possible values are info, warning, error or critical
# Empty for no log level
LOG_LEVEL=${LOG_LEVEL:-}

# The output format. There is no default since the _quarto.yml file,
# if present in the input folder, probably mentionned the expected format
OUTPUT_FORMAT="${OUTPUT_FORMAT:-""}"

# Default folder where our input files are expected to be located
INPUT_FOLDER="${PROJECT_FOLDER}/input"

# Default folder where we'll move our rendered files
OUTPUT_FOLDER="${PROJECT_FOLDER}/output"

# Temporary logfile used during the rendering of Quarto
LOG_FILE_NAME="/tmp/quarto.log"

# Absolute name of the file we'll convert
# Note: this can be a folder and in that case, all .qmd files in that
# folder will be converted
INPUT_FILE_ABSOLUTE_PATH="${PROJECT_FOLDER}/input/${INPUT_FILES[0]}"

# The command line we'll use to run Quarto and render our file
QUARTO_COMMAND_LINE=""

# Once the generation has been completed, are there any files to be
# copied from the input folder to the one containing the generation result?
# Files are comma separated ("demo.pdf,samples.json,...")
FILES_TO_COPY=${FILES_TO_COPY:-}

# Once the rendering has been done and the resulting files moved
# to the output folder; did we also need to copy some folders from
# the input folder to the output folder. This will be the case for,
# for instance, images or static files used during the display of the
# generated files
# Folders are comma separated ("assets,images,...")
FOLDERS_TO_COPY=${FOLDERS_TO_COPY:-}

# region - private function entrypoint::__loadHelpers
#
# Import helpers
#
# shellcheck disable=SC1090,SC2048,SC2086
# endregion
function entrypoint::__loadHelpers() {
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
# Make sure the installation is correct. If an error occurs, display
# error message and exit
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

    return 0
}

# region - private function entrypoint::__initialize
#
# Initialize some variables
#
# endregion
function entrypoint::__initialize() {
    # Make sure the input file exists and the .qmd extension was mentionned
    if [ ! -f "${INPUT_FOLDER}/${INPUT_FILE}" ] && [ -f "${INPUT_FOLDER}/${INPUT_FILE}.qmd" ] ; then
        # The extension was not mentionned (like "blog/index" instead of "blog/index.qmd"), add it
        INPUT_FILE_ABSOLUTE_PATH="${INPUT_FOLDER}/${INPUT_FILE}.qmd"
        INPUT_FILE="$(basename "${INPUT_FILE}.qmd")"
        INPUT_FILES=(${INPUT_FILE})
    fi

    # The input file ... is a directory. We'll retrieve the first .qmd file in that directory
    if [ -d "${INPUT_FOLDER}/${INPUT_FILE}" ]; then
        # Remove the final "/" if present
        INPUT_FILE_ABSOLUTE_PATH="$(echo "${INPUT_FILE_ABSOLUTE_PATH}" | string::rtrim "/")"
        console::debug "${INPUT_FILE_ABSOLUTE_PATH} is a folder"

        # Count the number of .qmd files in that directory
        # If more than one, ok we can't continue since we need to know
        # the name of the file to convert
        # shellcheck disable=SC2012,SC2086
        count=$(ls -AU ${INPUT_FILE_ABSOLUTE_PATH}/*.qmd 2>/dev/null | wc -l)

        if [[ $count -eq 0 ]]; then
            console::printError "The folder ${INPUT_FILE_ABSOLUTE_PATH} didn't contains any .qmd files."
            console::printError "Please check your \"INPUT_FILE\" parameter. Here is the content of the folder:"
            console::printRed ""
            # shellcheck disable=SC2012,SC2086
            console::printRed "$(ls -al ${INPUT_FILE_ABSOLUTE_PATH})"
            exit 1
        fi

        # The folder contains more than one .qmd file so we'll proceed all at once
        # Jump in the folder so "ls" will return relative paths, not absolute paths
        # INPUT_FILE will be an array
        pushd "${INPUT_FILE_ABSOLUTE_PATH}/" 1>/dev/null && INPUT_FILES=($(ls *.qmd)) && popd 1>/dev/null

        INPUT_FILE_ABSOLUTE_PATH="${INPUT_FILE_ABSOLUTE_PATH}"/${INPUT_FILES[0]}
    fi

    # Just for debugging purposes
    for FILE in ${INPUT_FILES[@]}; do
        console::debug "[DEBUG] File to process \"$FILE\""
    done

    # Absolute name of the file(s) parent folder
    # In case of INPUT_FILE is an array, all files are in the same parent folder
    INPUT_FOLDER_ABSOLUTE_PATH="$(dirname "${INPUT_FILE_ABSOLUTE_PATH}")"
    
    if [ ! -d "${INPUT_FOLDER_ABSOLUTE_PATH}" ]; then
        console::printError "The folder ${INPUT_FOLDER_ABSOLUTE_PATH} didn't exist."
        console::printError "Please check your \"INPUT_FILE\" parameter."
        exit 1
    fi

    if [ ! -f "${INPUT_FILE_ABSOLUTE_PATH}" ]; then
        console::printError "The file ${INPUT_FILE_ABSOLUTE_PATH} didn't exist."
        console::printError "Please check your \"INPUT_FILE\" parameter."
        exit 1
    fi

    # Derive the output folder name; if we need to convert "input/blog/index.qmd"
    # the output folder will be "output/blog"
    OUTPUT_FOLDER=$(string::replace "${INPUT_FOLDER_ABSOLUTE_PATH}" "${INPUT_FOLDER}" "${OUTPUT_FOLDER}")

    # console::debug "[DEBUG] - INPUT_FILES (first file)   = ${INPUT_FILES[0]}"
    # console::debug "[DEBUG] - INPUT_FILE_ABSOLUTE_PATH   = ${INPUT_FILE_ABSOLUTE_PATH}"
    # console::debug "[DEBUG] - INPUT_FOLDER_ABSOLUTE_PATH = ${INPUT_FOLDER_ABSOLUTE_PATH}"
    # console::debug "[DEBUG] - OUTPUT_FOLDER              = ${OUTPUT_FOLDER}"
    # exit 1
    
    # All tests passed and variables set, we can continue
    return 0
}

# region - private function entrypoint::__deriveQuartoCommandLine
#
# Based on variables, generate the full command line for Quarto
#
# ## Parameters
#
# 1. FILENAME - A basename like "index.qmd"
#
# endregion
function entrypoint::__deriveQuartoCommandLine() {
    local FILENAME="${INPUT_FOLDER_ABSOLUTE_PATH}/${1}"

    # The command line we'll use to run Quarto and render our file
    # QUARTO_COMMAND_LINE="quarto render ${INPUT_FILE_ABSOLUTE_PATH} --log ${LOG_FILE_NAME}"
    QUARTO_COMMAND_LINE="quarto render ${FILENAME} --log ${LOG_FILE_NAME}"

    # Did we have a loglevel defined as OS variable? If so, use it
    [ -n "${LOG_LEVEL}" ] && QUARTO_COMMAND_LINE="${QUARTO_COMMAND_LINE} --log-level ${LOG_LEVEL}"

    # If the output format was specified on command line / OS, use it
    # Otherwise relay on the _quarto.yml where there is probably the
    # output defined, f.i., like this:
    #
    # format:
    #   html:
    #     theme: cosmo
    #     css: styles.css
    [ -n "${OUTPUT_FORMAT}" ] && QUARTO_COMMAND_LINE="${QUARTO_COMMAND_LINE} --to ${OUTPUT_FORMAT}"

    # Return the command line to the calling function
    echo "${QUARTO_COMMAND_LINE}"

    # All tests passed; we can continue
    return 0
}

# region - private function entrypoint::__runQuarto
#
# Run Quarto
#
# endregion
function entrypoint::__runQuarto() {
    # Remove the previous log
    [ -f ${LOG_FILE_NAME} ] && rm -f ${LOG_FILE_NAME}

    mkdir -p "${OUTPUT_FOLDER}"
    if [ -d "${OUTPUT_FOLDER}" ] && [ "${OUTPUT_FOLDER}" != "${PROJECT_FOLDER}/output" ];  then
        # Don't remove the folder /project/output but well when it's a 
        # subdirectory
        console::debug "Before starting, erase ${OUTPUT_FOLDER} so don't keep old stuff"
        rm -rf "${OUTPUT_FOLDER}"
    fi

    # INPUT_FILES is an array containing one or more .qmd filenames
    for FILE in ${INPUT_FILES[@]}; do
        QUARTO_COMMAND_LINE=$(entrypoint::__deriveQuartoCommandLine "${FILE}")
        console::printYellow "Rendering ${FILE} to the ${OUTPUT_FOLDER} folder"
        console::printGray "$QUARTO_COMMAND_LINE"

        # Execute the command, run Quarto. Note: output will be also written
        # to the log file (by default /tmp/quarto.log: as defined in variable LOG_FILE_NAME)
        ${QUARTO_COMMAND_LINE}

        entrypoint::__moveToOutputDirectory ${FILE}
    done

    return 0
}

# region - private function entrypoint::__moveToOutputDirectory
#
# Move rendered files/folders to the output directory
#
# ## Parameters
#
# 1. FILENAME - A basename like "index.qmd", the .qmd file being rendered
#
# endregion
function entrypoint::__moveToOutputDirectory() {
    local FILENAME="${1}"

    # Retrieve from the Quarto logfile the name of the generated file (f.i. "blog.html")
    # Note: can be too "_site/index.html" i.e. contains a folder name
    GENERATED_FILE="$(grep -Po 'Output created: \K(.*)?' ${LOG_FILE_NAME})"
    console::debug "Generated file is ${GENERATED_FILE}"

    entrypoint::__moveToOutputDirectoryWhenSiteOrBook

    # Move it to the final, output, directory
    if [ -f "${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FILE}" ]; then
        console::debug "Move ${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FILE} to ${OUTPUT_FOLDER}"
        mkdir -p "$(dirname "${OUTPUT_FOLDER}/${GENERATED_FILE}")"
        mv "${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FILE}" "${OUTPUT_FOLDER}/${GENERATED_FILE}"
    fi

    # Same for the .quarto folder generated automatically by Quarto (in case of a Quarto project)
    if [ -d "${INPUT_FOLDER_ABSOLUTE_PATH}/.quarto" ]; then
        console::debug "Move ${INPUT_FOLDER_ABSOLUTE_PATH}/.quarto to ${OUTPUT_FOLDER}/.quarto"
        rm -rf "${OUTPUT_FOLDER}/.quarto"
        mv "${INPUT_FOLDER_ABSOLUTE_PATH}/.quarto" "${OUTPUT_FOLDER}/.quarto"
    fi

    # Quarto will generate a folder called "blog_files" during the
    # rendering of the "blog.qmd" file so check if such folder exists
    # and if so, move it to the output folder too
    # Syntax below will remove the ".qmd" extension
    GENERATED_FOLDER="$(basename "${FILENAME}" .qmd)_files"

    if [ -d "${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FOLDER}" ]; then
        console::debug "Move folder ${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FOLDER} to ${OUTPUT_FOLDER}/${GENERATED_FOLDER}"
        # shellcheck disable=SC2115
        rm -rf "${OUTPUT_FOLDER}/${GENERATED_FOLDER}"
        mv "${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FOLDER}" "${OUTPUT_FOLDER}/${GENERATED_FOLDER}"
    fi

    entrypoint::__copyFilesFoldersToCopyToOutputDirectory

    return 0
}

# region - private function entrypoint::__moveToOutputDirectoryWhenSiteOrBook
#
# When generating a book or a website, Quarto creates directoy called
# "_book" or "_site". If found, move that one to the output folder.
#
# endregion
function entrypoint::__moveToOutputDirectoryWhenSiteOrBook() {
    declare -A folders

    folders[0]="_book"
    folders[1]="_site"

    for key in "${!folders[@]}"
    do
        # If the folder exists; move it to the output directory
        if [ -d "${INPUT_FOLDER_ABSOLUTE_PATH}/${folders[$key]}" ]; then
            console::debug "Create ${OUTPUT_FOLDER}/${folders[$key]}"
            # shellcheck disable=SC2115
            rm -rf "${OUTPUT_FOLDER}/${folders[$key]}"
            mv "${INPUT_FOLDER_ABSOLUTE_PATH}/${folders[$key]}" "${OUTPUT_FOLDER}"
        fi
    done

    return 0
}

# region - private function entrypoint::__copyFilesFoldersToCopyToOutputDirectory
#
# Once the rendering has been done and the resulting files moved
# to the output folder; did we also need to copy some folders from
# the input folder to the output folder. This will be the case for,
# for instance, images or static files used during the display of the
# generated files
#
# endregion
function entrypoint::__copyFilesFoldersToCopyToOutputDirectory {
    # We need to use a subshell because IFS should be updated only in
    # this function and not globally
    (
        if [ -n "${FILES_TO_COPY}" ]; then    
            console::printPurple "Copying files... ${FILES_TO_COPY}"

            # Files are comma separated ("folder1,folder2,folder3")
            export IFS=","

            for FILE_TO_COPY in ${FILES_TO_COPY}; do
                if [ -f "${INPUT_FOLDER_ABSOLUTE_PATH}/${FILE_TO_COPY}" ]; then
                    console::printYellow "Copy file ${INPUT_FOLDER_ABSOLUTE_PATH}/${FILE_TO_COPY} to ${OUTPUT_FOLDER}/${FILE_TO_COPY}"
                    cp "${INPUT_FOLDER_ABSOLUTE_PATH}/${FILE_TO_COPY}" "${OUTPUT_FOLDER}/${FILE_TO_COPY}"
                else
                    console::printError "The file ${INPUT_FOLDER_ABSOLUTE_PATH}/${FILE_TO_COPY} didn't exist"
                    exit 1
                fi
            done
        fi

        if [ -n "${FOLDERS_TO_COPY}" ]; then
            console::printPurple "Copying folders... ${FOLDERS_TO_COPY}"

            # Folders are comma separated ("folder1,folder2,folder3")
            export IFS=","
            for FOLDER_TO_COPY in ${FOLDERS_TO_COPY}; do
                if [ -d "${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY}" ]; then
                    console::printYellow "Copy folder ${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY} to ${OUTPUT_FOLDER}/${FOLDER_TO_COPY}"
                    cp -R "${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY}" "${OUTPUT_FOLDER}/${FOLDER_TO_COPY}"
                else
                    console::printError "The folder ${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY} didn't exist"
                    exit 1
                fi
            done
        fi
    )

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
    entrypoint::__loadHelpers $*

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
    entrypoint::__initialize
    entrypoint::__runQuarto

    return 0
}

# shellcheck disable=SC2048,SC2086
__main $*
