#!/bin/sh

#  AstroImageClissifier_0.9.sh
#  
#
#  Created by edwin ripaud on 19/03/2022.
#  

root_path=$(pwd)
source "$root_path/Param_func.sh"

OPT="$1"
DIR="$2"

case $OPT in
    ("-r" | "-run")
        echo "Run process"
        run_process
        ;;
    
    ("-u" | "-undo")
        echo "Undo process"
        undo_process
        ;;
    
    ("-t" | "-temp")
        echo "Temporary files checking"
        temp_check
        ;;
    
    ("-h" | "-help" | "")
        help_fnc
        ;;
esac
