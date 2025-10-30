#!/bin/bash

projetos=(
    "code-erp|producao|producao|main"
    "multt|producao|producao|main"
	"route-365|producao|producao|main"
    "contabil|producao|producao|main"
    "poker|producao|servidor-poker|master"
    "emprestimo|producao|producao|main"
    "cidadania|homologacao|testes|master"
    "cidadania|producao|servidor-cidadania|master"
    "codetech|producao|producao|master"
    "epubliq|producao|producao|main"
)

buscar_projeto() {
    local nome_projeto=$1
    local ambiente=$2

    for projeto in "${projetos[@]}"; do
        # Divide a string do "objeto" em atributos
        IFS="|" read -r nome obj_ambiente remoto branch senha <<< "$projeto"

        if [[ $nome == "$nome_projeto" && $obj_ambiente == "$ambiente" ]]; then
            echo "$nome|$obj_ambiente|$remoto|$branch"
            return
        fi
    done

    # Se não encontrado, retornar vazio
    echo ""
}



if [ $# -lt 1 ]; then
	echo -e "\033[0;31m Faltou selecionar os parametros\033[0m"
	exit 1
fi

echo "Voce escolheu publicar os projetos $*"

echo -e "Em qual ambiente deseja publicar? (producao ou homologacao)"; read ambiente

if [ -z $ambiente ]; then
	echo -e "\033[0;31m Por favor selecione o ambiente\033[0m"
	exit 1
fi

echo -e "Tem certeza que deseja publicar $* no ambiente de $ambiente? (S ou N)"; read decisao

if [[ "$decisao" != "S" && "$decisao" != "s" ]]; then
    echo -e "\033[0;31m Operação cancelada pelo usuário.\033[0m"
    exit 1
fi

echo -e "Qual tag deseja criar: (se nao criar, deixe vazio)"; read tag

for FUNCAO in $*; do
	FUNCAO="${FUNCAO////}"
	
	resultado=$(buscar_projeto "$FUNCAO" "$ambiente")

	if [[ -z "$resultado" ]]; then
	    echo "Projeto '$FUNCAO' no ambiente '$ambiente' não encontrado."
	    exit 1
	else
		IFS="|" read -r nome obj_ambiente remoto branch <<< "$resultado"
		
		echo -e "\033[1;34mPublicando projeto: $nome\033[0m";
		cd /Users/nds/Workspace/publicacao/$nome

		ADEHOJE=$(date +"%d")
		MES=$(date +"%m")
		ANO=$(date +"%Y")
		DSEMANA=$(date +"%w")

		HOJE=$ADEHOJE"-"$MES"-"$ANO

		if [ -n "$tag" ]; then
			tag="$obj_ambiente-$tag"
		fi

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


	fi

done


