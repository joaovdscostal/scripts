#!/bin/bash
# ============================================================================
# SCRIPT DE RESTORE COMPLETO PARA VPS
# ============================================================================
# Este script restaura todos os componentes do backup:
# - Bancos de dados MariaDB
# - Aplicações Spring Boot (Java 21)
# - Apache Tomcat 9
# - Aplicações Node.js (PM2)
# - Aplicações estáticas (HTML)
# - Configurações Nginx + SSL (Certbot)
# - Scripts customizados
# ============================================================================

set -euo pipefail

# ============================================================================
# FUNÇÃO PARA ENVIAR NOTIFICAÇÃO VIA WHATSAPP
# ============================================================================

send_whatsapp_notification() {
    local MESSAGE="$1"
    local STATUS="${2:-info}"  # success, error, info

    if [ "${SEND_WHATSAPP_NOTIFICATION:-false}" != true ]; then
        return 0
    fi

    # Adicionar emoji baseado no status
    case "$STATUS" in
        "success")
            MESSAGE="✅ $MESSAGE"
            ;;
        "error")
            MESSAGE="❌ $MESSAGE"
            ;;
        "info")
            MESSAGE="ℹ️ $MESSAGE"
            ;;
    esac

    # Enviar mensagem via API
    local TEMP_RESPONSE=$(mktemp)
    local HTTP_CODE=$(curl --silent --show-error --write-out "%{http_code}" \
        --location --request POST "${WHATSAPP_API_URL}" \
        --header 'Content-Type: application/json' \
        --header "apiKey: ${WHATSAPP_API_KEY}" \
        --output "$TEMP_RESPONSE" \
        --data "{
            \"number\": \"${WHATSAPP_NUMBER}\",
            \"textMessage\": {
                \"text\": \"${MESSAGE}\"
            }
        }" 2>&1)

    local CURL_EXIT=$?
    local RESPONSE_BODY=$(cat "$TEMP_RESPONSE" 2>/dev/null)
    rm -f "$TEMP_RESPONSE"

    # Log do resultado
    if [ $CURL_EXIT -eq 0 ] && [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        echo "[INFO] WhatsApp enviado (HTTP $HTTP_CODE)"
        return 0
    else
        echo "[AVISO] Falha ao enviar WhatsApp (curl exit: $CURL_EXIT, HTTP: $HTTP_CODE)"
        [ -n "$RESPONSE_BODY" ] && echo "[AVISO] Resposta: $RESPONSE_BODY"
        return 1
    fi
}

# ============================================================================
# TRATAMENTO DE ERROS
# ============================================================================

# Variável para armazenar o último comando executado
LAST_COMMAND=""
trap 'LAST_COMMAND=$BASH_COMMAND' DEBUG

