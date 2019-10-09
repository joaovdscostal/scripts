#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Faltou você escolher os projetos para publicar"
	exit 1
fi

echo Voce escolheu publicar os projetos $*

echo "Qual remoto deseja utilizar : (se vazio: origin)"; read remoto

if [ -z $remoto ]; then
	remoto='origin';
fi

echo "Qual branch deseja enviar : (se vazio: master)"; read branch

if [ -z $branch ]; then
	branch='master';
fi

for FUNCAO in $*; do
	if [ -d $FUNCAO/.git ]; then
		echo "##### Publicando projeto: $FUNCAO #####";
	 
		if [ $FUNCAO != "base" ] && ( [ $remoto = "producao" ] || [ $remoto = "homologacao" ] || [ $remoto = "teste" ] ); then
			
			cd /Users/nds/Workspace/publicacao/$FUNCAO

			ADEHOJE=$(date +"%d")
			MES=$(date +"%m")
			ANO=$(date +"%Y")
			DSEMANA=$(date +"%w")

			HOJE=$ADEHOJE"-"$MES"-"$ANO

			git add .
			git commit -a -m "envio para $remoto - $HOJE"
			
			git push -f $remoto $branch:master 
		else
			echo "##### OPCAO INVALIDA PARA SERVIDOR #####";
		fi
			
		echo "##### Envio do projeto $FUNCAO terminado #####";
		echo
		cd ..

	else
		echo "##### ISSO NÃO É UM PROJETO GIT#####";
	fi
	
done

