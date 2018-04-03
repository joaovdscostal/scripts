#!/bin/bash


if [ $# -lt 1 ]; then
   echo "Faltou você escolher os projetos ver o status"
   exit 1
fi

for FUNCAO in $*; do
    if [ -d $FUNCAO/.git ];
    then
        echo "##### Projeto: $FUNCAO #####";
        
        cd $FUNCAO

        git status
        
        echo
        cd ..
    fi
done
