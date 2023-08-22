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

# The log level for Quarto; possible values are info, warning, error or critical
# Empty for no log level
LOG_LEVEL="${LOG_LEVEL:-""}"

# The output format. There is no default since the _quarto.yml file,
# if present in the input folder, probably mentionned the expected format
OUTPUT_FORMAT="${OUTPUT_FORMAT:-""}"

# Our input file (index.qmd) but having the targeted extension (like index.html)
OUTPUT_FILE=${INPUT_FILE%.qmd}.${OUTPUT_FORMAT}

# Folder where we'll move our rendered files
OUTPUT_FOLDER="${PROJECT_FOLDER}/output"

# Temporary logfile used during the rendering of Quarto
LOG_FILE_NAME="/tmp/quarto.log"

# Absolute name of the file we'll convert
INPUT_FILE_ABSOLUTE_PATH="${PROJECT_FOLDER}/input/${INPUT_FILE}"

# The command line we'll use to run Quarto and render our file
QUARTO_COMMAND_LINE=""

# Once the rendering has been done and the resulting files moved
# to the output folder; did we also need to copy some folders from
# the input folder to the output folder. This will be the case for, 
# for instance, images or static files used during the display of the
# generated files
# Folders are comma separated ("assets,images,...")
FOLDERS_TO_COPY=${FOLDERS_TO_COPY:-}

