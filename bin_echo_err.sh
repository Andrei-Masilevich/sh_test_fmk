#!/bin/bash

echo "Some output"
echo ">> $1" | perl -ne 'print STDERR'
echo "Some other output"

exit 1
