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
                        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} orientation value unknown.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not enought folder names or bad delimiter.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
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
                    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} not a number.${NORMAL}"
                fi
                ;;
            ("reset")
                echo "\n${BOLD}${UNDERLINED}Reset parameters${NORMAL}"
                rm "$ROOT_PATH/src/parameters.config"
                cp "$ROOT_PATH/src/.parameters.config" "$ROOT_PATH/src/parameters.config"
                echo "${GREEN}done${NORMAL}"
                ;;
            (*)
                echo "\n${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED}${BOLD} Wrong value, get: ${ITALIC}$arg${NORMAL}"
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
        nb_files=$(< "$TEMP_PATH/temp_rotation.txt" wc -l)
    fi
    
#    nb_files=$(< "$TEMP_PATH/temp_rotation.txt" wc -l)
#    if [ -z "$nb_files" ]; then
#        nb_files="0"
#    else
#        nb_files=$(echo "$nb_files" | sed 's/ //g')
#    fi
    end_r=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- rotation()") ($nb_files)" $start_r $end_r >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

biases(){
    start_b=`gdate +%s.%3N`
    ##############
    # - Biases - #
    ##############
    # Catch and move the biases
    echo "\nSearch for the biases..."
    exiftool -filename -if '$shutterspeed eq "1/8000"' -r "$BASE_PATH/RAW" | grep "File Name" | sed 's/.*: //' >> "$TEMP_PATH/temp_biases.txt"
    
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_biases.txt") biases found.${NORMAL}"
    
    echo "Move biases files to the ${ITALIC}${BOLD}'biases/'${NORMAL} directory...\n"

    make_dir "${FOLDERS_NAMES[0]}"

    lines=$(cat "$TEMP_PATH/temp_biases.txt")
    for line in $lines
    do
        overwrite "${line}..."
        mv "$BASE_PATH/RAW"/${line} "$BASE_PATH/biases/"
    done
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_biases.txt" ]; then
        nb_files=$(< "$TEMP_PATH/temp_biases.txt" wc -l)
    fi
#    nb_files=$(< "$TEMP_PATH/temp_biases.txt" wc -l)
#    if [ -z "$nb_files" ]; then
#        nb_files="0"
#    else
#        nb_files=$(echo "$nb_files" | sed 's/ //g')
#    fi
    end_b=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- biases()") ($nb_files)" $start_b $end_b >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

flats(){
    start_f=`gdate +%s.%3N`
    #############
    # - Flats - #
    #############
    # Catch and move the flats
    echo "\nSearch for the flats..."
    exiftool -filename -if '$MeasuredEV ge 10' -r "$BASE_PATH/RAW" | grep "File Name" | sed 's/.*: //' >> "$TEMP_PATH/temp_flats.txt"

    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_flats.txt") flats found.${NORMAL}"
    
    echo "Move flats files to the ${ITALIC}${BOLD}'flats/'${NORMAL} directory..."
    echo ""

    make_dir "${FOLDERS_NAMES[2]}"

    lines=$(cat "$TEMP_PATH/temp_flats.txt")
    for line in $lines
    do
        overwrite "${line}..."
        mv "$BASE_PATH/RAW"/${line} "$BASE_PATH/flats/"
    done
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_flats.txt" ]; then
        nb_files=$(< "$TEMP_PATH/temp_flats.txt" wc -l)
    fi
#    nb_files=$(< "$TEMP_PATH/temp_flats.txt" wc -l)
#    if [ -z "$nb_files" ]; then
#        nb_files="0"
#    else
#        nb_files=$(echo "$nb_files" | sed 's/ //g')
#    fi
    end_f=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- flats()") ($nb_files)" $start_f $end_f >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

catch_darks_lights(){
    start_cdl=`gdate +%s.%3N`
    #####################
    # - darks & lights- #
    #####################
    # Saerch in all the remaning images a discontinuity in the naming of the file number.
    # All the images before the discontinuity will be place in the "lights" directory
    # and all the others will be place in the "darks" directory.

    # Catch and move the lights
    echo "\nSearch for lights and darks..."

    # The first itetration is to defin the first image of the directory, so it's a separate loop
    TEST=true
    FIND=false
    PREV_NAME=0 # store the name of the image before the last discontinuity
    CHANGE_NAME=0 # the counter for the loop
    for FILE in "$BASE_PATH/RAW"/*; do # scann for all the files in the "RAW" directoy
        if ! $FIND; then
            if $TEST; then # check if it's the first file
                TEST=false # turn the boolean to 'false'
                temp=${FILE#*_}
                PREV_NAME=${temp%.*}
                CHANGE_NAME=PREV_NAME
            else
                temp=${FILE#*_}
                dif=$((${temp%.*}-$CHANGE_NAME)) # calculate the difference between the numerotation of the previous and the current image
                if [ $dif -gt 5 ]; then # if the difference is greater than the threshold, it's a discontinuity
                    for ((i=$PREV_NAME; i<$CHANGE_NAME+1; i++))
                    do
                        echo "IMG_$i.CR3" >> "$TEMP_PATH/temp_lights.txt"
                    done
                    PREV_NAME=${temp%.*}
                fi
                CHANGE_NAME=${temp%.*}
            fi
        else
            temp=${FILE#*_}
            CHANGE_NAME=${temp%.*}
        fi
    done
        
    # Catch darks to move
    for ((i=$PREV_NAME; i<$CHANGE_NAME+1; i++))
    do
        echo "IMG_$i.CR3" >> "$TEMP_PATH/temp_darks.txt"
    done
    end_cdl=`gdate +%s.%3N`
    log_time "- catch_darks_lights()" $start_cdl $end_cdl >> "$LOG_PATH"
}

lights(){
    start_l=`gdate +%s.%3N`
    ##############
    # - Lights - #
    ##############
    # move the lights
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_lights.txt") lights found.${NORMAL}"
    
    echo "Move lights files to the ${ITALIC}${BOLD}'lights/'${NORMAL} directory..."
    echo ""

    make_dir "${FOLDERS_NAMES[3]}"

    lines=$(cat "$TEMP_PATH/temp_lights.txt")
    for line in $lines
    do
        overwrite "${line}..."
        mv "$BASE_PATH/RAW"/${line} "$BASE_PATH/lights/"
    done
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_lights.txt" ]; then
        nb_files=$(< "$TEMP_PATH/temp_lights.txt" wc -l)
    fi
#    nb_files=$(< "$TEMP_PATH/temp_lights.txt" wc -l)
#    if [ -z "$nb_files" ]; then
#        nb_files="0"
#    else
#        nb_files=$(echo "$nb_files" | sed 's/ //g')
#    fi
    end_l=`gdate +%s.%3N`
    log_time "$(printf "%-15s" "- lights()") ($nb_files)" $start_l $end_l >> "$LOG_PATH"
    echo "${GREEN}done${NORMAL}"
}

darks(){
    start_d=`gdate +%s.%3N`
    #############
    # - Darks - #
    #############
    # move the darks
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_darks.txt") darks found.${NORMAL}"
    
    echo "Move darks files to the ${ITALIC}${BOLD}'darks/'${NORMAL} directory..."
    echo ""

    make_dir "${FOLDERS_NAMES[1]}"

    lines=$(cat "$TEMP_PATH/temp_darks.txt")
    for line in $lines
    do
        overwrite "${line}..."
        mv "$BASE_PATH/RAW"/${line} "$BASE_PATH/darks/"
    done
    
    nb_files="0"
    if [ -e "$TEMP_PATH/temp_darks.txt" ]; then
        nb_files=$(< "$TEMP_PATH/temp_darks.txt" wc -l)
    fi
#    nb_files=$(< "$TEMP_PATH/temp_darks.txt" wc -l)
#    if [ -z "$nb_files" ]; then
#        nb_files="0"
#    else
#        nb_files=$(echo "$nb_files" | sed 's/ //g')
#    fi
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


# --- UNDO SECTION --- #
undo_process() { # Function to undo the previous classification
    start_upr=`gdate +%s.%3N`
    echo $(pwd)
    
#    # check if there is temporary files
#    if [[ ! -e "$TEMP_PATH/temp_biases.txt" || ! -e "$TEMP_PATH/temp_flats.txt" || ! -e "$TEMP_PATH/temp_darks.txt" || ! -e "$TEMP_PATH/temp_lights.txt" ]]; then
#        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no temporary files${NORMAL}"
#        echo "Impossible to undo, there is not all the temporary files..."
#        Help
#        exit 1
#    fi
    
    nb_files_b=0
    nb_files_f=0
    nb_files_d=0
    nb_files_l=0
    nb_files_r=0
    nb_files_tot=0
    
    echo "${YELLOW}Working directory: ${NORMAL}${BASE_PATH}"
    
    echo "\nmove biases..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_biases.txt") images${NORMAL}\n"
    if [[ ! -z "$(ls -A "$BASE_PATH/biases")" && -e "$TEMP_PATH/temp_biases.txt" ]]; then
        lines=$(cat "$TEMP_PATH/temp_biases.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/biases"/${line} "$BASE_PATH/RAW/"
            nb_files_b=$((nb_files_b+1))
        done
        echo "${GREEN}done${NORMAL}"
    else
        echo "No file to move"
    fi
    
    echo "\nmove flats..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_flats.txt") images${NORMAL}\n"
    if [[ ! -z "$(ls -A "$BASE_PATH/flats")" && -e "$TEMP_PATH/temp_flats.txt" ]]; then
        lines=$(cat "$TEMP_PATH/temp_flats.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/flats"/${line} "$BASE_PATH/RAW/"
            nb_files_f=$((nb_files_f+1))
        done
        echo "${GREEN}done${NORMAL}"
    else
        echo "No file to move"
    fi
    
    echo "\nmove darks..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_darks.txt") images${NORMAL}\n"
    if [[ ! -z "$(ls -A "$BASE_PATH/darks")" && -e "$TEMP_PATH/temp_darks.txt" ]]; then
        lines=$(cat "$TEMP_PATH/temp_darks.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/darks"/${line} "$BASE_PATH/RAW/"
            nb_files_d=$((nb_files_d+1))
        done
        echo "${GREEN}done${NORMAL}"
    else
        echo "No file to move"
    fi

    echo "\nmove lights..."
    echo "${BLUE}$(wc -l < "$TEMP_PATH/temp_lights.txt") images${NORMAL}\n"
    if [[ ! -z "$(ls -A "$BASE_PATH/lights")" && -e "$TEMP_PATH/temp_lights.txt" ]]; then
        lines=$(cat "$TEMP_PATH/temp_lights.txt")
        for line in $lines
        do
            overwrite "${line}..."
            mv "$BASE_PATH/lights"/${line} "$BASE_PATH/RAW/"
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
        echo "\t${array[4]} \t${BLUE}${array[8]}${NORMAL}"
    done < "$input"
#    echo "Function: temp_check()" >> "$LOG_PATH"
    end_tc=`gdate +%s.%3N`
    log_time "Function: temp_check()" $start_tc $end_tc >> "$LOG_PATH"
}

temp_clear() { # Function that clear all temporary files
    start_tcl=`gdate +%s.%3N`
    OLDIFS=$IFS
    old_log="$(tail -n 11 "$LOG_PATH")"
    echo "$old_log"
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
