#!/bin/bash

echo "Some output"
echo ">>> blabla$1" >&2
echo ">> foo$1"
echo ">> $1"
echo "   >> $1eee" >&2
echo ">> $1 tttt" >&2 # This should be selected
echo ">> foo2$1" >&2
echo "->> $1" >&2
echo ">> $1    "
echo "Some other output" >&2

exit 1
