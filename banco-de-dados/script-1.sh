#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

TABLES=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -sN -e "SHOW TABLES;")

for TABLE in $TABLES; do
    # Verifica se a coluna 'id' existe
    COL_TYPE=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -sN -e "
        SELECT COLUMN_TYPE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = '$DATABASE'
          AND TABLE_NAME = '$TABLE'
          AND COLUMN_NAME = 'id';
    ")

    if [ -n "$COL_TYPE" ]; then
        # Opcional: verificar se 'id_antigo' já existe, para evitar erro de duplicidade
        ALREADY_EXISTS=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -sN -e "
            SELECT COLUMN_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = '$DATABASE'
              AND TABLE_NAME = '$TABLE'
              AND COLUMN_NAME = 'id_antigo';
        ")

        if [ -z "$ALREADY_EXISTS" ]; then
            echo "Criando coluna 'id_antigo' na tabela '$TABLE'..."
            mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -e "
                ALTER TABLE $TABLE
                ADD COLUMN id_antigo $COL_TYPE;
            "

            echo "Copiando dados de 'id' para 'id_antigo' na tabela '$TABLE'..."
            mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -e "
                UPDATE $TABLE
                SET id_antigo = id;
            "
        else
            echo "A coluna 'id_antigo' já existe na tabela '$TABLE'. Pulando..."
        fi
    fi
done

echo "Script finalizado."