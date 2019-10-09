#!/bin/bash

if [ $# -lt 1 ]; then
	echo -e "\033[0;31mFaltou você escolher os projetos para fazer o push\033[0m"
	exit 1
fi

echo "Voce escolheu enviar os projetos $*"

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
	echo -e "\033[1;34mEnviando projeto: $FUNCAO\033[0m";
	
	if [ -d $FUNCAO/.git ]; then

		cd /Users/nds/Workspace/$FUNCAO

		if [ $remoto = "origin" ]; then

			git push $remoto $branch

		elif [ $FUNCAO != "base" ] && ( [ $remoto = "producao" ] || [ $remoto = "homologacao" ] || [ $remoto = "teste" ] ); then

			git add .
			git commit -a -m "envio para homologacao"
			git push -f $remoto $branch:master 

		else
			echo -e "\033[0;31mOPCAO INVALIDA PARA SERVIDOR\033[0m";
		fi

		echo
		cd ..

	else
		echo -e "\033[0;31mISSO NÃO É UM PROJETO GIT\033[0m";
	fi
done
