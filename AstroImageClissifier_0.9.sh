#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#  

ROOT_PATH="$(pwd)"
source "$ROOT_PATH/Param_func.sh"

load_param

while getopts ":r:uthp" OPT "$@"; do
    echo "Flag read: $OPT"
    
    case $OPT in
        (":")
            echo "Wait you didn't enter the directory to classify"
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
            echo "Update parameters"
            update_param
            ;;

        ("h" | "?")
            help_fnc
            ;;
    esac
done
