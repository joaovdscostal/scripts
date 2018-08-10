#!/bin/bash

if [ $# -lt 1 ]; then
	echo -e "\033[0;31mFaltou você escolher os projetos para compilar\033[0m"
	exit 1
fi

echo "Voce escolheu compilar os projetos $*"

for FUNCAO in $*; do

	FUNCAO="${FUNCAO////}"
	echo -e "\033[1;34mCompilando projeto: $FUNCAO\033[0m";

	if [ -d $FUNCAO/.git ]; then
		

		cd /Workspace/$FUNCAO

		if [ -d "target/" ]; then
			rm -rf target/
		fi

		
		sed -i.bak 's/including=\"\*\*\/\*.java\"//g' .classpath
		rm .classpath.bak   

		mvn clean install -U


		if [ ! -d "/Workspace/publicacao/$FUNCAO" ]; then
			mkdir -p /Workspace/publicacao/$FUNCAO
		fi

		rsync -ahr --delete --stats --exclude '.git/' target/$FUNCAO-1.0/ /Workspace/publicacao/$FUNCAO
	else
		echo -e "\033[0;31mISSO NÃO É UM PROJETO GIT\033[0m";
	fi
done
