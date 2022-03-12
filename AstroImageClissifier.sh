#!/usr/local/bin/bash

# uniformiser le fichier log pour que chaque exécution donne la même taille de sortie log (remplir avec des lignes vides si besoin)


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
NO_COLOR='\033[m'

OverWrite(){
    sleep 0.05 # sleep for 50ms, juste to see that the line is being overwrite
    printf "\033[1A"  # move cursor one line up
    printf "\033[K"   # delete till end of line
    echo $1
}

Help(){
    echo "This is the Help page"
}

IsPicture(){
    # check for the RAW images directory
    if [ ! -d "$base_path/outAPN" ];
    then
        echo "${RED}Error:${NO_COLOR} There is no 'outAPN/' directory inside the specified working directory."
        echo "Pleas check the path or rename/create a 'outAPN' directory that contain all the RAW images from your APN."
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
    exiftool -filename -if '$orientation ne "Horizontal (normal)"' -r "$base_path/outAPN" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_rot.txt"
    
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_rot.txt") bad rotation found.${NO_COLOR}"
    echo "$(wc -l < "$root_path/.tmp/temp_rot.txt") bad rotation found." >> "$root_path/.tmp/AutoClassifier.log"
    lines=$(cat "$root_path/.tmp/temp_rot.txt")
    for line in $lines
    do
        echo "$base_path/outAPN/${line}" >> "$root_path/.tmp/temp_rotation.txt"
    done

    echo "Rotate images...${BLUE}"

    exiftool -@ "$root_path/.tmp/temp_rotation.txt" -orientation="Horizontal (normal)" -overwrite_original_in_place

    echo "${GREEN}done${NO_COLOR}"
}


Biases(){
    ##############
    # - Biases - #
    ##############
    # Catch and move the biases
    echo "\nSearch for the biases..."
    exiftool -filename -if '$shutterspeed eq "1/8000"' -r "$base_path/outAPN" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_biases.txt"
    
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_biases.txt") biases found.${NO_COLOR}"
    echo "$(wc -l < "$root_path/.tmp/temp_biases.txt") biases found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move biases files to the ${YELLOW}'biases/'${NO_COLOR} directory..."
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
        mv "$base_path/outAPN"/${line} "$base_path/biases/"
    done
    echo "$GREEN done${NO_COLOR}"
}


