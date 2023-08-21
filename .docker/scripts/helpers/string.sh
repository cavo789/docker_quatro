#!/usr/bin/env bash

# region - Intro block -----------------------------------------------
#
# Collection of public functions to work with strings like trim,
# transform to lower / upper case, ...
#
# ## How to use this script?
#
# Just include this script in your own Bash like this `source string.sh`
#
# Now, you can use any public functions defined here like `string::lower`.
#
# ## Namespace
#
# `string::`
#
# ## Unit tests
#
# See file `test/string.bats`.
# Run test scenario with `./test/bats/bin/bats test/string.bats`
#
# ## Dependencies
#
# * `assert.sh`
#
# ## Inspiration
#
# * [https://github.com/labbots/bash-utility/blob/master/src/string.sh](https://github.com/labbots/bash-utility/blob/master/src/string.sh)
# * [https://github.com/jmcantrell/bashful/blob/master/bin/bashful-utils](https://github.com/jmcantrell/bashful/blob/master/bin/bashful-utils)
#
# endregion - Intro block --------------------------------------------

# let script exit if an unsed variable is used or if a command fails
set -o nounset
set -o errexit

# region - public function string::contains
#
# ## Description
#
# Check if a string contains a substring
#
# ## Examples
#
# ```bash
# string::contains "Hello World!" "Earth" && echo "Contains the word ""Earth"""
# ```
#
# ## Parameters
#
# * @arg string The search string (f.i. `Hello World!`)
# * @arg string The substring string (f.i. `Earth`)
#
# ## Exit code
#
# * 0 If successful i.e. the substring was found.
# * 1 The substring wasn't found, the string didn't contains the given pattern.
# * 2 Function missing arguments.
#
# endregion
function string::contains() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    [[ ${1} == *"${2:-}"* ]]
    # or [[ "${1}" =~ .*"${2}".* ]] if we need to parse a regex
}

# region - public function string::endsWith
#
# ## Description
#
# Check if a string ends with a given suffixe
#
# ## Examples
#
# ```bash
# if ! $(string::endsWith "Hello World!" "Earth"); then
#    echo "The string didn't ends with Earth"
# fi
#
# if $(string::endsWith "federal_data_manager.wiki" ".wiki"); then
#    echo "It's a wiki!"
# fi
# ```
#
# ## Parameters
#
# * @arg string The search string (f.i. `Hello World!`)
# * @arg string The suffix string (f.i. `Earth`)
#
# ## Exit code
#
# * 0 If successful i.e. the suffix was found.
# * 1 The suffix wasn't found, the string didn't ends with the given pattern.
# * 2 Function missing arguments.
#
# endregion
function string::endsWith() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    [[ ${1} == *${2:-} ]]
}

# region - public function string::explode
#
# ## Description
#
# Explode a string like `a;b;c;d` into an array with has many
# entries we've in the string
#
# See also array::implode() which make the inverse
#
# ## Examples
#
# ```bash
# string::explode 'a;b;c;d' ';'
# ```
#
# ## Parameters
#
# * @arg string The string to explode
# * @arg string Optional, the delimiter (default is ;)
#
# ## Return
#
# An array with one entry by value found once exploded
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
# * 2 Function missing arguments.
#
# endregion
function string::explode() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    declare -a arrExplode=()

    local -r value="${1}"
    local -r separator="${2:-;}"

    IFS="${separator}" read -r -a arrExplode <<< "${value}"
    printf '%s\n' "${arrExplode[@]}"
}

# region - public function string::lower
#
# ## Description
#
# Make a string lowercase.
#
# ## Examples
#
# ```bash
# echo "HEllow WoRLD!" | string::lower # Will return "hello world!""
#
# yesno="$(echo $yesno | string::lower)"
# ```
#
# ## Return
#
# The string in lowercase
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# @https://github.com/jmcantrell/bashful/blob/master/bin/bashful-utils#L22
#
# endregion
function string::lower() {
    tr '[:upper:]' '[:lower:]'
}

# region - public function string::ltrim
#
# ## Description
#
# Removes all leading whitespace (from the left)
# Specify the character to remove (default is a space) as the first argument
# to remove that character; f.i. a starting slash
#
# ## Examples
#
# ```bash
# $(echo "     Hello world     " | string::ltrim)"  # "Hello world     "
# $(echo "/tmp/folder/" | string::ltrim "/")"       # "tmp/folder/"
# ```
#
# ## Parameters
#
# * @arg String The character to remove, default is a space
#
# ## Return
#
# The left-trimmed string
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# @link https://github.com/jmcantrell/bashful/blob/master/bin/bashful-utils#L233
#
# endregion
function string::ltrim() {
    local -r char=${1:-[:space:]}
    sed "s%^[${char//%/\\%}]*%%"
}

