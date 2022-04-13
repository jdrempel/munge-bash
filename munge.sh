#!/bin/bash

#######################################################
# munge.sh (root)                                     #
# Author: jedimoose32                                 #
# Date: 12 Apr 2022                                   #
#######################################################

# Useful for debugging when enabled
# set -e
# set -x

print_help_and_exit() {
    echo
    echo "Note: A dashed option, e.g. --platform can also be written in"
    echo "      the form of a Windows shell argument, e.g. /PLATFORM."
    echo
    echo "Usage: munge [--platform [PC|PS2|XBOX]]"
    echo "             [--language [ENGLISH|UK|FRENCH|GERMAN|JAPANESE|ITALIAN|SPANISH]]"
    echo "             [--world [EVERYTHING|NOTHING|<world1> <world2> ...]]"
    echo "             [--side [EVERYTHING|NOTHING|<side1> <side2> ...]]"
    echo "             [--load] [--sound] [--common] [--shell] [--movies] [--localize]"
    echo
    echo "Options:"
    echo "  If no parameters are specified then everything is munged."
    echo "  --platform    The platform to munge the data for (default PC)"
    echo "  --language    The language used for building (default ENGLISH)"
    echo "  --world       Selectively munges world data. If EVERYTHING or NOTHING is"
    echo "                  specified all world data is munged or not, respectively"
    echo "  --side        Selectively munges side data. If EVERYTHING or NOTHING is"
    echo "                  specified all side data is munged or not, respectively"
    echo "  --load        If specified munges loading screen data"
    echo "  --sound       If specified munges sound data"
    echo "  --common      If specified munges common data"
    echo "  --shell       If specified munges shell data"
    echo "  --movies      If specified munges movie data"
    echo "  --localize    If specified munges localization data"
    echo "  --no-xbox-copy If specified skips the data copy to the xbox"
    echo

    exit $1
}

# -------------- SETUP THE SCRIPT VARIABLES ---------------

WORLD_PARAMETERS=
SIDE_PARAMETERS=
MUNGE_LOAD=0
MUNGE_SIDE=0
MUNGE_COMMON=0
MUNGE_SHELL=0
MUNGE_MOVIES=0
MUNGE_LOCALIZE=0
MUNGE_SOUND=0
MUNGE_PLATFORM=PC
MUNGE_LANGVERSION=ENGLISH
MUNGE_LANGDIR=ENG
MUNGE_ALL=1
DISPLAY_MESSAGES=1
XBOX_COPY=1

# -------------- PROCESS COMMAND LINE ARGS ------------------

if [[ $# -le 1 ]]; then
    print_help_and_exit 0
fi

while [[ -n $1 ]]; do

    case $1 in

    /HELP | --help | -h )
        
        print_help_and_exit 0
        ;;

    /WORLD | --world )

        while true; do
            shift
            [[ -n $1 && ! $1 =~ ^(/|--).* ]] || break
            WORLD_PARAMETERS="$1 $WORLD_PARAMETERS"
            MUNGE_ALL=0
        done
        ;;

    /SIDE | --side )
        
        while true; do
            shift
            [[ -n $1 && ! $1 =~ ^(/|--).* ]] || break
            SIDE_PARAMETERS="$1 $SIDE_PARAMETERS"
            MUNGE_ALL=0
        done
        ;;

    /LOAD | --load )

        MUNGE_LOAD=1
        MUNGE_ALL=0
        shift
        ;;

    /NOMESSAGES | --quiet )

        DISPLAY_MESSAGES=0
        shift
        ;;

    /SOUND | --sound )
        
        MUNGE_SOUND=1
        MUNGE_ALL=0
        MUNGESTREAMS=1

        while true; do
            shift
            [[ -n $1 && ! $1 =~ ^(/|--).* ]] || break
            if [[ $1 == NOSTREAMS ]]; then 
                MUNGESTREAMS=0;
            fi
            SOUNDLVL="$1 $SOUNDLVL"
            MUNGE_ALL=0
        done
        ;;

    /COMMON | --common )
        
        MUNGE_COMMON=1
        MUNGE_ALL=0
        shift
        ;;

    /SHELL | --shell )
        
        MUNGE_SHELL=1
        MUNGE_ALL=0
        shift
        ;;

    /MOVIES | --movies )
        
        MUNGE_MOVIES=1
        MUNGE_ALL=0
        shift
        ;;

    /LOCALIZE | --localize )
        
        MUNGE_LOCALIZE=1
        MUNGE_ALL=0
        shift
        ;;

    /NOXBOXCOPY | --no-xbox-copy )

        XBOX_COPY=0
        shift
        ;;

    /PLATFORM | --platform )
        
        shift
        case $1 in
            PC) MUNGE_PLATFORM=PC ;;
            PS2) MUNGE_PLATFORM=PS2 ;;
            XBOX) MUNGE_PLATFORM=XBOX ;;
            *) echo "Error (Invalid Platform Parameter): $1"
               print_help_and_exit 1
               ;;
        esac
        shift
        ;;

    /LANGUAGE | --language )
        
        shift
        case $1 in
            ENGLISH)
                MUNGE_PLATFORM=ENGLISH
                MUNGE_LANGDIR=ENG
                ;;
            UK)
                MUNGE_LANGDIR=UK_
                MUNGE_LANGVERSION=UK_
                ;;
            FRENCH)
                MUNGE_LANGDIR=FRENCH
                MUNGE_LANGVERSION=FRENCH
                ;;
            GERMAN)
                MUNGE_LANGDIR=GERMAN
                MUNGE_LANGVERSION=GERMAN
                ;;
            JAPANESE)
                MUNGE_LANGDIR=JAPANESE
                MUNGE_LANGVERSION=JAPANESE
                ;;
            ITALIAN)
                MUNGE_LANGDIR=ITALIAN
                MUNGE_LANGVERSION=ITALIAN
                ;;
            SPANISH)
                MUNGE_LANGDIR=SPANISH
                MUNGE_LANGVERSION=SPANISH
                ;;
            *)
                echo "Error (Invalid Language Parameter): $1"
                print_help_and_exit 1
                ;;
        esac
        shift
        ;;

    * )

        echo "Error (Invalid Parameter): $1"
        print_help_and_exit 1
        ;;

    esac

