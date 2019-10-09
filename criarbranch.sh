#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Faltou você escolher os projetos para criar a branch!"
	exit 1
fi

echo Voce escolheu mudar a branch dos projetos $*

echo "Qual branch você deseja criar : (se vazio: envio_homologacao)"; read branch

if [ -z $branch ]; then
	branch='envio_homologacao';
fi

for FUNCAO in $*; do
	if [ -d $FUNCAO/.git ]; then
		
		cd /Users/nds/Workspace/$FUNCAO
		
		if [ ` git branch --list $branch ` ]
		then
		   	echo "##### Branch $branch ja existe, apenas alterando para a mesma! #####";	
			git checkout $branch
		else
			echo "##### Criando branch do projeto: $FUNCAO #####";
 			git checkout -b $branch	
		fi


		
	else
		echo "##### ISSO NÃO É UM PROJETO GIT#####";
	fi
done

