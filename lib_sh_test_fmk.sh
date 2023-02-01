#!/bin/bash

# Constants
__SH_TEST_FMK_SEPARATOR_CHAR='.'
__SH_TEST_FMK_IGNORE='--'

function __get_screen_width()
{
    echo $(/usr/bin/tput cols)
}

function __print_decorated()
{
    local PREFIX=$1
    local POSTFIX=$2
    local SYMBOL=$3

    if [ ! -n "${SYMBOL}" ]; then
        SYMBOL=$__SH_TEST_FMK_SEPARATOR_CHAR
    else
        SYMBOL=${SYMBOL::1}
    fi

    local LIMIT_L=$(__get_screen_width)
    local INPUT_L=$((LIMIT_L - ${#PREFIX} - ${#POSTFIX}))

    if [ -n "$PREFIX" ]; then
        echo -n $PREFIX
    fi
    local SYMB_I=0
    for ((;SYMB_I<$INPUT_L; SYMB_I=SYMB_I+1)) do
        printf $SYMBOL
    done
    if [ -n "$POSTFIX" ]; then
        echo -n $POSTFIX
    fi    
    echo
}

function __trace()
{
    if (( SH_TEST_FMK_VERBOSE )); then
        echo ">> $@"
    fi
}

# To setup initial context. It is required for 
# API fuctions
function INIT_SH_TEST_FMK()
{
    if (( __SH_TEST_FMK_INITILIZED )); then
        __SH_TEST_FMK_MODULE_TITLE=$@

        return 0
    fi

    local TITLE=$@

    if [ ! -n "${TITLE}" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) 'Description required!"
    fi

    # Requirements
    local REQUIREMENTS=(realpath find fgrep cat file)
    for REQUIRED_APP in ${REQUIREMENTS[@]}; do
        if [ ! -n "$(which ${REQUIRED_APP})" ]; then
            ERROR "($(basename ${BASH_SOURCE}):${LINENO}) '${REQUIRED_APP}' required!"
        fi
    done

    __SH_TEST_FMK_TITLE=$@
    __SH_TEST_FMK_MODULE_TITLE=${__SH_TEST_FMK_TITLE}

    if (( SH_TEST_FMK_SUPPRESS_WELCOM == 0 )); then
        # Thx. https://patorjk.com/software/taag/#p=display&f=Whimsy&t=Sh%20Test%20FMK
        local LOGO=$(dirname ${BASH_SOURCE})/logo.txt
        if [ -f ${LOGO} ]; then
            W=0
            while read -r LOGO_LN_; do
                local W_LN=${#LOGO_LN_}
                if (( W_LN > W )); then
                    W=$W_LN
                fi
            done <${LOGO}
            if (( W > 0 && W < $(__get_screen_width) )); then
                cat ${LOGO}
            fi
        fi
        __print_decorated "STARTED" "${__SH_TEST_FMK_TITLE}"
        echo
    fi

    # Options
    # SH_TEST_FMK_VERBOSE=0
    # SH_TEST_FMK_SUPPRESS_WELCOM=0

    # Context variables

    __SH_TEST_FMK_CURR_SUITE_NAME=
    __SH_TEST_FMK_CURR_SUITE_C=0
    __SH_TEST_FMK_SUITE_C=0
    __SH_TEST_FMK_TOTAL_C=0

    SH_TEST_FMK_TMP_FILES=
    trap "__cleanup" EXIT

    __SH_TEST_FMK_INITILIZED=1
}

function __cleanup()
{
    if [ -n "${SH_TEST_FMK_TMP_FILES}" ]; then
        __trace "Clean up (FMK): ${SH_TEST_FMK_TMP_FILES}"
        rm -f ${SH_TEST_FMK_TMP_FILES}
    fi
    SH_TEST_FMK_TMP_FILES=
}

function __assert()
{
    local REGISTER_SUCCESS=$1
    shift
    local TEST_NAME_=${1}
    if eval ${2}; then
        if (( REGISTER_SUCCESS )); then
            __SH_TEST_FMK_CURR_SUITE_C=$((__SH_TEST_FMK_CURR_SUITE_C + 1))
            __SH_TEST_FMK_TOTAL_C=$((__SH_TEST_FMK_TOTAL_C + 1))

            __trace
            __print_decorated "#${__SH_TEST_FMK_SUITE_C}.${__SH_TEST_FMK_CURR_SUITE_C} ${TEST_NAME_}" "OK"
        fi
    else
        __SH_TEST_FMK_CURR_SUITE_C=$((__SH_TEST_FMK_CURR_SUITE_C + 1))

        __trace
        __print_decorated "#${__SH_TEST_FMK_SUITE_C}.${__SH_TEST_FMK_CURR_SUITE_C} ${TEST_NAME_}" "ERROR" "!"
        exit 1
    fi
}

function MESSAGE()
{
    echo "== $@"
}

function TRACE()
{
    __trace $@
}

function ERROR()
{
    __assert 0 '((0))'
}

# Checking for named expression (any bash executable condition)
#
#   TEST [Name] [Expression]
#
# Usage examples:
#
#   TEST "Check for VAL >= 123" "[ $VAL -ge 123 ]"
#   TEST "Check for NAME is empty and CONTENT is not empty string" "[[ ! -n  \"$NAME\" && -n \"$CONTENT\" ]]"
#
function TEST()
{
    if (( __SH_TEST_FMK_INITILIZED == 0 )); then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Initialization required!"
    fi

    if [ ! -n "${__SH_TEST_FMK_CURR_SUITE_NAME}" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) There is no any active test suite!"
    fi

    local TEST_NAME_=${1}
    if [ ! -n "${TEST_NAME_}" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Test name required"
    fi

    local EXPRESSION_=${2}
    if [ ! -n "${EXPRESSION_}" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Expression required"
    fi

    __assert 1 "${TEST_NAME_}" "${EXPRESSION_}"
}

# Implementation for TEST_APP_* group
function __test_app()
{
    if [ ! -n "$__SH_TEST_FMK_INITILIZED" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Initialization required!"
    fi

    if [ ! -n "$__SH_TEST_FMK_CURR_SUITE_NAME" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) There is no any active test suite!"
    fi

    if [ $# -lt 6 ]; then
        # It's supposed that it was checked and never happens
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Arguments are required!"
    fi

    local TEST_NAME_=${1}
    shift

    local APP_=${1}
    shift

    if [ ! -e ${APP_} ]; then
        APP_=$(which ${APP_})
        if [ ! -n "$APP_" ]; then
            ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application required!"
        fi
    fi

    if [ ! -f ${APP_} ]; then
        APP_=$(realpath ${APP_})
    fi
    
    if [[ ! -f ${APP_} || ! -n "$(find ${APP_} -type f -executable)" ]]; then
        local MIME_ENCODING=$(file --mime-encoding ${APP_}|cut -d ' ' -f 2)
        if [ "${MINE_ENCODING}" == 'binary' ]; then
            ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application is not executable!"
        fi
    
        local APP_INTER=
        while read -r APP_LN_; do
            APP_LN_=$(echo -n $APP_LN_)
            if [ -z ${APP_LN_} ]; then
                continue
            elif [ "${APP_LN_:0:2}" == "#!"  ]; then
                APP_INTER=${APP_LN_:2}
                break
            elif [ "${APP_LN_:0:1}" != "#"  ]; then
                break
            fi
        done <${APP_}

        if [ ! -n "${APP_INTER}" ]; then
            ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Can't find interpretation for app!"
        fi

        if [ ! -e ${APP_INTER} ]; then
            APP_INTER=$(which ${APP_INTER})
        fi

        if [ ! -f ${APP_INTER} ]; then
            APP_INTER=$(realpath ${APP_INTER})
        fi

        if [[ ! -f ${APP_INTER} || ! -n "$(find ${APP_INTER} -type f -executable)" ]]; then
            ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application is not executable!"
        fi

        APP_="${APP_INTER} ${APP_}"
    fi

    local EXPECTED_CODE=${1}
    shift
    
    if [[ ! ${EXPECTED_CODE} =~ ^[0-9]+$ ]]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Invalid expected code. Should be in range [0,255]!"
    fi
    EXPECTED_CODE=$((${EXPECTED_CODE}))

    if (( EXPECTED_CODE < 0 || EXPECTED_CODE > 255 )); then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Invalid expected code. Should be in range [0,255]!"
    fi

    local SEARCH_PATTERN=${1}
    shift

    if [ ${SEARCH_PATTERN} == ${__SH_TEST_FMK_IGNORE} ]; then
        SEARCH_PATTERN=
    fi
    
    local OUTPUT_FD=${1}
    shift

    if [[ ! ${OUTPUT_FD} =~ ^[0-2]$ ]]; then
        echo "Invalid output device. Should be in range [1,2]!"
        exit 1
    fi
    OUTPUT_FD=$(($OUTPUT_FD))

    local EXPECTED_RESULT=${1}
    shift

    if [ ${EXPECTED_RESULT} == ${__SH_TEST_FMK_IGNORE} ]; then
        EXPECTED_RESULT=
    fi

    local OUTPUT_TMP=$(mktemp /tmp/test.XXXXXX)
    SH_TEST_FMK_TMP_FILES="${SH_TEST_FMK_TMP_FILES} ${OUTPUT_TMP}"

    __trace
    __trace "STARTED ${TEST_NAME_}${__SH_TEST_FMK_SEPARATOR_CHAR}${__SH_TEST_FMK_SEPARATOR_CHAR}${__SH_TEST_FMK_SEPARATOR_CHAR}"
    __trace
    __trace "${APP_} $@"

    if [ $OUTPUT_FD == 0 ]; then
        ${APP_} $@ 1>${OUTPUT_TMP} 2>&1
    elif [ $OUTPUT_FD == 1 ]; then
        ${APP_} $@ 1>${OUTPUT_TMP} 2>/dev/null
    elif [ $OUTPUT_FD == 2 ]; then
        ${APP_} $@ 2>${OUTPUT_TMP} 1>/dev/null
    fi
    
    local ACTIAL_CODE=$?
    __trace "ACTIAL_CODE=${ACTIAL_CODE}"
    
    if (( SH_TEST_FMK_VERBOSE )); then
        if [ -f ${OUTPUT_TMP} ]; then
            while read -r OUTPUT_LN_; do
                __trace ${OUTPUT_LN_}
            done <${OUTPUT_TMP}
        fi
    fi

    __assert 0 "${TEST_NAME_}" "[ $ACTIAL_CODE -eq $EXPECTED_CODE ]"
    if [ -n "${EXPECTED_RESULT}" ]; then
        local ACTUAL_RESULT=
        local SEARCH_EXPECTED=${EXPECTED_RESULT}
        if [ "${EXPECTED_RESULT:0:1}" == '-' ]; then
            SEARCH_EXPECTED=" ${EXPECTED_RESULT}"
        fi
        __trace "fgrep "\"${EXPECTED_RESULT}\"" ${OUTPUT_TMP}"
        # Split matched results by words
        if [ -n "${SEARCH_PATTERN}" ]; then
            read -d '' -a EXPECTED_CANDIDATES < <(fgrep "${SEARCH_EXPECTED}" ${OUTPUT_TMP}|fgrep "${SEARCH_PATTERN}")
        else
            read -d '' -a EXPECTED_CANDIDATES < <(fgrep "${SEARCH_EXPECTED}" ${OUTPUT_TMP})
        fi

        __trace "EXPECTED_RESULT=${EXPECTED_RESULT}"
        for EXPECTED_CANDIDATE in ${EXPECTED_CANDIDATES[@]}; do
            __trace "EXPECTED_CANDIDATE=${EXPECTED_CANDIDATE}"
            if [ "${EXPECTED_CANDIDATE}" == "${EXPECTED_RESULT}" ]; then
                ACTUAL_RESULT=${EXPECTED_CANDIDATE}
                break
            fi
        done

        __assert 0 "${TEST_NAME_}" "[ \"${ACTUAL_RESULT}\" == \"${EXPECTED_RESULT}\" ]"
    fi
    __assert 1 "${TEST_NAME_}" '((1))'
}

# Checking for external application results (TEST_APP_* group).
# It suppresses all output and check exit code for 0 only.
#
#   TEST_APP [Test Name] [Application Path/Name] (arguments)
#
# Usage examples:
#
#   TEST_APP "Check for access" stat /foo
#   TEST_APP "Check for decryption" ansible-vault decrypt --vault-password-file /foo.key --output - /foo
#
function TEST_APP()
{
    local TEST_NAME_=${1}
    local APP_=${2}

    if [ ! -n "$TEST_NAME_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Test name required"
    fi
    if [ ! -n "$APP_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application required"
    fi

    shift; shift

    local EXPECTED_CODE=0
    local SEARCH_PATTERN=$__SH_TEST_FMK_IGNORE
    local EXPECTED_RESULT=$__SH_TEST_FMK_IGNORE
    local OUTPUT_FD=0

    __test_app "${TEST_NAME_}" "${APP_}" $EXPECTED_CODE $SEARCH_PATTERN $OUTPUT_FD $EXPECTED_RESULT $@
}

# Checking for external application results (TEST_APP_* group).
# Checking for exit code for 0 and expecting the particular string in output.
#
#   TEST_APP_OUTPUT [Test Name] [Application Path/Name] [Serch Pattern/-- (for all)] [Expected] (arguments)
#
# Usage examples:
#
#   TEST_APP_OUTPUT "Check for access" stat "Size:" 844  /foo
#   TEST_APP_OUTPUT "Check for -x option" foo_script -- "-x [prefix]" -h
#   TEST_APP_OUTPUT "Check if Docker script exists" curl -- 200 --write-out '%{http_code}' -sSL --head --output /dev/null get.docker.com
#
function TEST_APP_OUTPUT()
{
    local TEST_NAME_=${1}
    local APP_=${2}

    if [ ! -n "$TEST_NAME_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Test name required"
    fi
    if [ ! -n "$APP_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application required"
    fi

    local SEARCH_PATTERN=${3}
    local EXPECTED_RESULT=${4}

    if [ ! -n "$SEARCH_PATTERN" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Search pattern required"
    fi
    if [ ! -n "$EXPECTED_RESULT" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Expected string required"
    fi

    shift; shift; shift; shift;

    local EXPECTED_CODE=0
    local OUTPUT_FD=0

    __test_app "${TEST_NAME_}" "${APP_}" $EXPECTED_CODE "$SEARCH_PATTERN" $OUTPUT_FD "$EXPECTED_RESULT" $@
}

# TEST_APP extended by expected code
function TEST_APP_()
{
    local TEST_NAME_=${1}
    local APP_=${2}

    if [ ! -n "$TEST_NAME_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Test name required"
    fi
    if [ ! -n "$APP_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application required"
    fi

    local EXPECTED_CODE=${3}

    if [[ ! -n "$EXPECTED_CODE" || ! $EXPECTED_CODE =~ ^[0-9]+$ ]]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Expected code required"
    fi
    
    shift; shift; shift 

    local SEARCH_PATTERN=$__SH_TEST_FMK_IGNORE
    local EXPECTED_RESULT=$__SH_TEST_FMK_IGNORE
    local OUTPUT_FD=0

    __test_app "${TEST_NAME_}" "${APP_}" $EXPECTED_CODE $SEARCH_PATTERN $OUTPUT_FD $EXPECTED_RESULT $@
}

# TEST_APP_OUTPUT extended by expected code
function TEST_APP_OUTPUT_()
{
    local TEST_NAME_=${1}
    local APP_=${2}

    if [ ! -n "$TEST_NAME_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Test name required"
    fi
    if [ ! -n "$APP_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application required"
    fi

    local EXPECTED_CODE=${3}

    if [[ ! -n "$EXPECTED_CODE" || ! $EXPECTED_CODE =~ ^[0-9]+$ ]]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Expected code required"
    fi

    local SEARCH_PATTERN=${4}
    local EXPECTED_RESULT=${5}

    if [ ! -n "$SEARCH_PATTERN" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Search pattern required"
    fi
    if [ ! -n "$EXPECTED_RESULT" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Expected string required"
    fi

    shift; shift; shift; shift; shift;

    local OUTPUT_FD=0

    __test_app "${TEST_NAME_}" "${APP_}" $EXPECTED_CODE "$SEARCH_PATTERN" $OUTPUT_FD "$EXPECTED_RESULT" $@
}

# TEST_APP_OUTPUT extended by expected code and output FD
function TEST_APP_OUTPUT_FD_()
{
    local TEST_NAME_=${1}
    local APP_=${2}

    if [ ! -n "$TEST_NAME_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Test name required"
    fi
    if [ ! -n "$APP_" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Application required"
    fi

    local EXPECTED_CODE=${3}
    local OUTPUT_FD=${4}

    if [[ ! -n "$OUTPUT_FD" || ! $OUTPUT_FD =~ 1|2 ]]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Output FD (1/2) required"
    fi
    if [[ ! -n "$EXPECTED_CODE" || ! $EXPECTED_CODE =~ ^[0-9]+$ ]]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Expected code required"
    fi

    local SEARCH_PATTERN=${5}
    local EXPECTED_RESULT=${6}

    if [ ! -n "$SEARCH_PATTERN" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Search pattern required"
    fi
    if [ ! -n "$EXPECTED_RESULT" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Expected string required"
    fi

    shift; shift; shift; shift; shift; shift;

    __test_app "${TEST_NAME_}" "${APP_}" $EXPECTED_CODE "$SEARCH_PATTERN" $OUTPUT_FD "$EXPECTED_RESULT" $@
}

function __print_suite_info()
{
    local SUITE_NAME=$1
    local SUITE_INFO=$2
    
    local NAME_W=${#SUITE_NAME}
    local INFO_W=${#SUITE_INFO}
    local W=$(__get_screen_width)

    if (( INFO_W > W )); then
        local REST_W=$((INFO_W - W - 3))
        SUITE_INFO="...${SUITE_INFO:$REST_W}"
        SUITE_NAME=__SH_TEST_FMK_SEPARATOR_CHAR
    elif (( W - INFO_W < NAME_W )); then
        local REST_W=$((NAME_W - W + INFO_W - 3))
        SUITE_INFO="${SUITE_INFO::$REST_W}..."
    fi

    __print_decorated "${SUITE_NAME}" "${SUITE_INFO}"
}

function START_TEST_SUITE()
{
    if (( __SH_TEST_FMK_INITILIZED == 0 )); then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Initialization required!"
    fi

    if [ -n "$__SH_TEST_FMK_CURR_SUITE_NAME" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) There is any active test suite!"
    fi

    local SUITE_NAME=$@
    if [ ! -n "${SUITE_NAME}" ]; then
        SUITE_NAME=${__SH_TEST_FMK_MODULE_TITLE}
    elif [ "${__SH_TEST_FMK_MODULE_TITLE}" !=  "${__SH_TEST_FMK_TITLE}" ]; then
        SUITE_NAME="${__SH_TEST_FMK_MODULE_TITLE} - ${SUITE_NAME}"
    fi

    __SH_TEST_FMK_CURR_SUITE_NAME=${SUITE_NAME}
    __SH_TEST_FMK_SUITE_C=$((__SH_TEST_FMK_SUITE_C + 1))

    __print_suite_info "#$__SH_TEST_FMK_SUITE_C - ${SUITE_NAME}" $__SH_TEST_FMK_SEPARATOR_CHAR
}

function END_TEST_SUITE()
{
    if (( __SH_TEST_FMK_INITILIZED == 0 )); then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Initialization required!"
    fi

    if [ ! -n "$__SH_TEST_FMK_CURR_SUITE_NAME" ]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) There is no any active test suite!"
    fi

    local SUITE_INFO="(${__SH_TEST_FMK_CURR_SUITE_C}/${__SH_TEST_FMK_TOTAL_C})"
    __print_suite_info $__SH_TEST_FMK_SEPARATOR_CHAR "${SUITE_INFO} DONE"
    echo

    __SH_TEST_FMK_CURR_SUITE_NAME=
    __SH_TEST_FMK_CURR_SUITE_C=0
    __cleanup
}
