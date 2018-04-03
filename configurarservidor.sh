#!/bin/bash

if [ $# -lt 1 ]; then
	echo "Faltou você escolher para qual quer configurar o servidor"
	exit 1
fi

echo "Qual remoto deseja configurar :"; read remoto

if [ -z $remoto ]; then
	echo "Por favor selecione um remoto para configurar";
	exit 1
fi

echo "Qual endereço do remoto $remoto :"; read endereco




for FUNCAO in $*; do
	if [ -d /Workspace/publicacao/$FUNCAO/.git ]; then
		cd /Workspace/publicacao/$FUNCAO

		git remote add $remoto $endereco

		echo "Servidor $remoto configurado para o endereco $endereco"; 
	else
		echo "##### ISSO NÃO É UM PROJETO GIT#####";
	fi
	
done