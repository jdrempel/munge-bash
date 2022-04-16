#!/bin/bash

#######################################################
# munge_side.sh (Sides)                               #
# Author: jedimoose32                                 #
# Date: 14 Apr 2022                                   #
#######################################################

# Note: $2 must be given in this case, since $1 is the side name not the platform
source ../utils.sh $2 debug

# Note: 3 ..'s required here
MUNGE_ROOT_DIR=../../..
OUTPUT_DIR=$MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM

MUNGE_SIDE_FROM_SUBDIR= 
FOUND_DIR=0
PARAMS=("$1")
for PARAM in ${PARAMS[@]}; do
    if [[ -d $PARAM ]]; then
        FOUND_DIR=1
        break
    fi
done

UP_PARAMS=()
for PARAM in ${PARAMS[@]}; do
    UP_PARAMS+=../$PARAM
done

if [[ $FOUND_DIR == 0 ]]; then
    for PARAM in ${UP_PARAMS[@]}; do
        if [[ -d $PARAM ]]; then
            MUNGE_SIDE_FROM_SUBDIR=1
            FOUND_DIR=1
            break
        fi
    done
fi

if [[ $FOUND_DIR == 0 ]]; then
    echo "Usage: munge_side <sidename> [platform]"
    echo "       Must be called from Sides/ or Sides/subdir with .."
    exit 1
fi

MUNGE_SIDE_STARTING_DIR=$(pwd)
[[ $MUNGE_SIDE_FROM_SUBDIR == 1 ]] && cd ..

if [[ "$1" == Common ]]; then
    export MUNGED_SIDES_COMMON=1
elif [[ -z $MUNGED_SIDES_COMMON ]]; then
    ./munge_side Common $2
    export MUNGED_SIDES_COMMON=1
fi
cd $1

OUTPUT_DIR=$OUTPUT_DIR/SIDE

SOURCE_SUBDIR=Sides/$1
SOURCE_DIR= 
if [[ -n "$MUNGE_OVERRIDE_DIR" ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR=$SOURCE_DIR $MUNGE_ROOT_DIR/$DIR/$SOURCE_SUBDIR
    done
fi
SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$SOURCE_SUBDIR"

mkdir -p $MUNGE_DIR

if [[ -e $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/MUNGED ]]; then
    COUNT=$(ls -1b $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/MUNGED | wc -l)
    [[ $COUNT -gt 1 ]] && cp -ru $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/MUNGED/*.* $MUNGE_DIR
fi
if [[ -e $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/$MUNGE_DIR ]]; then
    COUNT=$(ls -1b $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/$MUNGE_DIR | wc -l)
    [[ $COUNT -gt 1 ]] && cp -ru $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/$MUNGE_DIR/*.* $MUNGE_DIR
fi

odf_munge '$*.odf'

config_munge 'effects/*.fx'
mv -f ConfigMunge.log configmunge_fx.log

config_munge '$*.combo'
mv -f ConfigMunge.log configmunge_combo.log

model_munge '$*.msh'

texture_munge '$*.tga' '$*.pic'

config_munge '*.snd' '*.mus' 'Sound'
mv -f ConfigMunge.log configmunge_sound.log

COMMON_MUNGE_DIR=../../Common/MUNGED/$MUNGE_PLATFORM
SIDES_COMMON_MUNGE_DIR=../Common/MUNGED/$MUNGE_PLATFORM

wine LevelPack \
    -inputfile 'REQ/*.req' \
    -common $COMMON_MUNGE_DIR/core.files \
            $COMMON_MUNGE_DIR/common.files \
            $COMMON_MUNGE_DIR/ingame.files \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -inputdir $MUNGE_DIR $SIDES_COMMON_MUNGE_DIR \
    -outputdir $MUNGE_DIR \
    2>>$MUNGE_LOG
mv -f LevelPack.log levelpack_units.log

if [[ "$1" != Common ]]; then
    mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/SIDE

    wine LevelPack \
        -inputfile '*.req' \
        $MUNGE_ARGS \
        -sourcedir $SOURCE_DIR \
        -inputdir $MUNGE_DIR $SIDES_COMMON_MUNGE_DIR \
        -outputdir $OUTPUT_DIR \
        2>>$MUNGE_LOG
    mv -f LevelPack.log levelpack_side.log
    ./../munge_fpm.sh $1
fi

cd $MUNGE_SIDE_STARTING_DIR

