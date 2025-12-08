#!/bin/bash
if [ $# -lt 1 ]; then
   echo "Você nao selecionou os parametros!"
   exit 1
fi

if [ $# -eq 1 ] && [ $1 == "--help" ]; then
    echo "Parametros"
    echo "-basededadosorigem     Nome do banco de dados origem!"
    echo "-origem                Base origem (producao, poker, jhonata, testes, localhost)!"
    exit 1
fi


while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -basededadosorigem)
    basededadosorigem="$2"
    shift # past argument
    ;;
    -origem)
    origem="$2"
    shift # past argument
    ;;
    
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

echo "Iniciou processo de execucao de importacao de banco de dados!"


if [ -z $basededadosorigem ];
then
    echo "Por favor digite a base de dados origem."
    exit 1
fi

if [ $origem != "producao" ]  && [ $origem != "poker" ]  && [ $origem != "jhonata" ] && 
    [ $origem != "formeseguro" ] &&
 [ $origem != "localhost" ] && [ $origem != "testes" ] && [ $origem != "bu-homolog" ] &&  [ $origem != "servidor-cidadania" ]; then
    echo "Origem inválida! Permitida: producao, jhonata, poker, formeseguro, testes, servidor-cidadania, bu-homolog ou localhost"
    exit 1
fi



if [ $origem == "localhost" ]; then
    servidororigem='localhost'
    usuarioorigem='root'
    senhaorigem='mysql'
fi

if [ $origem == "producao" ]; then
    servidororigem='157.230.231.220'
    usuarioorigem='root'
    senhaorigem='MuTk9xL2W9v'
fi


if [ $origem == "testes" ]; then
    servidororigem='164.90.147.61'
    usuarioorigem='root'
    senhaorigem='MuTk9xL2W9v'
fi

if [ $origem == "poker" ]; then
    servidororigem='191.252.196.239'
    usuarioorigem='root'
    senhaorigem='MuTk9xL2W9v'
fi

if [ $origem == "jhonata" ]; then
    servidororigem='192.241.133.126'
    usuarioorigem='root'
    senhaorigem='J4M38n2p4bjk'
fi

if [ $origem == "servidor-cidadania" ]; then
    servidororigem='142.93.127.120'
    usuarioorigem='root'
    senhaorigem='MuTk9xL2W9v'
fi

if [ $origem == "formeseguro" ]; then
    servidororigem='35.222.5.173'
    usuarioorigem='formeseguro'
    senhaorigem='sr8x-vGzSeg'
fi

if [ $origem == "bu-homolog" ]; then
    servidororigem='dbmysg-homologacao.ca6icfds8q4p.us-east-1.rds.amazonaws.com'
    usuarioorigem='root'
    senhaorigem='SGMyDb.3427#'
fi





#mysqldump=/usr/local/opt/mysql@5.6/bin/mysqldump
#mysql=/usr/local/opt/mysql@5.6/bin/mysql
mysqldump=/opt/homebrew/opt/mysql@8.1/bin/mysqldump
mysql=/opt/homebrew/opt/mysql@8.1/bin/mysql

arquivosql=/Users/nds/Workspace/dados/backup$basededadosorigem.sql
logFile=/home/ubuntu/backup/dados/log.txt


#rm -rf $arquivosql

echo "Iniciando processo de dump da origem comando: $mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem $basededadosorigem > $arquivosql "
$mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem --no-tablespaces --set-gtid-purged=OFF --databases $basededadosorigem > $arquivosql 
echo "Terminou processo de dump da origem"

echo "ACABOU - AEEEEE"














