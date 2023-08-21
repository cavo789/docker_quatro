#!/usr/bin/env bash

# region - Intro block -----------------------------------------------
#
# Helpers to works with command line options like `-v` or `--verbose` f.i.
#
# ## How to use this script?
#
# Just include this script in your own Bash like this `source opts.sh`
#
# Now, you can use any public functions defined here like `opts::hasFlag`.
#
# ## Namespace
#
# `opts::`
#
# ## Unit tests
#
# See file `test/opts.bats`.
# Run test scenario with `./test/bats/bin/bats test/opts.bats`
#
# ## Dependencies
#
# * `assert.sh`
#
# endregion - Intro block --------------------------------------------

# let script exit if an unsed variable is used or if a command fails
set -o nounset
set -o errexit

# Define a global variable that will contains the list of command line arguments.
CAF_OPTS_ARGUMENTS=""

# region - private function opts::__init
#
# ## Description
#
# This function will initialize important global variables.
# This function is called as soon as this file is "sourced" (like "source opts.sh")
# to make sure variables are initialized as soon as possible.
#
#! Should be called with $* (without quotes) to get access to the list
#! of CLI arguments#
#
# ## Examples
#
# ```bash
# opts::__init
# ```
#
# ## Parameters
#
# * @arg parameters List of CLI arguments
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# endregion
function opts::__init() {
    # If no argument (most probably the case), use the arguments given on the command line
    [[ $# == 0 ]] && CAF_OPTS_ARGUMENTS="${BASH_ARGV[*]}" && return 0

    # Arguments have been passed to this function, use them and not the ones from the command line
    # For instance: "source src/opts.sh $*"
    CAF_OPTS_ARGUMENTS="$*"

    return 0
}

# region - public function opts::hasFlag
#
# ## Description
#
# This function will return true when the program was called with a given
# argument like `--verbose`.
#
# See function `console::verbose` for a real example
#
# ## Examples
#
# ```bash
# opts::hasFlag "--verbose"        # Search only for --verbose (the long format)
# opts::hasFlag "-v|--verbose"     # Search for both -v and --verbose
#
# opts::hasFlag "-f|--force" && params['force']=true  # Set the params force to true
#
# opts::hasFlag "-h|--help" && console::printYellow "HELP ON"
# ! opts::hasFlag "-h|--help" && console::printYellow "HELP OFF"
# opts::hasFlag "-v|--verbose" && console::printYellow "VERBOSE ON"
# ! opts::hasFlag "-v|--verbose" && console::printYellow "VERBOSE OFF"
#
# arr=("concat" "--help" "--verbose" "--quiet")
# opts::hasFlag "-v|--verbose" arr && echo "Verbose mode enabled"
#
# opts::hasFlag "-v|--verbose" "concat --help --verbose --quiet" && echo "Verbose mode enabled"
# ```
#
# ## Parameters
#
# * @arg string   The name of the flag (f.i. "-h", "--help", "-v", "--verbose", ...)
#               Note: can be a list of possible values like "-v|--verbose"
# * @arg array    Optional. The list of arguments. Will use ${BASH_ARGV[*]} if not mentionned
#
# ## Return code (not exit code)
#
#! Unlike exit code, return 1 when OK (i.e. found) and return 0 when NOT OK (i.e. not found)
#
# * 1 When the flag was retrieved (hasFlag should return 0 when flag is retrieved)
# * 0 If the flag was NOT well mentionned in the command line argument
#
# endregion
function opts::hasFlag() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local flag="$1" # For instance "-v|--verbose"
    shift

    # The list of arguments is optional
    # shellcheck disable=SC2206
    if [[ $# != 0 ]]; then
        # Parameters has been mentionned, use tems
        optsArguments=($*)
    else
        # Use the command line parameters
        optsArguments=($CAF_OPTS_ARGUMENTS)
    fi

    # shellcheck disable=SC2048
    for opts_flag in ${optsArguments[*]}; do #${BASH_ARGV[*]}; do
        # console::printGray "Check $flag; is it $opts_flag? "
        # $1 can be "-h|--help", use the "== +(...)" syntax to match all possible values
        if [[ $opts_flag == +($flag) ]]; then
            # When found, return 0 meaning no error found => found
            return 0
        fi
    done

    # When not found, return 1 meaning an error has occurred => not found
    return 1
}

# This script didn't contains executable code; only helpers.
(return 0 2> /dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
    printf "[1;31m%s[0m\n" "ERROR, the $0 script is meant to be sourced. Try 'source $0' and use public functions."
    exit 1
fi

# Make some initializations
# shellcheck disable=SC2048,SC2086
opts::__init $*
