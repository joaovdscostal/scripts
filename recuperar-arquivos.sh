#!/bin/bash
# Script para recuperar arquivos de um backup após deploy que apagou tudo

# Configurações
PROJECT_NAME="route-365"
SERVER_HOST="157.230.231.220"
SERVER_USER="root"
TOMCAT_PATH="/root/appservers/apache-tomcat-9/webapps/$PROJECT_NAME"
BACKUP_DIR="/root/backups/$PROJECT_NAME"

echo "🔍 Verificando backups disponíveis..."
echo ""

# Lista backup
ssh -i ~/.ssh/id_ed25519 $SERVER_USER@$SERVER_HOST << 'ENDSSH'
  cd /root/backups/route-365

  if [ -f "backup_latest.tar.gz" ]; then
    echo "✅ Backup disponível:"
    ls -lh backup_latest.tar.gz
  else
    echo "❌ Nenhum backup encontrado!"
    exit 1
  fi
ENDSSH

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 OPÇÕES DE RECUPERAÇÃO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1) Recuperar APENAS arquivos/ e img/ (recomendado)"
echo "2) Recuperar arquivos/ + img/ + WEB-INF/web.xml"
echo "3) Restaurar backup COMPLETO (substitui tudo)"
echo "4) Extrair backup para análise manual"
echo "5) Sair"
echo ""
read -p "Escolha uma opção [1-5]: " OPCAO

case $OPCAO in
  1)
    echo "📂 Recuperando apenas arquivos/ e img/..."
    ssh -i ~/.ssh/id_ed25519 $SERVER_USER@$SERVER_HOST << 'ENDSSH'
      BACKUP="backup_latest.tar.gz"
      echo "Usando backup: $BACKUP"

      # Extrai em temp
      TEMP_DIR="/tmp/recovery_$$"
      mkdir -p $TEMP_DIR
      cd $TEMP_DIR
      tar -xzf /root/backups/route-365/$BACKUP

      # Copia apenas arquivos e img
      if [ -d "route-365/arquivos" ]; then
        echo "→ Recuperando arquivos/"
        cp -rv route-365/arquivos /root/appservers/apache-tomcat-9/webapps/route-365/
      fi

      if [ -d "route-365/img" ]; then
        echo "→ Recuperando img/"
        cp -rv route-365/img /root/appservers/apache-tomcat-9/webapps/route-365/
      fi

      # Limpa
      rm -rf $TEMP_DIR

      echo "✅ Recuperação concluída!"
ENDSSH
    ;;

  2)
    echo "📂 Recuperando arquivos/ + img/ + web.xml..."
    ssh -i ~/.ssh/id_ed25519 $SERVER_USER@$SERVER_HOST << 'ENDSSH'
      BACKUP="backup_latest.tar.gz"
      echo "Usando backup: $BACKUP"

      TEMP_DIR="/tmp/recovery_$$"
      mkdir -p $TEMP_DIR
      cd $TEMP_DIR
      tar -xzf /root/backups/route-365/$BACKUP

      if [ -d "route-365/arquivos" ]; then
        echo "→ Recuperando arquivos/"
        cp -rv route-365/arquivos /root/appservers/apache-tomcat-9/webapps/route-365/
      fi

      if [ -d "route-365/img" ]; then
        echo "→ Recuperando img/"
        cp -rv route-365/img /root/appservers/apache-tomcat-9/webapps/route-365/
      fi

      if [ -f "route-365/WEB-INF/web.xml" ]; then
        echo "→ Recuperando WEB-INF/web.xml"
        cp -v route-365/WEB-INF/web.xml /root/appservers/apache-tomcat-9/webapps/route-365/WEB-INF/
      fi

      rm -rf $TEMP_DIR

      echo "✅ Recuperação concluída!"
ENDSSH
    ;;

  3)
    echo "⚠️  ATENÇÃO: Isso vai substituir TODA a aplicação atual!"
    read -p "Tem certeza? [s/N] " CONFIRM
    if [ "$CONFIRM" = "s" ] || [ "$CONFIRM" = "S" ]; then
      echo "🔄 Restaurando backup completo..."
      ssh -i ~/.ssh/id_ed25519 $SERVER_USER@$SERVER_HOST << 'ENDSSH'
        /root/tomcat.sh stop

        BACKUP="backup_latest.tar.gz"
        echo "Restaurando: $BACKUP"

        cd /root/appservers/apache-tomcat-9/webapps
        rm -rf route-365
        tar -xzf /root/backups/route-365/$BACKUP

        /root/tomcat.sh start

        echo "✅ Backup restaurado!"
ENDSSH
    else
      echo "Operação cancelada."
    fi
    ;;

  4)
    echo "📦 Extraindo backup para análise..."
    ssh -i ~/.ssh/id_ed25519 $SERVER_USER@$SERVER_HOST << 'ENDSSH'
      BACKUP="backup_latest.tar.gz"
      echo "Extraindo: $BACKUP"

      EXTRACT_DIR="/tmp/backup_analysis_\$(date +%Y%m%d_%H%M%S)"
      mkdir -p \$EXTRACT_DIR
      cd \$EXTRACT_DIR
      tar -xzf /root/backups/route-365/\$BACKUP

      echo ""
      echo "✅ Backup extraído em: \$EXTRACT_DIR"
      echo ""
      echo "Estrutura:"
      du -h --max-depth=2 \$EXTRACT_DIR
ENDSSH
    ;;

  5)
    echo "Saindo..."
    exit 0
    ;;

  *)
    echo "❌ Opção inválida!"
    exit 1
    ;;
esac
