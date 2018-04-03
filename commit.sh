#!/bin/bash


if [ $# -lt 1 ]; then
   echo "Faltou você escolher os projetos para commitar"
   exit 1
fi

echo Voce escolheu commitar os projetos $*

echo "Digite a mensagem do commit: "; read mensagem

for FUNCAO in $*; do

    if [ -d $FUNCAO/.git ];
    then
        cd /Workspace/$FUNCAO

        branchatual=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
     
        echo "##### Commitando projeto $FUNCAO na branch $branchatual #####";

        git add -u
        git add .
        git commit -m "$mensagem"
        
        echo "##### Commit do projeto $FUNCAO terminado #####";
        echo
        cd ..
    fi
done
