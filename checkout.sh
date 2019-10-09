#!/bin/bash


if [ $# -lt 1 ]; then
   echo "Faltou você escolher os projetos para fazer o checkout"
   exit 1
fi

echo Voce escolheu enviar os projetos $*


for FUNCAO in $*; do
    if [ -d $FUNCAO/.git ];
    then
        echo "##### Checkout projeto: $FUNCAO #####";
        echo "Qual parametro deseja utilizar para o projeto $FUNCAO: "; read mensagem

        cd /Users/nds/Workspace/publicacao/$FUNCAO
        git checkout $mensagem
        
        echo "##### Checkout do projeto $FUNCAO terminado #####";
        echo
        cd ..
    fi
done
