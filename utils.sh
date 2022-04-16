#!/bin/bash

#######################################################
# utils.sh                                            #
# Author: jedimoose32                                 #
# Date: 13 Apr 2022                                   #
#######################################################

# --------- BOILERPLATE ----------

# Useful for debugging when enabled
# set -e makes the program exit immediately if there is a non-zero return
# set -x causes the program to print its output as it is executed
[[ $2 == debug ]] && set -e && set -x

# Allow filename patterns which match no files to expand to a null string
shopt -s nullglob

export MUNGE_ROOT_DIR=../..

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

export MUNGE_ARGS="-checkdate -continue -platform $MUNGE_PLATFORM"
export SHADER_MUNGE_ARGS="-continue -platform $MUNGE_PLATFORM"
export MUNGE_DIR=MUNGED/$MUNGE_PLATFORM
export OUTPUT_DIR=${MUNGE_ROOT_DIR}/_LVL_${MUNGE_PLATFORM}

LOCAL_MUNGE_LOG=$(pwd)/${MUNGE_PLATFORM}_MungeLog.txt
if [[ -z $MUNGE_LOG ]]; then
    MUNGE_LOG=$LOCAL_MUNGE_LOG
    if [[ -e $LOCAL_MUNGE_LOG ]]; then
        rm -vf $LOCAL_MUNGE_LOG
    fi
fi

# ----- END BOILERPLATE ------

# ---------- MUNGERS -----------

# Performs a generic munge operation. Positional args are:
#   $1: munger binary prefix (e.g. Config or Odf)
#   $2,3: input files'
#   $4: source subdirectory
munge () {

    ARGS=("$@")

    HASH=
    [[ $1 =~ Movie || "$@" =~ mcfg ]] && HASH=-hashstrings

    SUBSOURCE_DIR="${ARGS[3]}"

    wine ${1}Munge \
        -inputfile "${ARGS[@]:1:2}" \
        $MUNGE_ARGS \
        -sourcedir $SOURCE_DIR/$SUBSOURCE_DIR \
        -outputdir $MUNGE_DIR \
        $HASH \
        2>>$MUNGE_LOG

}

bin_munge () {
    munge Bin "$@"
}

config_munge () {
    munge Config "$@"
}

font_munge () {
    munge Font "$@"
}

localize_munge () {
    munge Localize "$@"
}

movie_munge () {
    munge Movie "$@"
}

odf_munge () {
    munge Odf "$@"
}

path_munge () {
    munge Path "$@"
}

path_planning_munge () {
    munge PathPlanning "$@"
}

model_munge () {
    munge ${MUNGE_PLATFORM,,}_Model "$@"
}

shader_munge () {
    munge ${MUNGE_PLATFORM,,}_Shader "$@"
}

texture_munge () {
    munge ${MUNGE_PLATFORM,,}_Texture "$@"
}

script_munge () {
    munge Script "$@"
}

shadow_munge () {
    munge Shadow "$@"
}

soundfl_munge () {
    munge SoundFL "$@"
}

sprite_munge () {
    munge Sprite "$@"
}

terrain_munge () {
    munge Terrain "$@"
}

world_munge () {
    munge World "$@"
}

# ------------ LEVEL PACKING ------------

# Invokes LevelPack.exe. Positional args are:
#   $1: Input file(s)
#   $2: Output directory
#   [$3]: Arguments for -common
#   [$4]: Arguments for -writefiles'
#
level_pack () {

    COMMON= 
    if [[ -n $3 ]]; then
        COMMON=-common
        COMARRAY=($3)
        for COMFILE in ${COMARRAY[@]}; do
            if [[ "$COMFILE" =~ ^\.\..* ]]; then
                COMMON="$COMMON $COMFILE"
            else
                COMMON="$COMMON $MUNGE_DIR/$COMFILE"
            fi
        done
    fi

    WRITEFILES= 
    if [[ -n $4 ]]; then
        WRITEFILES=-writefiles
        WRFARRAY=($4)
        for WRFILE in ${WRFARRAY[@]}; do
            WRITEFILES="$WRITEFILES $MUNGE_DIR/$WRFILE"
        done
    fi

    wine LevelPack \
        -inputfile "$1" \
        $WRITEFILES \
        $COMMON \
        $MUNGE_ARGS \
        -sourcedir $SOURCE_DIR \
        -inputdir $MUNGE_DIR \
        -outputdir $2 \
        # -debug \
        2>>$MUNGE_LOG
}

