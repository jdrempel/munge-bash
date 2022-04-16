#!/bin/bash

#######################################################
# munge.sh (Shell)                                    #
# Author: jedimoose32                                 #
# Date: 13 Apr 2022                                   #
#######################################################

source ../utils.sh $1

LOCAL_MUNGE_LOG=$(pwd)/${MUNGE_PLATFORM}_MungeLog.txt
if [[ -z $MUNGE_LOG ]]; then
    MUNGE_LOG=$LOCAL_MUNGE_LOG
    if [[ -e $LOCAL_MUNGE_LOG ]]; then
        rm -vf $LOCAL_MUNGE_LOG
    fi
fi

mkdir -p $MUNGE_DIR
mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/Shell
mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/Movies

# ---------- Handle files in Shell/Movies

SOURCE_SUBDIR=Shell/movies
SOURCE_DIR= 
if [[ -n "$MUNGE_OVERRIDE_DIR" ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$DIR/$SOURCE_SUBDIR"
    done
fi
SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$SOURCE_SUBDIR"

config_munge '*.mcfg'
mv -f ConfigMunge.log configmunge_mcfg.log

for MLST in $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/$MUNGE_PLATFORM/*.mlst; do
    MNAME=${MLST##*/}
    wine MovieMunge -input $MLST -output \
        $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/Movies/${MNAME%.mlst}.mvs -checkdate \
    2>>$MUNGE_LOG
done

# ---------- Handle files in Shell/Sound ----------
# Obsolete, this is just here for completeness I guess

SOURCE_SUBDIR=Shell/Sound
SOURCE_DIR= 
if [[ -n "$MUNGE_OVERRIDE_DIR" ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$DIR/$SOURCE_SUBDIR"
    done
fi
SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$SOURCE_SUBDIR"

# ----------- Handle files in Shell/ ------------

SOURCE_SUBDIR=Shell
SOURCE_DIR= 
if [[ -n "$MUNGE_OVERRIDE_DIR" ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$DIR/$SOURCE_SUBDIR"
    done
fi
SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$SOURCE_SUBDIR"

config_munge 'effects/*.fx'
mv -f ConfigMunge.log configmunge_fx.log

script_munge 'scripts/*.lua'
texture_munge '$*.tga'
font_munge 'fonts/*.fff'
model_munge '$*.msh'

if [[ $MUNGE_PLATFORM == PS2 ]]; then
    bin_munge 'ps2bin/*.ps2bin'
fi

# -------- Build LVL Files ---------

level_pack shell.req $OUTPUT_DIR \
    "../Common/MUNGED/$MUNGE_PLATFORM/core.files
     ../Common/MUNGED/$MUNGE_PLATFORM/common.files" \

if [[ $MUNGE_PLATFORM == PS2 ]]; then
    level_pack shellps2.req $OUTPUTDIR \
        "../Common/MUNGED/$MUNGE_PLATFORM/core.files"
fi

        
