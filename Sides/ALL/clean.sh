#!/bin/bash

#######################################################
# clean.sh (SIDENAME)                                 #
# Author: jedimoose32                                 #
# Date: 15 Apr 2022                                   #
#######################################################

if [[ -z $1 ]]; then
    PLATFORMS=('PC' 'PS2' 'XBOX')
    for PLATFORM in ${PLATFORMS[@]}; do
        rm -rf MUNGED/${PLATFORM}
    done
else
    rm -rf MUNGED/$1
fi
