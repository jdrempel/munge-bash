#!/bin/bash

#######################################################
# munge.sh (Common)                                   #
# Author: jedimoose32                                 #
# Date: 12 Apr 2022                                   #
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

wine OdfMunge -inputfile '$*.odf' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG

wine ConfigMunge -inputfile '$*.fx' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_fx.log

wine ConfigMunge -inputfile '$*.combo' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_combo.log

wine ScriptMunge -inputfile '$*.lua' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG

wine ConfigMunge -inputfile '$*.mcfg' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR -hashstrings 2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_mcfg.log

wine ConfigMunge -inputfile '$*.sanm' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_sanm.log

wine ConfigMunge -inputfile '$*.hud' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_hud.log

wine FontMunge -inputfile '$*.fff' $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG

wine ${MUNGE_PLATFORM}_TextureMunge -inputfile '$*.tga $*.pic' $MUNGE_ARGS -sourcedir \
    $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG

wine ${MUNGE_PLATFORM}_ModelMunge -inputfile '$effects\*.msh' '$mshs\*.msh' $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG

if [[ $MUNGE_PLATFORM != PS2 ]]; then
# TODO what does the -I mean and is it important? nothing in the helptext for the exe
    wine ${MUNGE_PLATFORM}_ShaderMunge -inputfile 'shaders/*.xml' 'shaders/*.vsfrag' \
        $SHADER_MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir $MUNGE_DIR -I \
        $SOURCE_DIR/shaders/$MUNGE_PLATFORM/ 2>>$MUNGE_LOG
fi

# -------------- Munge global.snd, global.sfx --------------

if [[ $SOUNDLOG -eq 1 ]]; then
    SOUNDOPT=-verbose
    SOUNDLOGOUT=$LOGDIR/SoundBankLog.txt
else
    SOUNDOPT=
    SOUNDLOGOUT=/dev/null
fi

wine ConfigMunge -inputfile '*.snd' '*.mus' $MUNGE_ARGS -sourcedir $SOURCE_DIR/Sound \
    -outputdir $MUNGE_DIR/ -hashstrings 2>>$MUNGE_LOG
for SFX in $MUNGE_ROOT_DIR/Common/Sound/*.sfx; do
    wine SoundFLMunge -platform ${MUNGE_PLATFORM,,} -banklistinput $SFX -bankoutput \
        $MUNGE_DIR/ -checkdate -checkid -resample $SOUNDOPT 2>>$MUNGE_LOG 1>>$SOUNDLOGOUT
done
for STM in $MUNGE_ROOT_DIR/Common/Sound/*.stm; do
    wine SoundFLMunge -platform ${MUNGE_PLATFORM,,} -banklistinput $STM -bankoutput \
        $MUNGE_DIR/ -stream -checkdate -checkid -resample $SOUNDOPT 2>>$MUNGE_LOG \
        1>>$SOUNDLOGOUT
done

./munge_sprites.sh $MUNGE_PLATFORM

# ---------------- Merge and munge localization files -----------------

INPUT_DIR1=$MUNGE_ROOT_DIR/Common/Localize/$MUNGE_PLATFORM
INPUT_DIR2=$MUNGE_ROOT_DIR/Common/Localize
MUNGE_TEMP=MungeTemp

./merge_localize.sh $INPUT_DIR1 $INPUT_DIR2 $MUNGE_TEMP  # TODO
# Perform munging
wine LocalizeMunge -inputfile '*.cfg' $MUNGE_ARGS -sourcedir $MUNGE_TEMP -outputdir \
    $MUNGE_DIR 2>>$MUNGE_LOG
# Clean up
rm -rf $MUNGE_TEMP

# ------------ Build LVL files -----------------

if [[ ! -e $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/COMMON ]]; then
    mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/COMMON
fi

wine LevelPack -inputfile core.req -writefiles $MUNGE_DIR/core.files $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR -inputdir $MUNGE_DIR -outputdir $OUTPUT_DIR \
    2>>$MUNGE_LOG
mv -f levelpack.log levelpack_core.log

wine LevelPack -inputfile common.req -writefiles $MUNGE_DIR/common.files -common \
    $MUNGE_DIR/core.files $MUNGE_ARGS -sourcedir $SOURCE_DIR -inputdir $MUNGE_DIR \
    -outputdir $OUTPUT_DIR 2>>$MUNGE_LOG
mv -f levelpack.log levelpack_common.log

wine LevelPack -inputfile ingame.req -writefiles $MUNGE_DIR/ingame.files -common \
    $MUNGE_DIR/core.files $MUNGE_DIR/common.files $MUNGE_ARGS -sourcedir $SOURCE_DIR \
    -inputdir $MUNGE_DIR -outputdir $OUTPUT_DIR 2>>$MUNGE_LOG
mv -f levelpack.log levelpack_ingame.log

wine LevelPack -inputfile inshell.req -writefiles $MUNGE_DIR/inshell.files -common \
    $MUNGE_DIR/core.files $MUNGE_DIR/common.files $MUNGE_ARGS -sourcedir $SOURCE_DIR \
    -inputdir $MUNGE_DIR -outputdir $OUTPUT_DIR 2>>$MUNGE_LOG
mv -f levelpack.log levelpack_inshell.log

wine LevelPack -inputfile mission/*.req -common $MUNGE_DIR/core.files \
    $MUNGE_DIR/common.files $MUNGE_DIR/ingame.files $MUNGE_ARGS -sourcedir $SOURCE_DIR \
    -inputdir $MUNGE_DIR -outputdir $MUNGE_DIR 2>>$MUNGE_LOG
mv -f levelpack.log levelpack_missions.log

wine LevelPack -inputfile mission.req $MUNGE_ARGS -sourcedir $SOURCE_DIR -inputdir \
    $MUNGE_DIR -outputdir $OUTPUT_DIR 2>>$MUNGE_LOG
mv -f levelpack.log levelpack_mission.log

./munge_fpm.sh $MUNGE_PLATFORM  # TODO

# If the munge log was created and has anything in it, view it
if [[ $MUNGE_LOG == $LOCAL_MUNGE_LOG ]]; then
    if [[ -e $MUNGE_LOG ]]; then
        for LOGFILE in $MUNGE_LOG; do
            if [[ $(wc -l $LOGFILE) -gt 0 ]]; then
                $EDITOR $LOGFILE
            else
                rm -f $LOGFILE
            fi
        done
    fi
fi