done

# ----------- POST PROCESS SOME VARIABLES -------------

if [[ $MUNGE_LANGVERSION == ENGLISH ]]; then
    MUNGE_OVERRIDE_DIR=
else
    MUNGE_OVERRIDE_DIR=${MUNGE_PLATFORM}_${MUNGE_LANGDIR}
fi

if [[ -z $WORLD_PARAMETERS ]]; then
    WORLD_PARAMETERS=NOTHING
else
    for PARAM in $WORLD_PARAMETERS; do
        if [[ $PARAM == NOTHING ]]; then
            WORLD_PARAMETERS=NOTHING
        fi
    done
fi

if [[ -z $SIZE_PARAMETERS ]]; then
    SIDE_PARAMETERS=NOTHING
else
    for PARAM in $SIDE_PARAMETERS; do
        if [[ $PARAM == NOTHING ]]; then
            SIDE_PARAMETERS=NOTHING
        fi
    done
fi

if [[ $MUNGE_ALL -eq 1 ]]; then
	WORLD_PARAMETERS=EVERYTHING
	SIDE_PARAMETERS=EVERYTHING
	MUNGE_LOAD=1
	MUNGE_SIDE=1
	MUNGE_COMMON=1
	MUNGE_SHELL=1
	MUNGE_MOVIES=1
	MUNGE_LOCALIZE=1
	MUNGE_SOUND=1
fi

# -------------- SETUP LOGGING ---------------

MUNGE_LOG=$(pwd)/${MUNGE_PLATFORM}_MungeLog.txt
if [[ -e $MUNGE_LOG ]]; then
    rm -vf $MUNGE_LOG
fi

MUNGE_BIN_DIR=$(pwd)/../../ToolsFL/bin

# ---------------- MUNGE COMMON ---------------

if [[ $MUNGE_COMMON -eq 1 ]]; then
    echo "Common/munge $MUNGE_PLATFORM"
    cd Common
    ./munge.sh $MUNGE_PLATFORM
    cd ..
fi

# ---------------- MUNGE SHELL ---------------

if [[ $MUNGE_SHELL -eq 1 ]]; then
    echo "Shell/munge $MUNGE_PLATFORM"
    cd Shell
    ./munge.sh $MUNGE_PLATFORM
    cd ..
fi

# ---------------- MUNGE LOAD ---------------

if [[ $MUNGE_LOAD -eq 1 ]]; then
    echo "Load/munge $MUNGE_PLATFORM"
    cd Load
    ./munge.sh $MUNGE_PLATFORM
    cd ..
fi

# ---------------- MUNGE SIDES ---------------

if [[ $SIDE_PARAMETERS != NOTHING ]]; then
    echo "Sides/munge $MUNGE_PLATFORM"
    cd Sides
    ./munge.sh $MUNGE_PLATFORM $SIDE_PARAMETERS
    cd ..
fi

# ---------------- MUNGE WORLDS ---------------

if [[ $WORLD_PARAMETERS != NOTHING ]]; then
    echo "Worlds/munge $MUNGE_PLATFORM"
    cd Worlds
    ./munge.sh $MUNGE_PLATFORM $WORLD_PARAMETERS
    cd ..
fi

# ---------------- MUNGE SOUNDS ---------------

if [[ $MUNGE_SOUND -eq 1 ]]; then
    echo "Sound/munge $MUNGE_PLATFORM"
    cd Sound
    ./munge.sh $MUNGE_PLATFORM
    cd ..
fi

if [[ $MUNGE_PLATFORM == XBOX ]]; then
    if [[ XBOX_COPY -eq 1 ]]; then
        echo "Copying files to XBOX..."
        xbcp -d -y -t -r -f ../_lvl_xbox/*.lvl xe:\\Battlefront2\\Data\\_lvl_xbox\\ \
            2>>$MUNGE_LOG
		xbcp -d -y -t -r -f ../_lvl_xbox/*.mvs xe:\\Battlefront2\\Data\\_lvl_xbox\\ \
            2>>$MUNGE_LOG
		xbcp -d -y -t -r -f ../sound/global/dsstdfx.bin xe:\\Battlefront2\\Data\\ \
            2>>$MUNGE_LOG
    fi
fi

# If the munge log has anything in it, view it
if [[ $DISPLAY_MESSAGES -eq 1 ]]; then
    for LOGFILE in $MUNGE_LOG; do
        if [[ ! -e $LOGFILE ]]; then
            break
        fi
        if [[ $(wc -l $LOGFILE) -gt 0 ]]; then
            $EDITOR $MUNGE_LOG
        else
            if [[ -e $MUNGE_LOG ]]; then
                rm -vf $MUNGE_LOG
            fi
        fi
    done
fi

exit 0
