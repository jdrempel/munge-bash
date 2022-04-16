#!/bin/bash

#######################################################
# munge_fpm.sh (Sides)                                #
# Author: jedimoose32                                 #
# Date: 15 Apr 2022                                   #
#######################################################

# set -e && set -x

if [[ -z "$1" ]]; then
    echo "Usage: munge_fpm.sh <sidename> [platform]"
    exit 1
fi

if [[ -n "$2" ]]; then
    MUNGE_PLATFORM=$2
else
    MUNGE_PLATFORM=PC
fi

OUTPUT_DIR=$MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/FPM/$1

LOCAL_MUNGE_LOG=$(pwd)/${MUNGE_PLATFORM}_MungeFpmLog.txt
if [[ -z $MUNGE_LOG ]]; then
    MUNGE_LOG=$LOCAL_MUNGE_LOG
    if [[ -e $LOCAL_MUNGE_LOG ]]; then
        rm -f $LOCAL_MUNGE_LOG
    fi
fi

# -------- Handle files in Sides/<sidename>/req/FPM -----------

SOURCE_SUBDIR=Sides/$1/req/FPM
SOURCE_DIR= 
if [[ -n $MUNGE_OVERRIDE_DIR ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$DIR/$SOURCE_SUBDIR"
    done
fi
SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$SOURCE_SUBDIR"

echo $MUNGE_DIR ...
echo $MUNGE_ROOT_DIR ...

mkdir -p $MUNGE_DIR
mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/FPM/$1

COMMON_MUNGE_DIR=../../Common/MUNGED/$MUNGE_PLATFORM

wine LevelPack \
    -inputfile '*.req' \
    -common $COMMON_MUNGE_DIR/core.files \
            $COMMON_MUNGE_DIR/common.files \
            $COMMON_MUNGE_DIR/ingame.files \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -inputdir $MUNGE_DIR \
    -outputdir $OUTPUT_DIR \
    2>>$MUNGE_LOG
mv -f LevelPack.log levelpack_fpm.log

