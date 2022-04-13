#!/bin/bash

#######################################################
# merge_localize.sh                                   #
# Author: jedimoose32                                 #
# Date: 13 Apr 2022                                   #
#######################################################

# Useful for debugging when enabled
# set -e
# set -x

# Allow filename patterns which match no files to expand to a null string
shopt -s nullglob

if [[ $# -ne 3 ]]; then
    echo
    echo "Format: merge_localize <input-dir1> <input-dir2> <temp-dir>"
    echo
    exit 1
fi

SOURCE1_DIR=$1
SOURCE2_DIR=$2
TEMP_DIR=$3

# Copy and merge the two text files for each language

mkdir -p $TEMP_DIR

for CFG in ${SOURCE1_DIR}/*.cfg ${SOURCE2_DIR}/*.cfg; do
    echo "Merging $CFG..."
# TODO Not sure if the filename needs to be lowercased or capitalized
    CFG_LOWER=${CFG,,}
    cat $CFG >> ${TEMP_DIR}/${CFG_LOWER##*/}
done

