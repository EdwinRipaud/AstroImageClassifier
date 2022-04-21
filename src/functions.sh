#!/bin/sh

#  Param_func.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#

# Global variable definition
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
ORIENTATION_NAMES=("Horizontal (normal)" "Rotate 180" "Rotate 90 CW" "Rotate 270 CW")
BIASE_EXP_TIME=4000
FLATS_EXP_VALUE=10
FILE_NUM_DIFF=5
ORIENTATION="Horizontal (normal)"
MAX_SIZE=20
MAX_AGE=90
SLEEP=0.05

#/Applications/SiriL.app/Contents/MacOS/siril-cli -d "/Volumes/Edwin SSD 1/5 - Astrophoto/AstroImageClissifier/Test" -s "/Applications/SiriL.app/Contents/Resources/share/siril/scripts/Couleur_Pre-traitement.ssf"
IMG_TYPE="$((2#0000))" # (Dark, Offset, Flats, Lights)
SIRIL_PATH=""
SCRIPT_PATH="../Resources/share/siril/scripts"
SCRIPTS_fr=( "Couleur_Pre-traitement.ssf" "Couleur_Pre-traitement_SansFlat.ssf" "Couleur_Pre-traitement_SansDark.ssf" "Couleur_Pre-traitement_SansDOF.ssf" )
SCRIPTS_en=( "OSC_Preprocessing.ssf" "OSC_Preprocessing_WithoutFlat.ssf" "OSC_Preprocessing_WithoutDark.ssf" "OSC_Preprocessing_WithoutDBF.ssf" )
SCRIPTS=$SCRIPTS_fr
EXEC_SCRIPT="${SCRIPTS[0]}"

check_dependencies() { # Function that will if all the dépendencies are available
    # check for Siril command line tool
    case "$OSTYPE" in
        (darwin*)
            echo "(OK) MacOS"
            if [ -e "/Applications/SiriL.app/Contents/MacOS/siril-cli" ]; then
                SIRIL_PATH="/Applications/SiriL.app/Contents/MacOS/siril-cli"
                SCRIPT_PATH="/Applications/SiriL.app/Contents/Resources/share/siril/scripts"
                echo "(OK) SiriL"
            elif [ -e "/Applications/Siril.app/Contents/Resources/bin/Siril-cli" ]; then
                SIRIL_PATH="/Applications/Siril.app/Contents/Resources/bin/Siril-cli"
                SCRIPT_PATH="/Applications/Siril.app/Contents/Resources/Resources/share/siril/scripts"
                echo "(OK) SiriL"
            else
                echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} You need to install Siril (${UNDERLINED}www.siril.org${NORMAL}) to run some function of this program.${NORMAL}"
            fi
            ;;
        (linux*)
            echo "(OK) Linux"
            if [ -e "/usr/local/bin/siril-cli" ]; then
                SIRIL_PATH="/usr/local/bin/siril-cli"
                SCRIPT_PATH="/usr/local/Resources/share/siril/scripts"
                echo "(OK) SiriL"
            elif [ -e "/usr/bin/siril-cli" ]; then
                SIRIL_PATH="/usr/bin/Resources/share/siril/scripts"
                SCRIPT_PATH="/usr/bin"
                echo "(OK) SiriL"
            else
                echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} You need to install Siril (${UNDERLINED}www.siril.org${NORMAL}) to run some function of this program.${NORMAL}"
            fi
            ;;
        (win* | msys* | cygwin*)
            echo "(OK) Windows"
            if [ -e "C:\\Program Files\\SiriL\\bin\\siril-cli.exe" ]; then
                SIRIL_PATH="C:\\Program Files\\SiriL\\bin\\siril-cli.exe"
                SCRIPT_PATH="C:\\Program Files\\SiriL\\Resources/share/siril/scripts"
                echo "(OK) SiriL"
            elif [ -e "C:\\Program Files (x86)\\SiriL\\bin\\siril-cli.exe" ]; then
                SIRIL_PATH="C:\\Program Files (x86)\\SiriL\\bin\\siril-cli.exe"
                SCRIPT_PATH="C:\\Program Files (x86)\\SiriL\\Resources/share/siril/scripts"
                echo "(OK) SiriL"
            else
                echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} You need to install Siril (${UNDERLINED}www.siril.org${NORMAL}) to run some function of this program.${NORMAL}"
            fi
            ;;
        (*)
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} unknown Operating System.${NORMAL}"
    esac
    
    # check for exiftool
    if command -v "exiftool" > /dev/null 2>&1; then
        echo "(OK) Exiftool"
    else
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} You must have exiftool (${UNDERLINED}www.exiftool.org${NORMAL}${RED}${BOLD}) installed.${NORMAL}"
        exit 1;
    fi
}

overwrite(){ # Function that will write the input text on the previous line of the termial, to create the overwrite effect
    sleep "$SLEEP"
    printf "\033[1A"  # move cursor one line up
    printf "\033[K"   # delete till end of line
    echo $1
}

