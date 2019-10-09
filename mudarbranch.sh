#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Faltou você escolher os projetos para alterar a branch!"
	exit 1
fi

echo Voce escolheu mudar a branch dos projetos $*

echo "Para qual branch você deseja mudar : (se vazio: master)"; read branch

if [ -z $branch ]; then
	branch='master';
fi

for FUNCAO in $*; do
	if [ -d $FUNCAO/.git ]; then

		cd /Users/nds/Workspace/$FUNCAO

		branchatual=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')


		if [ $branch = $branchatual ]; then
			echo "##### Você ja esta na branch $branchatual #####";
			exit 1
		fi


		if [ ` git branch --list $branch ` ]
		then
		   	echo "##### Mudando branch do projeto: $FUNCAO #####";	
			git checkout $branch
		else
 			echo "##### Branch $branch não existe no projeto: $FUNCAO #####";	

		fi

		
	else
		echo "##### ISSO NÃO É UM PROJETO GIT#####";
	fi
done

