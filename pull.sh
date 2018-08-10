#!/bin/bash


if [ $# -lt 1 ]; then
	echo -e "\033[0;31mFaltou você escolher os projetos para fazer o pull\033[0m"
	exit 1
fi

echo "Voce escolheu baixar os projetos $*"

echo -e "Qual remoto deseja utilizar: \033[1;37m(se vazio: origin)\033[0m"; read remoto

echo -e "Qual branch deseja utilizar: \033[1;37m(se vazio: master)\033[0m"; read branch

if [ -z $remoto ]; then
	remoto='origin';
fi

if [ -z $branch ]; then
	branch='master';
fi

for FUNCAO in $*; do
	
	FUNCAO="${FUNCAO////}"
	echo -e "\033[1;34mBaixando projeto: $FUNCAO\033[0m";

	if [ -d $FUNCAO/.git ];
	then

		cd /Workspace/$FUNCAO

		git pull $remoto $branch
		
		echo
		cd ..

	else
		echo -e "\033[0;31mISSO NÃO É UM PROJETO GIT\033[0m";
	fi
done
