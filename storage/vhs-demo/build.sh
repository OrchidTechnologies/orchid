#!/bin/bash

if [ -z "$STRHOME" ]
then
    echo "Set STRHOME env first"
    exit
fi

export PS1="> "
time vhs < orchid_storage1.tape
time vhs < orchid_storage2.tape
