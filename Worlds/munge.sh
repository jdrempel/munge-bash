#!/bin/bash

#######################################################
# munge.sh (Worlds)                                   #
# Author: jedimoose32                                 #
# Date: 16 Apr 2022                                   #
#######################################################

source ../utils.sh $1

MUNGE_WORLD_DIRS= 

# Check if any parameters specify platform - if they do, remove them.
# Add all others to the world munge list
PARAMS=("$*")
for PARAM in ${PARAMS[@]}; do
    if [[ "$PARAM" == PC || "$PARAM" == PS2 || "$PARAM" == XBOX ]]; then
        MUNGE_PLATFORM=$PARAM
    else
        MUNGE_WORLD_DIRS="$PARAM $MUNGE_WORLD_DIRS"
    fi
done

for PARAM in ${PARAMS[@]}; do

    case $PARAM in
    
    NOTHING* )
        exit 0
        ;;
    
    EVERYTHING* )
        MUNGE_WORLD_DIRS=*/
        ;;

    esac
done

echo "munge_world Common $MUNGE_PLATFORM"
./munge_world.sh Common $MUNGE_PLATFORM
export MUNGED_WORLDS_COMMON=1

DIRS=("$MUNGE_WORLD_DIRS")
for DIR in ${DIRS[@]}; do

    DNAME=${DIR%/}

    if [[ ! -d "$DNAME" ]]; then
        echo
        echo "Error (Invalid Parameter): $DNAME"
        echo
        exit 1
    fi

    if [[ "$DNAME" != Common ]]; then
        echo "munge_world $DNAME $MUNGE_PLATFORM"
        ./munge_world.sh $DNAME $MUNGE_PLATFORM
    fi

done