# Função para lidar com erros
handle_error() {
    local EXIT_CODE=$?
    local LINE_NUMBER=$1

    echo -e "${RED}[ERRO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - Erro na linha ${LINE_NUMBER}: código de saída ${EXIT_CODE}"
    echo -e "${RED}[ERRO]${NC} Comando que falhou: ${LAST_COMMAND}"

    # Enviar notificação de erro via WhatsApp
    ERROR_MESSAGE="⚠️ *Restore VPS FALHOU*

📅 Data: $(date '+%d/%m/%Y %H:%M:%S')
❌ Linha: ${LINE_NUMBER}
🔢 Código: ${EXIT_CODE}

🔧 Comando:
\`${LAST_COMMAND}\`

📝 Log: ${RESTORE_LOG:-Não disponível}"

    # Garantir que a notificação seja enviada
    if [ "${SEND_WHATSAPP_NOTIFICATION:-false}" = true ]; then
        send_whatsapp_notification "$ERROR_MESSAGE" "error" 2>&1 || echo "Falha ao enviar WhatsApp de erro"
    fi

    exit $EXIT_CODE
}

# Registrar handler de erro
trap 'handle_error ${LINENO}' ERR

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Comando '$1' não encontrado. Instale-o antes de continuar."
        return 1
    fi
    return 0
}

confirm_action() {
    local message=$1
    echo -e "${YELLOW}[CONFIRMAÇÃO]${NC} $message"
    read -p "Deseja continuar? (S/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_warning "Operação cancelada pelo usuário"
        return 1
    fi
    return 0
}

# ============================================================================
# VERIFICAR ARGUMENTOS
# ============================================================================

if [ $# -lt 1 ]; then
    echo "Uso: $0 <caminho-do-backup>"
    echo ""
    echo "Exemplos:"
    echo "  $0 /root/backups/20250130_120000.tar.gz"
    echo "  $0 /root/backups/20250130_120000"
    exit 1
fi

BACKUP_SOURCE=$1

# Verificar se é arquivo compactado ou diretório
if [ -f "$BACKUP_SOURCE" ]; then
    log_info "Detectado arquivo de backup compactado"

    # Extrair backup
    BACKUP_EXTRACT_DIR="/tmp/restore_$(date +%s)"
    mkdir -p "$BACKUP_EXTRACT_DIR"

    log_info "Extraindo backup..."
    tar -xzf "$BACKUP_SOURCE" -C "$BACKUP_EXTRACT_DIR"

    BACKUP_DIR=$(find "$BACKUP_EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)

elif [ -d "$BACKUP_SOURCE" ]; then
    log_info "Detectado diretório de backup"
    BACKUP_DIR="$BACKUP_SOURCE"
else
    log_error "Backup não encontrado: $BACKUP_SOURCE"
    exit 1
fi

log_success "Backup localizado em: $BACKUP_DIR"

# ============================================================================
# CARREGAR CONFIGURAÇÕES (se disponível)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/backup.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    log_info "Configurações carregadas de: $CONFIG_FILE"
else
    log_warning "Arquivo de configuração não encontrado. Usando valores padrão."

    # Valores padrão
    TOMCAT_HOME="/opt/tomcat9"
    NGINX_CONFIG_DIR="/etc/nginx"
    SSL_CERTS_DIR="/etc/letsencrypt"
    PM2_USER="root"
fi

# ============================================================================
# LOG
# ============================================================================

RESTORE_LOG="/var/log/restore-vps-$(date +%Y%m%d_%H%M%S).log"
RESTORE_CRON_LOG="${CRON_LOG_FILE:-/root/backups/ultimo_restore.log}"

# Redirecionar output para arquivo de log detalhado e para log do cron (sobrescreve)
exec > >(tee -a "$RESTORE_LOG" | tee "$RESTORE_CRON_LOG") 2>&1

log_info "=========================================="
log_info "INICIANDO RESTORE VPS"
log_info "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')"
log_info "Backup: $BACKUP_DIR"
log_info "=========================================="

# ============================================================================
# MOSTRAR INVENTÁRIO
# ============================================================================

if [ -f "${BACKUP_DIR}/inventory/system-info.txt" ]; then
    log_info "Informações do sistema de origem:"
    echo "=========================================="
    head -30 "${BACKUP_DIR}/inventory/system-info.txt"
    echo "=========================================="
    echo ""

    if ! confirm_action "Este é o backup correto?"; then
        exit 1
    fi
fi

# ============================================================================
# MENU DE RESTORE
# ============================================================================

echo ""
log_info "Selecione o que deseja restaurar:"
echo ""
echo "  === RESTAURAÇÃO RÁPIDA ==="
echo "  [1] Tudo (restore completo)"
echo "  [2] Tudo EXCETO banco de dados"
echo "  [3] Infraestrutura (tudo exceto banco e webapps)"
echo ""
echo "  === COMPONENTES INDIVIDUAIS ==="
echo "  [4] Apenas banco de dados"
echo "  [5] Apenas webapps do Tomcat"
echo "  [6] Apenas aplicações Spring Boot"
echo "  [7] Apenas Tomcat (sem webapps)"
echo "  [8] Apenas Node.js"
echo "  [9] Apenas aplicações estáticas"
echo "  [10] Apenas Nginx"
echo "  [11] Apenas scripts customizados"
echo ""
echo "  [12] Personalizado (escolher componentes)"
echo ""
read -p "Opção: " RESTORE_OPTION

RESTORE_DB=false
RESTORE_SPRINGBOOT=false
RESTORE_TOMCAT=false
RESTORE_TOMCAT_WEBAPPS_ONLY=false
RESTORE_NODEJS=false
RESTORE_STATIC=false
RESTORE_NGINX=false
RESTORE_SCRIPTS=false

case $RESTORE_OPTION in
    1)
        # Tudo
        RESTORE_DB=true
        RESTORE_SPRINGBOOT=true
        RESTORE_TOMCAT=true
        RESTORE_NODEJS=true
        RESTORE_STATIC=true
        RESTORE_NGINX=true
        RESTORE_SCRIPTS=true
        ;;
    2)
        # Tudo exceto banco
        RESTORE_DB=false
        RESTORE_SPRINGBOOT=true
        RESTORE_TOMCAT=true
        RESTORE_NODEJS=true
        RESTORE_STATIC=true
        RESTORE_NGINX=true
        RESTORE_SCRIPTS=true
        ;;
    3)
        # Infraestrutura (sem banco e sem webapps)
        RESTORE_DB=false
        RESTORE_SPRINGBOOT=true
        RESTORE_TOMCAT=true
        RESTORE_NODEJS=true
        RESTORE_STATIC=true
        RESTORE_NGINX=true
        RESTORE_SCRIPTS=true
        # Flag para indicar que deve restaurar Tomcat mas sem webapps
        RESTORE_TOMCAT_SKIP_WEBAPPS=true
        ;;
    4) RESTORE_DB=true ;;
    5)
        # Apenas webapps
        RESTORE_TOMCAT=true
        RESTORE_TOMCAT_WEBAPPS_ONLY=true
        ;;
    6) RESTORE_SPRINGBOOT=true ;;
    7)
        # Apenas Tomcat sem webapps
        RESTORE_TOMCAT=true
        RESTORE_TOMCAT_SKIP_WEBAPPS=true
        ;;
    8) RESTORE_NODEJS=true ;;
    9) RESTORE_STATIC=true ;;
    10) RESTORE_NGINX=true ;;
    11) RESTORE_SCRIPTS=true ;;
    12)
        read -p "Restaurar banco de dados? (S/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Ss]$ ]] && RESTORE_DB=true
        read -p "Restaurar Spring Boot? (S/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Ss]$ ]] && RESTORE_SPRINGBOOT=true
        read -p "Restaurar Tomcat? (S/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Ss]$ ]] && RESTORE_TOMCAT=true
        if [ "$RESTORE_TOMCAT" = true ]; then
            read -p "  Restaurar webapps do Tomcat? (S/N): " -n 1 -r; echo; [[ ! $REPLY =~ ^[Ss]$ ]] && RESTORE_TOMCAT_SKIP_WEBAPPS=true
        fi
        read -p "Restaurar Node.js? (S/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Ss]$ ]] && RESTORE_NODEJS=true
        read -p "Restaurar aplicações estáticas? (S/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Ss]$ ]] && RESTORE_STATIC=true
        read -p "Restaurar Nginx? (S/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Ss]$ ]] && RESTORE_NGINX=true
        read -p "Restaurar scripts? (S/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Ss]$ ]] && RESTORE_SCRIPTS=true
        ;;
    *)
        log_error "Opção inválida"
        exit 1
        ;;
esac

# ============================================================================
# RESTORE BANCO DE DADOS
# ============================================================================

if [ "$RESTORE_DB" = true ]; then
    log_info "=========================================="
    log_info "RESTORE DE BANCO DE DADOS"
    log_info "=========================================="

    if ! confirm_action "ATENÇÃO: Isto irá SOBRESCREVER os bancos de dados existentes!"; then
        log_warning "Restore de banco de dados cancelado"
    else
        # Verificar credenciais
        if [ -z "${DB_USER:-}" ] || [ -z "${DB_PASSWORD:-}" ]; then
            read -p "Usuário do MariaDB: " DB_USER
            read -sp "Senha do MariaDB: " DB_PASSWORD
            echo ""
        fi

        # Verificar método de backup usado
        if [ -d "${BACKUP_DIR}/database/mariabackup" ]; then
            log_info "Detectado backup físico (mariabackup)"

            if ! check_command mariabackup; then
                log_error "mariabackup não encontrado. Instale: sudo apt install mariadb-backup"
                exit 1
            fi

            log_warning "ATENÇÃO: O restore com mariabackup requer que o MariaDB esteja parado!"
            if confirm_action "Parar o MariaDB agora?"; then
                systemctl stop mariadb || systemctl stop mysql

                # Fazer backup do datadir atual
                DATADIR=$(mysql_config --variable=datadir || echo "/var/lib/mysql")
                DATADIR_BACKUP="${DATADIR}_backup_$(date +%s)"

                log_info "Fazendo backup do datadir atual..."
                mv "$DATADIR" "$DATADIR_BACKUP"

                # Restaurar
                log_info "Restaurando backup..."
                mariabackup --copy-back --target-dir="${BACKUP_DIR}/database/mariabackup"

                # Ajustar permissões
                chown -R mysql:mysql "$DATADIR"

                # Iniciar MariaDB
                systemctl start mariadb || systemctl start mysql

                log_success "Banco de dados restaurado com mariabackup"
            fi

        elif ls "${BACKUP_DIR}/database/"*.sql &> /dev/null; then
            log_info "Detectado backup lógico (mysqldump)"

            for SQL_FILE in "${BACKUP_DIR}/database/"*.sql; do
                DB_NAME=$(basename "$SQL_FILE" .sql)
                log_info "Restaurando banco: $DB_NAME"

                mysql -u"$DB_USER" -p"$DB_PASSWORD" < "$SQL_FILE"

                log_success "  Banco $DB_NAME restaurado"
            done

        else
            log_warning "Nenhum backup de banco de dados encontrado"
        fi
    fi
fi

# ============================================================================
# RESTORE SPRING BOOT
# ============================================================================

if [ "$RESTORE_SPRINGBOOT" = true ] && [ -d "${BACKUP_DIR}/springboot" ]; then
    log_info "=========================================="
    log_info "RESTORE DE APLICAÇÕES SPRING BOOT"
    log_info "=========================================="

    for APP_DIR in "${BACKUP_DIR}/springboot/"*; do
        [ -d "$APP_DIR" ] || continue

        APP_NAME=$(basename "$APP_DIR")
        log_info "Restaurando aplicação: $APP_NAME"

        # Solicitar destino
        read -p "Diretório de destino para $APP_NAME [/opt/apps/$APP_NAME]: " TARGET_DIR
        TARGET_DIR=${TARGET_DIR:-/opt/apps/$APP_NAME}

        mkdir -p "$TARGET_DIR"

        # Copiar todos os arquivos (exceto .service que vai para systemd)
        log_info "  Copiando arquivos da aplicação..."
        for ITEM in "$APP_DIR"/*; do
            ITEM_NAME=$(basename "$ITEM")

            # Pular arquivos .service (serão copiados para /etc/systemd/system)
            if [[ "$ITEM_NAME" == *.service ]]; then
                continue
            fi

            # Copiar tudo mais
            if [ -f "$ITEM" ]; then
                cp "$ITEM" "$TARGET_DIR/"
            elif [ -d "$ITEM" ]; then
                cp -r "$ITEM" "$TARGET_DIR/"
            fi
        done

        log_success "  Arquivos da aplicação copiados"

        # Contar o que foi restaurado
        JAR_COUNT=$(ls "$TARGET_DIR"/*.jar 2>/dev/null | wc -l)
        CONFIG_COUNT=$(ls "$TARGET_DIR"/application.* 2>/dev/null | wc -l)

        [ "$JAR_COUNT" -gt 0 ] && log_success "  JARs encontrados: $JAR_COUNT"
        [ "$CONFIG_COUNT" -gt 0 ] && log_success "  Arquivos de configuração: $CONFIG_COUNT"

        # Restaurar service systemd
        if ls "$APP_DIR"/*.service &> /dev/null; then
            cp "$APP_DIR"/*.service /etc/systemd/system/
            systemctl daemon-reload
            log_success "  Service systemd restaurado"

            SERVICE_NAME=$(basename "$APP_DIR"/*.service)
            read -p "Deseja habilitar e iniciar o serviço $SERVICE_NAME? (S/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                systemctl enable "$SERVICE_NAME"
                systemctl start "$SERVICE_NAME"
                log_success "  Serviço iniciado"
            fi
        fi
    done

    log_success "Restore Spring Boot concluído"
fi

# ============================================================================
# RESTORE TOMCAT
# ============================================================================

if [ "$RESTORE_TOMCAT" = true ] && [ -d "${BACKUP_DIR}/tomcat" ]; then
    log_info "=========================================="

    # Determinar tipo de restore
    if [ "${RESTORE_TOMCAT_WEBAPPS_ONLY}" = true ]; then
        log_info "RESTORE DAS WEBAPPS DO TOMCAT"
        RESTORE_TYPE="webapps-only"
    elif [ "${RESTORE_TOMCAT_SKIP_WEBAPPS}" = true ]; then
        log_info "RESTORE DO TOMCAT (SEM WEBAPPS)"
        RESTORE_TYPE="skip-webapps"
    else
        log_info "RESTORE DO TOMCAT"
        RESTORE_TYPE="full"
    fi

    log_info "=========================================="

    if ! confirm_action "Isto irá sobrescrever componentes do Tomcat em $TOMCAT_HOME"; then
        log_warning "Restore do Tomcat cancelado"
    else
        # Parar Tomcat (se não for apenas webapps)
        if [ "$RESTORE_TYPE" != "webapps-only" ]; then
            systemctl stop tomcat || "$TOMCAT_HOME/bin/shutdown.sh" || true
        fi

        # OPÇÃO 1: Restaurar SOMENTE webapps
        if [ "$RESTORE_TYPE" = "webapps-only" ]; then
            if [ -d "${BACKUP_DIR}/tomcat/webapps" ]; then
                log_info "Parando Tomcat para restaurar webapps..."
                systemctl stop tomcat || "$TOMCAT_HOME/bin/shutdown.sh" || true

                rm -rf "${TOMCAT_HOME}/webapps"/*
                cp -r "${BACKUP_DIR}/tomcat/webapps"/* "${TOMCAT_HOME}/webapps/"
                log_success "Webapps restauradas"
            else
                log_error "Diretório de webapps não encontrado no backup"
            fi

        # OPÇÃO 2: Restaurar tudo EXCETO webapps
        elif [ "$RESTORE_TYPE" = "skip-webapps" ]; then
            # Restaurar bin/
            if [ -d "${BACKUP_DIR}/tomcat/bin" ]; then
                cp -r "${BACKUP_DIR}/tomcat/bin"/* "${TOMCAT_HOME}/bin/"
                log_success "Binários restaurados"
            fi

            # Restaurar conf/
            if [ -d "${BACKUP_DIR}/tomcat/conf" ]; then
                cp -r "${BACKUP_DIR}/tomcat/conf"/* "${TOMCAT_HOME}/conf/"
                log_success "Configurações restauradas"
            fi

            # Restaurar lib/
            if [ -d "${BACKUP_DIR}/tomcat/lib" ]; then
                cp -r "${BACKUP_DIR}/tomcat/lib"/* "${TOMCAT_HOME}/lib/"
                log_success "Bibliotecas restauradas"
            fi

            # Restaurar arquivos raiz (LICENSE, NOTICE, etc)
            for file in "${BACKUP_DIR}/tomcat"/*; do
                if [ -f "$file" ] && [ "$(basename "$file")" != "backup-info.txt" ] && [ "$(basename "$file")" != "tomcat.service" ]; then
                    cp "$file" "${TOMCAT_HOME}/"
                fi
            done

            log_info "Webapps foram PULADAS (não restauradas)"

        # OPÇÃO 3: Restaurar TUDO (restore normal)
        else
            # Restaurar todos os diretórios
            for dir in bin conf lib webapps; do
                if [ -d "${BACKUP_DIR}/tomcat/$dir" ]; then
                    if [ "$dir" = "webapps" ]; then
                        rm -rf "${TOMCAT_HOME}/webapps"/*
                    fi
                    cp -r "${BACKUP_DIR}/tomcat/$dir"/* "${TOMCAT_HOME}/$dir/"
                    log_success "Diretório $dir/ restaurado"
                fi
            done

            # Restaurar arquivos raiz (LICENSE, NOTICE, etc)
            for file in "${BACKUP_DIR}/tomcat"/*; do
                if [ -f "$file" ] && [ "$(basename "$file")" != "backup-info.txt" ] && [ "$(basename "$file")" != "tomcat.service" ]; then
                    cp "$file" "${TOMCAT_HOME}/"
                fi
            done
        fi

        # Restaurar service systemd (sempre, exceto se for apenas webapps)
        if [ "$RESTORE_TYPE" != "webapps-only" ] && [ -f "${BACKUP_DIR}/tomcat/tomcat.service" ]; then
            cp "${BACKUP_DIR}/tomcat/tomcat.service" /etc/systemd/system/
            systemctl daemon-reload
            log_success "Service systemd restaurado"
        fi

        # Iniciar Tomcat
        read -p "Deseja iniciar o Tomcat agora? (S/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            systemctl start tomcat || "$TOMCAT_HOME/bin/startup.sh"
            log_success "Tomcat iniciado"
        fi

        log_success "Restore Tomcat concluído"
    fi
fi

# ============================================================================
# RESTORE NODE.JS
# ============================================================================

if [ "$RESTORE_NODEJS" = true ] && [ -d "${BACKUP_DIR}/nodejs" ]; then
    log_info "=========================================="
    log_info "RESTORE DE APLICAÇÕES NODE.JS"
    log_info "=========================================="

    for APP_DIR in "${BACKUP_DIR}/nodejs/"*; do
        [ -d "$APP_DIR" ] || continue
        [[ "$(basename "$APP_DIR")" == ".pm2" ]] && continue

        APP_NAME=$(basename "$APP_DIR")
        log_info "Restaurando aplicação Node.js: $APP_NAME"

        # Solicitar destino
        read -p "Diretório de destino para $APP_NAME [/opt/nodejs/$APP_NAME]: " TARGET_DIR
        TARGET_DIR=${TARGET_DIR:-/opt/nodejs/$APP_NAME}

        mkdir -p "$TARGET_DIR"
        cp -r "$APP_DIR"/* "$TARGET_DIR/"

        # Instalar dependências
        if [ -f "$TARGET_DIR/package.json" ]; then
            log_info "  Instalando dependências..."
            cd "$TARGET_DIR"
            npm install
            log_success "  Dependências instaladas"
        fi
    done

    # Restaurar PM2
    if [ -d "${BACKUP_DIR}/nodejs/.pm2" ]; then
        log_info "Restaurando configuração PM2..."

        PM2_HOME=$(su - "$PM2_USER" -c "echo \$HOME")
        cp -r "${BACKUP_DIR}/nodejs/.pm2" "$PM2_HOME/"
        chown -R "$PM2_USER":"$PM2_USER" "${PM2_HOME}/.pm2"

        su - "$PM2_USER" -c "pm2 resurrect"
        log_success "PM2 restaurado"
    fi

    log_success "Restore Node.js concluído"
fi

# ============================================================================
# RESTORE APLICAÇÕES ESTÁTICAS
# ============================================================================

if [ "$RESTORE_STATIC" = true ] && [ -d "${BACKUP_DIR}/static" ]; then
    log_info "=========================================="
    log_info "RESTORE DE APLICAÇÕES ESTÁTICAS"
    log_info "=========================================="

    for APP_DIR in "${BACKUP_DIR}/static/"*; do
        [ -d "$APP_DIR" ] || continue

        APP_NAME=$(basename "$APP_DIR")
        log_info "Restaurando aplicação estática: $APP_NAME"

        # Solicitar destino
        read -p "Diretório de destino para $APP_NAME [/var/www/html/$APP_NAME]: " TARGET_DIR
        TARGET_DIR=${TARGET_DIR:-/var/www/html/$APP_NAME}

        mkdir -p "$TARGET_DIR"
        cp -r "$APP_DIR"/* "$TARGET_DIR/"

        # Ajustar permissões
        chown -R www-data:www-data "$TARGET_DIR"
        chmod -R 755 "$TARGET_DIR"

        log_success "  Aplicação restaurada"
    done

    log_success "Restore de aplicações estáticas concluído"
fi

# ============================================================================
# RESTORE NGINX
# ============================================================================

if [ "$RESTORE_NGINX" = true ] && [ -d "${BACKUP_DIR}/nginx" ]; then
    log_info "=========================================="
    log_info "RESTORE DO NGINX"
    log_info "=========================================="

    if ! confirm_action "Isto irá sobrescrever as configurações do Nginx"; then
        log_warning "Restore do Nginx cancelado"
    else
        # Fazer backup das configurações atuais
        NGINX_BACKUP="/etc/nginx_backup_$(date +%s)"
        cp -r /etc/nginx "$NGINX_BACKUP"
        log_info "Backup das configurações atuais salvo em: $NGINX_BACKUP"

        # Restaurar configurações
        if [ -d "${BACKUP_DIR}/nginx/nginx" ]; then
            cp -r "${BACKUP_DIR}/nginx/nginx"/* /etc/nginx/
            log_success "Configurações Nginx restauradas"
        fi

        # Restaurar certificados SSL
        if [ -d "${BACKUP_DIR}/nginx/ssl" ]; then
            cp -r "${BACKUP_DIR}/nginx/ssl"/* "$SSL_CERTS_DIR/"
            log_success "Certificados SSL restaurados"
        fi

        # Testar configuração
        log_info "Testando configuração do Nginx..."
        if nginx -t; then
            log_success "Configuração válida"

            read -p "Deseja recarregar o Nginx? (S/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                systemctl reload nginx
                log_success "Nginx recarregado"
            fi
        else
            log_error "Configuração inválida! Restaurando backup..."
            rm -rf /etc/nginx
            mv "$NGINX_BACKUP" /etc/nginx
        fi

        log_success "Restore Nginx concluído"
    fi
fi

# ============================================================================
# RESTORE SCRIPTS CUSTOMIZADOS
# ============================================================================

if [ "$RESTORE_SCRIPTS" = true ] && [ -d "${BACKUP_DIR}/system/scripts" ]; then
    log_info "=========================================="
    log_info "RESTORE DE SCRIPTS CUSTOMIZADOS"
    log_info "=========================================="

    read -p "Diretório de destino para scripts [/opt/scripts]: " SCRIPTS_DIR
    SCRIPTS_DIR=${SCRIPTS_DIR:-/opt/scripts}

    mkdir -p "$SCRIPTS_DIR"
    cp -r "${BACKUP_DIR}/system/scripts"/* "$SCRIPTS_DIR/"
    chmod +x "$SCRIPTS_DIR"/*.sh

    log_success "Scripts restaurados em: $SCRIPTS_DIR"

    # Restaurar crontab
    if [ -f "${BACKUP_DIR}/system/crontab-root.txt" ]; then
        log_info "Crontab encontrado no backup"
        cat "${BACKUP_DIR}/system/crontab-root.txt"
        echo ""

        if confirm_action "Deseja restaurar o crontab?"; then
            crontab "${BACKUP_DIR}/system/crontab-root.txt"
            log_success "Crontab restaurado"
        fi
    fi

    log_success "Restore de scripts concluído"
fi

# ============================================================================
# LIMPEZA
# ============================================================================

if [ -n "${BACKUP_EXTRACT_DIR:-}" ] && [ -d "$BACKUP_EXTRACT_DIR" ]; then
    log_info "Limpando arquivos temporários..."
    rm -rf "$BACKUP_EXTRACT_DIR"
fi

# ============================================================================
# NOTIFICAÇÃO VIA WHATSAPP
# ============================================================================

if [ "$SEND_WHATSAPP_NOTIFICATION" = true ]; then
    log_info "Enviando notificação via WhatsApp..."

    # Montar lista de componentes restaurados
    RESTORED_COMPONENTS=""
    [ "$RESTORE_DB" = true ] && RESTORED_COMPONENTS="${RESTORED_COMPONENTS}✓ Banco de dados\n"
    [ "$RESTORE_SPRINGBOOT" = true ] && RESTORED_COMPONENTS="${RESTORED_COMPONENTS}✓ Spring Boot\n"
    [ "$RESTORE_TOMCAT" = true ] && RESTORED_COMPONENTS="${RESTORED_COMPONENTS}✓ Tomcat\n"
    [ "$RESTORE_NODEJS" = true ] && RESTORED_COMPONENTS="${RESTORED_COMPONENTS}✓ Node.js\n"
    [ "$RESTORE_STATIC" = true ] && RESTORED_COMPONENTS="${RESTORED_COMPONENTS}✓ Apps Estáticas\n"
    [ "$RESTORE_NGINX" = true ] && RESTORED_COMPONENTS="${RESTORED_COMPONENTS}✓ Nginx\n"
    [ "$RESTORE_SCRIPTS" = true ] && RESTORED_COMPONENTS="${RESTORED_COMPONENTS}✓ Scripts\n"

    NOTIFICATION_MESSAGE="🔄 *Restore VPS Concluído*

📅 Data: $(date '+%d/%m/%Y %H:%M:%S')
📦 Backup: $(basename "$BACKUP_SOURCE")
📝 Log: ${RESTORE_LOG}

🔧 *Componentes Restaurados:*
${RESTORED_COMPONENTS}
✅ Status: Sucesso"

    send_whatsapp_notification "$NOTIFICATION_MESSAGE" "success"
fi

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

log_success "=========================================="
log_success "RESTORE CONCLUÍDO!"
log_success "=========================================="
log_success "Log salvo em: $RESTORE_LOG"
log_success ""
log_info "Próximos passos recomendados:"
log_info "1. Verificar logs de todas as aplicações"
log_info "2. Testar conectividade com banco de dados"
log_info "3. Verificar status dos serviços: systemctl status <service>"
log_info "4. Testar acesso às aplicações web"
log_info "5. Verificar certificados SSL se necessário"
log_success "=========================================="

exit 0
