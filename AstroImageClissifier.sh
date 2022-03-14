#!/usr/local/bin/bash

# pour la commande de visualisation / suppression des fichiers temporaires, ajouter la visualisation sous forme d'arbre de fichier avec en plus la taille

###########################################################################
###########################################################################
## -------------------- Declaration of the function -------------------- ##
###########################################################################
###########################################################################

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
TITLE="" #'\033#6'
SOUND='\007'

OverWrite(){
    sleep 0.05 # sleep for 50ms, juste to see that the line is being overwrite
    printf "\033[1A"  # move cursor one line up
    printf "\033[K"   # delete till end of line
    echo $1
}

Help(){
    echo "\t${YELLOW}${BOLD}${UNDERLINED}${TITLE}This is the Help page${NORMAL}\n"
    echo "${BOLD}${UNDERLINED}Description:${NORMAL}"
    echo "This utility command script help you to classify your RAW images, out of your APN SD card, into 4 folders: Biases, Darks, Flats and Lights. Then you can easily use those folder to process your image, like withh ${ITALIC}${BOLD}Siril${NORMAL}.\nYou need to put all your image in the same folder named ${Bold}${ITALIC}'RAW'${NORMAL}, which need to be in another directory (${DIM}the working directory${NORMAL}), for instance named as you picture object ${BOLD}${ITALIC}\"Orion M42\"${NORMAL}."
        echo "Your folder architecture tree need to be like this:\n"
    echo "\t${BOLD}${UNDERLINED}Befor classification${NORMAL}\t\t\t${BOLD}${UNDERLINED}After classification${NORMAL}"
    echo "${BOLD}\t\t\t\t\t|"
    echo "\tOrion M42\t\t\t|\tOrion M42"
    echo "\t   ${DIM}|–>${NORMAL}${BOLD} RAW\t\t\t|\t   ${DIM}|->${NORMAL}${BOLD} Biases"
    echo "\t\t${DIM}|–>${NORMAL}${BOLD} ${BLUE}IMG_0001.CR3${NORMAL}${BOLD}\t|\t   ${DIM}|\t|->${NORMAL}${BOLD} ${BLUE}IMG_0001.CR3${NORMAL}${BOLD}"
    echo "\t\t${DIM}|${NORMAL}${BOLD} ...\t\t\t|\t   ${DIM}|\t|${NORMAL}${BOLD} ..."
    echo "\t\t${DIM}|–>${NORMAL}${BOLD} ${BLUE}IMG_0120.CR3${NORMAL}${BOLD}\t|\t   ${DIM}|\t|->${NORMAL}${BOLD} ${BLUE}IMG_0010.CR3${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|->${NORMAL}${BOLD} Darks"
    echo "\t\t\t\t\t|\t   ${DIM}|\t|–>${NORMAL}${BOLD} ${BLUE}IMG_0011.CR3${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|\t|${NORMAL}${BOLD} ..."
    echo "\t\t\t\t\t|\t   ${DIM}|\t|–>${NORMAL}${BOLD} ${BLUE}IMG_0020.CR3${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|->${NORMAL}${BOLD} Flats"
    echo "\t\t\t\t\t|\t   ${DIM}|\t|–>${NORMAL}${BOLD} ${BLUE}IMG_0021.CR3${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|\t|${NORMAL}${BOLD} ..."
    echo "\t\t\t\t\t|\t   ${DIM}|\t|–>${NORMAL}${BOLD} ${BLUE}IMG_0030.CR3${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|->${NORMAL}${BOLD} Lights"
    echo "\t\t\t\t\t|\t   ${DIM}|\t|–>${NORMAL}${BOLD} ${BLUE}IMG_0031.CR3${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|\t|${NORMAL}${BOLD} ..."
    echo "\t\t\t\t\t|\t   ${DIM}|\t|–>${NORMAL}${BOLD} ${BLUE}IMG_0120.CR3${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|${NORMAL}${BOLD}"
    echo "\t\t\t\t\t|\t   ${DIM}|->${NORMAL}${BOLD} RAW"
    echo "\t\t\t\t\t|\t   ${DIM}|\t|–>${NORMAL}${BOLD} ${RED}Empty${NORMAL}"
    echo ""
    echo "\n${BOLD}${UNDERLINED}Option:${NORMAL}"
    echo "\t-r ${DIM}(-run)${NORMAL}: lunch the clissification process. Add the path to the RAW images directory.\n\t\tYou can add -Y to process directly the images."
    echo "\t-u ${DIM}(-undo)${NORMAL}: undo the last process, move back the images and rotate them as before.\n\t\tYou can add -Y to undo directly the last action"
    echo "\t-t ${DIM}(-temporary)${NORMAL}: show the volume of the .tmp files.\n\t\tYou can clean up the files if they take too much space."
    echo "\t-h ${DIM}(-help)${NORMAL}: show this help page."
    echo "\n${BOLD}${UNDERLINED}Exemples:${NORMAL}"
    echo "\tsh AstroImageClissifier.sh -r Test -Y \n\t\t${BOLD}-->${NORMAL} Lunch direclty the classification of the images in the folder ${ITALIC}'Test'${NORMAL}"
    echo "\tsh AstroImageClissifier.sh -u \n\t\t${BOLD}-->${NORMAL} Undo the last classification process, with -Y you can skip the confirmation"
    echo ""
}

