#!/usr/bin/env bash

# region - Define colors
__GRAY=30
__RED=31
__GREEN=32
__YELLOW=33
__BLUE=34
__PURPLE=35
__CYAN=36
__WHITE=37
# endregion

# region - Intro block -----------------------------------------------
#
# Collection of public functions to work with the console like outputting
# text in colors (red, blue, yellow, green, ...), writing a banner, ...
#
# ## How to use this script?
#
# Just include this script in your own Bash like this `source console.sh`
#
# Now, you can use any public functions defined here like `console::printYellow`.
#
# ## Command line arguments
#
# When this helper is "sourced" (like `source console.sh`), the `__init` private
# function is fired and will check the presence of some command line arguments
#
#    `-q` or `--quiet`   ==> set a global variable called `QUIET` to `1`   (`0` otherwise)
#    `-v` or `--verbose` ==> set a global variable called `VERBOSE` to `1` (`0` otherwise)
#
# `QUIET=1`   will disable any console::printxxxx statement i.e. nothing will be echoed on the console
# `VERBOSE=1` will enable the console::verbose function i.e. allow to write more detailed information on the console.
#
# The calling script (let's say "myscript.sh" that included the "source console.sh" statement)
# didn't need to take any action i.e. as soon as `-v` or `-q` f.i. are on the command line, these options will
# be processed by console.sh. "myscript.sh" didn't do anything special here to manage these options.
#
# ## Namespace
#
# `console::`
#
# ## Unit tests
#
# See file `test/console.bats`.
# Run test scenario with `./test/bats/bin/bats test/console.bats`
#
# ## Dependencies
#
# * `opts.sh`
#
# endregion - Intro block --------------------------------------------

# let script exit if an unsed variable is used or if a command fails
set -o nounset
set -o errexit

# region - private function console::__init
#
# ## Description
#
# This function will initialize important global variables like QUIET or VERBOSE.
# This function is called as soon as this file is "sourced" (like "source console.sh")
# to make sure variables are initialized as soon as possible.
#
# ## Examples
#
# ```bash
# console::__init
# ```
# endregion
function console::__init() {
    # Check if the DEBUG global variable is already defined (isset)
    # if [[ ! -v DEBUG ]]; then
    # No, not yet defined so, first initialize it to zero then
    # read once the list of command line options and set the variable to 1 if -d or --debug is found
    DEBUG=0
    opts::hasFlag "-d|--debug" && DEBUG=1
    # fi

    # Check if the QUIET global variable is already defined (isset)
    # if [[ ! -v QUIET ]]; then
    # No, not yet defined so, first initialize it to zero then
    # read once the list of command line options and set the variable to 1 if -v or --QUIET is found
    QUIET=0
    opts::hasFlag "-q|--quiet" && QUIET=1
    # fi

    # Check if the VERBOSE global variable is already defined (isset)
    # if [[ ! -v VERBOSE ]]; then
    # No, not yet defined so, first initialize it to zero then
    # read once the list of command line options and set the variable to 1 if -v or --verbose is found
    VERBOSE=0
    opts::hasFlag "-v|--verbose" && VERBOSE=1
    # fi

    # Make sure to return 0 i.e. everything was fine
    return 0
}

# region - public function console::askYesNo
#
# ## Description
#
# Ask a question on the console. The expected answer is Yes or No
#
# ## Examples
#
# ```bash
# if $(console::askYesNo "Do you want to enable DEV environment?" "Y"); then
#    echo "Ok, enable DEV mode"
# fi
# ```
#
# ## Parameters
#
# * @arg text The question (like "Do you want to enable DEV environment?")
# * @arg text The default answer (like "Y")
#
# ## Exit code
#
# * 0 The user has answered YES
# * 1 The user has answered NO (or nothing, just by pressing enter)
#
# endregion
function console::askYesNo() {
    prompt="$1"

    # shellcheck disable=SC2060
    default="$(echo "$2" | tr [:lower:] [:upper:])"

    if [ "${default}" != "N" ]; then
        values="[Yn]"
    else
        values="[yN]"
    fi

    # shellcheck disable=SC2162
    read -p "${prompt} ${values} " answer

    # If the user has just pressed enter, use the default answer
    answer="${answer:-${default}}"

    # Convert to uppercase, /bin/sh compatible syntax)
    # shellcheck disable=SC2060
    answer=$(echo "${answer}" | tr [:lower:] [:upper:])

    if [ "${answer}" = "Y" ]; then
        # The user has answered Yes
        exit 0
    fi

    # The user has answered No
    exit 1
}