log_time() { # calculates the time difference and returns the value in a string
    runtime=$( echo "1000*($3-$2)" | bc -l )
    runtime=${runtime%.*}
    if [[ $runtime -lt 1000 ]]; then
        if [ ! -z "$1" ]; then
            echo "$(printf "%-30s" "$1") => Runtime: $(printf "%10s" "$runtime") ms"
        else
            echo "=> Runtime: $(printf "%10s" "$runtime") ms"
        fi
    else
        if [ ! -z "$1" ]; then
            echo "$(printf "%-30s" "$1") => Runtime: $(printf "%10s" "$(echo "scale=3; $runtime/1000" | bc -l)") s"
        else
            echo "=> Runtime: $(printf "%10s" "$(echo "scale=3; $runtime/1000" | bc -l)") s"
        fi
    fi
}

# --- PARAMETERS SECTION --- #
load_param() { # Function that load parameters from the .config file and store the values in global variables
    start_lp=`gdate +%s.%3N`
    echo "Loading parameters..."
    OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "$ROOT_PATH/src/parameters.config")
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
                    if [[ "${ORIENTATION_NAMES[*]}" =~ "${line#*: }" ]]; then
                        ORIENTATION="${line#*: }"
                    else
                        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} orientation value unknown.${NORMAL}"
                    fi
                    ;;
                ("6- ")
                    MAX_SIZE=${line#*: }
                    ;;
                ("7- ")
                    MAX_AGE=${line#*: }
                    ;;
                ("8- ")
                    SLEEP=$(echo "${line#*: }/1000" | bc -l)
                    ;;
                (*)
                    echo "Error";;
            esac
        fi
    done
    IFS=$OLDIFS
#    echo "Function: load_param()" >> "$LOG_PATH"
    end_lp=`gdate +%s.%3N`
    log_time "Function: load_param()" $start_lp $end_lp >> "$LOG_PATH"
    echo "${GREEN}Done${NORMAL}"
}

clean_oversize() { # Function to delete the .log file if it's to old or to big, with respect to the configuration parameters
    start_co=`gdate +%s.%3N`
    log_weight=$(echo "scale=1; "$(ls -lrt "$LOG_PATH" | awk '{ total += $5 }; END { print total }')"/1024" | bc)
    
    log_date=$(stat -s "$LOG_PATH")
    log_date="${log_date#*"st_mtime="}"
    log_date="${log_date%st_ctime*}"
    log_date_diff="$(echo "($TODAY - $log_date)/(3600*24)" | bc -l)"
    
    oversize=$(echo "$log_weight > $MAX_SIZE" | bc -l)
    overage=$(echo "$log_date_diff >= $MAX_AGE" | bc -l)
    
    old_log="$(tail -n 31 "$LOG_PATH")"
    
    if [[ $oversize -eq 1 || $overage -eq 1 ]]; then
        echo "Clear .log: to old or to big"
        rm "$LOG_PATH"
        echo "$old_log" >> "$LOG_PATH"
    fi
#    echo "Function: clean_oversize()" >> "$LOG_PATH"
    end_co=`gdate +%s.%3N`
    log_time "Function: clean_oversize()" $start_co $end_co >> "$LOG_PATH"
}

is_folder_name_valide() { # Function to check if the new classification folder respect the number of required folder
    start_ifnv=`gdate +%s.%3N`
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
    echo "Function: is_folder_name_valide()" >> "$LOG_PATH"
    end_ifnv=`gdate +%s.%3N`
    log_time "" $start_ifnv $end_ifnv >> "$LOG_PATH"
}

write_param() { # Function that write the input parameter to the .config file
    sed -i '' "/^$1/s/\(.*\)$2/\1$3/" "$ROOT_PATH/src/parameters.config"
}

update_param() { # Global function to walk through parameters
    start_up=`gdate +%s.%3N`
    echo "To set all parameters value to default, use ${BOLD}${ITALIC}'reset'${NORMAL}\n"
    OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "$ROOT_PATH/src/parameters.config")
    for line in $lines
    do
        val=$(echo "$line" | grep -o ".- *")
        if [[ "$val" == "" ]]; then
            echo "${UNDERLINED}$line${NORMAL}"
        else
            echo "\t$(printf "%-35s" "${line% :*}"): ${line#*: }"
        fi
    done
    IFS=$OLDIFS
#    echo "Function: update_param()" >> "$LOG_PATH"
    echo "\nEnter the number of the parameter to change ${DIM}(\"n\" or \"q\" to exit)${NORMAL}:"
    read arg
    while [[ "$arg" != "n" && "$arg" != "q" ]];
    do
        case "$arg" in
            ("1")
                echo "\n${BOLD}${UNDERLINED}Folder name${NORMAL}"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "1- F*")"
                echo "Actual value: : ${BOLD}${actual#*: }${NORMAL}"
                echo "Enter the new names for the folders ${DIM}(need 4 arguments separate by \"; \")${NORMAL}:"
                read newArg
                is_folder_name_valide "$newArg"
                if [[ $? == 1 ]]; then
                    echo "\nNew folder names saved as: ${UNDERLINED}$newArg${NORMAL}"
                    write_param "1- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not enought folder names or bad delimiter.${NORMAL}"
                    echo "Impossible to write the new parameter."
                fi
                ;;
            ("2")
                echo "\n${BOLD}${UNDERLINED}Biases exposure time (in 1/X s)${NORMAL}"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "2- B*")"
                echo "Actual value: : ${BOLD}1/${actual#*: } s${NORMAL}"
                echo "Enter the new exposure time:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew exposure time saved as: ${UNDERLINED}1/$newArg$ s{NORMAL}"
                    write_param "2- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not a number.${NORMAL}"
                fi
                ;;
            ("3")
                echo "\n${BOLD}${UNDERLINED}Flats exposure value (in EV)${NORMAL}"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "3- F*")"
                echo "Actual value: : ${BOLD}${actual#*: } EV${NORMAL}"
                echo "Enter the new exposure value:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew exposure value saved as: ${UNDERLINED}$newArg EV${NORMAL}"
                    write_param "3- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not a number.${NORMAL}"
                fi
                ;;
            ("4")
                echo "\n${BOLD}${UNDERLINED}File numeration difference${NORMAL}"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "4- F*")"
                echo "Actual value: : ${BOLD}${actual#*: }${NORMAL}"
                echo "Enter the new numeration difference:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew numeration difference saved as: ${UNDERLINED}$newArg${NORMAL}"
                    write_param "4- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not a number.${NORMAL}"
                fi
                ;;
            ("5")
                echo "\n${BOLD}${UNDERLINED}Frame orientaion${NORMAL}"
                echo "Posible orientation:\n\t(1) \"Horizontal (normal)\"\n\t(2) \"Rotate 180\"\n\t(3) \"Rotate 90 CW\"\n\t(4) \"Rotate 270 CW\"\n"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "5- F*")"
                echo "Actual value: : ${BOLD}${actual#*: }${NORMAL}"
                echo "Enter the number of the new orientation:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew orientation saved as: ${UNDERLINED}${ORIENTATION_NAMES[(($newArg-1))]}${NORMAL}"
                    write_param "5- " "${actual#*: }" "${ORIENTATION_NAMES[(($newArg-1))]}"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not a number.${NORMAL}"
                fi
                ;;
            ("6")
                echo "\n${BOLD}${UNDERLINED}Max size (in ko)${NORMAL}"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "6- M*")"
                echo "Actual value: : ${BOLD}${actual#*: } ko${NORMAL}"
                echo "Enter the new maximum size for temporary files:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew max size saved as: ${UNDERLINED}$newArg ko${NORMAL}"
                    write_param "6- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not a number.${NORMAL}"
                fi
                ;;
            ("7")
                echo "\n${BOLD}${UNDERLINED}Max age (in day)${NORMAL}"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "7- A*")"
                echo "Actual value: : ${BOLD}${actual#*: } days${NORMAL}"
                echo "Enter the new maximum age for temporary files:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew max age saved as: ${UNDERLINED}$newArg days${NORMAL}"
                    write_param "7- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not a number.${NORMAL}"
                fi
                ;;
            ("9")
                echo "\n${BOLD}${UNDERLINED}Overwrite screen time (in ms)${NORMAL}"
                actual="$(echo "$(cat "$ROOT_PATH/src/parameters.config")" | grep "8- O*")"
                echo "Actual value: : ${BOLD}${actual#*: } ms${NORMAL}"
                echo "Enter the new screen time:"
                read newArg
                re='^[0-9]+$'
                if [[ $newArg =~ $re ]]; then
                    echo "\nNew screen time saved as: ${UNDERLINED}$newArg ms${NORMAL}"
                    write_param "8- " "${actual#*: }" "$newArg"
                    echo "${GREEN}done${NORMAL}"
                else
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} not a number.${NORMAL}"
                fi
                ;;
            ("reset")
                echo "\n${BOLD}${UNDERLINED}Reset parameters${NORMAL}"
                rm "$ROOT_PATH/src/parameters.config"
                cp "$ROOT_PATH/src/.parameters.config" "$ROOT_PATH/src/parameters.config"
                echo "${GREEN}done${NORMAL}"
                ;;
            (*)
                echo "\n${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} Wrong value, get: ${ITALIC}$arg${NORMAL}"
                ;;
        esac
        echo "\nEnter the number of the parameter to change ${DIM}(\"n\" or \"q\" to exit)${NORMAL}:"
        read arg
    done
    end_up=`gdate +%s.%3N`
    log_time "Function: update_param()" $start_up $end_up >> "$LOG_PATH"
}


