#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Faltou você escolher os projetos para compilar"
	exit 1
fi

echo Voce escolheu compilar os projetos $*

for FUNCAO in $*; do
	if [ -d $FUNCAO/.git ]; then

		echo "##### Compilando projeto: $FUNCAO #####";

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

		echo "##### TERMINOU DE COMPILAR#####";
	else
		echo "##### ISSO NÃO É UM PROJETO GIT#####";
	fi
done


#Antigo

#if [ $FUNCAO = "base" ]; then
#			cd /Workspace/$FUNCAO
#			mvn clean install -U

#		else
 	
#			cd /Workspace/$FUNCAO
			
			#sed  -i.bak -e '/target/d' .gitignore
			#sed  -i.bak -e '/build/d' .gitignore

			#rm .gitignore.bak

#			rm -rf target/
#			sed -i.bak 's/including=\"\*\*\/\*.java\"//g' .classpath
#			rm .classpath.bak   

#		 	mvn clean install -U

#		 	sleep 5 
#			sed  -i.bak -e '/target/d' .gitignore
#			rm .gitignore.bak	
#		fi
