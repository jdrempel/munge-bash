#!/bin/bash

#######################################################
# munge.sh (Sides)                                    #
# Author: jedimoose32                                 #
# Date: 14 Apr 2022                                   #
#######################################################

source ../utils.sh $1 debug

MUNGE_SIDE_DIRS= 

# Check if any parameters specify platform - if they do, remove them.
# Add all others to the side munge list
PARAMS=("$*")
for PARAM in ${PARAMS[@]}; do
    if [[ "$PARAM" == PC || "$PARAM" == PS2 || "$PARAM" == XBOX ]]; then
        MUNGE_PLATFORM=$PARAM
    else
        MUNGE_SIDE_DIRS="$PARAM $MUNGE_SIDE_DIRS"
    fi
done

for PARAM in ${PARAMS[@]}; do

    case $PARAM in
    
    NOTHING* )
        exit 0
        ;;
    
    EVERYTHING* )
        MUNGE_SIDE_DIRS=*/
        ;;

    GCW* | gcw* )
        MUNGE_SIDE_DIRS='ALL IMP'
        ;;

    CW* | cw* )
        MUNGE_SIDE_DIRS='CIS REP'
        ;;

    esac
done

echo "munge_side Common $MUNGE_PLATFORM"
./munge_side.sh Common $MUNGE_PLATFORM
MUNGED_SIDES_COMMON=1

DIRS=("$MUNGE_SIDE_DIRS")
for DIR in ${DIRS[@]}; do

    if [[ ! -d "$DIR" ]]; then
        echo
        echo "Error (Invalid Parameter): $DIR"
        echo
        exit 1
    fi

    if [[ "$DIR" != Common ]]; then
        echo "munge_side $DIR $MUNGE_PLATFORM"
        ./munge_side.sh $DIR $MUNGE_PLATFORM
    fi

done