# region - public function console::banner
#
# ## Description
#
# Make sure to write to STDERR, write a text in red on the console
#
# ## Examples
#
# ```bash
# console::banner "Step 1 - Initialization"
# ```
#
# ## Parameters
#
# * @arg text Text to echo on screen
#
# ## Returns
#
# ```text
# ============================================
# = Step 1 - Initialization                  =
# ============================================
# ```
#
# ## Exit code
#
# * 0 If successful or nothing to display
#

# endregion
function console::banner() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    msg="    $*    "

    # shellcheck disable=SC2001
    empty="$(echo "$msg" | sed 's/./ /g')"
    # shellcheck disable=SC2001
    header="##$(echo "$msg" | sed 's/./#/g')##"

    echo ""
    echo "$header"
    echo "# $empty #"
    echo "# $msg #"
    echo "# $empty #"
    echo "$header"
    echo ""
}

# region - public function console::printBlue()
#
# ## Description
#
# Write in blue on the console
#
# ## Examples
#
# ```bash
# console::printBlue() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printBlue() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__BLUE}m%s[0m\n" "$line"
    done
}

# region - public function console::printBlueNoNewLine()
#
# ## Description
#
# Write in blue on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printBlueNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printBlueNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__BLUE}m%s\e[m" "$*"
}

# region - public function console::printCyan()
#
# ## Description
#
# Write in cyan on the console
#
# ## Examples
#
# ```bash
# console::printCyan() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printCyan() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__CYAN}m%s[0m\n" "$line"
    done
}

# region - public function console::printCyanNoNewLine()
#
# ## Description
#
# Write in cyan on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printCyanNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printCyanNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__CYAN}m%s\e[m" "$*"
}

# region - public function console::printError
#
# ## Description
#
# Make sure to write to STDERR, write a text in red on the console
#
# ## Examples
#
# ```bash
# console::printError "${FUNCNAME[0]} - Mandatory file is missing"
# ```
#
# ## Returns
#
# ```text
# [2022-02-02T16:57:56+0100] ERROR - docker::init - Mandatory file is missing"
# ````
#
# ## Parameters
#
# * @arg text Text to echo on screen
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printError() {
    [[ $# == 0 ]] && return 0
    for line in "$@"; do
        line="$(echo "$line" | string::trim)"
        console::printRed "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR - $line" >&2
    done
}

# region - public function console::printGray()
#
# ## Description
#
# Write in gray on the console
#
# ## Examples
#
# ```bash
# console::printGray() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printGray() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__GRAY}m%s[0m\n" "$line"
    done
}

# region - public function console::printGrayNoNewLine()
#
# ## Description
#
# Write in gray on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printGrayNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printGrayNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__GRAY}m%s\e[m" "$*"
}

# region - public function console::printGreen()
#
# ## Description
#
# Write in green on the console
#
# ## Examples
#
# ```bash
# console::printGreen() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printGreen() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__GREEN}m%s[0m\n" "$line"
    done
}

# region - public function console::printGreenNoNewLine()
#
# ## Description
#
# Write in green on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printGreenNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printGreenNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__GREEN}m%s\e[m" "$*"
}

# region - public function console::printItalic()
#
# ## Description
#
# Write a text on the console in italic
#
# ## Examples
#
# ```bash
# console::printItalic() "Information"
# ```
#
# ## Parameters
#
# * @arg text Text to echo on screen
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printItalic() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    echo -e "\e[3m$*\e[0m"
}

# region - public function console::printPurple()
#
# ## Description
#
# Write in purple on the console
#
# ## Examples
#
# ```bash
# console::printPurple() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printPurple() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__PURPLE}m%s[0m\n" "$line"
    done
}

# region - public function console::printPurpleNoNewLine()
#
# ## Description
#
# Write in purple on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printPurpleNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printPurpleNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__PURPLE}m%s\e[m" "$*"
}

# region - public function console::printRed()
#
# ## Description
#
# Write in red on the console
#
# ## Examples
#
# ```bash
# console::printRed() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printRed() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__RED}m%s[0m\n" "$line"
    done
}

# region - public function console::printRedNoNewLine()
#
# ## Description
#
# Write in red on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printRedNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printRedNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__RED}m%s\e[m" "$*"
}

