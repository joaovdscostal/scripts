#!/bin/bash

# Variáveis de conexão
USER="root"
PASSWORD="mysql"
HOST="localhost"
DATABASE="code-erp-prod"

# 1) Desabilitar checagem de FKs (opcional, mas geralmente recomendado antes de dropar constraints)
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=0;"

# 2) Gerar e executar comandos para dropar todas as FKs
#    Vamos ler do INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS.
SQL_DROP_FK=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
  SELECT CONCAT('ALTER TABLE \`', TABLE_NAME, '\` DROP FOREIGN KEY \`', CONSTRAINT_NAME, '\`;')
  FROM information_schema.REFERENTIAL_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = '$DATABASE';
")

echo "Apagando todas as Foreign Keys..."
# Executa de uma só vez os comandos gerados
if [ -n "$SQL_DROP_FK" ]; then
  mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "$SQL_DROP_FK"
else
  echo "Nenhuma FK encontrada no schema '$DATABASE'."
fi

# 3) Para cada tabela do banco, se existir a coluna 'id', removê-la
TABLES=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "SHOW TABLES;")

for TABLE in $TABLES; do
  HAS_ID=$(mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -sN -e "
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = '$DATABASE'
      AND TABLE_NAME = '$TABLE'
      AND COLUMN_NAME = 'id';
  ")
  if [ "$HAS_ID" -eq 1 ]; then
    echo "Removendo coluna 'id' da tabela '$TABLE'..."
    mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
      ALTER TABLE \`$TABLE\` DROP COLUMN \`id\`;
    "
  fi
done

# 4) Em seguida, adicionar novamente a coluna 'id' como INT AUTO_INCREMENT PK em cada tabela
#    - O script abaixo simplesmente força a criação desse 'id' em todas as tabelas.
#    - Se alguma tabela já tiver outra PK (ou for uma tabela de relacionamento), revise antes de criar outra PK.
for TABLE in $TABLES; do
  echo "Criando nova coluna 'id' AUTO_INCREMENT em '$TABLE'..."
  mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "
    ALTER TABLE \`$TABLE\`
      ADD COLUMN \`id\` BIGINT NOT NULL AUTO_INCREMENT,
      ADD PRIMARY KEY (\`id\`);
  "
done

# 5) Reabilitar checagem de FKs (depende se você quer ficar sem FK até recriá-las ou não)
mysql -u"$USER" -p"$PASSWORD" -h"$HOST" -D"$DATABASE" -e "SET FOREIGN_KEY_CHECKS=1;"

echo "Processo concluído."