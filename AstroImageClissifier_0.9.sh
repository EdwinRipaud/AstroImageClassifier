#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#


#####################
# - Next features - #
#####################
# TODO: utiliser les nombres binaires pour faire le choix du script à exécuter
# TODO: chercher parmis les script dans le dossier '/SCRIPT_PATH' en quelle lange ils sont, puis en déduire le script à exécuter
# TODO: ajouter/modifier les options pour que l'on puisse exécuter : une classification seule, un script siril seule (à partir des images trouvée) et une classification suivi d'un script SiriL
# TODO: modifier le undo pour qu'il supprime le dossier créé par siril lors de l'exécution d'un script
# TODO: ajouter dans les logs les opération sur les exécution de script SiriL
# TODO: avant l'éxécution d'un script SiriL, demander une confiramtion et prévenir de l'espace que va prendre le traitement


##############
# - Issues - #
##############
# TODO: !!! ISSUE 1 --> problème de chemin lors de l'appelle des fonction de classifications et qu'il n'y a pas d'image de ce type (fichier .txt inexistant). Ajouter une vérification d'existance du fichier .txt au début de la fonction.


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

LOG_PATH="$TEMP_PATH/AutoClassifier.log"
TODAY="$(date +%s)"

check_dependencies

#val1="$((2#10100))"
#val2="$((2#10010))"
#key="$((2#10011))"
#if [[ "$(($val1 ^ $key))" = 0 ]]; then
#    echo "True: val1^key=$(($val1 ^ $key))"
#    echo "False: val2^key=$(($val2 ^ $key))"
#elif [[ "$(($val2 ^ $key))" = 0 ]]; then
#    echo "False: val1^key=$(($val1 ^ $key))"
#    echo "True: val2^key=$(($val2 ^ $key))"
#else
#    echo "False: val1^key=$(($val1 ^ $key))"
#    echo "False: val2^key=$(($val2 ^ $key))"
#fi
#
#
#case "$(($val1))" in
#    ("$((2#10100))")
#        echo "Yaha"
#        ;;
#    (*)
#        echo "jndzdbfi"
#        ;;
#esac
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
clear

load_param
clean_oversize


############
# - Main - #
############
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
