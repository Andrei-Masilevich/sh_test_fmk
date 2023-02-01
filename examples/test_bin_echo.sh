#!/bin/bash

THIS_DIR=$(cd $(dirname ${BASH_SOURCE}) && pwd)
source $THIS_DIR/../lib_sh_test_fmk.sh

INIT_SH_TEST_FMK "Echo Tests"

START_TEST_SUITE "Echo Success"

    app=$THIS_DIR/bin_echo_ok.sh

    TEST_APP            "($(basename ${BASH_SOURCE}):${LINENO})" $app
    TEST_APP            "($(basename ${BASH_SOURCE}):${LINENO})" $app       "some command"
    TEST_APP_           "($(basename ${BASH_SOURCE}):${LINENO})" $app 0
    TEST_APP_OUTPUT     "($(basename ${BASH_SOURCE}):${LINENO})" $app       ">>" "reflection" "reflection"
    TEST_APP_OUTPUT_    "($(basename ${BASH_SOURCE}):${LINENO})" $app 0     ">>" "reflection" "reflection"
    TEST_APP_OUTPUT_FD_ "($(basename ${BASH_SOURCE}):${LINENO})" $app 0 1   ">>" "reflection" "reflection"

END_TEST_SUITE

START_TEST_SUITE "Echo Failed"

    app=$THIS_DIR/bin_echo_err.sh

    TEST_APP_           "($(basename ${BASH_SOURCE}):${LINENO})" $app 1
    TEST_APP_           "($(basename ${BASH_SOURCE}):${LINENO})" $app 1     "some command"
    TEST_APP_OUTPUT_    "($(basename ${BASH_SOURCE}):${LINENO})" $app 1     ">>" "reflection" "reflection"
    TEST_APP_OUTPUT_FD_ "($(basename ${BASH_SOURCE}):${LINENO})" $app 1 2   ">>" "reflection" "reflection"

END_TEST_SUITE
