#!/bin/bash

source sh_test_fmk.sh.lib # TEST*, (ASSERT, TRACE, MESSAGE)

INIT_SH_TEST_FMK
# SH_TEST_FMK_VERBOSE=1

##############################################################
# Test some application with ability to encrypt/decrypt files

# ccrypt - for example
if [[ -z $(which ccrypt) ]]; then
    echo "External application \"ccrypt\" required (look at ccrypt-1.10-7.el7.x86_64.rpm)!"
    exit 1
fi

app=$(which ccrypt)

# Setup environment for particular test
file_tmp=$(mktemp /tmp/test_sophisticated.XXXXXX)
SH_TEST_FMK_TMP_FILES="${SH_TEST_FMK_TMP_FILES} ${file_tmp}"
psw="SECRET"
# Create random several MB size for new file
rnd=$(date +%s%N | cut -b10-19)
sz=$((1$rnd / 1024 + 1))
if (( ${rnd: -1} > 5 )); then
    # to make not odd rest from time to time
    sz=$(($sz * 2))
fi

# Create file for test
dd if=/dev/urandom count=1 bs=$sz of=$file_tmp 2>/dev/null

MESSAGE "File => $(stat $file_tmp|grep Size)"

# Show peace of file
MESSAGE $(xxd -l 16 $file_tmp)

# Calculate checksum
check_in=$(sha256sum ${file_tmp}|cut -d ' ' -f 1)

MESSAGE $check_in

TEST "Encryption Test" ${app} -K ${psw} -S .~ ${file_tmp}

encrypted_file_tmp=${file_tmp}.~
SH_TEST_FMK_TMP_FILES="${SH_TEST_FMK_TMP_FILES} ${encrypted_file_tmp}"

ASSERT "Encrypted File Test" "[ -f  ${encrypted_file_tmp} ]" "Encrypted file exists"

ASSERT "Encrypted File Test" "[ ! -f  ${file_tmp} ]" "Encrypted file renamed"

MESSAGE $(xxd -l 16 $encrypted_file_tmp)

check_out=$(sha256sum ${encrypted_file_tmp}|cut -d ' ' -f 1)

MESSAGE $check_out

ASSERT "Encrypted File Test" "[ \"$check_in\" != \"$check_out\" ]" "Encrypted file was changed"

TEST "Decryption Test" ${app} -d -K ${psw} -S .~ ${encrypted_file_tmp}

ASSERT "Decrypted File Test" "[ -f  ${file_tmp} ]" "Decrypted file exists"

ASSERT "Decrypted File Test" "[ ! -f  ${encrypted_file_tmp} ]" "Decrypted file renamed"

MESSAGE $(xxd -l 16 $file_tmp)

check_out=$(sha256sum ${file_tmp}|cut -d ' ' -f 1)

MESSAGE $check_out

ASSERT "Decrypted File Test" "[ \"$check_in\" == \"$check_out\" ]" "Encrypted file was successfully decrypted"
