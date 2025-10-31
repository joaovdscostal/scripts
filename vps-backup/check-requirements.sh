#!/bin/bash
# ============================================================================
# VERIFICADOR DE REQUISITOS PARA SISTEMA DE BACKUP
# ============================================================================
# Execute este script ANTES de instalar o sistema de backup
# para verificar se todos os requisitos estão atendidos
# ============================================================================

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS=$((ERRORS + 1))
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "========================================"
echo "VERIFICADOR DE REQUISITOS"
echo "Sistema de Backup VPS"
echo "========================================"
echo ""

# ============================================================================
# VERIFICAR SISTEMA OPERACIONAL
# ============================================================================

echo "1. Sistema Operacional"
echo "----------------------------------------"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    log_ok "OS: $NAME $VERSION"

    # Verificar se é Ubuntu/Debian
    if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
        log_ok "Distribuição suportada"
    else
        log_warning "Distribuição não testada (Ubuntu/Debian recomendado)"
    fi
else
    log_error "/etc/os-release não encontrado"
fi

echo ""

# ============================================================================
# VERIFICAR COMANDOS ESSENCIAIS
# ============================================================================

echo "2. Comandos Essenciais"
echo "----------------------------------------"

REQUIRED_COMMANDS=("bash" "tar" "gzip" "rsync" "find" "date")

for CMD in "${REQUIRED_COMMANDS[@]}"; do
    if command -v $CMD &> /dev/null; then
        VERSION=$(${CMD} --version 2>&1 | head -1 || echo "instalado")
        log_ok "$CMD: $VERSION"
    else
        log_error "$CMD não encontrado"
        echo "   Instale com: sudo apt install $CMD"
    fi
done

echo ""

# ============================================================================
# VERIFICAR PERMISSÕES
# ============================================================================

echo "3. Permissões"
echo "----------------------------------------"

if [ "$EUID" -eq 0 ]; then
    log_ok "Executando como root"
else
    log_warning "Não está executando como root (use sudo)"
    log_info "O sistema de backup requer privilégios de root"
fi

echo ""

# ============================================================================
# VERIFICAR BANCO DE DADOS
# ============================================================================

echo "4. Banco de Dados (MySQL/MariaDB)"
echo "----------------------------------------"

if command -v mysql &> /dev/null; then
    VERSION=$(mysql --version)
    log_ok "MySQL/MariaDB: $VERSION"

    # Verificar mariabackup
    if command -v mariabackup &> /dev/null; then
        log_ok "mariabackup instalado (backup físico - recomendado)"
    else
        log_warning "mariabackup não instalado (apenas mysqldump)"
        echo "   Para instalar: sudo apt install mariadb-backup"
    fi

    # Verificar mysqldump
    if command -v mysqldump &> /dev/null; then
        log_ok "mysqldump disponível"
    else
        log_warning "mysqldump não encontrado"
    fi
else
    log_warning "MySQL/MariaDB não encontrado"
    log_info "Se você usa banco de dados, instale com:"
    echo "   sudo apt install mariadb-server mariadb-backup"
fi

echo ""

# ============================================================================
# VERIFICAR JAVA
# ============================================================================

echo "5. Java (para Spring Boot)"
echo "----------------------------------------"

if command -v java &> /dev/null; then
    VERSION=$(java -version 2>&1 | head -1)
    log_ok "Java: $VERSION"

    # Verificar versão 21
    if java -version 2>&1 | grep -q "version \"21"; then
        log_ok "Java 21 detectado (Spring Boot compatível)"
    else
        log_warning "Java 21 não detectado (pode ser necessário para Spring Boot)"
    fi

    # Verificar JAVA_HOME
    if [ -n "${JAVA_HOME:-}" ]; then
        log_ok "JAVA_HOME: $JAVA_HOME"
    else
        log_warning "JAVA_HOME não definido"
    fi
else
    log_info "Java não encontrado (necessário apenas se usar Spring Boot)"
    echo "   Para instalar Java 21: sudo apt install openjdk-21-jdk"
fi

echo ""

# ============================================================================
# VERIFICAR NODE.JS
# ============================================================================

echo "6. Node.js e PM2"
echo "----------------------------------------"

if command -v node &> /dev/null; then
    VERSION=$(node --version)
    log_ok "Node.js: $VERSION"

    # Verificar NPM
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        log_ok "NPM: $NPM_VERSION"
    else
        log_warning "NPM não encontrado"
    fi

    # Verificar PM2
    if command -v pm2 &> /dev/null; then
        PM2_VERSION=$(pm2 --version)
        log_ok "PM2: $PM2_VERSION"
    else
        log_info "PM2 não encontrado (necessário apenas se usar Node.js)"
        echo "   Para instalar: sudo npm install -g pm2"
    fi
else
    log_info "Node.js não encontrado (necessário apenas se usar aplicações Node)"
    echo "   Para instalar: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
    echo "                  sudo apt install -y nodejs"
fi

echo ""

# ============================================================================
# VERIFICAR NGINX
# ============================================================================

echo "7. Nginx"
echo "----------------------------------------"

if command -v nginx &> /dev/null; then
    VERSION=$(nginx -v 2>&1)
    log_ok "Nginx: $VERSION"

    # Verificar configuração
    if [ -d /etc/nginx ]; then
        log_ok "Diretório de configuração: /etc/nginx"
    else
        log_warning "Diretório /etc/nginx não encontrado"
    fi
else
    log_info "Nginx não encontrado"
    echo "   Para instalar: sudo apt install nginx"
fi

echo ""

# ============================================================================
# VERIFICAR CERTBOT (SSL)
# ============================================================================

echo "8. Certbot (Let's Encrypt)"
echo "----------------------------------------"

