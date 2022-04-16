#!/bin/bash

#######################################################
# clean.sh (Worlds)                                   #
# Author: jedimoose32                                 #
# Date: 16 Apr 2022                                   #
#######################################################

MUNGE_WORLD_DIRS=

if [[ -z $MUNGE_PLATFORM ]]; then
    MUNGE_PLATFORM=PC
fi

# Check if any parameters specify platform - if they do, remove them.
# Add all others to the world clean list
PARAMS=("$*")
for PARAM in ${PARAMS[@]}; do
    if [[ "$PARAM" == PC || "$PARAM" == PS2 || "$PARAM" == XBOX ]]; then
        MUNGE_PLATFORM=$PARAM
    else
        MUNGE_WORLD_DIRS="$PARAM $MUNGE_SIDE_DIRS"
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

DIRS=("$MUNGE_WORLD_DIRS")
for DIR in ${DIRS[@]}; do

    DNAME=${DIR%/}

    if [[ ! -d "$DNAME" ]]; then
        echo
        echo "Error (Invalid Parameter): $DNAME"
        echo
        exit 1
    fi

    echo "Worlds/$DNAME/clean $MUNGE_PLATFORM"
    cd $DIR
    ./clean.sh $MUNGE_PLATFORM
    cd ..

done

