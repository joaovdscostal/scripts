#!/bin/bash
# ============================================================================
# SCRIPT DE BACKUP COMPLETO PARA VPS
# ============================================================================
# Este script realiza backup completo de:
# - Bancos de dados MariaDB (mariabackup ou mysqldump)
# - Aplicações Spring Boot (Java 21)
# - Apache Tomcat 9
# - Aplicações Node.js (PM2)
# - Aplicações estáticas (HTML)
# - Configurações Nginx + SSL (Certbot)
# - Inventário do sistema
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
    curl --silent --location --request POST "${WHATSAPP_API_URL}" \
        --header 'Content-Type: application/json' \
        --header "apiKey: ${WHATSAPP_API_KEY}" \
        --data "{
            \"number\": \"${WHATSAPP_NUMBER}\",
            \"textMessage\": {
                \"text\": \"${MESSAGE}\"
            }
        }" > /dev/null 2>&1

    return 0
}

# ============================================================================
# TRATAMENTO DE ERROS
# ============================================================================

# Função para lidar com erros
handle_error() {
    local EXIT_CODE=$?
    local LINE_NUMBER=$1

    echo -e "${RED}[ERRO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - Erro na linha ${LINE_NUMBER}: código de saída ${EXIT_CODE}"

    # Enviar notificação de erro via WhatsApp
    ERROR_MESSAGE="⚠️ *Backup VPS FALHOU*

📅 Data: $(date '+%d/%m/%Y %H:%M:%S')
❌ Erro na linha: ${LINE_NUMBER}
🔢 Código de saída: ${EXIT_CODE}
📝 Log: ${CRON_LOG_FILE:-Não disponível}"

    send_whatsapp_notification "$ERROR_MESSAGE" "error" || true

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

# ============================================================================
# CARREGAR CONFIGURAÇÕES
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"
log_info "Configurações carregadas de: $CONFIG_FILE"

# ============================================================================
# PROCESSAR MODO DE BACKUP
# ============================================================================

if [ -n "$BACKUP_MODE" ]; then
    log_info "Modo de backup: $BACKUP_MODE"

    case "$BACKUP_MODE" in
        "full")
            # Backup completo - tudo habilitado
            log_info "Backup COMPLETO - incluindo tudo"
            BACKUP_DATABASE=true
            BACKUP_SPRINGBOOT=true
            BACKUP_TOMCAT=true
            TOMCAT_BACKUP_WEBAPPS=true
            BACKUP_NODEJS=true
            BACKUP_STATIC_APPS=true
            BACKUP_NGINX=true
            BACKUP_CUSTOM_SCRIPTS=true
            ;;

        "infra")
            # Backup de infraestrutura - sem banco e sem webapps
            log_info "Backup de INFRAESTRUTURA - sem banco e sem webapps"
            BACKUP_DATABASE=false
            BACKUP_SPRINGBOOT=true
            BACKUP_TOMCAT=true
            TOMCAT_BACKUP_WEBAPPS=false  # SEM webapps
            BACKUP_NODEJS=true
            BACKUP_STATIC_APPS=true
            BACKUP_NGINX=true
            BACKUP_CUSTOM_SCRIPTS=true
            ;;

        "database")
            # Apenas banco de dados
            log_info "Backup apenas de BANCO DE DADOS"
            BACKUP_DATABASE=true
            BACKUP_SPRINGBOOT=false
            BACKUP_TOMCAT=false
            BACKUP_NODEJS=false
            BACKUP_STATIC_APPS=false
            BACKUP_NGINX=false
            BACKUP_CUSTOM_SCRIPTS=false
            ;;

        "webapps")
            # Apenas webapps do Tomcat
            log_info "Backup apenas de WEBAPPS do Tomcat"
            BACKUP_DATABASE=false
            BACKUP_SPRINGBOOT=false
            BACKUP_TOMCAT=true
            TOMCAT_BACKUP_WEBAPPS=true
            # Forçar backup SOMENTE das webapps (criar flag especial)
            TOMCAT_WEBAPPS_ONLY=true
            BACKUP_NODEJS=false
            BACKUP_STATIC_APPS=false
            BACKUP_NGINX=false
            BACKUP_CUSTOM_SCRIPTS=false
            ;;

        *)
            log_error "Modo de backup inválido: $BACKUP_MODE"
            log_error "Modos válidos: full, infra, database, webapps"
            exit 1
            ;;
    esac