IsPicture(){
    # check for the RAW images directory
    if [ ! -d "$base_path/RAW" ];
    then
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} There is no ${ITALIC}'RAW/'${NORMAL}${RED} directory inside the specified working directory.${NORMAL}"
        echo "Please ${BOLD}check the path${NORMAL} or rename / create a ${ITALIC}'RAW'${NORMAL} directory that contain all the RAW images out of your APN."
        return 1
    fi
    return 0
}


CleanTmp(){
    # remove the old temporary files
    if [ -e "$root_path/.tmp/temp_biases.txt" ];
    then
        rm "$root_path/.tmp/temp_biases.txt"
    fi

    if [ -e "$root_path/.tmp/temp_flats.txt" ];
    then
        rm "$root_path/.tmp/temp_flats.txt"
    fi

    if [ -e "$root_path/.tmp/temp_darks.txt" ];
    then
        rm "$root_path/.tmp/temp_darks.txt"
    fi

    if [ -e "$root_path/.tmp/temp_lights.txt" ];
    then
        rm "$root_path/.tmp/temp_lights.txt"
    fi

    if [ -e "$root_path/.tmp/temp_rot.txt" ];
    then
        rm "$root_path/.tmp/temp_rot.txt"
    fi

    if [ -e "$root_path/.tmp/temp_rotation.txt" ];
    then
        rm "$root_path/.tmp/temp_rotation.txt"
    fi
}


Rotation(){
    ###############
    # - Roation - #
    ###############
    # catch and rotate all the images that aren't in the right (Horizontal (normal)) position
    echo "Search non Horizontal (normal) image"
    exiftool -filename -if '$orientation ne "Horizontal (normal)"' -r "$base_path/RAW" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_rot.txt"
    
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_rot.txt") bad rotation found.${NORMAL}"
    echo "$(wc -l < "$root_path/.tmp/temp_rot.txt") bad rotation found." >> "$root_path/.tmp/AutoClassifier.log"
    lines=$(cat "$root_path/.tmp/temp_rot.txt")
    for line in $lines
    do
        echo "$base_path/RAW/${line}" >> "$root_path/.tmp/temp_rotation.txt"
    done

    echo "Rotate images...${BLUE}"

    exiftool -@ "$root_path/.tmp/temp_rotation.txt" -orientation="Horizontal (normal)" -overwrite_original_in_place

    echo "${GREEN}done${NORMAL}"
}


Biases(){
    ##############
    # - Biases - #
    ##############
    # Catch and move the biases
    echo "\nSearch for the biases..."
    exiftool -filename -if '$shutterspeed eq "1/8000"' -r "$base_path/RAW" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_biases.txt"
    
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_biases.txt") biases found.${NORMAL}"
    echo "$(wc -l < "$root_path/.tmp/temp_biases.txt") biases found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move biases files to the ${YELLOW}'biases/'${NORMAL} directory..."
    echo ""

    # Check if "biases" directory existe, otherwise create it
    if [ ! -d "$base_path/biases" ];
    then
        mkdir "$base_path/biases"
    fi

    lines=$(cat "$root_path/.tmp/temp_biases.txt")
    for line in $lines
    do
        #echo "${line}..."
        OverWrite "${line}..."
        mv "$base_path/RAW"/${line} "$base_path/biases/"
    done
    echo "$GREEN done${NORMAL}"
}


