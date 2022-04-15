#!/bin/bash

#######################################################
# clean.sh (Shell)                                    #
# Author: jedimoose32                                 #
# Date: 14 Apr 2022                                   #
#######################################################

if [[ -z $1 ]]; then
    PLATFORMS=('PC' 'PS2' 'XBOX')
    for PLATFORM in ${PLATFORMS[@]}; do
        rm -rvf MUNGED/${PLATFORM}
    done
else
    rm -rvf MUNGED/$1
fi

