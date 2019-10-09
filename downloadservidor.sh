#!/bin/bash



echo "Qual remoto deseja configurar :"; read remoto

if [ -z $remoto ]; then
	echo "Por favor selecione um remoto para configurar";
	exit 1
fi

echo "Qual endereço do remoto $remoto :"; read endereco




		cd /Users/nds/Workspace/publicacao

		git clone -o remoto $endereco 

		echo "Servidor $remoto configurado para o endereco $endereco"; 
	