Flats(){
    #############
    # - Flats - #
    #############
    # Catch and move the flats
    echo "\nSearch for the flats..."
    exiftool -filename -if '$MeasuredEV ge 10' -r "$base_path/outAPN" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_flats.txt"

    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_flats.txt") flats found.${NO_COLOR}"
    echo "$(wc -l < "$root_path/.tmp/temp_flats.txt") flats found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move flats files to the ${YELLOW}'flats/'${NO_COLOR} directory..."
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
        mv "$base_path/outAPN"/${line} "$base_path/flats/"
    done
    echo "$GREEN done${NO_COLOR}"
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
    for FILE in "$base_path/outAPN"/*; do # scann for all the files in the "outAPN" directoy
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
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_lights.txt") lights found.${NO_COLOR}"
    echo "$(wc -l < "$root_path/.tmp/temp_lights.txt") lights found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move lights files to the ${YELLOW}'lights/'${NO_COLOR} directory..."
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
        mv "$base_path/outAPN"/${line} "$base_path/lights/"
    done
    echo "$GREEN done${NO_COLOR}"
}


Darks(){
    #############
    # - Darks - #
    #############
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_darks.txt") darks found.${NO_COLOR}"
    echo "$(wc -l < "$root_path/.tmp/temp_darks.txt") darks found." >> "$root_path/.tmp/AutoClassifier.log"
    
    echo "Move darks files to the ${YELLOW}'darks/'${NO_COLOR} directory..."
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
        mv "$base_path/outAPN"/${line} "$base_path/darks/"
    done
    echo "$GREEN done${NO_COLOR}"
}


Undo(){
    start1=`gdate +%s.%3N`
    echo "\n${MAGENTA}Clean the directories${NO_COLOR}\n"
    
    # remove the old temporary files
    if [[ ! -e "$root_path/.tmp/temp_biases.txt" || ! -e "$root_path/.tmp/temp_flats.txt" || ! -e "$root_path/.tmp/temp_darks.txt" || ! -e "$root_path/.tmp/temp_lights.txt" || ! -e "$root_path/.tmp/temp_rotation.txt" ]]; then
        echo "${RED}Error: no temporary files${NO_COLOR}"
        echo "Impossible to undo, there is not all the temporary files..."
        echo "\nError: No '.tmp/' directory" >> "$root_path/.tmp/AutoClassifier.log"
        Help
        exit 1
    fi
    
    # search the last working directory in the .log
    base_path=$(tail -n 30 ".tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
    echo "${YELLOW}Working directory: ${NO_COLOR}${base_path}\n"
    cd "$base_path"
    
    echo "move biases..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_biases.txt") images${NO_COLOR}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/biases")" ]; then
        lines=$(cat "$root_path/.tmp/temp_biases.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/biases"/${line} "$base_path/outAPN/"
        done
        echo "$GREEN done${NO_COLOR}"
    else
        echo "No file to move"
    fi
    
    echo "move flats..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_flats.txt") images${NO_COLOR}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/flats")" ]; then
        lines=$(cat "$root_path/.tmp/temp_flats.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/flats"/${line} "$base_path/outAPN/"
        done
        echo "$GREEN done${NO_COLOR}"
    else
        echo "No file to move"
    fi

    echo "move darks..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_darks.txt") images${NO_COLOR}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/darks")" ]; then
        lines=$(cat "$root_path/.tmp/temp_darks.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/darks"/${line} "$base_path/outAPN/"
        done
        echo "$GREEN done${NO_COLOR}"
    else
        echo "No file to move"
    fi

    echo "move lights..."
    echo "${BLUE}$(wc -l < "$root_path/.tmp/temp_lights.txt") images${NO_COLOR}"
    echo ""
    if [ ! -z "$(ls -A "$base_path/lights")" ]; then
        lines=$(cat "$root_path/.tmp/temp_lights.txt")
        for line in $lines
        do
            #echo "${line}..."
            OverWrite "${line}..."
            mv "$base_path/lights"/${line} "$base_path/outAPN/"
        done
        echo "$GREEN done${NO_COLOR}"
    else
        echo "No file to move"
    fi
        

    echo "rotate images..."
    if [ -e "$root_path/.tmp/temp_rotation.txt" ];
    then
        echo "${BLUE}\c"
        exiftool -@ "$root_path/.tmp/temp_rotation.txt" -orientation="Rotate 270 CW" -overwrite_original_in_place
        echo "$GREEN done${NO_COLOR}\n"
    fi
    
    end1=`gdate +%s.%3N`

    runtime=$( echo "$end1 - $start1" | bc -l )
    
    echo "\nExecution time: $runtime s" >> "$root_path/.tmp/AutoClassifier.log"
    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
}



###########################################################################
###########################################################################
## ------------------------------- Main -------------------------------- ##
###########################################################################
###########################################################################

root_path=$(pwd)

if [ ! -d "$root_path/.tmp" ];
then
    mkdir "$root_path/.tmp"
fi

echo "Execution date: $(date)" >> "$root_path/.tmp/AutoClassifier.log"
echo "\nArguments : $1 $2" >> "$root_path/.tmp/AutoClassifier.log"
echo "\nUser: $USER" >> "$root_path/.tmp/AutoClassifier.log"
echo "\nRoot directory: $root_path" >> "$root_path/.tmp/AutoClassifier.log"

if [[ $1 == "-u" || $1 == "-undo" ]];
then
    Undo
    exit 1
fi

if [[ $1 == "-h" || $1 == "-H" || $1 == "-help" || $1 == "-Help" ]];
then
    Help
    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
    exit 1
fi


if [[ $1 == "-r" || $1 == "-run" ]];
then
    start1=`gdate +%s.%3N`

    echo "\n${MAGENTA}Auto classification of astrophotography image${NO_COLOR}\n"
    
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
        Help
        exit 1;
    fi

    echo "\nWorking directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
    
    nb_files=$(ls "$base_path/outAPN" | wc -l | xargs)
    echo "\n$nb_files images to process:" >> "$root_path/.tmp/AutoClassifier.log"
    echo "There are $nb_files images to process\n"
    
    if [ $nb_files == 0 ]; then
        echo "${RED}Error: No files to process${NO_COLOR}"
        Help
    else
        if [ -z $3 ]; then
            read -p "Do you want to run the script (Y/n): " sure
        else
            sure=$3
        fi
        
        if [[ ($sure != "n" || $sure != "-n") && ($sure == "Y" || $sure == "y" || $sure == "-y" || $sure == "-Y") ]]; then
            echo "${MAGENTA}Start processing...${NO_COLOR}\n"
            CleanTmp            # Clean temporary files
            Rotation            # Rotate image in Horizontal mode
            Biases              # Extract the biases
            Flats               # Extract the flats
            CatchDarksLights    # Differenciat the darks and the lights
            Darks               # Extract the darks
            Lights              # Extract the lights
        else
            echo "${RED}Abort process${NO_COLOR}"
        fi
        
        echo "\nDetailed sub-folder size (after process):\n$(du -h)" >> "$root_path/.tmp/AutoClassifier.log"
    fi
    
    end2=`gdate +%s.%3N`

    runtime_global=$( echo "$end2 - $start1" | bc -l )
    runtime_user=$( echo "$end1 - $start1" | bc -l )
    runtime_command=$( echo "$end2 - $start2" | bc -l )

    echo "\nExecution time: $runtime_global s\n\t- user time: $runtime_user s\n\t- cmd time: $runtime_command s" >> "$root_path/.tmp/AutoClassifier.log"

    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
else
    echo "\nUnknown argument" >> "$root_path/.tmp/AutoClassifier.log"
    echo "${RED}Error: Unknown argument ?${NO_COLOR}\n"
    Help
    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
fi
