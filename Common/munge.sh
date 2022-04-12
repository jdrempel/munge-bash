#!/bin/bash

#######################################################
# munge.sh (Common)                                   #
# Author: jedimoose32                                 #
# Date: 12 Apr 2022                                   #
#######################################################

# Useful for debugging when enabled
set -e
set -x

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
PATH=$(pwd)/../../../ToolsFL/Bin:$PATH

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

# ----------- Handle files in Common/ -------------

SOURCE_SUBDIR=Common
SOURCE_DIR=

if [[ -z $MUNGE_OVERRIDE_DIR ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR="${SOURCE_DIR} ${MUNGE_ROOT_DIR}/${DIR}/${SOURCE_SUBDIR}"
    done
fi
SOURCE_DIR="${SOURCE_DIR} ${MUNGE_ROOT_DIR}/${SOURCE_SUBDIR}"

# ------------ Copy Common binary format data from source root Common/ ----------

if [[ ! -e MUNGED ]]; then
    mkdir MUNGED
fi

if [[ ! -e $MUNGE_DIR ]]; then
    mkdir -p $MUNGE_DIR
fi

echo "Copying premunged files from MUNGED..."
if [[ -e ${MUNGE_ROOT_DIR}/${SOURCE_SUBDIR}/MUNGED ]]; then
    cp -ru $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/MUNGED/*.* $MUNGE_DIR
fi

echo "Copying premunged files from $MUNGE_DIR..."
if [[ -e ${MUNGE_ROOT_DIR}/${SOURCE_SUBDIR}/${MUNGE_DIR} ]]; then
    cp -ru $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/$MUNGE_DIR/*.* $MUNGE_DIR
fi

odfmunge -inputfile '$*.odf' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
configmunge -inputfile '$*.fx' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
mv -f configmunge.log configmunge_fx.log
configmunge -inputfile '$*.combo' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
mv -f configmunge.log configmunge_combo.log
scriptmunge -inputfile '$*.lua' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
configmunge -inputfile '$*.mcfg' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR -hashstrings 2>>$MUNGE_LOG
mv -f configmunge.log configmunge_mcfg.log
configmunge -inputfile '$*.sanm' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
mv -f configmunge.log configmunge_sanm.log
configmunge -inputfile '$*.hud' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
mv -f configmunge.log configmunge_hud.log

fontmunge -inputfile '$*.fff' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
$MUNGE_PLATFORM_texturemunge -inputfile '$*.tga $*.pic' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
$MUNGE_PLATFORM_modelmunge -inputfile '$Effects/*.msh $MSHs/*.msh' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
