#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

echo "Iniciando a recriação de Foreign Keys..."

# 1) Desabilitar checagem de FKs (para evitar conflitos enquanto recriamos)
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=0;"

# 2) Ler os dados de fk_backup e montar dinamicamente o comando para criar cada FK
#    Supondo FKs de coluna única.
while IFS=$'\t' read -r constraint_name table_name column_name ref_table_name ref_column_name update_rule delete_rule
do
  # Monta o ALTER TABLE para criar a constraint
  # Exemplo para 1 coluna:
  # ALTER TABLE `pedidos`
  #   ADD CONSTRAINT `fk_pedidos_filial`
  #   FOREIGN KEY (`filial_id`) REFERENCES `filial`(`id`)
  #   ON UPDATE CASCADE
  #   ON DELETE RESTRICT;
  
  SQL_ALTER="
    ALTER TABLE \`${table_name}\`
      ADD CONSTRAINT \`${constraint_name}\`
      FOREIGN KEY (\`${column_name}\`)
      REFERENCES \`${ref_table_name}\` (\`${ref_column_name}\`)
      ON UPDATE ${update_rule}
      ON DELETE ${delete_rule}
  "
  
  echo "Recriando FK: ${constraint_name} em tabela '${table_name}'..."
  mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "$SQL_ALTER"

done < <(
  mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -s -N -e "
    SELECT 
      \`constraint_name\`,
      \`table_name\`,
      \`column_name\`,
      \`referenced_table_name\`,
      \`referenced_column_name\`,
      \`update_rule\`,
      \`delete_rule\`
    FROM \`fk_backup\`
    ORDER BY \`table_name\`, \`constraint_name\`;
  "
)

# 3) Reativar checagem de FKs
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=1;"

echo "Recriação de FKs finalizada!"