else
    log_info "Usando configurações individuais (BACKUP_MODE não definido)"
fi

# ============================================================================
# PREPARAR DIRETÓRIOS
# ============================================================================

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/${BACKUP_DATE}"
LOG_FILE="${BACKUP_DIR}/backup.log"

mkdir -p "${BACKUP_ROOT}"
mkdir -p "${BACKUP_DIR}"/{database,springboot,tomcat,nodejs,static,nginx,system,inventory}

# Redirecionar output para arquivo de log e para log do cron (sobrescreve)
exec > >(tee -a "$LOG_FILE" | tee "$CRON_LOG_FILE") 2>&1

log_info "=========================================="
log_info "INICIANDO BACKUP VPS"
log_info "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')"
log_info "Diretório: $BACKUP_DIR"
log_info "=========================================="

# ============================================================================
# GERAR INVENTÁRIO DO SISTEMA
# ============================================================================

log_info "Gerando inventário do sistema..."

cat > "${BACKUP_DIR}/inventory/system-info.txt" <<EOF
========================================
INVENTÁRIO DO SISTEMA - $(date)
========================================

SISTEMA OPERACIONAL:
$(cat /etc/os-release)

KERNEL:
$(uname -a)

HOSTNAME:
$(hostname)

UPTIME:
$(uptime)

MEMÓRIA:
$(free -h)

DISCO:
$(df -h)

VERSÕES DE SOFTWARE INSTALADO:
----------------------------------------

EOF

# Java
if check_command java; then
    echo "JAVA:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    java -version 2>&1 >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# Maven
if check_command mvn; then
    echo "MAVEN:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    mvn -version >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# Node.js
if check_command node; then
    echo "NODE.JS:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    node --version >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# NPM
if check_command npm; then
    echo "NPM:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    npm --version >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# PM2
if check_command pm2; then
    echo "PM2:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    pm2 --version >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"

    echo "PM2 LIST:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    su - "$PM2_USER" -c "pm2 list" >> "${BACKUP_DIR}/inventory/system-info.txt" 2>&1 || true
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# Nginx
if check_command nginx; then
    echo "NGINX:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    nginx -v 2>&1 >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# MariaDB
if check_command mysql; then
    echo "MARIADB/MYSQL:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    mysql --version >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# Tomcat
if [ -d "$TOMCAT_HOME" ]; then
    echo "TOMCAT:" >> "${BACKUP_DIR}/inventory/system-info.txt"
    echo "Instalado em: $TOMCAT_HOME" >> "${BACKUP_DIR}/inventory/system-info.txt"
    if [ -f "$TOMCAT_HOME/bin/version.sh" ]; then
        "$TOMCAT_HOME/bin/version.sh" >> "${BACKUP_DIR}/inventory/system-info.txt" 2>&1 || true
    fi
    echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"
fi

# Serviços systemd
echo "SERVIÇOS SYSTEMD (ativos):" >> "${BACKUP_DIR}/inventory/system-info.txt"
systemctl list-units --type=service --state=running >> "${BACKUP_DIR}/inventory/system-info.txt"
echo "" >> "${BACKUP_DIR}/inventory/system-info.txt"

log_success "Inventário gerado"

# ============================================================================
# BACKUP DE BANCO DE DADOS (MariaDB)
# ============================================================================

if [ "$BACKUP_DATABASE" = true ]; then
    if check_command mysql; then
        log_info "Iniciando backup de banco de dados..."

        # Obter lista de bancos
        if [ -z "$DB_LIST" ]; then
            DB_LIST=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "^(Database|${DB_EXCLUDE// /|})$")
        fi

        if [ "$DB_BACKUP_METHOD" == "mariabackup" ] && check_command mariabackup; then
            log_info "Usando mariabackup (backup físico)..."

            MARIABACKUP_DIR="${BACKUP_DIR}/database/mariabackup"
            mkdir -p "$MARIABACKUP_DIR"

            mariabackup --backup \
                --target-dir="$MARIABACKUP_DIR" \
                --user="$DB_USER" \
                --password="$DB_PASSWORD" \
                --host="$DB_HOST" \
                --port="$DB_PORT"

            # Preparar backup
            mariabackup --prepare --target-dir="$MARIABACKUP_DIR"

            log_success "Backup físico (mariabackup) concluído"

        else
            log_info "Usando mysqldump (backup lógico)..."

            for DB in $DB_LIST; do
                log_info "Backup do banco: $DB"

                mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" \
                    --single-transaction \
                    --routines \
                    --triggers \
                    --events \
                    --databases "$DB" > "${BACKUP_DIR}/database/${DB}.sql"

                log_success "Banco $DB: OK"
            done

            log_success "Backup lógico (mysqldump) concluído"
        fi

        # Salvar informações dos bancos
        echo "Lista de bancos:" > "${BACKUP_DIR}/inventory/databases.txt"
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" >> "${BACKUP_DIR}/inventory/databases.txt"

    else
        log_warning "MySQL/MariaDB não encontrado, pulando backup de banco de dados"
    fi
