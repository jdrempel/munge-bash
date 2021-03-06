#!/bin/bash

#######################################################
# munge_sprites.sh (Common)                           #
# Author: jedimoose32                                 #
# Date: 12 Apr 2022                                   #
#######################################################

source ../utils.sh $1

LOCAL_MUNGE_LOG=$(pwd)/MungeSpritesLog.txt
if [[ -z $MUNGE_LOG ]]; then
    MUNGE_LOG=$LOCAL_MUNGE_LOG
    if [[ -e $LOCAL_MUNGE_LOG ]]; then
        rm -f $LOCAL_MUNGE_LOG
    fi
fi

# ----------- Handle files in Common/ ----------

SOURCE_SUBDIR=Common
SOURCE_DIR= 
if [[ -n $MUNGE_OVERRIDE_DIR ]]; then
    for DIR in $MUNGE_OVERRIDE_DIR; do
        SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$DIR/$SOURCE_SUBDIR"
    done
fi
SOURCE_DIR="$SOURCE_DIR $MUNGE_ROOT_DIR/$SOURCE_SUBDIR"

mkdir -p ../Sides/ALL/MUNGED

SIDES=(ALL CIS IMP REP)
for SIDE in "${SIDES[@]}"; do
    mkdir -p ../Sides/${SIDE}/$MUNGE_DIR
done

SPRITES=(
    all_sprite_soldiersnow
    all_sprite_pilot
    all_sprite_soldier
    all_sprite_soldierjungle
    cis_sprite_bdroid
    cis_sprite_sbdroid
    cis_sprite_droideka
    imp_sprite_officer
    imp_sprite_tiepilot
    imp_sprite_stormtroopersnow
    imp_sprite_stormtrooper
    imp_sprite_atatpilot
    imp_sprite_scout
    rep_sprite_trooper
)

MUNGE_PLATFORM=${MUNGE_PLATFORM,,}
for SPRITE in "${SPRITES[@]}"; do
    TEAM=${SPRITE::3}
    TEAM=${TEAM^^}
# TODO Why does the next line fail?
    wine ${MUNGE_PLATFORM}_TextureMunge -inputfile "sprites/$SPRITE/output/packed/*.tga" \
        $MUNGE_ARGS -sourcedir $SOURCE_DIR -outputdir ../Sides/$TEAM/$MUNGE_DIR -8bit \
        -maps 1 2>>$MUNGE_LOG
done

# TODO wc is giving a divide-by-zero error and I don't know why, so for now we'll skip this
# If the munge log was created and has anything in it, view it
# if [[ $MUNGE_LOG == $LOCAL_MUNGE_LOG ]]; then
#     if [[ -e $MUNGE_LOG ]]; then
#         for LOGFILE in $MUNGE_LOG; do
#             if [[ ! -e $LOGFILE ]]; then
#                 break
#             fi
#             if [[ $(wc -l $LOGFILE) -gt 0 ]]; then
#                 $EDITOR $MUNGE_LOG
#             else
#                 if [[ -e $MUNGE_LOG ]]; then
#                     rm -vf $MUNGE_LOG
#                 fi
#             fi
#         done
#     fi
# fi

