#!/bin/bash

#######################################################
# clean.sh (Sides)                                    #
# Author: jedimoose32                                 #
# Date: 15 Apr 2022                                   #
#######################################################

MUNGE_SIDE_DIRS= 

if [[ -z $MUNGE_PLATFORM ]]; then
    MUNGE_PLATFORM=PC
fi

# Check if any parameters specify platform - if they do, remove them.
# Add all others to the side clean list
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

DIRS=("$MUNGE_SIDE_DIRS")
for DIR in ${DIRS[@]}; do

    DNAME=${DIR%/}

    if [[ ! -d "$DNAME" ]]; then
        echo
        echo "Error (Invalid Parameter): $DNAME"
        echo
        exit 1
    fi

    echo "Sides/$DNAME/clean $MUNGE_PLATFORM"
    cd $DIR
    ./clean.sh $MUNGE_PLATFORM
    cd ..

done

