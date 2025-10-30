#!/bin/bash
if [ $# -lt 1 ]; then
   echo "Você nao selecionou os parametros!"
   exit 1
fi

if [ $# -eq 1 ] && [ $1 == "--help" ]; then
    echo "Parametros"
    echo "-destino               Base destino (localhost, localhost-mariadb)"
    echo "-basededadosdestino    Nome do banco de dados destino!"
    echo "-arquivo     Nome do arquivo para importação!"
    exit 1
fi


while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -basededadosdestino)
    basededadosdestino="$2"
    shift # past argument
    ;;
    -arquivo)
    arquivo="$2"
    shift # past argument
    ;;
    -destino)
    destino="$2"
    shift # past argument
    ;;
    
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo "Iniciou processo de execucao de importacao de banco de dados!"


if [ -z $basededadosdestino ];
then
    echo "Por favor digite a base de dados destino."
    exit 1
fi

if [ -z $arquivo ];
then
    echo "Por favor digite o nome do arquivo."
    exit 1
fi

#if  [ $destino != "localhost" ]; then 
#    echo "Destino inválido! Permitida: localhost"
#    exit 1
#fi

if [ $destino == "localhost" ]; then
    servidordestino='localhost'
    usuariodestino='root'
    senhadestino='mysql'
fi

if [ $destino == "localhost-forme" ]; then
    servidordestino='127.0.0.1'
    usuariodestino='root'
    senhadestino='mysql'
    portadestino='-P 3303'
fi


mysql=/opt/homebrew/opt/mysql@8.0/bin/mysql
#mysql=/opt/homebrew/bin/mysql

arquivosql=/Users/nds/Workspace/dados/$arquivo


sed -i '' '1d' $arquivosql

if [[ $basededadosdestino == *"code-erp"* ]]; then
    echo "Substitui nome da base no arquivo"
    sed -i '' "s/code-erp/$basededadosdestino/g" $arquivosql
fi

echo "Iniciando processo de restauracao no destino com comando $mysql -h $servidordestino $portadestino -u $usuariodestino -p$senhadestino $basededadosdestino < $arquivosql wh"
$mysql -h $servidordestino $portadestino -u $usuariodestino -p$senhadestino $basededadosdestino < $arquivosql 

if [[ "$basededadosdestino" == *"code-erp"* ]]; then
    echo "Executando comando adicional para base de dados code-erp"
    $mysql -h $servidordestino -u $usuariodestino -p$senhadestino -e "USE $basededadosdestino; UPDATE PLAYERDEPAGAMENTOGESTOR SET AMBIENTE = 'HOMOLOGACAO', TOKEN = NULL;"
fi

echo "Terminou processo de restauracao no destino"

echo "ACABOU - AEEEEE"