else
    log_info "Backup de banco de dados desabilitado (BACKUP_DATABASE=false)"
fi

# ============================================================================
# BACKUP DE APLICAÇÕES SPRING BOOT
# ============================================================================

if [ "$BACKUP_SPRINGBOOT" = true ]; then
    log_info "Iniciando backup de aplicações Spring Boot..."

    for APP_CONFIG in "${SPRINGBOOT_APPS[@]}"; do
        IFS=':' read -r APP_NAME APP_PATH APP_SERVICE <<< "$APP_CONFIG"

        log_info "Backup da aplicação: $APP_NAME"

        APP_DIR="${BACKUP_DIR}/springboot/${APP_NAME}"
        mkdir -p "$APP_DIR"

        # Verificar se APP_PATH é um diretório ou arquivo
        if [ -d "$APP_PATH" ]; then
            # É um diretório - copiar todo o conteúdo
            log_info "  Copiando diretório da aplicação..."
            cp -r "$APP_PATH"/* "$APP_DIR/"
            log_success "  Diretório completo copiado"

        elif [ -f "$APP_PATH" ]; then
            # É um arquivo JAR específico - copiar apenas o JAR
            log_info "  Copiando JAR específico..."
            cp "$APP_PATH" "$APP_DIR/"
            log_success "  JAR copiado"

            # Backup de configurações do mesmo diretório do JAR
            APP_BASE_DIR=$(dirname "$APP_PATH")
            for CONFIG_FILE in application.properties application.yml application.yaml; do
                if [ -f "${APP_BASE_DIR}/${CONFIG_FILE}" ]; then
                    cp "${APP_BASE_DIR}/${CONFIG_FILE}" "$APP_DIR/"
                    log_success "  Configuração copiada: $CONFIG_FILE"
                fi
            done
        else
            log_warning "  Caminho não encontrado: $APP_PATH"
        fi

        # Backup do service systemd
        if [ -f "$APP_SERVICE" ]; then
            cp "$APP_SERVICE" "$APP_DIR/"
            log_success "  Service systemd copiado"
        else
            log_warning "  Service não encontrado: $APP_SERVICE"
        fi
    done

    # Backup de diretórios de configuração adicionais
    if [ -n "$SPRINGBOOT_CONFIG_DIRS" ]; then
        for CONFIG_DIR in $SPRINGBOOT_CONFIG_DIRS; do
            if [ -d "$CONFIG_DIR" ]; then
                cp -r "$CONFIG_DIR" "${BACKUP_DIR}/springboot/"
                log_success "Diretório de configuração copiado: $CONFIG_DIR"
            fi
        done
    fi

    log_success "Backup Spring Boot concluído"
fi

# ============================================================================
# BACKUP DO TOMCAT
# ============================================================================

if [ "$BACKUP_TOMCAT" = true ] && [ -d "$TOMCAT_HOME" ]; then
    TOMCAT_BACKUP_DIR="${BACKUP_DIR}/tomcat"

    # Verificar se é modo "webapps only"
    if [ "${TOMCAT_WEBAPPS_ONLY:-false}" = true ]; then
        log_info "Iniciando backup APENAS das webapps do Tomcat..."

        # Copiar SOMENTE o diretório webapps
        if [ -d "${TOMCAT_HOME}/webapps" ]; then
            cp -r "${TOMCAT_HOME}/webapps" "${TOMCAT_BACKUP_DIR}/"
            log_success "Webapps do Tomcat copiadas"

            echo "Backup mode: webapps-only" > "${TOMCAT_BACKUP_DIR}/backup-info.txt"
            echo "Data: $(date)" >> "${TOMCAT_BACKUP_DIR}/backup-info.txt"
        else
            log_warning "Diretório webapps não encontrado"
        fi

    elif [ "$TOMCAT_BACKUP_WEBAPPS" = true ]; then
        log_info "Iniciando backup do Tomcat (com webapps)..."

        # Copiar tudo exceto logs, work e temp
        rsync -a --exclude='logs' --exclude='work' --exclude='temp' \
            "${TOMCAT_HOME}/" "${TOMCAT_BACKUP_DIR}/"

        log_success "Backup completo do Tomcat (exceto logs/work/temp)"

        echo "Backup com webapps: true" > "${TOMCAT_BACKUP_DIR}/backup-info.txt"
        echo "Data: $(date)" >> "${TOMCAT_BACKUP_DIR}/backup-info.txt"

    else
        log_info "Iniciando backup do Tomcat (sem webapps)..."

        # Copiar tudo exceto logs, work, temp E webapps
        rsync -a --exclude='logs' --exclude='work' --exclude='temp' --exclude='webapps' \
            "${TOMCAT_HOME}/" "${TOMCAT_BACKUP_DIR}/"

        log_success "Backup do Tomcat sem webapps (exceto logs/work/temp/webapps)"

        echo "Backup com webapps: false" > "${TOMCAT_BACKUP_DIR}/backup-info.txt"
        echo "Data: $(date)" >> "${TOMCAT_BACKUP_DIR}/backup-info.txt"
    fi

    # Backup dos logs (opcional)
    if [ "$BACKUP_TOMCAT_LOGS" = true ] && [ -d "${TOMCAT_HOME}/logs" ]; then
        cp -r "${TOMCAT_HOME}/logs" "${TOMCAT_BACKUP_DIR}/"
        log_success "Logs do Tomcat copiados"
    fi

    # Backup do service systemd se existir
    if [ -f "/etc/systemd/system/tomcat.service" ] && [ "${TOMCAT_WEBAPPS_ONLY:-false}" != true ]; then
        cp "/etc/systemd/system/tomcat.service" "${TOMCAT_BACKUP_DIR}/"
        log_success "Service systemd do Tomcat copiado"
    fi

    log_success "Backup Tomcat concluído"
else
    if [ "$BACKUP_TOMCAT" = true ]; then
        log_warning "Tomcat não encontrado em: $TOMCAT_HOME"
    fi
fi

# ============================================================================
# BACKUP DE APLICAÇÕES NODE.JS
# ============================================================================

if [ "$BACKUP_NODEJS" = true ]; then
    log_info "Iniciando backup de aplicações Node.js..."

    for APP_CONFIG in "${NODEJS_APPS[@]}"; do
        IFS=':' read -r APP_NAME APP_PATH <<< "$APP_CONFIG"

        log_info "Backup da aplicação Node.js: $APP_NAME"

        if [ -d "$APP_PATH" ]; then
            # Copiar aplicação (excluindo node_modules)
            rsync -a --exclude='node_modules' --exclude='.git' "$APP_PATH" "${BACKUP_DIR}/nodejs/"
            log_success "  Aplicação copiada (sem node_modules)"

            # Salvar apenas o package.json e package-lock.json
            if [ -f "${APP_PATH}/package.json" ]; then
                mkdir -p "${BACKUP_DIR}/nodejs/$(basename "$APP_PATH")/dependencies"
                cp "${APP_PATH}/package.json" "${BACKUP_DIR}/nodejs/$(basename "$APP_PATH")/dependencies/"
                [ -f "${APP_PATH}/package-lock.json" ] && cp "${APP_PATH}/package-lock.json" "${BACKUP_DIR}/nodejs/$(basename "$APP_PATH")/dependencies/"
                log_success "  Arquivos de dependências salvos"
            fi
        else
            log_warning "  Aplicação não encontrada: $APP_PATH"
        fi
    done

    # Backup da configuração do PM2
    if [ "$BACKUP_PM2_CONFIG" = true ] && check_command pm2; then
        log_info "Backup da configuração PM2..."
        su - "$PM2_USER" -c "pm2 save" || true

        PM2_HOME=$(su - "$PM2_USER" -c "echo \$HOME")
        if [ -d "${PM2_HOME}/.pm2" ]; then
            cp -r "${PM2_HOME}/.pm2" "${BACKUP_DIR}/nodejs/"
            log_success "Configuração PM2 copiada"
        fi
    fi

    log_success "Backup Node.js concluído"
fi

# ============================================================================
# BACKUP DE APLICAÇÕES ESTÁTICAS
# ============================================================================

if [ "$BACKUP_STATIC_APPS" = true ]; then
    log_info "Iniciando backup de aplicações estáticas..."

    for STATIC_DIR in "${STATIC_APPS_DIRS[@]}"; do
        if [ -d "$STATIC_DIR" ]; then
            BASENAME=$(basename "$STATIC_DIR")
            log_info "Backup de: $STATIC_DIR"
            cp -r "$STATIC_DIR" "${BACKUP_DIR}/static/${BASENAME}"
            log_success "  Copiado: $BASENAME"
        else
            log_warning "Diretório não encontrado: $STATIC_DIR"
        fi
    done

    log_success "Backup de aplicações estáticas concluído"
fi

# ============================================================================
# BACKUP DO NGINX
# ============================================================================

if [ "$BACKUP_NGINX" = true ] && [ -d "$NGINX_CONFIG_DIR" ]; then
    log_info "Iniciando backup do Nginx..."

    # Backup das configurações
    cp -r "$NGINX_CONFIG_DIR" "${BACKUP_DIR}/nginx/"
    log_success "Configurações Nginx copiadas"

    # Backup dos logs (opcional)
    if [ "$BACKUP_NGINX_LOGS" = true ] && [ -d "/var/log/nginx" ]; then
        cp -r /var/log/nginx "${BACKUP_DIR}/nginx/logs"
        log_success "Logs Nginx copiados"
    fi

    # Backup dos certificados SSL
    if [ "$BACKUP_SSL_CERTS" = true ] && [ -d "$SSL_CERTS_DIR" ]; then
        cp -r "$SSL_CERTS_DIR" "${BACKUP_DIR}/nginx/ssl"
        log_success "Certificados SSL copiados"
    fi

    log_success "Backup Nginx concluído"
else
    if [ "$BACKUP_NGINX" = true ]; then
        log_warning "Nginx não encontrado em: $NGINX_CONFIG_DIR"
    fi
fi

# ============================================================================
# BACKUP DE CONFIGURAÇÕES DO SISTEMA
# ============================================================================

if [ "$BACKUP_SYSTEM_CONFIG" = true ]; then
    log_info "Iniciando backup de configurações do sistema..."

    SYSTEM_DIR="${BACKUP_DIR}/system"

    # Backup de cron jobs
    if [ "$BACKUP_CRON" = true ]; then
        crontab -l > "${SYSTEM_DIR}/crontab-root.txt" 2>/dev/null || echo "Nenhum crontab encontrado"
        cp -r /etc/cron.* "${SYSTEM_DIR}/" 2>/dev/null || true
        log_success "Cron jobs salvos"
    fi

    # Backup de hosts
    [ -f /etc/hosts ] && cp /etc/hosts "${SYSTEM_DIR}/"

    # Backup de serviços systemd customizados
    mkdir -p "${SYSTEM_DIR}/systemd"
    cp /etc/systemd/system/*.service "${SYSTEM_DIR}/systemd/" 2>/dev/null || true

    log_success "Configurações do sistema salvas"
fi

# ============================================================================
# BACKUP DE SCRIPTS CUSTOMIZADOS
# ============================================================================

if [ "$BACKUP_CUSTOM_SCRIPTS" = true ]; then
    log_info "Iniciando backup de scripts customizados..."

    SCRIPTS_DIR="${BACKUP_DIR}/system/scripts"
    mkdir -p "$SCRIPTS_DIR"

    SCRIPTS_FOUND=false

    for SCRIPT_PATH in $CUSTOM_SCRIPTS_DIRS; do
        # Expandir wildcards (como /home/*/scripts)
        for EXPANDED_PATH in $SCRIPT_PATH; do
            if [ -d "$EXPANDED_PATH" ]; then
                log_info "Copiando scripts de: $EXPANDED_PATH"

                # Criar subdiretório mantendo estrutura
                RELATIVE_PATH=$(echo "$EXPANDED_PATH" | sed 's/^\///')
                TARGET_DIR="${SCRIPTS_DIR}/${RELATIVE_PATH}"
                mkdir -p "$TARGET_DIR"

                # Copiar scripts
                find "$EXPANDED_PATH" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.rb" \) -exec cp {} "$TARGET_DIR/" \;

                SCRIPTS_FOUND=true
                log_success "  Scripts copiados de $EXPANDED_PATH"
            fi
        done
    done

    if [ "$SCRIPTS_FOUND" = false ]; then
        log_warning "Nenhum diretório de scripts encontrado"
    fi

    # Backup de logs dos scripts (opcional)
    if [ "$BACKUP_SCRIPT_LOGS" = true ] && [ -d "$SCRIPT_LOGS_DIR" ]; then
        cp -r "$SCRIPT_LOGS_DIR" "${BACKUP_DIR}/system/script-logs"
        log_success "Logs dos scripts copiados"
    fi

    log_success "Backup de scripts customizados concluído"
