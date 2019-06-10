#!/bin/bash

if [ "$1" = "--version" ] ; then
    echo 'orchid 1.bogus'
fi
echo 'Usage: orchid [OPTION]...'
echo 'Run an Orchid Server'
echo
./orchid-server --help 2>&1 | tail -n +3 | tac | tail -n +3 | tac
