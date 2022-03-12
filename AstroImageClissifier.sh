#!/usr/local/bin/bash

# Bugg sur la lecture du fichier .log dans la fonction 'undo': impossible de retrouver le dernier 'working directory'
# ajouter des sortie dans le terminal sur le nombre total de photo dans le directory et dans chaque catégorie trouvée
# Ajouter ces infos dans le fichier log
# uniformiser le fichier log pour que chaque exécution donne la même taille de sortie log (remplir avec des lignes vides si besoin)


###########################################################################
###########################################################################
## -------------------- Declaration of the function -------------------- ##
###########################################################################
###########################################################################

Help(){
    echo "This is the Help page"
}

IsPicture(){
    # check for the RAW picture directory
    if [ ! -d "$base_path/outAPN" ];
    then
        echo "There is 'outAPN' directory inside the specified working directory."
        echo "Pleas check the path or rename/create a 'outAPN' directory that contain all the RAW picture from your APN."
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
    # catch and rotate all the picture that aren't in the right (Horizontal (normal)) position
    echo "Search non Horizontal (normal) picture"
    exiftool -filename -if '$orientation ne "Horizontal (normal)"' -r "$base_path/outAPN" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_rot.txt"

    lines=$(cat "$root_path/.tmp/temp_rot.txt")
    for line in $lines
    do
        echo "$base_path/outAPN/${line}" >> "$root_path/.tmp/temp_rotation.txt"
    done

    echo "Bad roation found."
    echo "Rotate the picture..."

    exiftool -@ "$root_path/.tmp/temp_rotation.txt" -orientation="Horizontal (normal)" -overwrite_original_in_place

    echo "done"
}


Biases(){
    ##############
    # - Biases - #
    ##############
    # Catch and move the biases
    echo "\nSearch for the biases..."
    exiftool -filename -if '$shutterspeed eq "1/8000"' -r "$base_path/outAPN" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_biases.txt"

    echo "Biases found."
    echo "Move biases files to the \"biases\" directory..."

    # Check if "biases" directory existe, otherwise create it
    if [ ! -d "$base_path/biases" ];
    then
        mkdir "$base_path/biases"
    fi

    lines=$(cat "$root_path/.tmp/temp_biases.txt")
    for line in $lines
    do
        echo "${line}..."
        mv "$base_path/outAPN"/${line} "$base_path/biases/"
    done
    echo "done"
}


Flats(){
    #############
    # - Flats - #
    #############
    # Catch and move the flats
    echo "\nSearch for the flats..."
    exiftool -filename -if '$MeasuredEV ge 10' -r "$base_path/outAPN" | grep -w "File Name                       :" | sed 's/.*: //' >> "$root_path/.tmp/temp_flats.txt"

    echo "Flats found."
    echo "Move flats files to the \"flats\" directory..."

    # Check if "flats" directory existe, otherwise create it
    if [ ! -d "$base_path/flats" ];
    then
        mkdir "$base_path/flats"
    fi

    lines=$(cat "$root_path/.tmp/temp_flats.txt")
    for line in $lines
    do
        echo "${line}..."
        mv "$base_path/outAPN"/${line} "$base_path/flats/"
    done
    echo "done"
}


CatchDarksLights(){
    #####################
    # - darks & lights- #
    #####################
    # Saerch in all the remaning picture a discontinuity in the naming of the file number.
    # All the picture before the discontinuity will be place in the "lights" directory
    # and all the others will be place in the "darks" directory.

    # Catch and move the lights
    echo "\nSearch for the lights..."

    # The first itetration is to defin the first picture of the directory, so it's a separate loop
    TEST=true
    FIND=false
    PREV_NAME=0 # store the name of the picture befor the last discontinuity
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
                dif=$((${temp%.*}-$CHANGE_NAME)) # calculate the difference between the numerotation of the previous and the current picture
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
    echo "\nSearch for the darks..."

    for ((i=$PREV_NAME; i<$CHANGE_NAME+1; i++))
    do
        echo "IMG_$i.CR3" >> "$root_path/.tmp/temp_darks.txt"
    done
}


Lights(){
    ##############
    # - Lights - #
    ##############
    echo "lights found."
    echo "Move lights files to the \"lights\" directory..."

    # Check if "lights" directory existe, otherwise create it
    if [ ! -d "$base_path/lights" ];
    then
        mkdir "$base_path/lights"
    fi

    lines=$(cat "$root_path/.tmp/temp_lights.txt")
    for line in $lines
    do
        echo "${line}..."
        mv "$base_path/outAPN"/${line} "$base_path/lights/"
    done
    echo "done"
}


