#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Faltou você escolher os projetos para fazer o push"
	exit 1
fi

echo Voce escolheu enviar os projetos $*

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
		echo "##### Enviando projeto: $FUNCAO #####";
	 
		if [ $remoto = "origin" ]; then
		
			cd $FUNCAO
			git push $remoto $branch

		elif [ $FUNCAO != "base" ] && ( [ $remoto = "producao" ] || [ $remoto = "homologacao" ] || [ $remoto = "teste" ] ); then
			
			cd $FUNCAO

			git add .
			git commit -a -m "envio para homologacao"
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