fi

# ============================================================================
# BACKUP DE DIRETÓRIOS ADICIONAIS
# ============================================================================

if [ -n "$ADDITIONAL_DIRS" ]; then
    log_info "Backup de diretórios adicionais..."

    for DIR in $ADDITIONAL_DIRS; do
        if [ -d "$DIR" ]; then
            BASENAME=$(basename "$DIR")
            cp -r "$DIR" "${BACKUP_DIR}/additional/${BASENAME}"
            log_success "Copiado: $DIR"
        else
            log_warning "Diretório não encontrado: $DIR"
        fi
    done
fi

# ============================================================================
# CRIAR SCRIPT DE COMANDOS PARA MIGRAÇÃO
# ============================================================================

log_info "Gerando script de comandos para migração..."

cat > "${BACKUP_DIR}/inventory/migration-commands.sh" <<'MIGRATION_EOF'
#!/bin/bash
# ============================================================================
# COMANDOS PARA MIGRAÇÃO DO SERVIDOR
# ============================================================================
# Este arquivo contém os comandos necessários para replicar o ambiente
# em um novo servidor

echo "=========================================="
echo "INSTALAÇÃO DE PACOTES BÁSICOS"
echo "=========================================="

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar ferramentas básicas
sudo apt install -y curl wget git vim nano htop

