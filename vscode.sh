#!/bin/bash  
    if [[ $# = 0 ]]
    then
        open -a "Visual Studio Code" -n
    else
        [[ $1 = /* ]] && F="$1" || F="$PWD/${1#./}"
        open -a "Visual Studio Code" -n --args "$F"
    fi

