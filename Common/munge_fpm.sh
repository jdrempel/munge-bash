#!/bin/bash

#######################################################
# munge_fpm.sh                                        #
# Author: jedimoose32                                 #
# Date: 13 Apr 2022                                   #
#######################################################

# Useful for debugging when enabled
set -e
set -x

# Allow filename patterns which match no files to expand to a null string
shopt -s nullglob

MUNGE_ROOT_DIR=../..
if [[ -n $1 ]]; then
    MUNGE_PLATFORM=$1
fi
MUNGE_BIN_DIR=$(pwd)/${MUNGE_ROOT_DIR}/../ToolsFL/bin
export WINEPATH=$(pwd)/../../../ToolsFL/bin

MUNGE_ARGS="-checkdate -continue -platform $MUNGE_PLATFORM"
MUNGE_DIR=MUNGED/$MUNGE_PLATFORM
OUTPUT_DIR=$MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/FPM/COM

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

wine LevelPack -inputfile '*.req' -common $MUNGE_DIR/core.files $MUNGE_DIR/common.files \
    $MUNGE_DIR/ingame.files $MUNGE_ARGS -sourcedir $SOURCE_DIR -inputdir $MUNGE_DIR \
    -outputdir $OUTPUT_DIR 2>>$MUNGE_LOG
mv -f LevelPack.log levelpack_fpm.log

# If the munge log was created locally and has anything in it, view it
# TODO