Flats(){
    #############
    # - Flats - #
    #############
    # Catch and move the flats
    echo "\nSearch for the flats..."
    exiftool -filename -if '$MeasuredEV ge 10' -r "$base_path/RAW" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_flats.txt"

    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_flats.txt") flats found.${NORMAL}"
    echo "$(wc -l < "$root_path/.tmp/temp_flats.txt") flats found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move flats files to the ${YELLOW}'flats/'${NORMAL} directory..."
    echo ""

    # Check if "flats" directory existe, otherwise create it
    if [ ! -d "$base_path/flats" ];
    then
        mkdir "$base_path/flats"
    fi

    lines=$(cat "$root_path/.tmp/temp_flats.txt")
    for line in $lines
    do
        #echo "${line}..."
        OverWrite "${line}..."
        mv "$base_path/RAW"/${line} "$base_path/flats/"
    done
    echo "$GREEN done${NORMAL}"
}


CatchDarksLights(){
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
    for FILE in "$base_path/RAW"/*; do # scann for all the files in the "RAW" directoy
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
                        echo "IMG_$i.CR3" >> "$root_path/.tmp/temp_lights.txt"
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
        
    # Catch and move the darks
    for ((i=$PREV_NAME; i<$CHANGE_NAME+1; i++))
    do
        echo "IMG_$i.CR3" >> "$root_path/.tmp/temp_darks.txt"
    done
}


Lights(){
    ##############
    # - Lights - #
    ##############
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_lights.txt") lights found.${NORMAL}"
    echo "$(wc -l < "$root_path/.tmp/temp_lights.txt") lights found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move lights files to the ${YELLOW}'lights/'${NORMAL} directory..."
    echo ""

    # Check if "lights" directory existe, otherwise create it
    if [ ! -d "$base_path/lights" ];
    then
        mkdir "$base_path/lights"
    fi

    lines=$(cat "$root_path/.tmp/temp_lights.txt")
    for line in $lines
    do
        #echo "${line}..."
        OverWrite "${line}..."
        mv "$base_path/RAW"/${line} "$base_path/lights/"
    done
    echo "$GREEN done${NORMAL}"
}


Darks(){
    #############
    # - Darks - #
    #############
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_darks.txt") darks found.${NORMAL}"
    echo "$(wc -l < "$root_path/.tmp/temp_darks.txt") darks found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move darks files to the ${YELLOW}'darks/'${NORMAL} directory..."
    echo ""

    # Check if "darks" directory existe, otherwise create it
    if [ ! -d "$base_path/darks" ];
    then
        mkdir "$base_path/darks"
    fi

    lines=$(cat "$root_path/.tmp/temp_darks.txt")
    for line in $lines
    do
        #echo "${line}..."
        OverWrite "${line}..."
        mv "$base_path/RAW"/${line} "$base_path/darks/"
    done
    echo "$GREEN done${NORMAL}"
}


Undo(){
    start1=`gdate +%s.%3N`
    echo "\n${YELLOW}${BOLD}${UNDERLINED}${TITLE}Undo previous process${NORMAL}\n"
    echo $(pwd)
    
    # check if there is temporary files
    if [[ ! -e "$root_path/.tmp/temp_biases.txt" || ! -e "$root_path/.tmp/temp_flats.txt" || ! -e "$root_path/.tmp/temp_darks.txt" || ! -e "$root_path/.tmp/temp_lights.txt" || ! -e "$root_path/.tmp/temp_rotation.txt" ]]; then
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} no temporary files${NORMAL}"
        echo "Impossible to undo, there is not all the temporary files..."
        echo "Error: No '.tmp/' directory" >> "$root_path/.tmp/AutoClassifier.log"
        Help
        exit 1
    fi
    
    echo "${YELLOW}Working directory: ${NORMAL}${base_path}\n"
    
    echo "move biases..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_biases.txt") images${NORMAL}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/biases")" ]; then
        lines=$(cat "$root_path/.tmp/temp_biases.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/biases"/${line} "$base_path/RAW/"
        done
        echo "$GREEN done${NORMAL}"
    else
        echo "No file to move"
    fi
    
    echo "move flats..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_flats.txt") images${NORMAL}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/flats")" ]; then
        lines=$(cat "$root_path/.tmp/temp_flats.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/flats"/${line} "$base_path/RAW/"
        done
        echo "$GREEN done${NORMAL}"
    else
        echo "No file to move"
    fi

    echo "move darks..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_darks.txt") images${NORMAL}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/darks")" ]; then
        lines=$(cat "$root_path/.tmp/temp_darks.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/darks"/${line} "$base_path/RAW/"
        done
        echo "$GREEN done${NORMAL}"
    else
        echo "No file to move"
    fi

    echo "move lights..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_lights.txt") images${NORMAL}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/lights")" ]; then
        lines=$(cat "$root_path/.tmp/temp_lights.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/lights"/${line} "$base_path/RAW/"
        done
        echo "$GREEN done${NORMAL}"
    else
        echo "No file to move"
    fi
        

    echo "rotate images..."
    if [ -e "$root_path/.tmp/temp_rotation.txt" ];
    then
        echo "${BLUE}\c"
        exiftool -@ "$root_path/.tmp/temp_rotation.txt" -orientation="Rotate 270 CW" -overwrite_original_in_place
        echo "$GREEN done${NORMAL}\n"
    fi
    
    end1=`gdate +%s.%3N`

    runtime=$( echo "$end1 - $start1" | bc -l )
    
    echo "Execution time: $runtime s" >> "$root_path/.tmp/AutoClassifier.log"
    printf '\n%.0s' {1..15} >> "$root_path/.tmp/AutoClassifier.log"
    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
}

Temporary() {
    echo "\n${YELLOW}${BOLD}${UNDERLINED}${TITLE}Preview temporary files${NORMAL}\n"
    echo "Detailed size of temporary files:"
    tot="$(echo "scale=1; "$(ls -lrt "${root_path}/.tmp/" | awk '{ total += $5 }; END { print total }')"/1024" | bc)"
    echo "${YELLOW}Total size of the temporary folder: ${NORMAL}$tot Ko"
    echo "Size of temporary files: $tot Ko" >> "$root_path/.tmp/AutoClassifier.log"
    echo "$(ls -lrth "${root_path}/.tmp/")" >> "$root_path/.tmp/temporary.txt"
    echo "$(tail -n +2 "$root_path/.tmp/temporary.txt")" > "$root_path/.tmp/temporary.txt"
    input="$root_path/.tmp/temporary.txt"
    while IFS= read -r line
    do
        IFS=' ' read -r -a array <<< "$line"
        echo "\t${array[4]} \t${BLUE}${array[8]}${NORMAL}"
    done < "$input"
}


###########################################################################
###########################################################################
## ------------------------------- Main -------------------------------- ##
###########################################################################
###########################################################################

root_path=$(pwd)
# check the existence of the temporary folder
if [ ! -d "$root_path/.tmp" ];
then
    mkdir "$root_path/.tmp"
fi

# output the basis log informations
echo "Execution date: $(date)" >> "$root_path/.tmp/AutoClassifier.log"
echo "Arguments : $1 $2" >> "$root_path/.tmp/AutoClassifier.log"
echo "User: $USER" >> "$root_path/.tmp/AutoClassifier.log"
echo "Root directory: $root_path" >> "$root_path/.tmp/AutoClassifier.log"

# Undo process
if [[ $1 == "-u" || $1 == "-undo" ]];
then
    # search the last working directory in the .log
    base_path=$(tail -n 24 ".tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
    echo "Working directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
    nb_files=$(ls "$base_path/lights" | wc -l | xargs)
    if [ $nb_files == 0 ]; then
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} No files to undo${NORMAL}"
        echo "Error: No files to undo" >> "$root_path/.tmp/AutoClassifier.log"
        printf '\n%.0s' {1..15} >> "$root_path/.tmp/AutoClassifier.log"
        echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
        exit 1
    else
        if [ -z $2 ]; then
            read -p "Do you want to undo the last action (Y/n): " sure
        else
            sure=$2
        fi
        
        if [[ $sure == "Y" || $sure == "y" || $sure == "-y" || $sure == "-Y" ]]; then
            Undo
            echo "${SOUND}"
            exit 1
        else
            echo "${RED}Abort undo${NORMAL}"
            echo "Abort undo" >> "$root_path/.tmp/AutoClassifier.log"
            printf '\n%.0s' {1..15} >> "$root_path/.tmp/AutoClassifier.log"
            echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
            exit 1
        fi
    fi
fi

# Temporary files check process
if [[ $1 == "-t" || $1 == "-T" || $1 == "-temporary" || $1 == "-Temporary" ]];
then
    # search the last working directory in the .log
    base_path=$(tail -n 24 ".tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
    echo "Working directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
    echo "Temporary files check" >> "$root_path/.tmp/AutoClassifier.log"
    Temporary
    
    echo "\n${RED}${BOLD}${UNDERLINED}${BLINKING}!!! Warning !!!${NORMAL}${RED}\nThis operation cannot be cancelled !\n${NORMAL}"
    read -p "Do you want to clean up the temporary files (Y/n)? " res
    if [[ $res == "Y" || $res == "y" ]]; then
        base_path=$(tail -n 24 ".tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
        input="$root_path/.tmp/temporary.txt"
        while IFS= read -r line
        do
            IFS=' ' read -r -a array <<< "$line"
            rm "$root_path/.tmp/${array[8]}"
        done < "$input"
        rm "$root_path/.tmp/temporary.txt"
        # output the basis log informations
        echo "Execution date: $(date)" >> "$root_path/.tmp/AutoClassifier.log"
        echo "Arguments : -t" >> "$root_path/.tmp/AutoClassifier.log"
        echo "User: $USER" >> "$root_path/.tmp/AutoClassifier.log"
        echo "Root directory: $root_path" >> "$root_path/.tmp/AutoClassifier.log"
        echo "Working directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
        echo "Temporary files cleanning" >> "$root_path/.tmp/AutoClassifier.log"
        printf '\n%.0s' {1..15} >> "$root_path/.tmp/AutoClassifier.log"
        echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
        echo "${SOUND}"
    else
        printf '\n%.0s' {1..14} >> "$root_path/.tmp/AutoClassifier.log"
        echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
        rm "$root_path/.tmp/temporary.txt"
    fi
    exit 1
fi

# Help process
if [[ $1 == "-h" || $1 == "-H" || $1 == "-help" || $1 == "-Help" ]];
then
    # search the last working directory in the .log
    base_path=$(tail -n 24 ".tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
    echo "Working directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
    Help
    echo "Help" >> "$root_path/.tmp/AutoClassifier.log"
    printf '\n%.0s' {1..15} >> "$root_path/.tmp/AutoClassifier.log"
    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
    exit 1
fi

# Nominal process
if [[ $1 == "-r" || $1 == "-run" ]];
then
    start1=`gdate +%s.%3N`

    echo "\n${YELLOW}${BOLD}${UNDERLINED}${TITLE}Auto classification of astrophotography image${NORMAL}\n"
    
    if [ -z $2 ]; then
        read -p "Enter the folder to be filed: " wd
    else
        wd=$2
    fi
    
    end1=`gdate +%s.%3N`
    start2=`gdate +%s.%3N`

    cd "${wd}"

    base_path=$(pwd)

    IsPicture
    if [ $? == 1 ];
    then
        echo "\n"
        Help
        exit 1;
    fi

    echo "Working directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
    
    nb_files=$(ls "$base_path/RAW" | wc -l | xargs)
    echo "$nb_files images to process:" >> "$root_path/.tmp/AutoClassifier.log"
    echo "There are $nb_files images to process\n"
    
    if [ $nb_files == 0 ]; then
        echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} No files to process${NORMAL}"
        Help
    else
        if [ -z $3 ]; then
            read -p "Do you want to run the script (Y/n): " sure
        else
            sure=$3
        fi
        
        if [[ $sure == "Y" || $sure == "y" || $sure == "-y" || $sure == "-Y" ]]; then
            echo "${MAGENTA}Start processing${BLINKING}...${NORMAL}\n"
            CleanTmp            # Clean temporary files
            Rotation            # Rotate image in Horizontal mode
            Biases              # Extract the biases
            Flats               # Extract the flats
            CatchDarksLights    # Differenciat the darks and the lights
            Darks               # Extract the darks
            Lights              # Extract the lights
            echo "${SOUND}"
        else
            echo "${RED}Abort process${NORMAL}"
            echo "Abort process" >> "$root_path/.tmp/AutoClassifier.log"
        fi
        
        echo "Detailed sub-folder size (after process):\n$(du -h)" >> "$root_path/.tmp/AutoClassifier.log"
    fi
    
    end2=`gdate +%s.%3N`

    runtime_global=$( echo "$end2 - $start1" | bc -l )
    runtime_user=$( echo "$end1 - $start1" | bc -l )
    runtime_command=$( echo "$end2 - $start2" | bc -l )

    echo "Execution time: $runtime_global s\n\t- user time: $runtime_user s\n\t- cmd time: $runtime_command s" >> "$root_path/.tmp/AutoClassifier.log"

    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
else
    # search the last working directory in the .log
    base_path=$(tail -n 24 ".tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
    echo "Working directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
    echo "${RED}${BOLD}${UNDERLINED}Error:${NORMAL}${RED} Unknown argument ?${NORMAL}\n"
    echo "Error: Unknown argument ?" >> "$root_path/.tmp/AutoClassifier.log"
    Help
    printf '\n%.0s' {1..15} >> "$root_path/.tmp/AutoClassifier.log"
    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
fi
