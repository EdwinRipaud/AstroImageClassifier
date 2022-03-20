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
        ;;
    
    ("-t" | "-temp")
        echo "Temporary files checking"
        ;;
    
    ("-h" | "-help" | "")
        help_fnc
        ;;
esac

#if [ "$1" != "" ]; then
#
#    while getopts ":r:uth" VALUE "$@";
#    do
#
#        echo "GOT FLAG $VALUE"
#
#        case "$VALUE" in
#            ("r")
#                echo "Run the script on \"$OPTARG\" directory";;
#            (":")
#                echo "Which directory whould you classify?";;
#            ("u")
#                echo "Undo the last process";;
#            ("t")
#                echo "Temporary files management";;
#            ("h")
#                echo "Help";;
#            ("?")
#                echo "Unknown flag -$OPTARG detected.";;
#        esac
#
#    done
#
#else
#    echo "You need to put some arguments\n\t-r \"path/to/the/directory\" \n\t-u\n\t-t\n\t-h"
#
#fi
