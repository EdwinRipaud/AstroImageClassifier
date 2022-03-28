#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#  

# TODO: Penser à mettre 'Help.txt', 'parameters.config' et 'Param_func.sh' dans un dossier 'src'
# TODO: une fois les fonctions fini d'écrire dans 'Param_func.sh', découper le fichier en plusieurs fichiers regroupant les fonctions en catégorie

# TODO: enregistrer les log des actions effectuées

ROOT_PATH="$(pwd)"

source "$ROOT_PATH/Param_func.sh"

BASE_PATH=$(tail -n $LOG_LENGTH "$ROOT_PATH/.tmp/AutoClassifier.log" | grep -w "Working directory:" | sed 's/.*: //')
TODAY="$(date +%s)"

load_param
clean_oversize


while getopts ":r:uthp" OPT "$@"; do
    echo "\nFlag read: $OPT\n"
    
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
            IsPicture
            if [ $? == 1 ];
            then
                help_fnc
                exit 1;
            fi
                        
            echo "Run process in $BASE_PATH"
            run_process
            
            exit 1;;

        ("r")
            cd "$OPTARG"
            BASE_PATH="$(pwd)"
            IsPicture
            if [ $? == 1 ];
            then
                help_fnc
                exit 1;
            fi
            
            echo "Run process in $BASE_PATH"
            run_process
            exit 1;;

        ("u")
            echo "${BOLD}${UNDERLINED}Undo previous process${NORMAL}\n"
            undo_process
            exit 1;;

        ("t")
            echo "${BOLD}${UNDERLINED}${TITLE}Preview temporary files${NORMAL}\n"
            temp_check
            echo "\n${RED}${BOLD}${UNDERLINED}${BLINKING}!!! Warning !!!${NORMAL}${RED}\nThis operation cannot be cancelled !${NORMAL}"
            echo "Do you want to clean up the temporary files (Y/n)?"
            read res
            if [[ $res == "Y" || $res == "y" ]]; then
                temp_clear
            else
                echo "Clear temporary files abort"
            fi
            if [ -e "$ROOT_PATH/.tmp/temporary.txt" ]; then
                rm "$ROOT_PATH/.tmp/temporary.txt"
            fi
            exit 1;;

        ("p")
            echo "${BOLD}${UNDERLINED}Update parameters${NORMAL}\n"
            update_param
            exit 1;;

        ("h" | "?")
            help_fnc
            exit 1;;
    esac
done