# region - public function string::padding
#
# ## Description
#
# Make sure a string has a given length and, if not, add extra spaces to it.
#
# ## Examples
#
# ```bash
# echo "$(string::padding "A" 5)"       # Will print "A    "
# echo "$(string::padding "AB" 5)"      # Will print "AB   "
# echo "$(string::padding "ABC" 5)"     # Will print "ABC  "
# echo "$(string::padding "ABCD" 5)"    # Will print "ABCD "
# echo "$(string::padding "ABCDE" 5)"   # Will print "ABCDE"
# ```
#
# Use `.` instead of a space for the padding
#
# ```bash
# echo "$(string::padding "A" 5 ".")    # Will print "A...."
# ```
#
# ## Parameters
#
# * @arg string The string
# * @arg int Optional, the length of the string to return. Default is 80.
# * @arg string Optional, the character to use for the padding. Default is a space
#
# ## Return
#
# The string with extra spaces on his right so the returned string has the exact,
# expected, length
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
# * 2 Function missing arguments.
#
# endregion
function string::padding() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r value="$1"
    local -r length=${2:-80}     # Default will be 80 times
    local -r character="${3:- }" # The default character will be a space

    padding="$(string::repeat "${character}" "$length")"

    printf "%s%s" "$value" "${padding:${#value}}"
}

# region - public function string::repeat
#
# ## Description
#
# Repeat a character (or substring) x times
#
# ## Examples
#
# ```bash
# echo $(string::repeat "*" 5)   # will return `*****`
# echo $(string::repeat "   " 3) # will return `         `
# ```
#
# ## Parameters
#
# * @arg string A character or substring (like three spaces f.i.) to repeat
# * @arg string Optional, the number of times to repeat (f.i. 5, defaut 80)
#
# ## Return
#
# The pattern repeated x times
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
# * 2 Function missing arguments.
# endregion
function string::repeat() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    local -r pattern="${1:-=}" # Default will be an equal sign
    local -r end=${2:-80}      # Default will be 80 times

    local range

    # shellcheck disable=SC2086
    range=$(seq 1 $end)

    result=""

    # shellcheck disable=SC2034
    for i in $range; do result="${result}${pattern}"; done

    echo "$result"

    return 0
}

# region - public function string::replace
#
# ## Description
#
# Find and replace a string inside a string
#
# ## Examples
#
# ```bash
# echo $(string::replace "Hello World!" "World" "Belgium") # Hello Belgium!
# ```
#
# ## Parameters
#
# * @arg string The original string like `Hello World!`
# * @arg string The pattern to search for like `World`
# * @arg string When the pattern is found, replace it by a newer value like `Belgium`
#
# ## Return
#
# The string with the new value
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# endregion
function string::replace() {
    # If the first parameter (the string) is empty, there is nothing to do
    [[ -z $1 ]] && return

    # shellcheck disable=SC2048,SC2086
    local -r stringOriginal="$1"
    local -r stringPlaceHolder="$2"
    local -r stringNewValue="${3:-}"

    echo "${stringOriginal//$stringPlaceHolder/$stringNewValue}"
}

# region - public function string::reverse
#
# ## Description
#
# Reverse a string
#
# ## Examples
#
# ```bash
# string::reverse "ABCDE"  # Will return "EDCBA"
# ```
#
# ## Parameters
#
# * @arg string The original string to reverse
#
# ## Return
#
# The string with the new value
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# endregion
function string::reverse() {
    # If the first parameter (the string) is empty, there is nothing to do
    [[ -z $1 ]] && return

    echo "$1" | rev
}

# region - public function string::rtrim
#
# ## Description
#
# Removes all trailing whitespace (from the right).
# Specify the character to remove (default is a space) as the first argument
# to remove that character; f.i. an ending slash
#
# ## Examples
#
# ```bash
# $(echo "     Hello world     " | string::rtrim)"  # "     Hello world"
# $(echo "/tmp/folder/" | string::rtrim "/")"       # "/tmp/folder"
# ```
#
# ## Parameters
#
# * @arg String The character to remove, default is a space
#
# ## Return
#
# The right-trimmed string
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# @https://github.com/jmcantrell/bashful/blob/master/bin/bashful-utils#L245
#
# endregion
function string::rtrim() {
    local -r char=${1:-[:space:]}
    sed "s%[${char//%/\\%}]*$%%"
}

# region - public function string::slugify
#
# ## Description
#
# Create a slug from any text
# Return "how-to" f.i. the text is "How to?"
# https://gist.github.com/oneohthree/f528c7ae1e701ad990e6
#
# ## Examples
#
# ```bash
# echo "HEllow WoRLD!" | string::slugify  # will return `hellow-world`
# ```
#
# ## Parameters
#
# * @arg string A string to "slugify"
#
# ## Return
#
# The slug i.e. a string with spaces, special characters, ...
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
# endregion
function string::slugify() {
    # Replace the "– dash" sign and use the minus instead "-"
    # Use sed to remove some characters then convert uppercase to lower
    sed -E 's/[~\^]+//g' |
        # Remove purely and simply some characters
        sed -E 's/://g' |
        sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+\|-+$//g' |
        sed -E 's/^-+://g' | sed -E 's/-+$//g' | tr "[:upper:]" "[:lower:]" |
        sed -e "s/^-//"
}

