#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

# 1. Criar/Recriar tabela fk_backup no banco
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -e "
  DROP TABLE IF EXISTS \`fk_backup\`;
"

mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -e "
  CREATE TABLE \`fk_backup\` (
    \`constraint_name\`        VARCHAR(128) NOT NULL,
    \`table_name\`             VARCHAR(128) NOT NULL,
    \`column_name\`            VARCHAR(128) NOT NULL,
    \`referenced_table_name\`  VARCHAR(128) NOT NULL,
    \`referenced_column_name\` VARCHAR(128) NOT NULL,
    \`update_rule\`            VARCHAR(50)  NOT NULL,
    \`delete_rule\`            VARCHAR(50)  NOT NULL,
    PRIMARY KEY (\`constraint_name\`, \`table_name\`, \`column_name\`) 
    -- A PK aqui é só para evitar duplicações; ajuste conforme a sua necessidade.
  );
"

# 2. Inserir informações das Foreign Keys a partir do INFORMATION_SCHEMA
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D "$DATABASE" -e "
  INSERT INTO \`fk_backup\` (
    constraint_name,
    table_name,
    column_name,
    referenced_table_name,
    referenced_column_name,
    update_rule,
    delete_rule
  )
  SELECT 
    rc.CONSTRAINT_NAME,
    kcu.TABLE_NAME,
    kcu.COLUMN_NAME,
    rc.REFERENCED_TABLE_NAME,
    kcu.REFERENCED_COLUMN_NAME,
    rc.UPDATE_RULE,
    rc.DELETE_RULE
  FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
  JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
       ON rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
      AND rc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA
  WHERE rc.CONSTRAINT_SCHEMA = '${DATABASE}';
"

echo "Export das Foreign Keys concluído! Dados salvos em fk_backup."
echo "Script finalizado."