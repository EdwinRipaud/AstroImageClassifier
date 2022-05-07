#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#


#####################
# - Next features - #
#####################
# TODO: Mettre en forme les sorties dans le termianl pour le partie d'execution des scripts.
# TODO: ajouter dans les logs les opération sur les exécution de script SiriL

# TODO: prendre des screen du finder pour mettre dans le README.md pour visualiser l'arrangement des dossiers avant, après classification et après un script
# TODO: changer l'algo de détection des darks / lights en utilisant la valeur moyenne des pixels avec magick identify, si possible trouver un moyen de l'accélérer.

##############
# - Issues - #
##############


#######################
# - Initilalization - #
#######################
ROOT_PATH="$(pwd)"

source "$ROOT_PATH/src/functions.sh"

if [[ ! -d "$ROOT_PATH/.tmp" ]]; then
    mkdir "$ROOT_PATH/.tmp"
fi
TEMP_PATH="$ROOT_PATH/.tmp"

if [ -e "$TEMP_PATH/AutoClassifier.log" ]; then
    BASE_PATH="$(tail -n 25 "$TEMP_PATH/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')"
else
    BASE_PATH="$ROOT_PATH"
fi
#BASE_PATH="/Volumes/Edwin SSD 1/5 - Astrophoto/AstroImageClissifier/Test"

LOG_PATH="$TEMP_PATH/AutoClassifier.log"
TODAY="$(date +%s)"

check_dependencies

#echo "$BASE_PATH"
#load_param
#echo "$IMG_TYPE"
#which_image_type
#echo "$IMG_TYPE"
#
#exit 1;

# output the basis log informations
echo "Execution date: $(date)" >> "$LOG_PATH"
echo "Arguments : $1 $2" >> "$LOG_PATH"
echo "User: $USER" >> "$LOG_PATH"
echo "Root directory: $ROOT_PATH" >> "$LOG_PATH"


##############################
# - Cleaning working space - #
##############################
#clear

load_param
clean_oversize


############
# - Main - #
############
while getopts ":c:r:suthp" OPT "$@"; do

    case $OPT in
        (":")
            if [[ "$1" == "-r" || "$1" == "-c" ]]; then
                echo "Wait, where is the directory to classify???"
                read -p "Enter the folder to be filed: " OPTARG
                while [ ! -d "$OPTARG" ];
                do
                    echo "This is not a folder..."
                    read -p "Enter the folder to be filed: " OPTARG
                done
                cd "$OPTARG"
                BASE_PATH="$(pwd)"
                echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
                IsPicture
                if [ "$?" == 1 ];
                then
                    help_fnc
                    printf '\n%.0s' {1..12} >> "$LOG_PATH"
                    echo "\n####################" >> "$LOG_PATH"
                    exit 1;
                fi
                echo "Run process in $BASE_PATH"
                run_process
                if [[ "$1" == "-r" ]]; then
                    run_script
                fi
                printf '\n%.0s' {1..4} >> "$LOG_PATH"
                echo "\n####################" >> "$LOG_PATH"
            fi
            exit 1;;

        ("c")
            cd "$OPTARG"
            BASE_PATH="$(pwd)"
            echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
            IsPicture
            if [ $? == 1 ];
            then
                help_fnc
                printf '\n%.0s' {1..12} >> "$LOG_PATH"
                echo "\n####################" >> "$LOG_PATH"
                exit 1;
            fi
            echo "Run process in $BASE_PATH"
            run_process
            printf '\n%.0s' {1..4} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("s")
            which_image_type
            run_script
            exit 1;;

        ("r")
            cd "$OPTARG"
            BASE_PATH="$(pwd)"
            echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
            IsPicture
            if [ $? == 1 ];
            then
                help_fnc
                printf '\n%.0s' {1..12} >> "$LOG_PATH"
                echo "\n####################" >> "$LOG_PATH"
                exit 1;
            fi
            echo "Run process in $BASE_PATH"
            run_process
            printf '\n%.0s' {1..4} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            run_script
            exit 1;;

        ("u")
            echo "${BOLD}${UNDERLINED}Undo previous process${NORMAL}\n"
            echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
            echo "Do you want to undo the process (Y/n):"
            read sure
            if [[ $sure == "Y" || $sure == "y" ]]; then
                undo_process
            else
                echo "abort undo"
                echo "Abort: undo_process()\n" >> "$LOG_PATH"
            fi
            printf '\n%.0s' {1..6} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("t")
            echo "${BOLD}${UNDERLINED}${TITLE}Preview temporary files${NORMAL}\n"
            echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
            temp_check
            echo "\n${RED}${BOLD}${UNDERLINED}${BLINKING}!!! Warning !!!${NORMAL}${RED}\nThis operation cannot be cancelled !${NORMAL}"
            echo "Do you want to clean up the temporary files (Y/n)?"
            read res
            if [[ $res == "Y" || $res == "y" ]]; then
                temp_clear
            else
                echo "Clear temporary files abort"
                echo "Abort: temp_clear()\n" >> "$LOG_PATH"
            fi
            if [ -e "$TEMP_PATH/temporary.txt" ]; then
                rm "$TEMP_PATH/temporary.txt"
            fi
            printf '\n%.0s' {1..10} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("p")
            echo "${BOLD}${UNDERLINED}Update parameters${NORMAL}\n"
            echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
            update_param
            printf '\n%.0s' {1..12} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("h" | "?")
            echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
            help_fnc
            printf '\n%.0s' {1..12} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        (*)
            echo "Working directory: $BASE_PATH" >> "$LOG_PATH"
            help_fnc
            printf '\n%.0s' {1..12} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;
    esac
done