# --- CLASSIFICATION SECTION --- #
IsPicture(){ # Function to check if the 'RAW' directory, containing pictures, exist
    if [ ! -d "$BASE_PATH/RAW" ];
    then
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} There is no ${ITALIC}'RAW/'${NORMAL}${RED} directory inside the specified working directory.${NORMAL}"
        echo "Please ${BOLD}check the path${NORMAL} or rename / create a ${ITALIC}'RAW'${NORMAL} directory that contain all the RAW images out of your APN."
        return 1
    fi
    return 0
}

clean_tmp() { # Function to clean the temporary files used for the previous classification
    start_ct=`gdate +%s.%3N`
    # remove the old temporary files
    if [ -e "$TEMP_PATH/temp_biases.txt" ];
    then
        rm "$TEMP_PATH/temp_biases.txt"
    fi

    if [ -e "$TEMP_PATH/temp_flats.txt" ];
    then
        rm "$TEMP_PATH/temp_flats.txt"
    fi

    if [ -e "$TEMP_PATH/temp_darks.txt" ];
    then
        rm "$TEMP_PATH/temp_darks.txt"
    fi

    if [ -e "$TEMP_PATH/temp_lights.txt" ];
    then
        rm "$TEMP_PATH/temp_lights.txt"
    fi

    if [ -e "$TEMP_PATH/temp_rot.txt" ];
    then
        rm "$TEMP_PATH/temp_rot.txt"
    fi

    if [ -e "$TEMP_PATH/temp_rotation.txt" ];
    then
        rm "$TEMP_PATH/temp_rotation.txt"
    fi

    if [ -e "$TEMP_PATH/temp_rotation_orientation.txt" ];
    then
        rm "$TEMP_PATH/temp_rotation_orientation.txt"
    fi

    if [ -e "$TEMP_PATH/temporary.txt" ];
    then
        rm "$TEMP_PATH/temporary.txt"
    fi
#    echo "Function: clean_temp()" >> "$LOG_PATH"
    end_ct=`gdate +%s.%3N`
    log_time "Function: clean_temp()" $start_ct $end_ct >> "$LOG_PATH"
}

