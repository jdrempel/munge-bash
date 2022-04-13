#!/bin/bash

#######################################################
# munge.sh (Shell)                                    #
# Author: jedimoose32                                 #
# Date: 13 Apr 2022                                   #
#######################################################

# Useful for debugging when enabled
# set -e
# set -x

# Allow filename patterns which match no files to expand to a null string
shopt -s nullglob

MUNGE_ROOT_DIR=../..

if [[ -n $1 ]]; then
    MUNGE_PLATFORM=$1
fi

if [[ -z $MUNGE_PLATFORM ]]; then
    MUNGE_PLATFORM=PC
fi

if [[ -z $MUNGE_LANGDIR ]]; then
    MUNGE_LANGDIR=ENG
fi

MUNGE_BIN_DIR=$(pwd)/${MUNGE_ROOT_DIR}/../ToolsFL/bin
export WINEPATH=$(pwd)/../../../ToolsFL/bin

MUNGE_ARGS="-checkdate -continue -platform $MUNGE_PLATFORM"
SHADER_MUNGE_ARGS="-continue -platform $MUNGE_PLATFORM"
MUNGE_DIR=MUNGED/$MUNGE_PLATFORM
OUTPUT_DIR=${MUNGE_ROOT_DIR}/_LVL_${MUNGE_PLATFORM}

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

wine ConfigMunge -inputfile '*.mcfg' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR -hashstrings 2>>$MUNGE_LOG
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

wine ConfigMunge -inputfile 'effects/*.fx' $MUNGE_ARGS -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_fx.log
wine ScriptMunge -inputfile 'scripts/*.lua' $MUNGE_ARGS -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR 2>>$MUNGE_LOG

wine ${MUNGE_PLATFORM}_TextureMunge -inputfile '$*.tga' $MUNGE_ARGS -sourcedir \
    $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
wine FontMunge -inputfile 'fonts/*.fff' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG
wine ${MUNGE_PLATFORM}_ModelMunge -inputfile '$*.msh' $MUNGE_ARGS -sourcedir \
    $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
if [[ $MUNGE_PLATFORM == PS2 ]]; then
    wine BinMunge -inputfile 'ps2bin/*.ps2bin' $MUNGE_ARGS -sourcedir $SOURCE_DIR \
        -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
fi

# -------- Build LVL Files ---------

wine LevelPack -inputfile shell.req -common ../Common/MUNGED/$MUNGE_PLATFORM/core.files \
    ../Common/MUNGED/$MUNGE_PLATFORM/common.files $MUNGE_ARGS -sourcedir $SOURCE_DIR \
    -inputdir $MUNGE_DIR -outputdir $OUTPUT_DIR 2>>$MUNGE_LOG

echo $?
if [[ $MUNGE_PLATFORM == PS2 ]]; then
    wine LevelPack -inputfile shellps2.req -common \
        ../Common/MUNGED/$MUNGE_PLATFORM/core.files $MUNGE_ARGS -sourcedir $SOURCE_DIR \
        -inputdir $MUNGE_DIR -outputdir $OUTPUTDIR 2>>$MUNGE_LOG
fi

        
