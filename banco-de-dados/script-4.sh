#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

# 1) Desabilitar checagem de FKs para evitar conflitos de integridade durante a atualização
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=0;"

# 2) Ler cada linha da tabela fk_backup e montar o UPDATE
#    Precisamos dos campos: table_name, column_name, referenced_table_name, ...
#    (Não vamos usar referenced_column_name diretamente, pois assumimos que a 'id_antigo' está
#     lá como referência ao velho valor, e 'id' é o valor novo.)
while IFS=$'\t' read -r constraint_name table_name column_name ref_table_name ref_column_name update_rule delete_rule
do
  # Monta o comando de atualização
  # Exemplo: 
  # UPDATE pedidos p
  # JOIN filial f ON p.filial_id = f.id_antigo
  # SET p.filial_id = f.id;
  
  SQL_UPDATE="
    UPDATE \`${table_name}\` t
    JOIN \`${ref_table_name}\` r
      ON t.\`${column_name}\` = r.id_antigo
    SET t.\`${column_name}\` = r.id
    WHERE t.\`${column_name}\` IS NOT NULL
      AND r.id_antigo IS NOT NULL
  "

  echo "Atualizando '${table_name}.${column_name}' -> '${ref_table_name}.id' (de 'id_antigo')"

  # Executa o UPDATE
  mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "$SQL_UPDATE"

done < <(
  # Aqui fazemos o SELECT na fk_backup para gerar o input do while
  mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -s -N -e "
    SELECT 
      \`constraint_name\`,
      \`table_name\`,
      \`column_name\`,
      \`referenced_table_name\`,
      \`referenced_column_name\`,
      \`update_rule\`,
      \`delete_rule\`
    FROM fk_backup
    ORDER BY table_name;
  "
)

# 3) Reabilitar checagem de FKs
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=1;"

echo "Processo de atualização de FKs concluído."