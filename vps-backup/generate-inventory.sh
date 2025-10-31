#!/bin/bash
# ============================================================================
# SCRIPT DE GERAÇÃO DE INVENTÁRIO DO SISTEMA
# ============================================================================
# Este script gera um inventário detalhado do sistema para auxiliar
# na migração para outro servidor
# ============================================================================

set -euo pipefail

# Cores para output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

OUTPUT_FILE="${1:-system-inventory-$(date +%Y%m%d_%H%M%S).txt}"

echo -e "${BLUE}Gerando inventário do sistema...${NC}"

cat > "$OUTPUT_FILE" <<EOF
================================================================================
INVENTÁRIO COMPLETO DO SISTEMA
Gerado em: $(date)
Hostname: $(hostname)
================================================================================

EOF

# ============================================================================
# INFORMAÇÕES DO SISTEMA OPERACIONAL
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
1. SISTEMA OPERACIONAL
================================================================================

$(cat /etc/os-release 2>/dev/null || echo "Informação não disponível")

Kernel: $(uname -r)
Arquitetura: $(uname -m)
Uptime: $(uptime)

EOF

# ============================================================================
# HARDWARE
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
2. HARDWARE
================================================================================

CPU:
$(lscpu 2>/dev/null || echo "lscpu não disponível")

Memória:
$(free -h)

Disco:
$(df -h)

Partições:
$(lsblk 2>/dev/null || echo "lsblk não disponível")

EOF

# ============================================================================
# REDE
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
3. CONFIGURAÇÃO DE REDE
================================================================================