Darks(){
    #############
    # - Darks - #
    #############
    echo "darks found."
    echo "Move darks files to the \"darks\" directory..."

    # Check if "darks" directory existe, otherwise create it
    if [ ! -d "$base_path/darks" ];
    then
        mkdir "$base_path/darks"
    fi

    lines=$(cat "$root_path/.tmp/temp_darks.txt")
    for line in $lines
    do
        echo "${line}..."
        mv "$base_path/outAPN"/${line} "$base_path/darks/"
    done
    echo "done"
}


Undo(){
    start1=`gdate +%s.%3N`
    echo "\nClean the directories\n"
    
    # remove the old temporary files
    if [[ ! -e "$root_path/.tmp/temp_biases.txt" || ! -e "$root_path/.tmp/temp_flats.txt" || ! -e "$root_path/.tmp/temp_darks.txt" || ! -e "$root_path/.tmp/temp_lights.txt" || ! -e "$root_path/.tmp/temp_rotation.txt" ]]; then
        echo "Impossible to undo, there is not all the temporary files..."
        echo "\nError: No '.tmp/' directory" >> "$root_path/.tmp/AutoClassifier.log"
        Help
        exit 1
    fi
    
    # search the last working directory in the .log
#    echo "############"
#    echo tail -n 22 ".tmp/AutoClassifier.log"  | grep -w "Working directory:"  | sed 's/.*: //'
#    echo "############"
    base_path="/Volumes/Edwin SSD/5 - Astrophoto/AstroImageClissifier/Test" #$()
    echo $base_path
    cd "$base_path"
    
    echo "move biases..."
    if [ ! -z "$(ls -A "$base_path/biases")" ]; then
        lines=$(cat "$root_path/.tmp/temp_biases.txt")
        for line in $lines
        do
            echo "${line}..."
            mv "$base_path/biases"/${line} "$base_path/outAPN/"
        done
        echo "done"
    else
        echo "No file to move"
    fi
    
    echo "move flats..."
    if [ ! -z "$(ls -A "$base_path/flats")" ]; then
        lines=$(cat "$root_path/.tmp/temp_flats.txt")
        for line in $lines
        do
            echo "${line}..."
            mv "$base_path/flats"/${line} "$base_path/outAPN/"
        done
        echo "done"
    else
        echo "No file to move"
    fi

    echo "move darks..."
    if [ ! -z "$(ls -A "$base_path/darks")" ]; then
        lines=$(cat "$root_path/.tmp/temp_darks.txt")
        for line in $lines
        do
            echo "${line}..."
            mv "$base_path/darks"/${line} "$base_path/outAPN/"
        done
        echo "done"
    else
        echo "No file to move"
    fi

    echo "move lights..."
    if [ ! -z "$(ls -A "$base_path/lights")" ]; then
        lines=$(cat "$root_path/.tmp/temp_lights.txt")
        for line in $lines
        do
            echo "${line}..."
            mv "$base_path/lights"/${line} "$base_path/outAPN/"
        done
        echo "done"
    else
        echo "No file to move"
    fi
        

    echo "rotate picture..."
    if [ -e "$root_path/.tmp/temp_rotation.txt" ];
    then
        exiftool -@ "$root_path/.tmp/temp_rotation.txt" -orientation="Rotate 270 CW" -overwrite_original_in_place
        echo "done\n"
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

    echo "\nAuto classification of astrophotography picture\n"
    
    if [ -z $2 ]; then
        read -p "Enter the directory to classify: " wd
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

    CleanTmp

    echo "\nWorking directory: $base_path" >> "$root_path/.tmp/AutoClassifier.log"
    echo "\nDetailed sub-folder size:\n$(du -h)" >> "$root_path/.tmp/AutoClassifier.log"

    Rotation

    Biases

    Flats

    CatchDarksLights

    Darks

    Lights


    end2=`gdate +%s.%3N`

    runtime_global=$( echo "$end2 - $start1" | bc -l )
    runtime_user=$( echo "$end1 - $start1" | bc -l )
    runtime_command=$( echo "$end2 - $start2" | bc -l )

    echo "\nExecution time: $runtime_global s\n\t- user time: $runtime_user s\n\t- cmd time: $runtime_command s" >> "$root_path/.tmp/AutoClassifier.log"

    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
else
    echo "\nUnknown argument" >> "$root_path/.tmp/AutoClassifier.log"
    echo "Unknown argument ?\n"
    Help
    echo "\n#################\n" >> "$root_path/.tmp/AutoClassifier.log"
fi
