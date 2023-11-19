#!/bin/bash
if [ $# -lt 1 ]; then
   echo "Você nao selecionou os parametros!"
   exit 1
fi

if [ $# -eq 1 ] && [ $1 == "--help" ]; then
    echo "Parametros"
    echo "-basededadosdestino    Nome do banco de dados destino!"
    echo "-basededadosorigem     Nome do banco de dados origem!"
    echo "-origem                Base origem (bu)!"
    echo "-destino               Base destino (bu-homologacao)"
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
    -basededadosorigem)
    basededadosorigem="$2"
    shift # past argument
    ;;
    -origem)
    origem="$2"
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

if [ -z $basededadosorigem ];
then
    echo "Por favor digite a base de dados origem."
    exit 1
fi

if [ $origem != "bu" ]; then
    echo "Origem inválida! Permitida: bu"
    exit 1
fi

if [ $destino != "bu-homologacao" ]; then
    echo "Destino inválid0! Permitida: bu-homologacao"
    exit 1
fi

if [ $origem == "bu" ]; then
    servidororigem='dbmysg.ca6icfds8q4p.us-east-1.rds.amazonaws.com'
    usuarioorigem='root'
    senhaorigem='SGMyDb.3427#'
fi

if [ $destino == "bu-homologacao" ]; then
    servidordestino='dbmysg-homologacao.ca6icfds8q4p.us-east-1.rds.amazonaws.com'
    usuariodestino='root'
    senhadestino='SGMyDb.3427#'
fi


mysqldump=/usr/local/opt/mysql@5.6/bin/mysqldump
mysql=/usr/local/opt/mysql@5.6/bin/mysql
arquivosql=/Users/nds/Workspace/dados/origem-refresh.sql
logFile=/home/ubuntu/backup/dados/log.txt


#rm -rf $arquivosql

#echo "Iniciando processo de dump da origem comando: $mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem $basededadosorigem > $arquivosql "
#$mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem --no-tablespaces --set-gtid-purged=OFF --databases $basededadosorigem > $arquivosql 
#echo "Terminou processo de dump da origem"

echo "Iniciando processo de restauracao no destino com comando $mysql $portadestino -h $servidordestino -u $usuariodestino -p$senhadestino $basededadosdestino < $arquivosql " >> $logFile
$mysql $portadestino -h $servidordestino -u $usuariodestino -p$senhadestino $basededadosdestino < $arquivosql  >> $logFile
echo "Terminou processo de restauracao no destino" >> $logFile

echo "ACABOU - AEEEEE"














