#!/bin/bash


if [ $# -lt 1 ]; then
   echo "Faltou você escolher o projeto para observar"
   exit 1
fi

echo Voce escolheu enviar os projetos $1

if [ -d $1/.git ];
then

    echo "##### Observando projeto: $1 #####";

		cd /Workspace/$1
    mvn com.github.warmuuh:libsass-maven-plugin:0.2.10-libsass_3.5.3:watch
    cd ..

fi
