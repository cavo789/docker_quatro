#!/usr/bin/env bash

# region - Intro block -----------------------------------------------
#
# Provide assertXxxx functions like assertFileExists. The idea behind an assertion is
# to stop the execution of the script if the assertion fails.
#
# An assertion SHOULD BE valided before the script can continue. Prefer functions like
# `file::exists` if you don't want to quit.
#
# ## How to use this script?
#
# Just include this script in your own Bash like this `source assert.sh`
#
# Now, you can use any public functions defined here like `assert::assertFileExists`.
#
# ## Namespace
#
# `assert::`
#
# ## Unit tests
#
# See file `test/assert.bats`.
# Run test scenario with `./test/bats/bin/bats test/assert.bats`
#
# ## Dependencies
#
# * `array.sh`
# * `console.sh`
# * `string.sh`
#
# endregion - Intro block --------------------------------------------

# let script exit if an unsed variable is used or if a command fails
set -o nounset
set -o errexit

# region - public function assert::binaryExists
#
# ## Description
#
# Check that a specific binary (like `jq`, `xmllint`, ...) exists on the $PATH.
# If this is not the case, stop the execution of the script and exit with code 1.
#
# ## Examples
#
# ```bash
# assert::binaryExists "xmllint" "Oups, please install xmllint first"
# ```
#
# ## Parameters
#
# * @arg string The name of the binary
# * @arg string Optional, the error message to display if the file didn't exists
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
# * 2 Function missing arguments.
#
# endregion
function assert::binaryExists() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r binary="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - File \"$binary\" did not exists}"

    [[ -z "$(command -v "$binary" || true)" ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::dockerImageExists
#
# ## Description
#
# Check if a specific Docker image already exists on the host.
# If this is not the case, stop the execution of the script and exit with code 1.
#
# ## Examples
#
# ```bash
# assert::dockerImageExists "felixlohmeier/mermaid" "Sorry, the image didn't exists"
# ```
#
# ## Parameters
#
# * @arg String A Docker image name like "node", "postgres", "felixlohmeier/mermaid", ...
# * @arg string Optional, the error message to display if the file didn't exists
#
# ## Exit code
#
# * 0 If successful i.e. the Docker image has been retrieved onto the host
# * 1 The Docker image didn't exists.
# * 2 Function missing arguments.
#
# endregion
function assert::dockerImageExists() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r image="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - The Docker image \"$image\" did not exists}"

    # When the image exists, "docker images -q" will return his ID (f.i. `5eed474112e9`), an empty string otherwise
    [[ "$(docker images -q "$image" 2> /dev/null)" == "" ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::exitCode0
#
# ## Description
#
# Check the exit code of the preceding command and if different than 0,
# throw an error and stop the execution of the script, return the meet exit code
#
# ## Examples
#
# ```bash
# # Don't stop the code if the eval statement exit with something else than 0
# set +e
# eval "AN_INVALID_COMMAND"
# assert::exitCode0 "Ouch, sorry the command has failed"
# # Restore the "exit as soon as an error occurred"
# set -e
# ```
#
# ## Parameters
#
# * @arg string Optional, the error message to display on screen
#
# ## Unit tests
#
#! Note: this function can't be tested with Bats (or any other frameworks)
#! because it's using the `$?` special variable and that variable is the one
#! of the last command (fired by the framework itself)
#
# ## Exit code
#
# * 0 If successful.
# (any) The error code returned by the previous, fired, instruction.
#
# endregion
function assert::exitCode0() {
    local -r exitCode=$? # Get the exit code of the previous, fired, instruction

    [[ $exitCode -eq 0 ]] && return

    local -r msg="${*:-${FUNCNAME[0]} - The last instruction has failed}"

    console::printError "$msg (exitcode=$exitCode)"
    exit $exitCode
}

# region - public function assert::fileDontExists
#
# ## Description
#
# Check that a file didn't exists.
# If the file is well present, throw an error and stop the execution of the script
#
# ## Examples
#
# ```bash
# assert::fileDontExists "secrets.key"
# ```
#
# ## Parameters
#
# * @arg string The path to the file (absolute or relative)
# * @arg string Optional, the error message to display if the file well exists
#
# ## Exit code
#
# * 0 If successful, i.e. the file don't exists.
# * 1 An error has occurred i.e. the file well exist.
# * 2 Function missing arguments.
#
# endregion
function assert::fileDontExists() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r filename="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - File \"$filename\" exists.}"

    # -f = The file exists
    [[ -f $filename ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::fileExists
#
# ## Description
#
# Check that a file exists.
# If this is not the case, stop the execution of the script and exit with code 1.
#
# ## Examples
#
# ```bash
# assert::fileExists "composer.json"
# ```
#
# ## Parameters
#
# * @arg string The path to the file (absolute or relative)
# * @arg string Optional, the error message to display if the file didn't exists
#
# ## Exit code
#
# * 0 If successful, i.e. the file exists.
# * 1 An error has occurred i.e. the file didn't exist.
# * 2 Function missing arguments.
#
# endregion
function assert::fileExists() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r filename="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - File \"$filename\" did not exists}"

    # -f = The file exists
    [[ ! -f $filename ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::fileIsEmpty
#
# ## Description
#
# Check that a file is empty.
# If this is not the case, stop the execution of the script and exit with code 1.
#
# ## Examples
#
# ```bash
# assert::fileIsEmpty "composer.json"
# ```
#
# ## Parameters
#
# * @arg string The path to the file (absolute or relative)
# * @arg string Optional, the error message to display if the file didn't exists
#
# ## Exit code
#
# * 0 If successful i.e. the file is empty
# * 1 An error has occurred i.e. the file isn't empty
# * 2 Function missing arguments.
#
# endregion
function assert::fileIsEmpty() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r filename="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - File \"$filename\" should be empty and this is not the case.}"

    # -s = Checks if file has size greater than 0
    [[ -s $filename ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::fileNotEmpty
#
# ## Description
#
# Check that a file isn't empty.
# If this is not the case, stop the execution of the script and exit with code 1.
#
# ## Examples
#
# ```bash
# assert::fileNotEmpty "composer.json"
# ```
#
# ## Parameters
#
# * @arg string The path to the file (absolute or relative)
# * @arg string Optional, the error message to display if the file didn't exists
#
# ## Exit code
#
# * 0 If successful i.e. the file isn't empty
# * 1 An error has occurred i.e. the file is empty
# * 2 Function missing arguments.
#
# endregion
function assert::fileNotEmpty() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r filename="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - File \"$filename\" is empty}"

    # -s = Checks if file has size greater than 0
    [[ ! -s $filename ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::folderExists
#
# ## Description
#
# Check that a file exists, throw an error otherwise
#
# ## Examples
#
# ```bash
# assert::folderExists ".output" && echo "Ok, continue, folder is well there"
# ```
#
# ## Parameters
#
# * @arg string The path to the folder (absolute or relative)
# * @arg string Optional, the error message to display if the folder didn't exists
#
# ## Exit code
#
# * 0 If successful i.e. the folder exists
# * 1 An error has occurred i.e. the folder did not exist
# * 2 Function missing arguments.
#
# endregion
function assert::folderExists() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r foldername="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - Folder \"$foldername\" did not exists}"

    # -d = The folder exists
    [[ ! -d $foldername ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::functionExists
#
# ## Description
#
# Check that a given function exists, throw an error otherwise
#
# ## Examples
#
# ```bash
# # Check if the function exists and if so, call it
# assert::functionExists "helloWorld" && helloWorld
# ```
#
# ## Parameters
#
# * @arg string The name of the function
# * @arg string Optional, the error message to display if the function didn't exists
#
# ## Exit code
#
# * 0 If successful i.e. the function exists
# * 1 An error has occurred i.e. the function didn't exists
# * 2 Function missing arguments.
#
# endregion
function assert::functionExists() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r functionName="${1}"
    local -r msg="${2:-${FUNCNAME[0]} - Function \"$functionName\" did not exists}"

    [[ $(type -t "${functionName}") != function ]] && console::printError "$msg" && exit 1
    return 0
}

# region - public function assert::hasArguments
#
# ## Description
#
# Make sure a function is called with AT LEAST enough parameters. If not, show an error and die.
# `hasArguments 1` f.i. will be successfull when the number of arguments is greater; the idea is
# then that extra parameters are optionnal ones. See `assert::stringNoEmpty` for an example.
#
# ## Examples
#
# ```bash
# assert::hasArguments 2 arguments # Will fail when the number of arg is lower than 2 but OK if greater than 2
# ```
#
# ## Parameters
#
# * @arg int   The expected number f.i. `2`
# * @arg mixed List of arguments
#
# ## Exit code
#
# * 0 If successful i.e. the number of arguments has been met
# * 2 If failure i.e. the number of arguments has NOT met
#
# endregion
function assert::hasArguments() {
    # # Check this function, check "hasArguments" and here, we need at least two arguments.
    if [[ $# -lt 2 ]]; then
        console::printError "Missing arguments for function ${FUNCNAME[0]}" \
            "The function ${FUNCNAME[0]} has been called by ${FUNCNAME[1]} in ${BASH_SOURCE[1]}" \
            "(himself called by called by ${FUNCNAME[2]} in ${BASH_SOURCE[2]})" \
            "Please review your code and call the ${FUNCNAME[0]} with the correct number of parameters which is 2." \
            "See the documentation of the ${FUNCNAME[0]} function in file ${BASH_SOURCE[0]} if needed."
        exit 2
    fi

    local -r expectedNumberArgs=$1
    shift

    if [[ $# -lt $expectedNumberArgs ]]; then
        console::printError "Missing arguments for function ${FUNCNAME[1]}" \
            "Please review your code and call the ${FUNCNAME[1]} with the correct number of parameter which is ${expectedNumberArgs}." \
            "See the documentation of the ${FUNCNAME[1]} function in file ${BASH_SOURCE[1]} if needed." \
            "The function ${FUNCNAME[1]} has been called by ${FUNCNAME[2]} in ${BASH_SOURCE[2]}."
        exit 2
    fi

    return 0
}

# region - public function assert::keyExists
#
# ## Description
#
# Make sure a key exists in an associative array
#
# ## Examples
#
# ```bash
# declare -A arr=(
#    [commandLineArguments]=""
#    [projectRootDir]=""
#)
#
# assert::keyExists arr "projectRootDir" "The key projectRootDir is mandatory"
# ```
#
# ## Parameters
#
# * @arg array  The associative array
# * @arg string The key for which the presence should be checked
# * @arg string Optional, the error message to display if the key didn't exists
#
# ## Exit code
#
# * 0 If successful i.e. the key exists
# * 1 The key didn't exists
# * 2 Function missing arguments.
#
# endregion
function assert::keyExists() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 2 $*

    # shellcheck disable=SC2034
    local -n arrKeyExists=$1
    local -r key=$2
    local -r msg="${3:-${FUNCNAME[0]} - The key \"$key\" did not exists in the array}"

    [[ ! -v "arrKeyExists[$key]" ]] && console::printError "$msg" && exit 1

    return 0
}

# region - public function assert::stringNotEmpty
#
# ## Description
#
# Assert the string is not empty
#
# ## Examples
#
# ```bash
# firstname=""
# assert::stringNotEmpty "$firstname" "Sorry dear user but your firstname has to be filled in"
# ```
#
# ## Parameters
#
# * @arg string The string to check
# * @arg string Optional, the error message to display if the string is empty
#
# ## Exit code
#
# * 0 If successful i.e. the string isn't empty
# * 1 The string is empty
# * 2 Function missing arguments.
#
# endregion
function assert::stringNotEmpty() {
    local -r string="$1"
    shift
    local -r msg="${*:-${FUNCNAME[0]} - The string is empty}"

    # -z = The string is empty
    [[ -z $string ]] && console::printError "$msg" && exit 1

    return 0
}

# This script didn't contains executable code; only helpers.
(return 0 2> /dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
    printf "[1;31m%s[0m\n" "ERROR, the $0 script is meant to be sourced. Try 'source $0' and use public functions."
    exit 1
fi
