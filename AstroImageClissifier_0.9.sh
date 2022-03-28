#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#  

# TODO: une fois les fonctions fini d'écrire dans 'Param_func.sh', découper le fichier en plusieurs fichiers regroupant les fonctions en catégorie


ROOT_PATH="$(pwd)"

source "$ROOT_PATH/src/functions.sh"

BASE_PATH=$(tail -n 25 "$ROOT_PATH/.tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
LOG_PATH="$ROOT_PATH/.tmp/AutoClassifier.log"
TODAY="$(date +%s)"

# output the basis log informations
echo "Execution date: $(date)" >> "$LOG_PATH"
echo "Arguments : $1 $2" >> "$LOG_PATH"
echo "User: $USER" >> "$LOG_PATH"
echo "Root directory: $ROOT_PATH" >> "$LOG_PATH"

load_param
clean_oversize


while getopts ":r:uthp" OPT "$@"; do
    
    case $OPT in
        (":")
            echo "Wait, where is the directory to classify???"
            read -p "Enter the folder to be filed: " OPTARG
            while [ ! -d $OPTARG ];
            do
                echo "This is not a folder..."
                read -p "Enter the folder to be filed: " OPTARG
            done
            
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
            printf '\n%.0s' {1..12} >> "$LOG_PATH"
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
            if [ -e "$ROOT_PATH/.tmp/temporary.txt" ]; then
                rm "$ROOT_PATH/.tmp/temporary.txt"
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
