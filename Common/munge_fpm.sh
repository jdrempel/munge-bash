#!/bin/bash

#######################################################
# munge_fpm.sh (Common)                               #
# Author: jedimoose32                                 #
# Date: 13 Apr 2022                                   #
#######################################################

source ../utils.sh $1
OUTPUT_DIR=${OUTPUT_DIR}/FPM/COM

LOCAL_MUNGE_LOG=$(pwd)/MungeFpmLog.txt
if [[ -z "$MUNGE_LOG" ]]; then
    MUNGE_LOG=$LOCAL_MUNGE_LOG
    if [[ -e "$LOCAL_MUNGE_LOG" ]]; then
        rm -f $LOCAL_MUNGE_LOG
    fi
fi

# ------------- Handle files in Common/req/FPM/ ---------------

SOURCE_SUBDIR=Common/req/FPM
SOURCE_DIR= 
if [[ -n "$MUNGE_OVERRIDE_DIR" ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$DIR/$SOURCE_SUBDIR"
    done
fi
SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$SOURCE_SUBDIR"

mkdir -p $MUNGE_DIR
mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/FPM/COM

level_pack '*.req' $OUTPUT_DIR 'core.files common.files ingame.files'
mv -f LevelPack.log levelpack_fpm.log

# If the munge log was created locally and has anything in it, view it
# TODO
