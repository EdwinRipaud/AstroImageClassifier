#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#  

# TODO: Penser à mettre 'Help.txt', 'parameters.config' et 'Param_func.sh' dans un dossier 'src'
# TODO: une fois les fonctions fini d'écrire dans 'Param_func.sh', découper le fichier en plusieurs fichiers regroupant les fonctions en catégorie

# TODO: issue sur le changement des paramètres, cela change le numéro du paramètre quand la valleur est égale à celle du numéro.

ROOT_PATH="$(pwd)"
TODAY="$(date +%s)"
source "$ROOT_PATH/Param_func.sh"

load_param
clean_tmp

while getopts ":r:uthp" OPT "$@"; do
    echo "\nFlag read: $OPT\n"

    case $OPT in
        (":")
            echo "Wait, where is the directory to classify???"
            read -p "Enter the folder to be filed: " OPTARG
            cd "$OPTARG"
            BASE_PATH="$(pwd)"
            echo "$BASE_PATH"
            run_process "$BASE_PATH"
            ;;

        ("r")
            cd "$OPTARG"
            BASE_PATH="$(pwd)"
            echo "Run process in $BASE_PATH"
            run_process "$BASE_PATH"
            ;;

        ("u")
            echo "Undo process"
            undo_process
            ;;

        ("t")
            echo "Temporary files checking"
            temp_check
            ;;

        ("p")
            echo "${BOLD}${UNDERLINED}Update parameters${NORMAL}\n"
            update_param
            ;;

        ("h" | "?")
            help_fnc
            ;;
    esac
done
