#!/bin/bash

#######################################################
# munge_world.sh (Worlds)                             #
# Author: jedimoose32                                 #
# Date: 16 Apr 2022                                   #
#######################################################

# Note: $2 must be given in this case, since $1 is the world name not the platform
source ../utils.sh $2 debug

# Note: 3 ..'s required here
MUNGE_ROOT_DIR=../../..
OUTPUT_DIR=$MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM

MUNGE_WORLD_FROM_SUBDIR= 
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
            MUNGE_WORLD_FROM_SUBDIR=1
            FOUND_DIR=1
            break
        fi
    done
fi

if [[ $FOUND_DIR == 0 ]]; then
    echo "Usage: munge_world <worldname> [platform]"
    echo "       Must be called from Worlds/ or Worlds/subdir with .."
    exit 1
fi

MUNGE_WORLD_STARTING_DIR=$(pwd)
[[ $MUNGE_WORLD_FROM_SUBDIR == 1 ]] && cd ..

if [[ "$1" == Common ]]; then
    export MUNGED_WORLDS_COMMON=1
elif [[ -z $MUNGED_WORLDS_COMMON ]]; then
    ./munge_world Common $2
    export MUNGED_WORLDS_COMMON=1
fi
cd $1

# Shouldn't be necessary here
# OUTPUT_DIR=$OUTPUT_DIR/WORLD

# ----- Handle files in Worlds/<worldname>/ -----

SOURCE_SUBDIR=Worlds/$1
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

model_munge '$*.msh'

texture_munge '$*.tga' '$*.pic'

terrain_munge '$*.ter'

world_munge '$*.lyr'

world_munge '$*.wld'

for WLD in $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/**/*.wld; do

    WLDFILE=${WLD##*/}
    WLDFILE=${WLDFILE%.*}

    wine ConfigMunge \
        -inputfile "\$$WLDFILE*.pth" \
        $MUNGE_ARGS \
        -sourcedir $SOURCE_DIR \
        -outputfile ${WLDFILE} \
        -outputdir $MUNGE_DIR \
        -chunkid path \
        -ext path \
        2>>$MUNGE_LOG

done

path_planning_munge '$*.pln'

config_munge 'effects/*.fx'
mv -f ConfigMunge.log configmunge_fx.log

config_munge '$*.combo'
mv -f ConfigMunge.log configmunge_combo.log

wine ConfigMunge \
    -inputfile '$*.sky' \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR \
    -chunkid sky \
    2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_sky.log

wine ConfigMunge \
    -inputfile '$*.fx' \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR \
    -chunkid fx \
    -ext envfx \
    2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_fx.log

wine ConfigMunge \
    -inputfile '$*.prp' \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR \
    -hashstrings \
    -chunkid prp \
    -ext prop \
    2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_prp.log

wine ConfigMunge \
    -inputfile '$*.bnd' \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR \
    -hashstrings \
    -chunkid bnd \
    -ext boundary \
    2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_bnd.log

wine ConfigMunge \
    -inputfile '$*.snd $*.mus $*.tsr' \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR/Sound \
    -outputdir $MUNGE_DIR \
    -hashstrings \
    2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_sound.log

wine ConfigMunge \
    -inputfile '$*.lgt' \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR \
    -hashstrings \
    -chunkid lght \
    -ext light \
    2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_light.log

wine ConfigMunge \
    -inputfile '$*.pvs' \
    $MUNGE_ARGS \
    -sourcedir $SOURCE_DIR \
    -outputdir $MUNGE_DIR \
    -chunkid PORT \
    -ext povs \
    2>>$MUNGE_LOG
mv -f ConfigMunge.log configmunge_povs.log

COMMON_MUNGE_DIR=../../Common/MUNGED/$MUNGE_PLATFORM
WORLDS_COMMON_MUNGE_DIR=../Common/MUNGED/$MUNGE_PLATFORM

if [[ "$1" != Common ]]; then
    mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/$1

    WORLDS=($MUNGE_ROOT_DIR/$SOURCE_SUBDIR/world*)
    for WORLD in ${WORLDS[@]}; do

        wine LevelPack \
            -inputfile '*.req' \
            -common "$COMMON_MUNGE_DIR/core.files
                     $COMMON_MUNGE_DIR/common.files
                     $COMMON_MUNGE_DIR/ingame.files" \
            -onlyfiles \
            -writefiles $MUNGE_DIR/MZ.files \
            $MUNGE_ARGS \
            -sourcedir $WORLD \
            -inputdir $MUNGE_DIR $WORLDS_COMMON_MUNGE_DIR \
            2>>$MUNGE_LOG

        wine LevelPack \
            -inputfile '*.mrq' \
            -common "$COMMON_MUNGE_DIR/core.files
                     $COMMON_MUNGE_DIR/common.files
                     $COMMON_MUNGE_DIR/ingame.files
                     $MUNGE_DIR/MZ.files" \
            $MUNGE_ARGS \
            -sourcedir $WORLD \
            -inputdir $MUNGE_DIR $WORLDS_COMMON_MUNGE_DIR \
            -outputdir $MUNGE_DIR \
            2>>$MUNGE_LOG

        mv -f LevelPack.log levelpack_${WORLD##*/}_mode.log

        wine LevelPack \
            -inputfile '*.req' \
            -common "$COMMON_MUNGE_DIR/core.files
                     $COMMON_MUNGE_DIR/common.files
                     $COMMON_MUNGE_DIR/ingame.files" \
            $MUNGE_ARGS \
            -sourcedir $WORLD \
            -outputdir $OUTPUT_DIR \
            -inputdir $MUNGE_DIR $WORLDS_COMMON_MUNGE_DIR \
            2>>$MUNGE_LOG

        mv -f LevelPack.log levelpack_${WORLD##*/}.log

    done

    wine LevelPack \
        -inputfile '*.req' \
        -common "$COMMON_MUNGE_DIR/core.files
                 $COMMON_MUNGE_DIR/common.files
                 $COMMON_MUNGE_DIR/ingame.files" \
        $MUNGE_ARGS \
        -sourcedir $SOURCE_DIR/sky/REQ \
        -inputdir $MUNGE_DIR $WORLDS_COMMON_MUNGE_DIR \
        -outputdir $MUNGE_DIR \
        2>>$MUNGE_LOG
    mv -f LevelPack.log levelpack_sky_variations.log

    wine LevelPack \
        -inputfile '*.req' \
        -common "$COMMON_MUNGE_DIR/core.files
                 $COMMON_MUNGE_DIR/common.files
                 $COMMON_MUNGE_DIR/ingame.files" \
        $MUNGE_ARGS \
        -sourcedir $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/sky \
        -outputdir $OUTPUT_DIR \
        -inputdir $MUNGE_DIR $WORLDS_COMMON_MUNGE_DIR \
        2>>$MUNGE_LOG
    mv -f LevelPack.log levelpack_sky.log
fi

cd $MUNGE_WORLD_STARTING_DIR