make_dir() { # Function to check if 'input' directory existe, otherwise create it
    if [ ! -d "$BASE_PATH/$1" ];
    then
        mkdir "$BASE_PATH/$1"
    fi
}

rotation() {
    start_r=`gdate +%s.%3N`
    OLDIFS=$IFS
    IFS=$'\n'
    ###############
    # - Roation - #
    ###############
    # catch and rotate all the images that aren't in Horizontal (normal) position
    echo "Search non-horizontal (normal) image"
    prefix="$(echo "$BASE_PATH/RAW/" | sed 's_/_\\/_g')"
    phrase="\$orientation ne \"$ORIENTATION\""
    
    exiftool -filename -orientation -if "$phrase" -r "$BASE_PATH/RAW" | grep -w -e "File Name" -e "Orientation"  | sed 's/.*: //' >> "$TEMP_PATH/temp_rot_ori.txt"
    
    if [ -s "$TEMP_PATH/temp_rot_ori.txt" ]; then
        while read -r one; do
            read -r two
            echo "$BASE_PATH/RAW/$one" >> "$TEMP_PATH/temp_rotation.txt"
            echo "$BASE_PATH/RAW/$one; $two" >> "$TEMP_PATH/temp_rotation_orientation.txt"
        done < "$TEMP_PATH/temp_rot_ori.txt"
        
        echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_rotation.txt") bad rotation found.${NORMAL}"
        echo "Rotate images...${BLUE}"

        exiftool -@ "$TEMP_PATH/temp_rotation.txt" -orientation="$ORIENTATION" -overwrite_original_in_place
    else
        echo "${BLUE}No bad rotation found.${NORMAL}"
    fi
    rm "$TEMP_PATH/temp_rot_ori.txt"
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_rotation.txt" ]; then
        nb_files=$(wc -l < "$TEMP_PATH/temp_rotation.txt" | sed 's/ //g')
    fi
    IFS=$OLDIFS
    end_r=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- rotation()") ($nb_files)" $start_r $end_r >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

biases(){
    start_b=`gdate +%s.%3N`
    OLDIFS=$IFS
    IFS=$'\n'
    ##############
    # - Biases - #
    ##############
    # Catch and move the biases
    echo "\nSearch for the ${FOLDERS_NAMES[0]}..."
    exiftool -filename -if '$shutterspeed eq "1/8000"' -r "$BASE_PATH/RAW" | grep "File Name" | sed 's/.*: //' >> "$TEMP_PATH/temp_biases.txt"
    
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_biases.txt") ${FOLDERS_NAMES[0]} found.${NORMAL}"
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_biases.txt" ]; then
        nb_files=$(wc -l < "$TEMP_PATH/temp_biases.txt" | sed 's/ //g')
    fi
    
    if [ ! $nb_files == 0 ]; then
        echo "Move ${FOLDERS_NAMES[0]} files to the ${ITALIC}${BOLD}'${FOLDERS_NAMES[0]}/'${NORMAL} directory...\n"

        make_dir "${FOLDERS_NAMES[0]}"

        lines=$(cat "$TEMP_PATH/temp_biases.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/RAW/${line}" "$BASE_PATH/${FOLDERS_NAMES[0]}/"
        done
        IMG_TYPE="$(($IMG_TYPE | 2#0100))"
    else
        echo "No file to move"
    fi
    
    IFS=$OLDIFS
    end_b=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- biases()") ($nb_files)" $start_b $end_b >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

flats(){
    start_f=`gdate +%s.%3N`
    OLDIFS=$IFS
    IFS=$'\n'
    #############
    # - Flats - #
    #############
    # Catch and move the flats
    echo "\nSearch for the ${FOLDERS_NAMES[2]}..."
    exiftool -filename -if '$MeasuredEV ge 10' -r "$BASE_PATH/RAW" | grep "File Name" | sed 's/.*: //' >> "$TEMP_PATH/temp_flats.txt"

    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_flats.txt") ${FOLDERS_NAMES[2]} found.${NORMAL}"
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_flats.txt" ]; then
        nb_files=$(wc -l < "$TEMP_PATH/temp_flats.txt" | sed 's/ //g')
    fi
    
    if [ ! $nb_files == 0 ]; then
        echo "Move ${FOLDERS_NAMES[2]} files to the ${ITALIC}${BOLD}'${FOLDERS_NAMES[2]}/'${NORMAL} directory..."
        echo ""

        make_dir "${FOLDERS_NAMES[2]}"

        lines=$(cat "$TEMP_PATH/temp_flats.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/RAW/${line}" "$BASE_PATH/${FOLDERS_NAMES[2]}/"
        done
        IMG_TYPE="$(($IMG_TYPE | 2#0010))"
    else
        echo "No file to move"
    fi
    
    IFS=$OLDIFS
    end_f=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- flats()") ($nb_files)" $start_f $end_f >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

catch_darks_lights(){
    start_cdl=`gdate +%s.%3N`
    ######################
    # - darks & lights - #
    ######################
    # Saerch in all the remaning images a discontinuity in the naming of the file number.
    # All the images before the discontinuity will be place in the "lights" directory
    # and all the others will be place in the "darks" directory.

    # Catch and move the lights
    echo "\nSearch for ${FOLDERS_NAMES[3]} and ${FOLDERS_NAMES[1]}..."

    # The first itetration is to defin the first image of the directory, so it's a separate loop
    TEST=true
    FIND=false
    PREV_NAME=0 # store the name of the image before the last discontinuity
    CHANGE_NAME=0 # the counter for the loop
    index=0
    count=0
    for FILE_NAME in "$BASE_PATH/RAW"/*; do # scann for all the files in the "RAW" directoy
        FILE_NAME=${FILE_NAME##*/}
        NAME_array[count]="$FILE_NAME"
        count=$((count+1))
        FILE=${FILE_NAME%.*}
        if ! $FIND; then
            if $TEST; then # check if it's the first file
                TEST=false # turn the boolean to 'false'
                CHANGE_NAME=${FILE//[^0-9]/}
            else
                num=${FILE//[^0-9]/}
                diff=$(echo "$num-$CHANGE_NAME" | bc -l) # calculate the difference between the numerotation of the previous and the current image
                if [[ $diff -gt $FILE_NUM_DIFF ]]; then # if the difference is greater than the threshold, it's a discontinuity
                    index=$count
                    for ((i=0; i<$index-1; i++))
                    do
                        echo "${NAME_array[i]}" >> "$TEMP_PATH/temp_lights.txt"
                    done
                    FIND=true
                fi
                CHANGE_NAME=$num
            fi
        fi
    done
    
    if [ $index = 0 ]; then
        for ((i=0; i<$count; i++))
        do
            echo "${NAME_array[i]}" >> "$TEMP_PATH/temp_lights.txt"
            touch "$TEMP_PATH/temp_darks.txt"
        done
    else
        # Catch darks to move
        for ((i=$index-1; i<$count; i++))
        do
            echo "${NAME_array[i]}" >> "$TEMP_PATH/temp_darks.txt"
        done
    fi
    end_cdl=`gdate +%s.%3N`
    log_time "- catch_darks_lights()" $start_cdl $end_cdl >> "$LOG_PATH"
}

lights(){
    start_l=`gdate +%s.%3N`
    OLDIFS=$IFS
    IFS=$'\n'
    ##############
    # - Lights - #
    ##############
    # move the lights
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_lights.txt") ${FOLDERS_NAMES[3]} found.${NORMAL}"
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_lights.txt" ]; then
        nb_files=$(wc -l < "$TEMP_PATH/temp_lights.txt" | sed 's/ //g')
    fi
    
    if [ ! $nb_files == 0 ]; then
        echo "Move ${FOLDERS_NAMES[3]} files to the ${ITALIC}${BOLD}'${FOLDERS_NAMES[3]}/'${NORMAL} directory..."
        echo ""

        make_dir "${FOLDERS_NAMES[3]}"

        lines=$(cat "$TEMP_PATH/temp_lights.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/RAW/${line}" "$BASE_PATH/${FOLDERS_NAMES[3]}/"
        done
        IMG_TYPE="$(($IMG_TYPE | 2#0001))"
    else
        echo "No file to move"
    fi
    
    IFS=$OLDIFS
    end_l=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- lights()") ($nb_files)" $start_l $end_l >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

darks(){
    start_d=`gdate +%s.%3N`
    OLDIFS=$IFS
    IFS=$'\n'
    #############
    # - Darks - #
    #############
    # move the darks
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_darks.txt") ${FOLDERS_NAMES[1]} found.${NORMAL}"
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_darks.txt" ]; then
        nb_files=$(wc -l < "$TEMP_PATH/temp_darks.txt" | sed 's/ //g')
    fi
    
    if [ ! $nb_files == 0 ]; then
        echo "Move ${FOLDERS_NAMES[1]} files to the ${ITALIC}${BOLD}'${FOLDERS_NAMES[1]}/'${NORMAL} directory..."
        echo ""

        make_dir "${FOLDERS_NAMES[1]}"

        lines=$(cat "$TEMP_PATH/temp_darks.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/RAW/${line}" "$BASE_PATH/${FOLDERS_NAMES[1]}/"
        done
        IMG_TYPE="$(($IMG_TYPE | 2#1000))"
    else
        echo "No file to move"
    fi
    
    IFS=$OLDIFS
    end_d=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- darks()") ($nb_files)" $start_d $end_d >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

run_process() { # Global function that classify picture
    echo "Running process ..."
    nb_files=$(ls "$BASE_PATH/RAW" | wc -l | xargs)
    echo "$(printf "%-30s" "Function: run_process()") -> process: $(printf "%10s" "$nb_files") files" >> "$LOG_PATH"
    
    if [ $nb_files == 0 ]; then
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} No files to process.${NORMAL}"
        help_fnc
        printf '\n%.0s' {1..7} >> "$LOG_PATH"
    else
        echo "There are $nb_files images to process\n"
        echo "Do you want to run the script (Y/n):"
        read sure
        start_rp=`gdate +%s.%3N`
        if [[ $sure == "Y" || $sure == "y" ]]; then
            echo "Start processing${BLINKING}...${NORMAL}\n"
            clean_tmp           # Clean temporary files
            rotation            # Rotate image in Horizontal mode
            biases              # Extract the biases
            flats               # Extract the flats
            catch_darks_lights  # Differentiate the darks and the lights
            darks               # Extract the darks
            lights              # Extract the lights
            end_rp=`gdate +%s.%3N`
            echo "$(log_time "" $start_rp $end_rp)"
            log_time "run_process()" $start_rp $end_rp >> "$LOG_PATH"
            if [[ $(ls "$BASE_PATH/RAW" | wc -l | xargs) == 0 ]]; then
                rmdir "$BASE_PATH/RAW"
            fi
            echo "${SOUND}"
        else
            echo "${RED}Abort process${NORMAL}"
#            echo "Abort: run_process()" >> "$LOG_PATH"
            end_rp=`gdate +%s.%3N`
            echo "$(log_time "" $start_rp $end_rp)"
            log_time "Abort: run_process()" $start_rp $end_rp >> "$LOG_PATH"
            printf '\n%.0s' {1..7} >> "$LOG_PATH"
        fi
    fi
}


# --- SCRIPT SECTION --- #
script_language() {
    nb_fr=0
    nb_en=0
    for f in $(ls "$SCRIPT_PATH"); do
        if [[ "${SCRIPTS_fr[*]}" =~ "$f" ]]; then
            nb_fr=$((nb_fr+1))
        elif [[ "${SCRIPTS_en[*]}" =~ "$f" ]]; then
            nb_en=$((nb_en+1))
        fi
    done
    if [[ nb_fr -ge nb_en ]]; then
        SCRIPTS=(${SCRIPTS_fr[*]})
    else
        SCRIPTS=(${SCRIPTS_en[*]})
    fi
}

which_script() {
    case "$(($IMG_TYPE))" in # (Dark, Offset, Flats, Lights)
        ("$((2#1111))")
            echo "Processing DOF + Lights (${SCRIPTS[0]})"
            EXEC_SCRIPT=${SCRIPTS[0]}
            if [[ -e "$SCRIPT_PATH/${SCRIPTS[0]}" ]]; then
                EXEC_SCRIPT=${SCRIPTS[0]}
                echo "Script '$EXEC_SCRIPT' have been found"
            else
                echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}No correspondance found for '$EXEC_SCRIPT' script, please check your SiriL scripts or download it from: ${UNDERLINED}free-astro.org/index.php?title=Siril:scripts${NORMAL}"
            fi
            ;;
        ("$((2#0111))")
            echo "Processing without Darks (${SCRIPTS[2]})"
            EXEC_SCRIPT=${SCRIPTS[2]}
            if [[ -e "$SCRIPT_PATH/${SCRIPTS[2]}" ]]; then
                EXEC_SCRIPT=${SCRIPTS[2]}
                echo "Script '$EXEC_SCRIPT' have been found"
            else
                echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}No correspondance found for '$EXEC_SCRIPT' script, please check your SiriL scripts or download it from: ${UNDERLINED}free-astro.org/index.php?title=Siril:scripts${NORMAL}"
            fi
            ;;
        ("$((2#1011))")
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no '${FOLDERS_NAMES[0]}', no script correspond to this configuration.${NORMAL}"
            echo "Would you like to execut the most appropriate script: ${SCRIPTS[3]}"
            # demander un renvoie vers le script Sans DOF
            ;;
        ("$((2#1101))")
            echo "Processing without Flats (${SCRIPTS[1]})"
            EXEC_SCRIPT=${SCRIPTS[1]}
            if [[ -e "$SCRIPT_PATH/${SCRIPTS[1]}" ]]; then
                EXEC_SCRIPT=${SCRIPTS[1]}
                echo "Script '$EXEC_SCRIPT' have been found"
            else
                echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}No correspondance found for '$EXEC_SCRIPT' script, please check your SiriL scripts or download it from: ${UNDERLINED}free-astro.org/index.php?title=Siril:scripts${NORMAL}"
            fi
            ;;
        ("$((2#1110))")
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no '${FOLDERS_NAMES[3]}', no script correspond to this configuration.${NORMAL}"
            ;;
        ("$((2#0011))")
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no '${FOLDERS_NAMES[0]}' and '${FOLDERS_NAMES[1]}', no script correspond to this configuration.${NORMAL}"
            echo "Would you like to execut the most appropriate script: ${SCRIPTS[3]}"
            # demander un renvoie vers le script Sans DOF
            ;;
        ("$((2#0101))")
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no '${FOLDERS_NAMES[0]}' and '${FOLDERS_NAMES[2]}', no script correspond to this configuration.${NORMAL}"
            echo "Would you like to execut the most appropriate script: ${SCRIPTS[3]}"
            # demander un renvoie vers le script Sans DOF
            ;;
        ("$((2#0110))")
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no '${FOLDERS_NAMES[0]}' and '${FOLDERS_NAMES[3]}', no script correspond to this configuration.${NORMAL}"
            ;;
        ("$((2#0001))")
            echo "Processing without DOF (${SCRIPTS[3]})"
            EXEC_SCRIPT=${SCRIPTS[3]}
            if [[ -e "$SCRIPT_PATH/${SCRIPTS[3]}" ]]; then
                EXEC_SCRIPT=${SCRIPTS[3]}
                echo "Script '$EXEC_SCRIPT' have been found"
            else
                echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}No correspondance found for '$EXEC_SCRIPT' script, please check your SiriL scripts or download it from: ${UNDERLINED}free-astro.org/index.php?title=Siril:scripts${NORMAL}"
            fi
            ;;
        ("$((2#0000))")
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no images detected, please check your '/RAW' folder and/or the configuration file of this program.${NORMAL}"
            ;;
        (*)
            echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} unknown error.${NORMAL}"
            ;;
    esac
}

# --- UNDO SECTION --- #
undo_process() { # Function to undo the previous classification
    start_upr=`gdate +%s.%3N`
    OLDIFS=$IFS
    IFS=$'\n'
    
    nb_files_b=0
    nb_files_f=0
    nb_files_d=0
    nb_files_l=0
    nb_files_r=0
    nb_files_tot=0
    
    echo "${YELLOW}Working directory: ${NORMAL}${BASE_PATH}"
    if [ ! -d "$BASE_PATH/RAW" ]; then
        mkdir "$BASE_PATH/RAW"
    fi
    echo "\nmove ${FOLDERS_NAMES[0]}..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_biases.txt") images${NORMAL}"
    if [[ -d "$BASE_PATH/${FOLDERS_NAMES[0]}" && -e "$TEMP_PATH/temp_biases.txt" ]]; then
        echo ""
        lines=$(cat "$TEMP_PATH/temp_biases.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/${FOLDERS_NAMES[0]}/${line}" "$BASE_PATH/RAW/"
            nb_files_b=$((nb_files_b+1))
        done
        echo "${GREEN}done${NORMAL}"
    else
        echo "No file to move"
    fi
    
    echo "\nmove ${FOLDERS_NAMES[2]}..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_flats.txt") images${NORMAL}"
    if [[ -d "$BASE_PATH/${FOLDERS_NAMES[2]}" && -e "$TEMP_PATH/temp_flats.txt" ]]; then
        echo ""
        lines=$(cat "$TEMP_PATH/temp_flats.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/${FOLDERS_NAMES[2]}/${line}" "$BASE_PATH/RAW/"
            nb_files_f=$((nb_files_f+1))
        done
        echo "${GREEN}done${NORMAL}"
    else
        echo "No file to move"
    fi
    
    echo "\nmove ${FOLDERS_NAMES[1]}..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_darks.txt") images${NORMAL}"
    if [[ -d "$BASE_PATH/${FOLDERS_NAMES[1]}" && -e "$TEMP_PATH/temp_darks.txt" ]]; then
        echo ""
        lines=$(cat "$TEMP_PATH/temp_darks.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/${FOLDERS_NAMES[1]}/${line}" "$BASE_PATH/RAW/"
            nb_files_d=$((nb_files_d+1))
        done
        echo "${GREEN}done${NORMAL}"
    else
        echo "No file to move"
    fi

    echo "\nmove ${FOLDERS_NAMES[3]}..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_lights.txt") images${NORMAL}"
    if [[ -d "$BASE_PATH/${FOLDERS_NAMES[3]}" && -e "$TEMP_PATH/temp_lights.txt" ]]; then
        echo ""
        lines=$(cat "$TEMP_PATH/temp_lights.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/${FOLDERS_NAMES[3]}/${line}" "$BASE_PATH/RAW/"
            nb_files_l=$((nb_files_l+1))
        done
        echo "${GREEN}done${NORMAL}"
    else
        echo "No file to move"
    fi

    if [[ -e "$TEMP_PATH/temp_rotation.txt" && -e "$TEMP_PATH/temp_rotation_orientation.txt" ]]; then
        echo "\nrotate images..."
        while read -r line; do
            exiftool "${line%; *}" -orientation="${line#*; }" -overwrite_original_in_place > "/dev/null"
            nb_files_r=$((nb_files_r+1))
        done < "$TEMP_PATH/temp_rotation_orientation.txt"
        echo "${GREEN}done${NORMAL}\n"
    fi
    IFS=$OLDIFS
    
    nb_files_tot=$((nb_files_b+nb_files_f+nb_files_d+nb_files_l))
    end_upr=`gdate +%s.%3N`
    echo "$(log_time "" $start_upr $end_upr)"
    echo "$(printf "%-30s" "Function: undo_process()") -> process: $(printf "%10s" "$nb_files_tot") files" >> "$LOG_PATH"
    echo "$(printf "%-15s" "- biases") ($nb_files_b)" >> "$LOG_PATH"
    echo "$(printf "%-15s" "- flats") ($nb_files_f)" >> "$LOG_PATH"
    echo "$(printf "%-15s" "- darks") ($nb_files_d)" >> "$LOG_PATH"
    echo "$(printf "%-15s" "- lights") ($nb_files_l)" >> "$LOG_PATH"
    echo "$(printf "%-15s" "- rotations") ($nb_files_r)" >> "$LOG_PATH"
    log_time "undo_process()" $start_upr $end_upr >> "$LOG_PATH"
    for folders_name in "${FOLDERS_NAMES[@]}"
    do
        if [[ -d "$BASE_PATH/$folders_name" ]]; then
            rmdir "$BASE_PATH/$folders_name"
        fi
    done
    echo "${SOUND}"
}


# --- TEMPORARY FILE SECTION --- #
temp_check() { # Function to look at the temporary files that exist
    start_tc=`gdate +%s.%3N`
    echo "Detailed size of temporary files:"
    tot="$(echo "scale=1; "$(ls -lrt "${ROOT_PATH}/.tmp/" | awk '{ total += $5 }; END { print total }')"/1024" | bc)"
    echo "${UNDERLINED}Total size:${NORMAL} $tot Ko"
    echo "$(ls -lrth "${ROOT_PATH}/.tmp/")" >> "$TEMP_PATH/temporary.txt"
    echo "$(tail -n +2 "$TEMP_PATH/temporary.txt")" > "$TEMP_PATH/temporary.txt"
    input="$TEMP_PATH/temporary.txt"
    while IFS= read -r line
    do
        IFS=' ' read -r -a array <<< "$line"
        echo "$(printf "%-25s" "\t- ${array[8]}") ${array[4]}"
    done < "$input"
#    echo "Function: temp_check()" >> "$LOG_PATH"
    end_tc=`gdate +%s.%3N`
    log_time "Function: temp_check()" $start_tc $end_tc >> "$LOG_PATH"
}

temp_clear() { # Function that clear all temporary files
    start_tcl=`gdate +%s.%3N`
    OLDIFS=$IFS
    old_log="$(tail -n 11 "$LOG_PATH")"
    input="$TEMP_PATH/temporary.txt"
    while IFS= read -r line
    do
        IFS=' ' read -r -a array <<< "$line"
        rm "$TEMP_PATH/${array[8]}"
    done < "$input"
    echo "${SOUND}"
    IFS=$OLDIFS
    echo "$old_log" >> "$LOG_PATH"
#    echo "Function: temp_clear()" >> "$LOG_PATH"
    end_tcl=`gdate +%s.%3N`
    log_time "Function: temp_clear()" $start_tcl $end_tcl >> "$LOG_PATH"
}


# --- HELP SECTION --- #
help_fnc() { # Function that display the content of the src/Help.txt file
    start_hf=`gdate +%s.%3N`
    OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "$ROOT_PATH/src/Help.txt")
    for line in $lines
    do
        echo "$line"
    done
    IFS=$OLDIFS
#    echo "Function: help_fnc()" >> "$LOG_PATH"
    end_hf=`gdate +%s.%3N`
    log_time "Function: help_fnc()" $start_hf $end_hf >> "$LOG_PATH"
}
