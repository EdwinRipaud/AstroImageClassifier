#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#


#####################
# - Next features - #
#####################
# TODO: prendre des screen du finder pour mettre dans le README.md pour visualiser l'arrangement des dossiers avant, après classification et après un script
# TODO: changer l'algo de détection des darks / lights en utilisant la valeur moyenne des pixels avec magick identify, si possible trouver un moyen de l'accélérer.

##############
# - Issues - #
##############
# TODO: Renommer l'ensemble du projet, car faute de typo dans le nom : AstroImageClassifier


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
    WORK_PATH="$(tail -n 25 "$TEMP_PATH/AutoClassifier.log" | grep -w "Working directory:" | tail -1 | sed 's/.*: //')"
else
    WORK_PATH="$ROOT_PATH"
fi
#WORK_PATH="/Volumes/Edwin SSD 1/5 - Astrophoto/AstroImageClissifier/Test"

LOG_PATH="$TEMP_PATH/AutoClassifier.log"
TODAY="$(date +%s)"

check_dependencies

            
#echo "Wait, where is the directory to classify???"
#read -p "Enter the folder to be filed: " OPTARG
#while [ ! -d "$OPTARG" ];
#do
#    echo "($OPTARG) is not a folder..."
#    if [ "$OPTARG" == "q" ]; then
#        exit 1;
#    fi
#    read -p "Enter the folder to be filed: " OPTARG
#done
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
                echo "Wait, where is the directory to classify ???"
                read -p "Enter the name of the folder to clissify: " OPTARG
                while [[ ! -d "$OPTARG" ]];
                do
                    if [ "$OPTARG" == "q" ]; then
                        printf '\n%.0s' {1..14} >> "$LOG_PATH"
                        echo "\n####################" >> "$LOG_PATH"
                        exit 1;
                    fi
                    echo "This is not a folder..."
                    read -p "Enter the name of the folder to clissify (or q to exit): " OPTARG
                done
                cd "$OPTARG"
                WORK_PATH="$(pwd)"
                echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
                IsPicture
                if [ "$?" == 1 ];
                then
                    help_fnc
                    printf '\n%.0s' {1..12} >> "$LOG_PATH"
                    echo "\n####################" >> "$LOG_PATH"
                    exit 1;
                fi
                echo "Run process in $WORK_PATH"
                run_process
                if [[ "$1" == "-r" ]]; then
                    run_script
                    printf '\n%.0s' {1..1} >> "$LOG_PATH"
                    echo "\n####################" >> "$LOG_PATH"
                else
                    printf '\n%.0s' {1..4} >> "$LOG_PATH"
                    echo "\n####################" >> "$LOG_PATH"
                fi
            fi
            exit 1;;

        ("c")
            cd "$OPTARG"
            WORK_PATH="$(pwd)"
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
            IsPicture
            if [ $? == 1 ];
            then
                help_fnc
                printf '\n%.0s' {1..12} >> "$LOG_PATH"
                echo "\n####################" >> "$LOG_PATH"
                exit 1;
            fi
            echo "Run process in $WORK_PATH"
            run_process
            printf '\n%.0s' {1..4} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("s")
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
            which_image_type
            run_script
            printf '\n%.0s' {1..10} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("r")
            cd "$OPTARG"
            WORK_PATH="$(pwd)"
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
            IsPicture
            if [ $? == 1 ];
            then
                help_fnc
                printf '\n%.0s' {1..12} >> "$LOG_PATH"
                echo "\n####################" >> "$LOG_PATH"
                exit 1;
            fi
            echo "Run process in $WORK_PATH"
            run_process
            run_script
            printf '\n%.0s' {1..1} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("u")
            echo "${BOLD}${UNDERLINED}Undo previous process${NORMAL}\n"
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
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
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
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
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
            update_param
            printf '\n%.0s' {1..12} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        ("h" | "?")
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
            help_fnc
            printf '\n%.0s' {1..12} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;

        (*)
            echo "Working directory: $WORK_PATH" >> "$LOG_PATH"
            help_fnc
            printf '\n%.0s' {1..12} >> "$LOG_PATH"
            echo "\n####################" >> "$LOG_PATH"
            exit 1;;
    esac
done
