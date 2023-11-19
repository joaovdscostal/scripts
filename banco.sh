#!/bin/bash
if [ $# -lt 1 ]; then
   echo "Você nao selecionou os parametros!"
   exit 1
fi

if [ $# -eq 1 ] && [ $1 == "--help" ]; then
    echo "Parametros"
    echo "-basededadosdestino    Nome do banco de dados destino!"
    echo "-basededadosorigem     Nome do banco de dados origem!"
    echo "-origem                Base origem (localhost, producao, poker, tv, jhonata ou homologacao)!"
    echo "-destino               Base destino (localhost, localhost-mariadb)"
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

if [ $origem != "producao" ]  && [ $origem != "poker" ]  && [ $origem != "jhonata" ] && [ $origem != "localhost" ] && [ $origem != "tv" ]; then
    echo "Origem inválida! Permitida: producao, jhonata, poker, tv ou localhost"
    exit 1
fi

if  [ $destino != "localhost" ] && [ $destino != "localhost-mariadb" ]; then 
    echo "Destino inválido! Permitida: localhost ou localhost-mariadb"
    exit 1
fi

if [ $origem == "localhost" ]; then
    servidororigem='localhost'
    usuarioorigem='root'
    senhaorigem='mysql'
fi

if [ $destino == "localhost" ]; then
    servidordestino='localhost'
    usuariodestino='root'
    senhadestino='mysql'
fi

if [ $destino == "localhost-mariadb" ]; then
    servidordestino='localhost'
    usuariodestino='root'
    senhadestino='mysql'
fi

if [ $origem == "producao" ]; then
    servidororigem='157.230.231.220'
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

if [ $origem == "tv" ]; then
    servidororigem='137.184.69.82'
    usuarioorigem='admin'
    senhaorigem='AVNS_gBbXFCyFMp6Jrfv8j5a'
fi



#echo "Voce escolheu copiar de $origem deseja utilizar o mesmo servidor que é $servidororigem. Deseja alterar? Senão, só deixar vazio:"; 
#read servidor

#if [ -n "$servidor" ];
#then
#    servidororigem=$servidor;
#fi

#echo "Alterar usuario origem padrao? Senão, só deixar vazio:"; 
#read usuario

#if [ -n "$usuario" ];
#then
#    usuarioorigem=$usuario;
#fi

#echo "Alterar senha origem padrao? Senão, só deixar vazio:"; 
#read senha

#if [ -n "$senha" ];
#then
#    senhaorigem=$senha;
#fi


#echo "Voce escolheu copiar de $destino deseja utilizar o mesmo servidor que é $servidordestino. Deseja alterar? Senão, só deixar vazio:"; 
#read servidord

#if [ -n "$servidord" ];
#then
#    servidordestino=$servidord;
#fi

#echo "Alterar usuario destino padrao? Senão, só deixar vazio:"; 
#read usuariod

#if [ -n "$usuariod" ];
#then
 #   usuariodestino=$usuariod;
#fi

#echo "Alterar senha destino padrao? Senão, só deixar vazio:"; 
#read senhad

#if [ -n "$senhad" ];
#then
#    senhadestino=$senhad;
#fi


mysqldump=/usr/local/opt/mysql@5.6/bin/mysqldump
mysql=/usr/local/opt/mysql@5.6/bin/mysql
arquivosql=/Users/nds/Workspace/dados/origem.sql

if [ $destino == "localhost-mariadb" ]; then
    portadestino="-P 3310"
    mysqldump=/usr/local/opt/mariadb@10.10/bin/mysqldump
    mysql=/usr/local/opt/mariadb@10.10/bin/mysql
fi


rm -rf $arquivosql

echo "Iniciando processo de dump da origem comando: $mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem $basededadosorigem > $arquivosql 
 "
$mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem $basededadosorigem > $arquivosql 
echo "Terminou processo de dump da origem"

echo "Iniciando processo de restauracao no destino com comando $mysql $portadestino -h $servidordestino -u $usuariodestino -p$senhadestino $basededadosdestino < $arquivosql wh"
$mysql $portadestino -h $servidordestino -u $usuariodestino -p$senhadestino $basededadosdestino < $arquivosql 
echo "Terminou processo de restauracao no destino"

echo "ACABOU - AEEEEE"

if [ $origem == "homologacao" ] || [ $destino == "homologacao" ]; then
    ps aux | grep -ie ssh | awk '{print $2}' | xargs kill -9 > /dev/null
fi
#echo "TEste de destino $destino"