Interfaces de rede:
$(ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Informação não disponível")

Rotas:
$(ip route show 2>/dev/null || route -n 2>/dev/null || echo "Informação não disponível")

DNS (/etc/resolv.conf):
$(cat /etc/resolv.conf 2>/dev/null || echo "Arquivo não encontrado")

Hosts (/etc/hosts):
$(cat /etc/hosts 2>/dev/null || echo "Arquivo não encontrado")

Portas em escuta:
$(ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null || echo "Informação não disponível")

EOF

# ============================================================================
# SOFTWARES INSTALADOS
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
4. SOFTWARES E VERSÕES
================================================================================

EOF

# Java
if command -v java &> /dev/null; then
    echo "JAVA:" >> "$OUTPUT_FILE"
    java -version 2>&1 >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "JAVA_HOME: ${JAVA_HOME:-não definido}" >> "$OUTPUT_FILE"
    echo "Localização: $(which java)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Maven
if command -v mvn &> /dev/null; then
    echo "MAVEN:" >> "$OUTPUT_FILE"
    mvn -version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Gradle
if command -v gradle &> /dev/null; then
    echo "GRADLE:" >> "$OUTPUT_FILE"
    gradle --version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Node.js
if command -v node &> /dev/null; then
    echo "NODE.JS:" >> "$OUTPUT_FILE"
    echo "Versão: $(node --version)" >> "$OUTPUT_FILE"
    echo "Localização: $(which node)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# NPM
if command -v npm &> /dev/null; then
    echo "NPM:" >> "$OUTPUT_FILE"
    echo "Versão: $(npm --version)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# PM2
if command -v pm2 &> /dev/null; then
    echo "PM2:" >> "$OUTPUT_FILE"
    echo "Versão: $(pm2 --version)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "Aplicações PM2 em execução:" >> "$OUTPUT_FILE"
    pm2 list 2>&1 >> "$OUTPUT_FILE" || true
    echo "" >> "$OUTPUT_FILE"

    echo "Configuração de startup PM2:" >> "$OUTPUT_FILE"
    pm2 startup 2>&1 | grep -v "sudo" >> "$OUTPUT_FILE" || true
    echo "" >> "$OUTPUT_FILE"
fi

# Python
if command -v python3 &> /dev/null; then
    echo "PYTHON 3:" >> "$OUTPUT_FILE"
    echo "Versão: $(python3 --version)" >> "$OUTPUT_FILE"
    echo "Localização: $(which python3)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Pip
if command -v pip3 &> /dev/null; then
    echo "PIP3:" >> "$OUTPUT_FILE"
    echo "Versão: $(pip3 --version)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Nginx
if command -v nginx &> /dev/null; then
    echo "NGINX:" >> "$OUTPUT_FILE"
    nginx -v 2>&1 >> "$OUTPUT_FILE"
    echo "Arquivo de configuração: /etc/nginx/nginx.conf" >> "$OUTPUT_FILE"
    echo "Sites habilitados:" >> "$OUTPUT_FILE"
    ls -la /etc/nginx/sites-enabled/ 2>&1 >> "$OUTPUT_FILE" || echo "Diretório não encontrado" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Apache
if command -v apache2 &> /dev/null; then
    echo "APACHE:" >> "$OUTPUT_FILE"
    apache2 -v 2>&1 >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# MySQL/MariaDB
if command -v mysql &> /dev/null; then
    echo "MYSQL/MARIADB:" >> "$OUTPUT_FILE"
    mysql --version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "Tentando listar bancos de dados (requer credenciais)..." >> "$OUTPUT_FILE"
    # Nota: isto pode falhar se não houver credenciais
    mysql -e "SHOW DATABASES;" 2>&1 >> "$OUTPUT_FILE" || echo "Sem acesso - forneça credenciais manualmente" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# PostgreSQL
if command -v psql &> /dev/null; then
    echo "POSTGRESQL:" >> "$OUTPUT_FILE"
    psql --version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Redis
if command -v redis-server &> /dev/null; then
    echo "REDIS:" >> "$OUTPUT_FILE"
    redis-server --version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Docker
if command -v docker &> /dev/null; then
    echo "DOCKER:" >> "$OUTPUT_FILE"
    docker --version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "Containers em execução:" >> "$OUTPUT_FILE"
    docker ps 2>&1 >> "$OUTPUT_FILE" || true
    echo "" >> "$OUTPUT_FILE"

    echo "Imagens:" >> "$OUTPUT_FILE"
    docker images 2>&1 >> "$OUTPUT_FILE" || true
    echo "" >> "$OUTPUT_FILE"
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "DOCKER COMPOSE:" >> "$OUTPUT_FILE"
    docker-compose --version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Git
if command -v git &> /dev/null; then
    echo "GIT:" >> "$OUTPUT_FILE"
    git --version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Certbot
if command -v certbot &> /dev/null; then
    echo "CERTBOT:" >> "$OUTPUT_FILE"
    certbot --version 2>&1 >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "Certificados instalados:" >> "$OUTPUT_FILE"
    certbot certificates 2>&1 >> "$OUTPUT_FILE" || true
    echo "" >> "$OUTPUT_FILE"
fi

# Rclone
if command -v rclone &> /dev/null; then
    echo "RCLONE:" >> "$OUTPUT_FILE"
    rclone version >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "Remotes configurados:" >> "$OUTPUT_FILE"
    rclone listremotes 2>&1 >> "$OUTPUT_FILE" || true
    echo "" >> "$OUTPUT_FILE"
fi

# ============================================================================
# TOMCAT
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
5. TOMCAT
================================================================================

EOF

TOMCAT_PATHS=(
    "/opt/tomcat"
    "/opt/tomcat9"
    "/usr/share/tomcat9"
    "/var/lib/tomcat9"
)

TOMCAT_FOUND=false
for TOMCAT_PATH in "${TOMCAT_PATHS[@]}"; do
    if [ -d "$TOMCAT_PATH" ]; then
        echo "Tomcat encontrado em: $TOMCAT_PATH" >> "$OUTPUT_FILE"

        if [ -f "$TOMCAT_PATH/bin/version.sh" ]; then
            echo "Versão:" >> "$OUTPUT_FILE"
            "$TOMCAT_PATH/bin/version.sh" 2>&1 >> "$OUTPUT_FILE" || true
        fi

        echo "" >> "$OUTPUT_FILE"
        echo "Webapps instaladas:" >> "$OUTPUT_FILE"
        ls -la "$TOMCAT_PATH/webapps/" 2>&1 >> "$OUTPUT_FILE" || true
        echo "" >> "$OUTPUT_FILE"

        TOMCAT_FOUND=true
    fi
done

if [ "$TOMCAT_FOUND" = false ]; then
    echo "Tomcat não encontrado nos caminhos padrão" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

# ============================================================================
# SERVIÇOS SYSTEMD
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
6. SERVIÇOS SYSTEMD
================================================================================

Serviços em execução:
$(systemctl list-units --type=service --state=running --no-pager)

Serviços habilitados para iniciar com o sistema:
$(systemctl list-unit-files --type=service --state=enabled --no-pager)

Serviços customizados em /etc/systemd/system/:
$(ls -la /etc/systemd/system/*.service 2>/dev/null || echo "Nenhum serviço customizado encontrado")

EOF

# ============================================================================
# CRON JOBS
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
7. CRON JOBS
================================================================================

Crontab do root:
$(crontab -l 2>&1 || echo "Nenhum crontab configurado para root")

Cron jobs do sistema (/etc/cron.d/):
$(ls -la /etc/cron.d/ 2>/dev/null || echo "Diretório vazio ou não encontrado")

Cron diário (/etc/cron.daily/):
$(ls -la /etc/cron.daily/ 2>/dev/null || echo "Diretório vazio ou não encontrado")

Cron semanal (/etc/cron.weekly/):
$(ls -la /etc/cron.weekly/ 2>/dev/null || echo "Diretório vazio ou não encontrado")

Cron mensal (/etc/cron.monthly/):
$(ls -la /etc/cron.monthly/ 2>/dev/null || echo "Diretório vazio ou não encontrado")

EOF

# ============================================================================
# USUÁRIOS E GRUPOS
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
8. USUÁRIOS E GRUPOS
================================================================================

Usuários do sistema:
$(cat /etc/passwd)

Grupos:
$(cat /etc/group)

Usuários logados:
$(who)

EOF

# ============================================================================
# FIREWALL
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
9. FIREWALL
================================================================================

EOF

if command -v ufw &> /dev/null; then
    echo "UFW:" >> "$OUTPUT_FILE"
    ufw status verbose 2>&1 >> "$OUTPUT_FILE" || echo "UFW não está ativo" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

if command -v iptables &> /dev/null; then
    echo "IPTABLES:" >> "$OUTPUT_FILE"
    iptables -L -n 2>&1 >> "$OUTPUT_FILE" || echo "Sem permissão para listar regras" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# ============================================================================
# SCRIPTS CUSTOMIZADOS
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
10. SCRIPTS CUSTOMIZADOS
================================================================================

Scripts em /opt/scripts:
$(ls -lah /opt/scripts/ 2>/dev/null || echo "Diretório não encontrado")

Scripts em /root/scripts:
$(ls -lah /root/scripts/ 2>/dev/null || echo "Diretório não encontrado")

Scripts em /usr/local/bin/:
$(ls -lah /usr/local/bin/*.sh 2>/dev/null || echo "Nenhum script .sh encontrado")

EOF

# ============================================================================
# PACOTES INSTALADOS
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
11. PACOTES INSTALADOS (APT/YUM)
================================================================================

EOF

if command -v apt &> /dev/null; then
    echo "Pacotes instalados (APT):" >> "$OUTPUT_FILE"
    dpkg -l >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
elif command -v yum &> /dev/null; then
    echo "Pacotes instalados (YUM):" >> "$OUTPUT_FILE"
    yum list installed >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# ============================================================================
# VARIÁVEIS DE AMBIENTE
# ============================================================================

cat >> "$OUTPUT_FILE" <<EOF
================================================================================
12. VARIÁVEIS DE AMBIENTE
================================================================================

$(env | sort)

EOF

# ============================================================================
# COMANDOS DE INSTALAÇÃO PARA MIGRAÇÃO
# ============================================================================

cat >> "$OUTPUT_FILE" <<'EOF'
================================================================================
13. COMANDOS SUGERIDOS PARA MIGRAÇÃO
================================================================================

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar ferramentas básicas
sudo apt install -y curl wget git vim nano htop build-essential

EOF

# Adicionar comandos baseados no que está instalado
if command -v java &> /dev/null; then
    cat >> "$OUTPUT_FILE" <<'EOF'
# Instalar Java 21
sudo apt install -y openjdk-21-jdk

EOF
fi

if command -v node &> /dev/null; then
    cat >> "$OUTPUT_FILE" <<'EOF'
# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

EOF
fi

if command -v pm2 &> /dev/null; then
    cat >> "$OUTPUT_FILE" <<'EOF'
# Instalar PM2
sudo npm install -g pm2

EOF
fi

if command -v mysql &> /dev/null; then
    cat >> "$OUTPUT_FILE" <<'EOF'
# Instalar MariaDB
sudo apt install -y mariadb-server mariadb-backup
sudo systemctl enable mariadb
sudo mysql_secure_installation

EOF
fi

if command -v nginx &> /dev/null; then
    cat >> "$OUTPUT_FILE" <<'EOF'
# Instalar Nginx
sudo apt install -y nginx
sudo systemctl enable nginx

EOF
fi

if command -v certbot &> /dev/null; then
    cat >> "$OUTPUT_FILE" <<'EOF'
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

EOF
fi

if command -v rclone &> /dev/null; then
    cat >> "$OUTPUT_FILE" <<'EOF'
# Instalar Rclone
curl https://rclone.org/install.sh | sudo bash

EOF
fi

cat >> "$OUTPUT_FILE" <<'EOF'
# Configurar firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

================================================================================
FIM DO INVENTÁRIO
================================================================================
EOF

echo -e "${GREEN}Inventário gerado com sucesso: $OUTPUT_FILE${NC}"
echo ""
echo "Para visualizar:"
echo "  cat $OUTPUT_FILE"
echo "  less $OUTPUT_FILE"

exit 0