echo ""
echo "=========================================="
echo "INSTALAR JAVA 21"
echo "=========================================="
sudo apt install -y openjdk-21-jdk
java -version

echo ""
echo "=========================================="
echo "INSTALAR NODE.JS E NPM"
echo "=========================================="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version
npm --version

echo ""
echo "=========================================="
echo "INSTALAR PM2"
echo "=========================================="
sudo npm install -g pm2
pm2 --version

echo ""
echo "=========================================="
echo "INSTALAR MARIADB"
echo "=========================================="
sudo apt install -y mariadb-server mariadb-backup
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation

echo ""
echo "=========================================="
echo "INSTALAR NGINX"
echo "=========================================="
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

echo ""
echo "=========================================="
echo "INSTALAR CERTBOT (Let's Encrypt)"
echo "=========================================="
sudo apt install -y certbot python3-certbot-nginx

echo ""
echo "=========================================="
echo "INSTALAR TOMCAT 9"
echo "=========================================="
sudo apt install -y tomcat9
# OU baixar manualmente:
# wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.XX/bin/apache-tomcat-9.0.XX.tar.gz
# tar -xzf apache-tomcat-9.0.XX.tar.gz
# sudo mv apache-tomcat-9.0.XX /opt/tomcat9

echo ""
echo "=========================================="
echo "CONFIGURAR FIREWALL"
echo "=========================================="
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw enable

