#!/bin/sh

#  Param_func.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
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

FOLDERS_NAMES=("Biases" "Darks" "Flats" "Lights")
BIASE_EXP_TIME=4000
FLATS_EXP_VALUE=10
FILE_NUM_DIFF=5
MAX_SIZE=20
MAX_AGE=90
SLEEP=0.05

overwrite(){
    sleep "$SLEEP"
    printf "\033[1A"  # move cursor one line up
    printf "\033[K"   # delete till end of line
    echo $1
}

load_param() {
    echo "Loading parameters${BLINKING}...${NORMAL}"
    OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "parameters.config")
    for line in $lines
    do
        if [[ $line == *"-"* ]]; then
            Val=$(echo "$line" | grep -o ".- *")
            case "$Val" in
                ("1- ")
                    IFS="; "
                    i=0
                    FOLDERS_NAMES=()
                    for name in ${line#*: };
                    do
                        FOLDERS_NAMES[$i]=$name
                        ((i+=1))
                    done
                    ;;
                ("2- ")
                    BIASE_EXP_TIME=${line#*: }
                    ;;
                ("3- ")
                    FLATS_EXP_VALUE=${line#*: }
                    ;;
                ("4- ")
                    FILE_NUM_DIFF=${line#*: }
                    ;;
                ("5- ")
                    MAX_SIZE=${line#*: }
                    ;;
                ("6- ")
                    MAX_AGE=${line#*: }
                    ;;
                ("7- ")
                    SLEEP=$(echo "${line#*: }/1000" | bc -l)
                    ;;
                (*)
                    echo "Error";;
            esac
        fi
    done
    IFS=$OLDIFS
    echo "${GREEN}Done${NORMAL}"
}

clean_tmp(){
    # remove the old temporary files
    if [ -e "$ROOT_PATH/.tmp/temp_biases.txt" ];
    then
        rm "$ROOT_PATH/.tmp/temp_biases.txt"
    fi

    if [ -e "$ROOT_PATH/.tmp/temp_flats.txt" ];
    then
        rm "$ROOT_PATH/.tmp/temp_flats.txt"
    fi

    if [ -e "$ROOT_PATH/.tmp/temp_darks.txt" ];
    then
        rm "$ROOT_PATH/.tmp/temp_darks.txt"
    fi

    if [ -e "$ROOT_PATH/.tmp/temp_lights.txt" ];
    then
        rm "$ROOT_PATH/.tmp/temp_lights.txt"
    fi

    if [ -e "$ROOT_PATH/.tmp/temp_rot.txt" ];
    then
        rm "$ROOT_PATH/.tmp/temp_rot.txt"
    fi

    if [ -e "$ROOT_PATH/.tmp/temp_rotation.txt" ];
    then
        rm "$ROOT_PATH/.tmp/temp_rotation.txt"
    fi

    if [ -e "$ROOT_PATH/.tmp/temporary.txt" ];
    then
        rm "$ROOT_PATH/.tmp/temporary.txt"
    fi
    
    log_weight=$(echo "scale=1; "$(ls -lrt "$ROOT_PATH/.tmp/AutoClassifier.log" | awk '{ total += $5 }; END { print total }')"/1024" | bc)
    
    log_date=$(stat -s "$ROOT_PATH/.tmp/AutoClassifier.log")
    log_date="${log_date#*"st_mtime="}"
    log_date="${log_date%st_ctime*}"
    log_date_diff="$(echo "($TODAY - $log_date)/(3600*24)" | bc -l)"
    
    oversize=$(echo "$log_weight > $MAX_SIZE" | bc -l)
    overage=$(echo "$log_date_diff >= $MAX_AGE" | bc -l)
    
    if [[ ! $oversize || ! $overage ]]; then
        old="$(tail -n 24 "$ROOT_PATH/.tmp/AutoClassifier.log")"
        rm "$ROOT_PATH/.tmp/AutoClassifier.log"
        echo "$old" >> "$ROOT_PATH/.tmp/AutoClassifier.log"
    else
        echo "It's too yound to die"
    fi
}

is_folder_name_valide() {
    OLDIFS=$IFS
    IFS="; "
    
    i=0
    folder_name=()
    for name in $1;
    do
        folder_name[$i]=$name
        ((i+=1))
    done
    nb=${#folder_name[@]}
    IFS=$OLDIFS
    
    if [[ $nb == 4 ]]; then
        return 1
    else
        return 0
    fi
}

write_param() {
    sed -i '' "/^$1/s/\(.*\)$2/\1$3/" "parameters.config"
}

update_param() {
    OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "$ROOT_PATH/parameters.config")
    for line in $lines
    do
        Val=$(echo "$line" | grep -o ".- *")
        if [[ "$Val" == "" ]]; then
            echo "${UNDERLINED}$line${NORMAL}"
        else
            echo "\t${line%[(|:]*}"
        fi
    done
    IFS=$OLDIFS
    echo "\nEnter the number of the parameter to change ${DIM}(\"n\" or \"q\" to exit)${NORMAL}:"
    read arg
    while [[ "$arg" != "n" && "$arg" != "q" ]];
    do
        case "$arg" in
            ("1")
                echo "\n${BOLD}${UNDERLINED}Folder name${NORMAL}"
                actual="$(echo "$(cat "parameters.config")" | grep "1- F*")"
                echo "Actual value: : ${BOLD}${actual#*: }${NORMAL}"
                echo "Enter the new names for the folders ${DIM}(need 4 arguments separate by \"; \")${NORMAL}:"
                read newArg
                is_folder_name_valide "$newArg"
                if [[ $? == 1 ]]; then
                    echo "\nNew folder names saved as: ${UNDERLINED}$newArg${NORMAL}"
                    write_param "1- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not enought folder names.${NORMAL}"
                    echo "Impossible to write the new parameter."
                fi
                ;;
            ("2")
                echo "\n${BOLD}${UNDERLINED}Biases exposure time (in 1/X s)${NORMAL}"
                actual="$(echo "$(cat "parameters.config")" | grep "2- B*")"
                echo "Actual value: : ${BOLD}1/${actual#*: } s${NORMAL}"
                echo "Enter the new exposure time:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew exposure time saved as: ${UNDERLINED}1/$newArg$ s{NORMAL}"
                    write_param "2- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
                fi
                ;;
            ("3")
                echo "\n${BOLD}${UNDERLINED}Flats exposure value (in EV)${NORMAL}"
                actual="$(echo "$(cat "parameters.config")" | grep "3- F*")"
                echo "Actual value: : ${BOLD}${actual#*: } EV${NORMAL}"
                echo "Enter the new exposure value:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew exposure value saved as: ${UNDERLINED}$newArg EV${NORMAL}"
                    write_param "3- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
                fi
                ;;
            ("4")
                echo "\n${BOLD}${UNDERLINED}File numeration difference${NORMAL}"
                actual="$(echo "$(cat "parameters.config")" | grep "4- F*")"
                echo "Actual value: : ${BOLD}${actual#*: }${NORMAL}"
                echo "Enter the new numeration difference:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew numeration difference saved as: ${UNDERLINED}$newArg${NORMAL}"
                    write_param "4- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
                fi
                ;;
            ("5")
                echo "\n${BOLD}${UNDERLINED}Max size (in ko)${NORMAL}"
                actual="$(echo "$(cat "parameters.config")" | grep "5- M*")"
                echo "Actual value: : ${BOLD}${actual#*: } ko${NORMAL}"
                echo "Enter the new maximum size for temporary files:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew max size saved as: ${UNDERLINED}$newArg ko${NORMAL}"
                    write_param "5- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
                fi
                ;;
            ("6")
                echo "\n${BOLD}${UNDERLINED}Max age (in day)${NORMAL}"
                actual="$(echo "$(cat "parameters.config")" | grep "6- M*")"
                echo "Actual value: : ${BOLD}${actual#*: } days${NORMAL}"
                echo "Enter the new maximum age for temporary files:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew max age saved as: ${UNDERLINED}$newArg days${NORMAL}"
                    write_param "6- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
                fi
                ;;
            ("7")
                echo "\n${BOLD}${UNDERLINED}Overwrite screen time (in ms)${NORMAL}"
                actual="$(echo "$(cat "parameters.config")" | grep "7- O*")"
                echo "Actual value: : ${BOLD}${actual#*: } ms${NORMAL}"
                echo "Enter the new screen time:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew screen time saved as: ${UNDERLINED}$newArg ms${NORMAL}"
                    write_param "7- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
                fi
                ;;
            (*)
                echo "\n${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} Wrong number${NORMAL}"
                ;;
        esac
        echo "\nEnter the number of the parameter to change ${DIM}(\"n\" or \"q\" to exit)${NORMAL}: "
        read arg
    done
    
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
    if [ -d "$1" ]; then
        echo "$1"
    else
        echo "error ..."
    fi
}

undo_process() {
    echo "Undo process ..."
}

temp_check() {
    echo "Detailed size of temporary files:"
    tot="$(echo "scale=1; "$(ls -lrt "${ROOT_PATH}/.tmp/" | awk '{ total += $5 }; END { print total }')"/1024" | bc)"
    echo "${UNDERLINED}Total size:${NORMAL} $tot Ko"
    echo "$(ls -lrth "${ROOT_PATH}/.tmp/")" >> "$ROOT_PATH/.tmp/temporary.txt"
    echo "$(tail -n +2 "$ROOT_PATH/.tmp/temporary.txt")" > "$ROOT_PATH/.tmp/temporary.txt"
    input="$ROOT_PATH/.tmp/temporary.txt"
    while IFS= read -r line
    do
        IFS=' ' read -r -a array <<< "$line"
        echo "\t${array[4]} \t${BLUE}${array[8]}${NORMAL}"
    done < "$input"
}

temp_clear() {
    OLDIFS=$IFS
    input="$ROOT_PATH/.tmp/temporary.txt"
    while IFS= read -r line
    do
        IFS=' ' read -r -a array <<< "$line"
        rm "$ROOT_PATH/.tmp/${array[8]}"
    done < "$input"
    rm "$ROOT_PATH/.tmp/temporary.txt"
    echo "${SOUND}"
    IFS=$OLDIFS
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
