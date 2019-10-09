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
		

		cd /Users/nds/Workspace/$FUNCAO

		if [ -d "/Users/nds/Workspace/$FUNCAO/EarContent" ]; then
			echo "Existe a pasta EAR conteent"
		else
			if [ -d "target/" ]; then
				rm -rf target/
			fi

		
			sed -i.bak 's/including=\"\*\*\/\*.java\"//g' .classpath
			rm .classpath.bak   

			mvn clean install -U


			if [ ! -d "/Users/nds/Workspace/publicacao/$FUNCAO" ]; then
				mkdir -p /Users/nds/Workspace/publicacao/$FUNCAO
			fi

			

			rsync -ahr --delete --stats --exclude '.git/' target/$FUNCAO-1.0/ /Users/nds/Workspace/publicacao/$FUNCAO
		fi

	else
		echo -e "\033[0;31mISSO NÃO É UM PROJETO GIT\033[0m";
	fi
done