echo ""
echo "=========================================="
echo "PRÓXIMOS PASSOS MANUAIS:"
echo "=========================================="
echo "1. Execute o script restore-vps.sh para restaurar os backups"
echo "2. Configure os domínios no Nginx"
echo "3. Configure os certificados SSL com certbot"
echo "4. Configure as permissões de usuários e pastas"
echo "5. Inicie os serviços"

MIGRATION_EOF

chmod +x "${BACKUP_DIR}/inventory/migration-commands.sh"
log_success "Script de migração gerado"

# ============================================================================
# COMPACTAR BACKUP
# ============================================================================

if [ "$COMPRESS_BACKUPS" = true ]; then
    log_info "Compactando backup..."

    cd "$BACKUP_ROOT"
    tar -czf "${BACKUP_DATE}.tar.gz" "${BACKUP_DATE}"

    if [ $? -eq 0 ]; then
        rm -rf "${BACKUP_DATE}"
        log_success "Backup compactado: ${BACKUP_DATE}.tar.gz"
        BACKUP_FINAL="${BACKUP_ROOT}/${BACKUP_DATE}.tar.gz"
    else
        log_error "Erro ao compactar backup"
        BACKUP_FINAL="${BACKUP_DIR}"
    fi
else
    BACKUP_FINAL="${BACKUP_DIR}"
