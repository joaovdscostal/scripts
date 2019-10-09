#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Faltou você escolher os projetos para remover a branch!"
	exit 1
fi

echo Voce escolheu mudar a branch dos projetos $*

echo "Qual branch você deseja remover : (se vazio: master)"; read branch

if [ -z $branch ]; then
	branch='master';
fi

for FUNCAO in $*; do
	if [ -d $FUNCAO/.git ]; then

		if [ $branch = "master" ]; then
			echo "##### Nao podemos remover a branch master #####";
			exit 1
		fi

		cd /Users/nds/Workspace/$FUNCAO

		branchatual=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')

		if [ $branch = $branchatual ]; then
			echo "##### Nao podemos remover a branch $branch porque ela é a branch atual do projeto $FUNCAO #####";
			exit 1
		fi

		echo "##### removendo branch do projeto: $FUNCAO #####";
		
		git branch -D $branch
	else
		echo "##### ISSO NÃO É UM PROJETO GIT#####";
	fi
done

