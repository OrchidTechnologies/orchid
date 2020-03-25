#!/bin/bash

if [ "$1" = "--version" ] ; then
    echo 'orchidd 1.bogus'
fi
echo 'Usage: orchidd [OPTION]...'
echo 'Run an Orchid Server'
echo
./orchidd --help 2>&1 | tail -n +3 | tac | tail -n +3 | tac
