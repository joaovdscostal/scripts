#!/bin/bash

if [ $# -lt 1 ]; then
	echo -e "\033[0;31mFaltou você escolher os projetos para commitar\033[0m"
	exit 1
fi

echo "Voce escolheu commitar os projetos $*"

echo "Digite a mensagem do commit: "; read mensagem

if [ -z "$mensagem" ]
then
	echo -e "\033[0;31mFaltou você digitar a mensagem do commit\033[0m"
	exit 1
else
	for FUNCAO in $*; do

		FUNCAO="${FUNCAO////}"
		echo -e "\033[1;34mComitando projeto $FUNCAO na branch $branchatual\033[0m"

		if [ -d $FUNCAO/.git ];
		then
		
			cd /Workspace/$FUNCAO

			branchatual=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')

			git add -u
			git add .
			git commit -m "$mensagem"
			
			echo
			cd ..

		else
			echo -e "\033[0;31mISSO NÃO É UM PROJETO GIT\033[0m";
		fi
	done
fi
