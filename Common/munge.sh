#!/bin/bash

#######################################################
# munge.sh (Common)                                   #
# Author: jedimoose32                                 #
# Date: 12 Apr 2022                                   #
#######################################################

source ../utils.sh $1 debug

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

mkdir -p MUNGED
mkdir -p $MUNGE_DIR

echo "Copying premunged files from MUNGED..."
if [[ -e ${MUNGE_ROOT_DIR}/${SOURCE_SUBDIR}/MUNGED ]]; then
    cp -ru $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/MUNGED/*.* $MUNGE_DIR
fi

echo "Copying premunged files from $MUNGE_DIR..."
if [[ -e ${MUNGE_ROOT_DIR}/${SOURCE_SUBDIR}/${MUNGE_DIR} ]]; then
    cp -ru $MUNGE_ROOT_DIR/$SOURCE_SUBDIR/$MUNGE_DIR/*.* $MUNGE_DIR
fi

odf_munge '$*.odf'
config_munge '$*.fx' && mv -f ConfigMunge.log configmunge_fx.log
config_munge '$*.combo' && mv -f ConfigMunge.log configmunge_combo.log
script_munge '$*.lua'
config_munge '$*.mcfg' && mv -f ConfigMunge.log configmunge_mcfg.log
config_munge '$*.sanm' && mv -f ConfigMunge.log configmunge_sanm.log
config_munge '$*.hud' && mv -f ConfigMunge.log configmunge_hud.log
font_munge '$*.fff'
texture_munge '$*.tga' '$*.pic'
model_munge '$effects/*.msh' '$mshs/*.msh'

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

# TODO account for these different sourcedirs in munge()
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

./merge_localize.sh $INPUT_DIR1 $INPUT_DIR2 $MUNGE_TEMP
# Perform munging
localize_munge '*.cfg'
# Clean up
rm -rf $MUNGE_TEMP

# ------------ Build LVL files -----------------

mkdir -p $MUNGE_ROOT_DIR/_LVL_$MUNGE_PLATFORM/COMMON

level_pack core.req $OUTPUT_DIR '' 'core.files'
mv -f LevelPack.log levelpack_core.log

level_pack common.req $OUTPUT_DIR 'core.files' 'common.files'
mv -f LevelPack.log levelpack_common.log

level_pack ingame.req $OUTPUT_DIR 'core.files common.files' 'ingame.files'
mv -f LevelPack.log levelpack_ingame.log

level_pack inshell.req $OUTPUT_DIR 'core.files common.files' 'inshell.files'
mv -f LevelPack.log levelpack_inshell.log

level_pack 'mission/*.req' $MUNGE_DIR 'core.files common.files ingame.files'
mv -f LevelPack.log levelpack_missions.log

level_pack mission.req $OUTPUT_DIR
mv -f LevelPack.log levelpack_mission.log

./munge_fpm.sh $MUNGE_PLATFORM

# If the munge log was created and has anything in it, view it
# TODO wc ends up with division by 0
# if [[ $MUNGE_LOG == $LOCAL_MUNGE_LOG ]]; then
#     if [[ -e $MUNGE_LOG ]]; then
#         for LOGFILE in $MUNGE_LOG; do
#             if [[ $(wc -l $LOGFILE) -gt 0 ]]; then
#                 $EDITOR $LOGFILE
#             else
#                 rm -f $LOGFILE
#             fi
#         done
#     fi
# fi

