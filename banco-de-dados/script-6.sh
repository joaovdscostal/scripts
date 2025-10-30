#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

echo "Iniciando atualização de criadoPor_id e modificadoPor_id..."

# 1) Desabilitar checagem de FK (opcional, mas evita problemas caso existam constraints)
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=0;"

# 2) Obter a lista de tabelas do banco
TABLES=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "SHOW TABLES;")

for TABLE in $TABLES; do
    
    # Verifica se a coluna criadoPor_id existe
    HAS_CRIADO=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = '$DATABASE'
          AND TABLE_NAME = '$TABLE'
          AND COLUMN_NAME = 'criadoPor_id';
    ")
    if [ "$HAS_CRIADO" -eq 1 ]; then
        echo "Atualizando coluna criadoPor_id na tabela $TABLE..."
        mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
            UPDATE \`${TABLE}\` t
            JOIN \`USUARIO\` u ON t.\`criadoPor_id\` = u.id_antigo
            SET t.\`criadoPor_id\` = u.id
            WHERE t.\`criadoPor_id\` IS NOT NULL
        "
    fi

    # Verifica se a coluna modificadoPor_id existe
    HAS_MODIFICADO=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = '$DATABASE'
          AND TABLE_NAME = '$TABLE'
          AND COLUMN_NAME = 'modificadoPor_id';
    ")
    if [ "$HAS_MODIFICADO" -eq 1 ]; then
        echo "Atualizando coluna modificadoPor_id na tabela $TABLE..."
        mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
            UPDATE \`${TABLE}\` t
            JOIN \`USUARIO\` u ON t.\`modificadoPor_id\` = u.id_antigo
            SET t.\`modificadoPor_id\` = u.id
            WHERE t.\`modificadoPor_id\` IS NOT NULL
        "
    fi

done

# 3) Reabilitar checagem de FKs
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=1;"

echo "Processo concluído."