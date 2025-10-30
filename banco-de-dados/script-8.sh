#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

echo "Iniciando atualização de criadoPor_id e modificadoPor_id..."

# 0) Desabilitar FK checks (opcional, se quiser evitar algum conflito)
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=0;"

# 1) Recria (zera) tabela possible_references
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
  DROP TABLE IF EXISTS \`possible_references\`;
"

mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
  CREATE TABLE \`possible_references\` (
    \`id\` INT AUTO_INCREMENT PRIMARY KEY,
    \`referencing_table\`   VARCHAR(128) NOT NULL,
    \`referencing_column\`  VARCHAR(128) NOT NULL,
    \`referenced_table\`    VARCHAR(128) NOT NULL,
    \`referenced_column\`   VARCHAR(128) NOT NULL,
    \`example_value\`       BIGINT NULL,
    \`row_count\`           INT NOT NULL DEFAULT 0,
    \`created_at\`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
  );
"

# 2) Obter todas as tabelas do banco
ALL_TABLES=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "SHOW TABLES;")

# 3) Descobrir quais tabelas possuem a coluna 'id_antigo'
#    (pois agora queremos ver se alguma coluna BIGINT faz join com TBL2.id_antigo)
TABLES_WITH_ID_ANTIGO=()
while IFS= read -r TBL; do
  HAS_ID_ANTIGO=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA='$DATABASE'
      AND TABLE_NAME='$TBL'
      AND COLUMN_NAME='id_antigo';
  ")
  if [ "$HAS_ID_ANTIGO" -gt 0 ]; then
    TABLES_WITH_ID_ANTIGO+=("$TBL")
  fi
done <<< "$ALL_TABLES"

# 4) Para cada tabela, descobrir colunas BIGINT que não sejam FK
#    e também que não sejam 'codigoReferencia', 'criadoPor_id', 'modificadoPor_id', 'id', 'id_antigo'
for TBL in $ALL_TABLES; do

  # Lista as colunas BIGINT, excluindo colunas já usadas como FK
  # e ignorando nomes indesejados
  COLUMNS_BIGINT=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
    SELECT C.COLUMN_NAME
    FROM information_schema.COLUMNS C
    WHERE C.TABLE_SCHEMA = '$DATABASE'
      AND C.TABLE_NAME = '$TBL'
      AND C.DATA_TYPE = 'bigint'
      -- (ou C.COLUMN_TYPE LIKE 'bigint%' se preferir)
      AND C.COLUMN_NAME NOT IN (
          'codigoReferencia',
          'criadoPor_id',
          'modificadoPor_id',
          'id',
          'id_antigo'
      )
      AND NOT EXISTS (
          SELECT 1
          FROM information_schema.KEY_COLUMN_USAGE K
          JOIN information_schema.TABLE_CONSTRAINTS TCONS
               ON K.CONSTRAINT_NAME = TCONS.CONSTRAINT_NAME
              AND K.TABLE_SCHEMA = TCONS.TABLE_SCHEMA
              AND TCONS.CONSTRAINT_TYPE = 'FOREIGN KEY'
          WHERE K.TABLE_SCHEMA = C.TABLE_SCHEMA
            AND K.TABLE_NAME = C.TABLE_NAME
            AND K.COLUMN_NAME = C.COLUMN_NAME
      );
  ")

  # Se não achou colunas BIGINT sem FK, pula
  if [ -z "$COLUMNS_BIGINT" ]; then
    continue
  fi

  # Para cada coluna BIGINT, verificar se referencia a "id_antigo" de alguma tabela
  for COL in $COLUMNS_BIGINT; do
    for TBL2 in "${TABLES_WITH_ID_ANTIGO[@]}"; do

      # Contar quantas linhas batem
      ROW_COUNT=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
        SELECT COUNT(*)
        FROM \`$TBL\` t
        JOIN \`$TBL2\` x ON t.\`$COL\` = x.id_antigo
        WHERE t.\`$COL\` IS NOT NULL
      ")

      if [ "$ROW_COUNT" -gt 0 ]; then
        # Achamos correspondência -> TBL.COL aparentemente referencia TBL2.id_antigo

        # Pegar um valor de exemplo
        EXAMPLE_VAL=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
          SELECT t.\`$COL\`
          FROM \`$TBL\` t
          JOIN \`$TBL2\` x ON t.\`$COL\` = x.id_antigo
          WHERE t.\`$COL\` IS NOT NULL
          LIMIT 1;
        ")

        # Inserir um registro em possible_references
        mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
          INSERT INTO \`possible_references\`
            (\`referencing_table\`, \`referencing_column\`, \`referenced_table\`, \`referenced_column\`, \`example_value\`, \`row_count\`)
          VALUES
            ('$TBL', '$COL', '$TBL2', 'id_antigo', '$EXAMPLE_VAL', $ROW_COUNT);
        "

        # Se quiser parar no primeiro match (caso não faça sentido 
        # referenciar mais de uma tabela), poderia usar "break"
        # mas se deseja capturar todos, mantenha sem break.
      fi

    done
  done
done

# 5) Reabilitar checks de FK
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=1;"

echo "Processo de detecção finalizado! Consulte a tabela 'possible_references'."