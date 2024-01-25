#!/bin/bash

if [ -z "$STRHOME" ]
then
    echo "Set STRHOME env first"
    exit
fi

export PS1="> "
time vhs < storchid1.tape
time vhs < storchid2.tape
