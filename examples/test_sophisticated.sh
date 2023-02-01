#!/bin/bash

THIS_DIR=$(cd $(dirname ${BASH_SOURCE}) && pwd)
source $THIS_DIR/../lib_sh_test_fmk.sh

function __create_data_file()
{
    local FILE_PATH=$1
    if  [[ -z $FILE_PATH || ! -f $FILE_PATH ]]; then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Invalid arguments"
    fi

    local SZ_FACTOR=$2
    if (($SZ_FACTOR < 1)); then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Invalid arguments"
    fi

    declare -n FILE_PATH__=$3

    SH_TEST_FMK_TMP_FILES="${SH_TEST_FMK_TMP_FILES} ${FILE_PATH}"

    # Create random several MB size for new file
    local RND=$(date +%s%N | cut -b10-19)
    local SZ=$((1$RND / 1024 / $SZ_FACTOR + 1))
    if (( ${RND: -1} > 5 )); then
        # to make not odd rest from time to time
        SZ=$(($SZ * 2))
    fi

    if (($SZ < 1)); then
        ERROR "($(basename ${BASH_SOURCE}):${LINENO}) Invalid arguments"
    fi

    # Create file for test
    dd if=/dev/urandom count=1 bs=$SZ of=$FILE_PATH 2>/dev/null

    MESSAGE "File => $(stat $FILE_PATH|grep Size)"

    # Show peace of file
    MESSAGE $(xxd -l 16 $FILE_PATH)   

    FILE_PATH__=${FILE_PATH} 
}

function __create_secret_file()
{
    local TMP_FILE__=$(mktemp /tmp/$(basename $0).XXXXXX)
   __create_data_file ${TMP_FILE__} 66 $@
}

function __positive_encryption_case()
{

START_TEST_SUITE "Positive Encryption Case"

    local PASSPHRASE=secret

    __create_secret_file SECRET_FILE

    TEST "Secret file exists" "[ -f  ${SECRET_FILE} ]"

    local CHECKSUM_IN=$(sha256sum ${SECRET_FILE}|cut -d ' ' -f 1)

    MESSAGE $CHECKSUM_IN

    TEST_APP "Encryption Test" ${CRYPT_APP} -K ${PASSPHRASE} -S .~ ${SECRET_FILE}

    local ENCRYPTED_SECRET_FILE=${SECRET_FILE}.~
    SH_TEST_FMK_TMP_FILES="${SH_TEST_FMK_TMP_FILES} ${ENCRYPTED_SECRET_FILE}"

    TEST "Encrypted file exists" "[ -f  ${ENCRYPTED_SECRET_FILE} ]"

    TEST "Encrypted file renamed" "[ ! -f  ${SECRET_FILE} ]" "Encrypted file renamed"

    local CHECKSUM_OUT=$(sha256sum ${ENCRYPTED_SECRET_FILE}|cut -d ' ' -f 1)

    MESSAGE $CHECKSUM_OUT

    TEST "Encrypted file is different" "[ \"$CHECKSUM_IN\" != \"$CHECKSUM_OUT\" ]"

    TEST_APP "Decryption Test" ${CRYPT_APP} -d -K ${PASSPHRASE} -S .~ ${ENCRYPTED_SECRET_FILE}

    TEST "Decrypted file exists" "[ -f  ${SECRET_FILE} ]"

    TEST  "Decrypted file renamed" "[ ! -f  ${ENCRYPTED_SECRET_FILE} ]"

    CHECKSUM_OUT=$(sha256sum ${SECRET_FILE}|cut -d ' ' -f 1)

    MESSAGE $CHECKSUM_OUT

    TEST "Encrypted file was successfully decrypted" "[ \"$CHECKSUM_IN\" == \"$CHECKSUM_OUT\" ]"

END_TEST_SUITE

}

function __negative_decryption_case()
{

START_TEST_SUITE "Negative Decryption Case"

    local PASSPHRASE=valid-secret

    __create_secret_file SECRET_FILE

    TEST "Secret file exists" "[ -f  ${SECRET_FILE} ]"

    local CHECKSUM_IN=$(sha256sum ${SECRET_FILE}|cut -d ' ' -f 1)

    MESSAGE $CHECKSUM_IN

    TEST_APP "Encryption Test" ${CRYPT_APP} -K ${PASSPHRASE} -S .~ ${SECRET_FILE}

    local ENCRYPTED_SECRET_FILE=${SECRET_FILE}.~
    SH_TEST_FMK_TMP_FILES="${SH_TEST_FMK_TMP_FILES} ${ENCRYPTED_SECRET_FILE}"

    TEST "Encrypted file exists" "[ -f  ${ENCRYPTED_SECRET_FILE} ]"

    TEST "Encrypted file renamed" "[ ! -f  ${SECRET_FILE} ]" "Encrypted file renamed"

    local CHECKSUM_OUT=$(sha256sum ${ENCRYPTED_SECRET_FILE}|cut -d ' ' -f 1)

    MESSAGE $CHECKSUM_OUT

    TEST "Encrypted file is different" "[ \"$CHECKSUM_IN\" != \"$CHECKSUM_OUT\" ]"

    # Utility returns 4 on fail decryption
    TEST_APP_ "Decryption Fail Test. Invalid passphrase" ${CRYPT_APP} 4 -d -K "invalid" -S .~ ${ENCRYPTED_SECRET_FILE}

    TEST "Encrypted file exists" "[ -f  ${ENCRYPTED_SECRET_FILE} ]"

    TEST "Decrypted file doesn't exists" "[ ! -f  ${SECRET_FILE} ]"

    local EMPTY_FILE=$(mktemp /tmp/$(basename $0).XXXXXX)

    TEST_APP_ "Decryption Fail Test. Empty file" ${CRYPT_APP} 4 -d -K "invalid" -S .~ ${EMPTY_FILE}

    __create_secret_file INVALID_FILE

    TEST_APP_ "Decryption Fail Test. Invalid file" ${CRYPT_APP} 4 -d -K ${PASSPHRASE} -S .~ ${INVALID_FILE}

END_TEST_SUITE

}

##############################################################
# Test some application with ability to encrypt/decrypt files
# ccrypt - for example

INIT_SH_TEST_FMK "CCrypt Tests"
CRYPT_APP=ccrypt

if [ -z $(which $CRYPT_APP) ]; then
    ERROR "External application \"ccrypt\" required (https://ccrypt.sourceforge.net/#downloading)!"
fi

__positive_encryption_case
__negative_decryption_case
