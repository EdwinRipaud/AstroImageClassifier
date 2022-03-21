#!/bin/sh

#  Param_func.sh
#  
#
#  Created by edwin ripaud on 17/03/2022.
#

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
NORMAL='\033[m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINED='\033[4m'
BLINKING='\033[5m'
REVERSE='\033[7m'
SOUND='\007'

SLEEP=0.05

OverWrite(){
    sleep "$SLEEP" # sleep for 50ms, juste to see that the line is being overwrite
    printf "\033[1A"  # move cursor one line up
    printf "\033[K"   # delete till end of line
    echo $1
}

read_param() {
    echo "$(cat "parameters.config")"
}

write_param() {
    OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "parameters.config")
    for line in $lines
    do
        if [[ $line == *"-"* ]]; then
            Val=$(echo "$line" | grep -o ".- *")
            
            case $Val in
                ("1- ")
                    echo "Folders names"
                    echo "\t${line#*: }";;
                    
                ("2- ")
                    echo "Max size"
                    echo "\t${line#*: }";;
                ("3- ")
                    echo "Max age"
                    echo "\t${line#*: }";;
                ("4- ")
                    echo "Time"
                    echo "\t${line#*: }";;
                (*)
                    echo "Error";;
                
            esac
        fi
    done
    IFS=$OLDIFS
}

IsPicture(){
    # check if the 'RAW' directory exist
    if [ ! -d "$base_path/RAW" ];
    then
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} There is no ${ITALIC}'RAW/'${NORMAL}${RED} directory inside the specified working directory.${NORMAL}"
        echo "Please ${BOLD}check the path${NORMAL} or rename / create a ${ITALIC}'RAW'${NORMAL} directory that contain all the RAW images out of your APN."
        return 1
    fi
    return 0
}

run_process() {
    echo "Running process ..."
    if [ "$1" != "" ]; then
        echo "$1"
    fi
}

undo_process() {
    echo "Undo process ..."
}

temp_check() {
    echo "Temporary files checking"
}

help_fnc() {
        OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "Help.txt")
    for line in $lines
    do
        echo "$line"
    done
    IFS=$OLDIFS
}
