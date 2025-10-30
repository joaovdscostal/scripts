#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

echo "Iniciando atualização de criadoPor_id e modificadoPor_id..."

# 1) Desabilitar checagem de FKs (opcional, mas geralmente recomendável)
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=0;"

# 2) Verifica se a coluna 'ultimaFilialLogada' existe em 'USUARIO'
HAS_COL=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = '$DATABASE'
      AND TABLE_NAME = 'USUARIO'
      AND COLUMN_NAME = 'ultimaFilialLogada';
")

if [ "$HAS_COL" -eq 1 ]; then
    echo "Atualizando USUARIO.ultimaFilialLogada com base em FILIAL.id_antigo..."
    mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
        UPDATE \`USUARIO\` u
        JOIN \`FILIAL\` f
           ON u.\`ultimaFilialLogada\` = f.\`id_antigo\`
        SET u.\`ultimaFilialLogada\` = f.\`id\`
        WHERE u.\`ultimaFilialLogada\` IS NOT NULL
    "
    echo "Atualização concluída."
else
    echo "A coluna 'ultimaFilialLogada' não existe na tabela 'USUARIO'. Nenhuma ação necessária."
fi

# 3) Reabilitar checagem de FKs
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=1;"

echo "Processo finalizado."