# region - public function string::startsWith
#
# ## Description
#
# Check if a string starts with a given suffix
#
# ## Examples
#
# ```bash
# if ! $(string::startsWith "Hello World!" "Good"); then
#    echo "The string didn't start with Good"
# fi
#
# if $(string::startsWith "Hello World!" "."); then
#    echo "The string starts with a dot"
# fi
# ```
#
# ## Parameters
#
# * @arg string The search string (f.i. `Hello World!`)
# * @arg string The suffix string (f.i. `Good`)
#
# ## Exit code
#
# * 0 If successful i.e. the suffix was found.
# * 1 The suffix wasn't found, the string didn't starts with the given pattern.
#
# endregion
function string::startsWith() {
    # If the first parameter (the string) is empty, there is nothing to do
    [[ -z $1 ]] && return 1

    [[ ${1} == ${2}* ]]
}

# region - public function string::stripAnsi
#
# ## Description
#
# Remove ANSI escape sequences from a string
#
# ## Examples
#
# ```bash
# string::stripAnsi '\e[1m\e[91mThis is bold red text\e(B\e[m.\e[92mThis is green text.\e(B\e[m'
# ```
#
# ## Parameters
#
# * @arg string The string from where ANSI sequences should be removed
#
# ## Return
#
# The string expurged from ANSI sequences
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# @https://stackoverflow.com/a/57741453/1065340
# endregion
function string::stripAnsi() {
    sed -E 's/\\e[^\\]*m//g'
}

# region - public function string::substr
#
# ## Description
#
# Extract a portion of a text
#
# ## Examples
#
# ```bash
# string::substr "Lorem ipsum dolor" 0 5  # Will return "Lorem"
# string::substr "Lorem ipsum dolor" 6 5  # Will return "ipsum"
# string::substr "Lorem ipsum dolor" 6    # Will return "ipsum dolor"
# ```
#
# ## Parameters
#
# * @arg string The string from where a portion has to be extracted
# * @arg number The start position (starting at zero)
# * @arg number Optional, the number of characters to extract (if not mentionned, till the last character)
#
# ## Return
#
# Returns the portion of string specified by the offset and length parameters.
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
# * 2 Function missing arguments.
#
# endregion
function string::substr() {
    local -r string="$1"
    local -r offset="$2"

    # By default, till the last character of the string
    local length=${#string}
    [[ $# == 3 ]] && length=$3

    echo "${string:offset:length}"
}

# region - public function string::trim
#
# ## Description
#
# Removes all leading/trailing whitespace.
# Specify the character to remove (default is a space) as the first argument
# to remove that character; f.i. a slash
#
# ## Examples
#
# ```bash
# $(echo "     Hello world     " | string::trim)"   # "Hello world"
# $(echo "/tmp/folder/" | string::trim "/")"        # "tmp/folder"
# ```
#
# ## Parameters
#
# * @arg String to trim
#
# ## Return
#
# The trimmed string (left and right)
#
# ## Exit code
#
# * 0 If successful.
#
#https://github.com/jmcantrell/bashful/blob/master/bin/bashful-utils#L219
#
# endregion
function string::trim() {
    local -r char=${1:-[:space:]}
    # shellcheck disable=SC2068
    string::ltrim $@ | string::rtrim $@
}

# region - public function string::ucfirst
#
# ## Description
#
# Write the first character in uppercase then lower for the rest
#
# ## Examples
#
# ```bash
# echo $(string::ucfirst "test")            # will write 'Test'
# echo $(string::ucfirst "developer_guide") # will write 'Developer_guide'
# ```
#
# ## Parameters
#
# * @arg string A string
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
# endregion
function string::ucfirst() {
    # shellcheck disable=SC2048,SC2086
    assert::hasArguments 1 $*

    echo "${1^}"

    return 0
}

# region - public function string::upper
#
# ## Description
#
# Make a string uppercase.
#
# ## Examples
#
# ```bash
# echo "HEllow WoRLD!" | string::upper
# #Output
# HELLO WORLD!
#
# title="$(echo "Project title" | string::upper)"
# ```
#
# ## Return
#
# The string in uppercase
#
# ## Exit code
#
# * 0 If successful.
# * 1 An error has occurred.
#
# https://github.com/jmcantrell/bashful/blob/master/bin/bashful-utils#L33
#
# endregion
function string::upper() {
    tr '[:lower:]' '[:upper:]'
}

# This script didn't contains executable code; only helpers.
(return 0 2> /dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 0 ]; then
    printf "[1;31m%s[0m\n" "ERROR, the $0 script is meant to be sourced. Try 'source $0' and use public functions."
    exit 1
fi
