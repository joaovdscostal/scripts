#!/bin/bash

if [ $# -lt 1 ]; then
	echo -e "\033[0;31mFaltou você escolher os projetos ver o status\033[0m"
	exit 1
fi

for FUNCAO in $*; do
	
	FUNCAO="${FUNCAO////}"
	echo -e "\033[1;34mProjeto: $FUNCAO\033[0m";

	if [ -d $FUNCAO/.git ];
	then
		
		cd /Users/nds/Workspace/$FUNCAO

		git status
		
		echo

		cd ..

	else
		echo -e "\033[0;31mISSO NÃO É UM PROJETO GIT\033[0m";
	fi
done
