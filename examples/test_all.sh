#!/bin/bash

THIS_DIR=$(cd $(dirname ${BASH_SOURCE}) && pwd)
source $THIS_DIR/../lib_sh_test_fmk.sh

INIT_SH_TEST_FMK "Test Examples"

# Collecting of all available test modules
for test_file in $THIS_DIR/test_*.sh; do
    if [ "$(basename $0)" != "$(basename ${test_file})" ]; then
        . ${test_file}
    fi
done