# region - private function entrypoint::__initialize
#
# Import helpers and initialize global variables
#
# endregion
function entrypoint::__initialize() {
    local helpersDir
    helpersDir="$SCRIPT_DIR/helpers"

    source "${helpersDir}/opts.sh" $*
    source "${helpersDir}/assert.sh" $*
    source "${helpersDir}/string.sh" $*
    source "${helpersDir}/console.sh" $*

    # The command line we'll use to run Quarto and render our file
    QUARTO_COMMAND_LINE="quarto render "${INPUT_FILE_ABSOLUTE_PATH}" --log ${LOG_FILE_NAME}"

    # Did we have a loglevel defined as OS variable? If so, use it
    [ ! -z "${LOG_LEVEL}" ] && QUARTO_COMMAND_LINE=$(echo "${QUARTO_COMMAND_LINE} --log-level ${LOG_LEVEL}")

    # If the output format was specified on command line / OS, use it
    # Otherwise relay on the _quarto.yml where there is probably the
    # output defined, f.i., like this:
    #
    # format:
    #   html:
    #     theme: cosmo
    #     css: styles.css
    [ ! -z "${OUTPUT_FORMAT}" ] && QUARTO_COMMAND_LINE=$(echo "${QUARTO_COMMAND_LINE} --to ${OUTPUT_FORMAT}")

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

    # The input file ... is a directory. We'll retrieve the first .qmd file in that directory
    if [ -d "${INPUT_FILE_ABSOLUTE_PATH}" ]; then
        # Remove the final "/" if present
        INPUT_FILE_ABSOLUTE_PATH="$(echo "${INPUT_FILE_ABSOLUTE_PATH}" | string::rtrim "/")"
        console::printGray "${INPUT_FILE_ABSOLUTE_PATH} is a folder"

        # Count the number of .qmd files in that directory
        # If more than one, ok we can't continue since we need to know
        # the name of the file to convert
        count=$(ls -AU ${INPUT_FILE_ABSOLUTE_PATH}/*.qmd | wc -l)

        if [ $count -gt 1 ]; then
            console::printError "The folder ${INPUT_FILE_ABSOLUTE_PATH} contains more than one .qmd file"
            console::printError "Please specify which file has to be rendered. Here is the list of files found:"
            console::printRed ""
            console::printRed "$(ls -al ${INPUT_FILE_ABSOLUTE_PATH}/*.qmd)"
            exit 1
        fi
        
        FIRST_FILE=$(ls -AU ${INPUT_FILE_ABSOLUTE_PATH}/*.qmd | head -1)

        if [ -f "${FIRST_FILE}" ]; then
            console::printGray "The first retrieved .qmd file was ${FIRST_FILE}, we'll then use that one"

            # Remember the absolute one
            INPUT_FILE_ABSOLUTE_PATH="${FIRST_FILE}"

            # and derive the relative filename
            INPUT_FILE="$(string::replace "${INPUT_FILE_ABSOLUTE_PATH}" "${PROJECT_FOLDER}/input/" "")"
            
        fi
    fi

    # Absolute name of the file parent folder
    INPUT_FOLDER_ABSOLUTE_PATH="$(dirname "${INPUT_FILE_ABSOLUTE_PATH}")"

    # Make sure the input file exists
    if [ ! -f "${INPUT_FILE_ABSOLUTE_PATH}" ]; then
        console::printError "The file ${INPUT_FILE_ABSOLUTE_PATH} didn't exist; please be sure to set the INPUT_FILE OS variable."
        console::printError "This can be done like this: \"docker run --rm -it -v \${PWD}/input:/project/input -v \${PWD}/output:/project/output -e INPUT_FILE=my_documentation.qmd bosa/quarto\"."
        console::printError "Make sure the specified input file exists."
        exit 1
    fi

    # Derive the output folder name; if we need to convert "input/blog/index.qmd"
    # the output folder will be "output/blog"
    OUTPUT_FOLDER="$(echo "${OUTPUT_FOLDER}/$(dirname "${INPUT_FILE}")")" 

    # All tests passed; we can continue
    return 0
}

# region - private function entrypoint::__createProjectIfRequired
#
# If the file _quarto.yml didn't exist yet, we are not in a Quarto
# project so, just create one
#
# endregion
function entrypoint::__createProjectIfRequired() {
    # if [ ! -f "${INPUT_FOLDER_ABSOLUTE_PATH}/_quarto.yml" ]; then
    #     console::printCyan "Create the Quarto Project"
    #     quarto create
    # fi

    return 0
}

# region - private function entrypoint::__runQuarto
#
# Run Quarto
#
# endregion
function entrypoint::__runQuarto() {
    console::printYellow "Rendering ${INPUT_FILE} to the ${OUTPUT_FOLDER} folder"
    console::printGray "$QUARTO_COMMAND_LINE"

    # Remove the previous log
    [ -f ${LOG_FILE_NAME} ] && rm -f ${LOG_FILE_NAME}

    # Execute the command, run Quarto. Note: output will be also written
    # to the log file (by default /tmp/quarto.log: as defined in variable LOG_FILE_NAME)
    ${QUARTO_COMMAND_LINE}

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
            rm -rf "${OUTPUT_FOLDER}/${folders[$key]}"
            mv "${INPUT_FOLDER_ABSOLUTE_PATH}/${folders[$key]}" "${OUTPUT_FOLDER}"
        fi
    done

    return 0
}

# region - private function entrypoint::__copyFoldersToCopyToOutputDirectory
#
# Once the rendering has been done and the resulting files moved
# to the output folder; did we also need to copy some folders from
# the input folder to the output folder. This will be the case for, 
# for instance, images or static files used during the display of the
# generated files
#
# endregion
function entrypoint::__copyFoldersToCopyToOutputDirectory {
    if [ ! -z "${FOLDERS_TO_COPY}" ]; then
        console::printPurple "Copying folders... ${FOLDERS_TO_COPY}"

        # Folders are comma separated ("folder1,folder2,folder3")
        export IFS=","
        for FOLDER_TO_COPY in $FOLDERS_TO_COPY; do
            if [ -d "${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY}" ]; then
                console::printYellow "Copy folder ${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY} to ${OUTPUT_FOLDER}/${FOLDER_TO_COPY}"
                cp -R "${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY}" "${OUTPUT_FOLDER}/${FOLDER_TO_COPY}"
            else
                console::printError "The folder ${INPUT_FOLDER_ABSOLUTE_PATH}/${FOLDER_TO_COPY} didn't exist"
                exit 1
            fi
        done
    fi
}
# region - private function entrypoint::__moveToOutputDirectory
#
# Move rendered files/folders to the output directory
#
# endregion
function entrypoint::__moveToOutputDirectory() { 

    if [ -d "${OUTPUT_FOLDER}" ] && [ "$(basename "${OUTPUT_FOLDER}")" -neq "." ];  then
        console::debug "Before copying newest version, erase ${OUTPUT_FOLDER} so don't keep old stuff"

        console::p
        rm -rf "${OUTPUT_FOLDER}"
    fi

    console::debug "Create folder ${OUTPUT_FOLDER}" && mkdir -p "${OUTPUT_FOLDER}"

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
    GENERATED_FOLDER="$(basename ${INPUT_FILE} .qmd)_files"
    if [ -d "${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FOLDER}" ]; then
        console::debug "Move folder ${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FOLDER} to ${OUTPUT_FOLDER}/${GENERATED_FOLDER}"
        rm -rf "${OUTPUT_FOLDER}/${GENERATED_FOLDER}"
        mv "${INPUT_FOLDER_ABSOLUTE_PATH}/${GENERATED_FOLDER}" "${OUTPUT_FOLDER}/${GENERATED_FOLDER}"
    fi

    entrypoint::__copyFoldersToCopyToOutputDirectory

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
    entrypoint::__createProjectIfRequired
    entrypoint::__runQuarto
    entrypoint::__moveToOutputDirectory

    return 0
}

# shellcheck disable=SC2048,SC2086
__main $*
