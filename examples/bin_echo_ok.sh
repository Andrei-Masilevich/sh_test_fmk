#!/bin/bash

echo "Some output"
echo ">>> blabla$1"
echo ">> foo$1"
echo "   >> $1eee"
echo ">> $1 tttt" # This should be selected
echo ">> foo2$1"
echo "->> $1"
echo ">> $1    "
echo "Some other output"

exit 0
