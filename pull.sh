#!/bin/bash


if [ $# -lt 1 ]; then
   echo "Faltou você escolher os projetos para fazer o pull"
   exit 1
fi

echo Voce escolheu baixar os projetos $*

echo "Qual remoto deseja utilizar: (se vazio: origin)"; read remoto

for FUNCAO in $*; do
    if [ -d $FUNCAO/.git ];
    then
        echo "##### Baixando projeto: $FUNCAO #####";
        

        if [ -z $remoto ];
        then
            remoto='origin';
        fi

        cd $FUNCAO
        git pull $remoto master
        
        echo "##### Download do projeto $FUNCAO terminado #####";
        echo
        cd ..
    fi
done



#for DIR in `ls`;
#do
#    if [ -d $DIR/.git ];
#    then
#            echo "updating location: " $DIR;
#            cd $DIR
            # your commands here...
            #git add -u 
            #git add .
            #git commit -m 'Latest'

#            cd ..
#    fi
#done