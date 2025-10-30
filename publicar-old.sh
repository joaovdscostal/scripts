#!/bin/bash

if [ $# -lt 1 ]; then
	echo -e "\033[0;31m Falto selecionar os parametros\033[0m"
	exit 1
fi

echo "Voce escolheu publicar os projetos $*"

echo -e "Qual remoto deseja utilizar: \033[1;37m(se vazio: origin)\033[0m"; read remoto

echo -e "Qual branch deseja utilizar: \033[1;37m(se vazio: master)\033[0m"; read branch

echo -e "Qual tag deseja criar: (se nao criar, deixe vazio)"; read tag

if [ -z $remoto ]; then
	remoto='origin';
fi

if [ -z $branch ]; then
	branch='master';
fi


if [ -n "$tag" ]; then
	if ( [ $remoto = "producao" ] || [ $remoto = "servidorpoker" ] || [ $remoto = "servidor-cidadania" ] || [ $remoto = "servidor-poker" ] ); then
		tag="prod-$tag"
	fi

	if ( [ $remoto = "homologacao" ] || [ $remoto = "teste" ] || [ $remoto = "teste-remoto" ]   || [ $remoto = "testes" ] ); then
		tag="teste-$tag"
	fi
fi

for FUNCAO in $*; do
	FUNCAO="${FUNCAO////}"

	echo -e "\033[1;34mPublicando projeto: $FUNCAO\033[0m";

	if [ -d $FUNCAO/.git ]; then

		if [ $FUNCAO != "base" ] && ( [ $remoto = "producao" ] || [ $remoto = "servidorpoker" ] || [ $remoto = "homologacao" ] || 
			[ $remoto = "teste" ] || [ $remoto = "teste-remoto" ]  || [ $remoto = "servidor-cidadania" ] || 
			[ $remoto = "servidor-poker" ] || [ $remoto = "testes" ] ); then
			
			cd /Users/nds/Workspace/publicacao/$FUNCAO

			ADEHOJE=$(date +"%d")
			MES=$(date +"%m")
			ANO=$(date +"%Y")
			DSEMANA=$(date +"%w")

			HOJE=$ADEHOJE"-"$MES"-"$ANO

			git add .
			git commit -a -m "Commit para envio da tag $tag para $remoto - $HOJE"

			echo -e "\033[0;31mPublicando no remoto $remoto e na branch $branch\033[0m";
			
			git push -f $remoto $branch
			
			

			if [ -n "$tag" ]; then
				echo -e "\033[0;31mCriando e publicando a tag $tag\033[0m";

				cd /Users/nds/Workspace/sts/$FUNCAO

				git add .
				git commit -a -m "Commit para envio da tag $tag para $remoto - $HOJE"
				git tag $tag
				git push origin :refs/tags/$tag
				git push origin $tag -f
			fi
		else
			echo -e "\033[0;31mOPCAO INVALIDA PARA SERVIDOR\033[0m";
		fi
			
		echo
		cd ..

	else
		echo -e "\033[0;31mISSO NÃO É UM PROJETO GIT\033[0m";
	fi
	
done