if command -v certbot &> /dev/null; then
    VERSION=$(certbot --version)
    log_ok "Certbot: $VERSION"

    # Verificar diretório de certificados
    if [ -d /etc/letsencrypt ]; then
        CERT_COUNT=$(find /etc/letsencrypt/live -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        log_ok "Certificados instalados: $CERT_COUNT"
    fi
else
    log_info "Certbot não encontrado (necessário apenas se usar SSL)"
    echo "   Para instalar: sudo apt install certbot python3-certbot-nginx"
fi

echo ""

# ============================================================================
# VERIFICAR TOMCAT
# ============================================================================

echo "9. Apache Tomcat"
echo "----------------------------------------"

TOMCAT_FOUND=false
TOMCAT_PATHS=(
    "/root/appservers/apache-tomcat-9"
    "/root/appservers/tomcat"
    "/root/appservers/tomcat9"
    "/opt/tomcat"
    "/opt/tomcat9"
    "/usr/share/tomcat9"
    "/var/lib/tomcat9"
)

for TOMCAT_PATH in "${TOMCAT_PATHS[@]}"; do
    if [ -d "$TOMCAT_PATH" ]; then
        log_ok "Tomcat encontrado em: $TOMCAT_PATH"
        TOMCAT_FOUND=true
        break
    fi
done

if [ "$TOMCAT_FOUND" = false ]; then
    log_info "Tomcat não encontrado nos caminhos padrão"
    echo "   Para instalar: sudo apt install tomcat9"
fi

echo ""

# ============================================================================
# VERIFICAR RCLONE (S3)
# ============================================================================

echo "10. Rclone (para backup S3)"
echo "----------------------------------------"

if command -v rclone &> /dev/null; then
    VERSION=$(rclone version | head -1)
    log_ok "Rclone: $VERSION"

    # Verificar remotes configurados
    REMOTES=$(rclone listremotes 2>/dev/null)
    if [ -n "$REMOTES" ]; then
        log_ok "Remotes configurados:"
        echo "$REMOTES" | while read -r REMOTE; do
            echo "     - $REMOTE"
        done
    else
        log_warning "Nenhum remote configurado"
        echo "   Configure com: rclone config"
    fi
else
    log_info "Rclone não encontrado (necessário apenas para backup S3)"
    echo "   Para instalar: curl https://rclone.org/install.sh | sudo bash"
fi

echo ""

# ============================================================================
# VERIFICAR ESPAÇO EM DISCO
# ============================================================================

echo "11. Espaço em Disco"
echo "----------------------------------------"

BACKUP_DIR="/root/backups"
if [ -d "$BACKUP_DIR" ]; then
    AVAILABLE=$(df -h "$BACKUP_DIR" | tail -1 | awk '{print $4}')
    USED_PERCENT=$(df -h "$BACKUP_DIR" | tail -1 | awk '{print $5}' | tr -d '%')

    log_ok "Diretório de backup existe: $BACKUP_DIR"
    log_info "Espaço disponível: $AVAILABLE"

    if [ "$USED_PERCENT" -gt 80 ]; then
        log_warning "Disco está ${USED_PERCENT}% cheio"
    else
        log_ok "Uso do disco: ${USED_PERCENT}%"
    fi
else
    log_info "Diretório $BACKUP_DIR será criado"
fi

echo ""

# ============================================================================
# VERIFICAR SYSTEMD
# ============================================================================

echo "12. Systemd"
echo "----------------------------------------"

if command -v systemctl &> /dev/null; then
    log_ok "Systemd disponível"

    # Contar serviços customizados
    CUSTOM_SERVICES=$(ls /etc/systemd/system/*.service 2>/dev/null | wc -l)
    log_info "Serviços customizados: $CUSTOM_SERVICES"
else
    log_error "Systemd não encontrado (necessário para gerenciar serviços)"
fi

echo ""

# ============================================================================
# VERIFICAR CRON
# ============================================================================

echo "13. Cron (para backup automático)"
echo "----------------------------------------"

if command -v crontab &> /dev/null; then
    log_ok "Cron disponível"

    # Verificar se há crontab configurado
    if crontab -l &> /dev/null; then
        CRON_COUNT=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | wc -l)
        log_info "Tarefas cron configuradas: $CRON_COUNT"
    else
        log_info "Nenhuma tarefa cron configurada"
    fi
else
    log_error "Cron não disponível"
fi

echo ""

# ============================================================================
# RESUMO
# ============================================================================

echo "========================================"
echo "RESUMO DA VERIFICAÇÃO"
echo "========================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os requisitos atendidos!${NC}"
    echo ""
    echo "Você está pronto para instalar o sistema de backup."
    echo ""
    echo "Próximos passos:"
    echo "  1. Copie os scripts para /opt/backup-scripts/"
    echo "  2. Configure backup.conf"
    echo "  3. Execute: sudo ./backup-vps.sh"
    exit 0

elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS aviso(s) encontrado(s)${NC}"
    echo ""
    echo "O sistema pode funcionar, mas alguns recursos"
    echo "podem não estar disponíveis."
    echo ""
    echo "Revise os avisos acima e instale os componentes"
    echo "necessários para suas aplicações."
    exit 0

else
    echo -e "${RED}✗ $ERRORS erro(s) encontrado(s)${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS aviso(s) encontrado(s)${NC}"
    fi
    echo ""
    echo "Corrija os erros acima antes de prosseguir."
    echo ""
    echo "Comandos sugeridos para instalar requisitos básicos:"
    echo "  sudo apt update"
    echo "  sudo apt install -y tar gzip rsync mariadb-server mariadb-backup"
    exit 1
fi
