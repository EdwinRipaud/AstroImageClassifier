#!/bin/sh

#  Param_func.sh
#  
#
#  Created by edwin ripaud on 17/03/2022.
#

read_param() {
    echo "$(cat "parameters.config")"
}

write_param() {
    OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "parameters.config")
    for line in $lines
    do
        if [[ $line == *"-"* ]]; then
            Val=$(echo "$line" | grep -o ".- *")
            
            case $Val in
                ("1- ")
                    echo "Folders names"
                    echo "\t${line#*: }";;
                    
                ("2- ")
                    echo "Max size"
                    echo "\t${line#*: }";;
                ("3- ")
                    echo "Max age"
                    echo "\t${line#*: }";;
                ("4- ")
                    echo "Time"
                    echo "\t${line#*: }";;
                (*)
                    echo "Error";;
                
            esac
        fi
    done
    IFS=$OLDIFS
}

run_process() {
    echo "Running process ..."
}

help_fnc() {
        OLDIFS=$IFS
    IFS=$'\n'
    lines=$(cat "Help.txt")
    for line in $lines
    do
        echo "$line"
    done
    IFS=$OLDIFS
}
