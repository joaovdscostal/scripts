#!/bin/bash
if [ $# -lt 1 ]; then
   echo "Você nao selecionou os parametros!"
   exit 1
fi

if [ $# -eq 1 ] && [ $1 == "--help" ]; then
    echo "Parametros"
    echo "-basededadosdestino    Nome do banco de dados destino!"
    echo "-basededadosorigem     Nome do banco de dados origem!"
    echo "-origem                Base origem (localhost, producao, ou homologacao)!"
    echo "-destino               Base destino (localhost, homologacao)"
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

if [ $origem != "producao" ] && [ $origem != "homologacao" ] && [ $origem != "localhost" ]; then
    echo "Origem inválida! Permitida: producao, homologacao ou localhost"
    exit 1
fi

if  [ $destino != "homologacao" ] && [ $destino != "localhost" ]; then
    echo "Destino inválido! Permitida: homologacao ou localhost"
    exit 1
fi

if [ $origem == "localhost" ]; then
    servidororigem='localhost'
    usuarioorigem='redentor_nds'
    senhaorigem='mysql'
fi

if [ $destino == "localhost" ]; then
    servidordestino='localhost'
    usuariodestino='redentor_nds'
    senhadestino='mysql'
fi

if [ $origem == "producao" ]; then
    servidororigem='70.38.37.101'
    usuarioorigem='redentor_nds'
    senhaorigem='v8L1T4Ljeo'
fi

if [ $origem == "homologacao" ]; then
    servidororigem='127.0.0.1'
    usuarioorigem='redentor_nds'
    senhaorigem='mysql'
fi

if [ $destino == "homologacao" ]; then
    servidordestino='127.0.0.1'
    usuariodestino='redentor_nds'
    senhadestino='mysql'
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


mysqldump=/usr/local/mysql/bin/mysqldump
mysql=/usr/local/mysql/bin/mysql

if [ $origem == "homologacao" ] || [ $destino == "homologacao" ]; then
    ps aux | grep -ie ssh | awk '{print $2}' | xargs kill -9 > /dev/null
    echo "Executando comando: /usr/bin/ssh -v -N -o ControlMaster=no -o ExitOnForwardFailure=yes -o ConnectTimeout=10 -o NumberOfPasswordPrompts=3 -o TCPKeepAlive=no -o ServerAliveInterval=60 -o ServerAliveCountMax=1 redentor@25.72.118.215 -L 59076:10.0.1.111:3306 &> /dev/null"
    /usr/bin/ssh -v -N -o  ControlMaster=no -o ExitOnForwardFailure=yes -o ConnectTimeout=10 -o NumberOfPasswordPrompts=3 -o TCPKeepAlive=no -o ServerAliveInterval=60 -o ServerAliveCountMax=1 redentor@25.72.118.215 -L 59076:10.0.1.111:3306 -f
fi

if [ $destino == "homologacao" ]; then
    portadestino="-P 59076"
fi

if [ $origem == "homologacao" ]; then
    portaorigem="-P 59076"
fi

rm -rf dados/origem.sql

echo "Iniciando processo de dump da origem comando: $mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem $basededadosorigem > dados/origem.sql 
 "
$mysqldump $portaorigem -h $servidororigem -u $usuarioorigem -p$senhaorigem $basededadosorigem > dados/origem.sql 
echo "Terminou processo de dump da origem"

echo "Iniciando processo de restauracao no destino com comando $mysql $portadestino -h $servidordestino -u $usuariodestino -p$senhadestino $basededadosdestino < dados/origem.sql wh"
$mysql $portadestino -h $servidordestino -u $usuariodestino -p$senhadestino $basededadosdestino < dados/origem.sql 
echo "Terminou processo de restauracao no destino"







echo "ACABOU - AEEEEE"

if [ $origem == "homologacao" ] || [ $destino == "homologacao" ]; then
    ps aux | grep -ie ssh | awk '{print $2}' | xargs kill -9 > /dev/null
fi
#echo "TEste de destino $destino"