fi

# ============================================================================
# BACKUP REMOTO
# ============================================================================

if [ "$REMOTE_BACKUP" = true ]; then
    log_info "Enviando backup para servidor remoto..."

    rsync -avz -e "ssh -i $REMOTE_SSH_KEY" \
        "$BACKUP_FINAL" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"

    if [ $? -eq 0 ]; then
        log_success "Backup enviado para servidor remoto"
    else
        log_error "Erro ao enviar backup para servidor remoto"
    fi
fi

# ============================================================================
# BACKUP PARA S3 VIA RCLONE
# ============================================================================

if [ "$S3_BACKUP" = true ]; then
    if ! check_command rclone; then
        log_error "rclone não encontrado. Instale: curl https://rclone.org/install.sh | sudo bash"
    else
        log_info "Enviando backup para S3 via rclone..."

        # Upload para S3
        rclone copy "$BACKUP_FINAL" "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/" --progress

        if [ $? -eq 0 ]; then
            log_success "Backup enviado para S3: ${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/"

            # Limpar backups antigos no S3
            if [ "$S3_RETENTION_COUNT" -gt 0 ]; then
                log_info "Limpando backups antigos no S3 (mantendo últimos ${S3_RETENTION_COUNT})..."

                # Listar arquivos ordenados por data (mais recentes primeiro)
                BACKUP_FILES=$(rclone lsf "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/" | sort -r)

                # Contar arquivos
                FILE_COUNT=$(echo "$BACKUP_FILES" | wc -l)

                if [ "$FILE_COUNT" -gt "$S3_RETENTION_COUNT" ]; then
                    # Calcular quantos arquivos deletar
                    DELETE_COUNT=$((FILE_COUNT - S3_RETENTION_COUNT))

                    # Pegar os arquivos mais antigos
                    FILES_TO_DELETE=$(echo "$BACKUP_FILES" | tail -n "$DELETE_COUNT")

                    # Deletar arquivos
                    echo "$FILES_TO_DELETE" | while read -r FILE; do
                        log_info "Deletando do S3: $FILE"
                        rclone delete "${RCLONE_REMOTE}:${S3_BUCKET}/${S3_PATH}/${FILE}"
                    done

                    log_success "Backups antigos removidos do S3"
                else
                    log_info "Nenhum backup antigo para remover do S3"
                fi
            fi
        else
            log_error "Erro ao enviar backup para S3"
        fi
    fi
fi

# ============================================================================
# LIMPEZA DE BACKUPS ANTIGOS
# ============================================================================

if [ "$BACKUP_RETENTION_DAYS" -gt 0 ]; then
    log_info "Limpando backups antigos (>${BACKUP_RETENTION_DAYS} dias)..."

    find "$BACKUP_ROOT" -name "*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete
    find "$BACKUP_ROOT" -maxdepth 1 -type d -mtime +${BACKUP_RETENTION_DAYS} -exec rm -rf {} \; 2>/dev/null || true

    log_success "Limpeza concluída"
fi

# ============================================================================
# NOTIFICAÇÃO VIA WHATSAPP
# ============================================================================

if [ "$SEND_WHATSAPP_NOTIFICATION" = true ]; then
    log_info "Enviando notificação via WhatsApp..."

    BACKUP_SIZE=$(du -sh "$BACKUP_FINAL" 2>/dev/null | cut -f1)

    NOTIFICATION_MESSAGE="🔄 *Backup VPS Concluído*

📅 Data: $(date '+%d/%m/%Y %H:%M:%S')
📦 Tamanho: ${BACKUP_SIZE}
📍 Local: ${BACKUP_FINAL}
✅ Status: Sucesso"

    send_whatsapp_notification "$NOTIFICATION_MESSAGE" "success"
fi

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

BACKUP_SIZE=$(du -sh "$BACKUP_FINAL" | cut -f1)

log_success "=========================================="
log_success "BACKUP CONCLUÍDO COM SUCESSO!"
log_success "=========================================="
log_success "Local: $BACKUP_FINAL"
log_success "Tamanho: $BACKUP_SIZE"
log_success "Log: $LOG_FILE"
log_success "=========================================="

exit 0