# region - public function console::printStart
#
# ## Description
#
# Display name of the running script and the start time
#
# ## Examples
#
# ```bash
# console::printStart   #Output something like `Running docker-down.sh - Start at 02/02/22 16:47:43`
# ```
#
# ## Parameters
#
# * @arg String Optional, the name of the script
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# endregion
function console::printStart() {
    [[ $QUIET -eq 1 ]] && return 0

    scriptName="$(basename "$0")"
    [[ $# == 1 ]] && scriptName="$1"

    console::printWhiteNoNewLine "Running ${scriptName} - Start at $(date +'%d/%m/%y %H:%M:%S')" \
        ""
    echo ""
}

# region - public function console::printStop
#
# ## Description
#
# Display name of the running script, the end time and elapsed time in seconds
#
# ## Examples
#
# ```bash
# console::printStop   #Output something like `Running docker-down.sh - End at 02/02/22 16:47:45, duration: 2 seconds`
# ```
#
# ## Parameters
#
# * @arg String Optional, the name of the script
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# endregion
function console::printStop() {
    [[ $QUIET -eq 1 ]] && return 0

    scriptName="$(basename "$0")"
    [[ $# == 1 ]] && scriptName="$1"

    console::printWhiteNoNewLine "Running ${scriptName} - End at $(date +'%d/%m/%y %H:%M:%S'), duration: $SECONDS seconds" \
        ""
    echo ""
}

# region - public function console::printWhite()
#
# ## Description
#
# Write in white on the console
#
# ## Examples
#
# ```bash
# console::printWhite() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printWhite() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__WHITE}m%s[0m\n" "$line"
    done
}

# region - public function console::printWhiteNoNewLine()
#
# ## Description
#
# Write in white on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printWhiteNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printWhiteNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__WHITE}m%s\e[m" "$*"
}

# region - public function console::printYellow()
#
# ## Description
#
# Write in Yellow on the console
#
# ## Examples
#
# ```bash
# console::printYellow() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printYellow() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    for line in "$@"; do
        printf "[1;${__YELLOW}m%s[0m\n" "$line"
    done
}

# region - public function console::printYellowNoNewLine()
#
# ## Description
#
# Write in yellow on the console, one line, no carriage return
#
# ## Examples
#
# ```bash
# console::printYellowNoNewLine() "Lorem ipsum dolor sit amet, consectetur adipiscing elit." \
#     "Donec a tortor viverra, auctor urna sed, lacinia diam. "
# ```
#
# ## Parameters
#
# * @arg parameters Can be a multi-lines argument, each line will be echoed on the console
#
# ## Exit code
#
# * 0 If successful or nothing to display
#
# endregion
function console::printYellowNoNewLine() {
    [[ $# == 0 ]] && return 0
    [[ $QUIET -eq 1 ]] && return 0

    printf "\e[1;${__YELLOW}m%s\e[m" "$*"
}

# region - public function console::verbose
#
# ## Description
#
# Write a string in the console only when the application is started
# in verbose mode i.e. when the "-v" or "--verbose" flag is present
# on the command line argument.
# Don't write to console in the absence of the flag
#
# ## Examples
#
# ```bash
# console::verbose "Running ... step ..."
# ```
#
# ## Parameters
#
# * @arg string The text to write on the console but only if verbose mode is set
#
# endregion
function console::verbose() {
    [[ $# == 0 ]] && return 0
    # Illogic but, in case of the --quiet mode is enabled, that one has the favor
    [[ ${QUIET:-0} -eq 1 ]] && return 0
    [[ ${VERBOSE:-0} -ne 1 ]] && return 0

    for line in "$@"; do
        console::printGray >&2 "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [VERBOSE] - ${FUNCNAME[1]} - $line"
    done

    return 0
}

# region - public function console::debug
#
# ## Description
#
# Write a string in the console only when the application is started
# in debug mode i.e. when the "-d" or "--debug" flag is present
# on the command line argument.
# Don't write to console in the absence of the flag
#
# ## Examples
#
# ```bash
# console::debug "..."
# ```
#
# ## Parameters
#
# * @arg string The text to write on the console but only if debug mode is set
#
# endregion
function console::debug() {
    [[ $# == 0 ]] && return 0
    [[ ${DEBUG:-0} -ne 1 ]] && return 0
    [[ ${QUIET:-0} -eq 1 ]] && return 0

    console::printGray >&2 "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [DEBUG] - ${FUNCNAME[1]} - $*"
    return 0
}

# This script didn't contains executable code; only helpers.
(return 0 2> /dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
    printf "[1;31m%s[0m\n" "ERROR, the $0 script is meant to be sourced. Try 'source $0' and use public functions."
    exit 1
fi

# Make some initializations
# shellcheck disable=SC2048,SC2086
console::__init $*
