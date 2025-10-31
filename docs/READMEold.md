# Sistema de Backup e Restore para VPS

Sistema completo de backup e restauração para servidores VPS Linux com suporte a múltiplas aplicações e tecnologias.

## 📋 Índice

- [Características](#características)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Configuração](#configuração)
- [Uso](#uso)
- [Estrutura de Backup](#estrutura-de-backup)
- [Exemplos Práticos](#exemplos-práticos)
- [Troubleshooting](#troubleshooting)

## ✨ Características

### Componentes Suportados

- ☕ **APIs Spring Boot** (Java 21)
  - Backup de JARs executáveis
  - Configurações (application.properties/yml)
  - Services systemd

- 🐱 **Apache Tomcat 9**
  - Configurações (/conf)
  - Webapps deployadas
  - Service systemd

- 🟢 **Aplicações Node.js**
  - Código-fonte (sem node_modules)
  - package.json e package-lock.json
  - Configuração PM2

- 🗄️ **MariaDB**
  - Backup físico (mariabackup - rápido)
  - Backup lógico (mysqldump - compatível)
  - Todos os bancos ou selecionados

- 🌐 **Nginx**
  - Configurações completas
  - Sites habilitados
  - Certificados SSL (Let's Encrypt/Certbot)

- 📄 **Aplicações Estáticas**
  - Sites HTML/CSS/JS
  - Assets

- 🔧 **Scripts Customizados**
  - Scripts em Shell, Python, JS, Ruby
  - Cron jobs
  - Configurações systemd

### Funcionalidades Extras

- 📊 Geração de inventário detalhado do sistema
- 📦 Compactação de backups (tar.gz)
- 🔄 Rotação automática de backups
- ☁️ Upload para S3 via rclone
- 🔒 Backup remoto via rsync
- 📧 Notificações por email (opcional)
- 🔄 Restore seletivo ou completo

## 🔧 Requisitos

### Sistema Operacional
- Ubuntu 20.04+ / Debian 10+
- CentOS/RHEL 8+ (com adaptações)

### Ferramentas Necessárias

**Essenciais:**
```bash
sudo apt install -y tar gzip rsync
```

**Para backup de banco de dados:**
```bash
sudo apt install -y mariadb-client mariadb-backup
```

**Para S3 (opcional):**
```bash
curl https://rclone.org/install.sh | sudo bash
```

**Para notificações (opcional):**
```bash
sudo apt install -y mailutils
```

## 📥 Instalação

### 1. Clone ou Baixe os Scripts

```bash
# Criar diretório
sudo mkdir -p /opt/backup-scripts
cd /opt/backup-scripts

# Copiar os arquivos
# - backup.conf
# - backup-vps.sh
# - restore-vps.sh
# - generate-inventory.sh
```

### 2. Dar Permissões de Execução

```bash
sudo chmod +x backup-vps.sh restore-vps.sh generate-inventory.sh
```

### 3. Criar Diretório de Backups

```bash
sudo mkdir -p /root/backups
```

## ⚙️ Configuração

### 1. Editar backup.conf

```bash
sudo nano backup.conf
```

### Configurações Principais

#### Diretório de Backup
```bash
BACKUP_ROOT="/root/backups"
BACKUP_RETENTION_DAYS=7  # Manter por 7 dias
COMPRESS_BACKUPS=true    # Compactar em .tar.gz
```

#### Banco de Dados
```bash
DB_USER="root"
DB_PASSWORD="sua_senha"
DB_HOST="localhost"
DB_PORT="3306"

# Fazer backup de bancos específicos
DB_LIST="banco1 banco2 banco3"
# OU deixar vazio para todos os bancos
DB_LIST=""

# Método: "mariabackup" (rápido) ou "mysqldump" (compatível)
DB_BACKUP_METHOD="mariabackup"
```

#### Aplicações Spring Boot
```bash
BACKUP_SPRINGBOOT=true

SPRINGBOOT_APPS=(
    "api-produtos:/opt/apps/api-produtos/app.jar:/etc/systemd/system/api-produtos.service"
    "api-usuarios:/opt/apps/api-usuarios/app.jar:/etc/systemd/system/api-usuarios.service"
)
```

#### Tomcat
```bash
BACKUP_TOMCAT=true
TOMCAT_HOME="/opt/tomcat9"
BACKUP_TOMCAT_LOGS=false  # false para economizar espaço
```

#### Node.js
```bash
BACKUP_NODEJS=true

NODEJS_APPS=(
    "api-websocket:/opt/nodejs/api-websocket"
    "app-frontend:/opt/nodejs/app-frontend"
)

PM2_USER="root"  # Usuário que roda o PM2
```

#### Aplicações Estáticas
```bash
BACKUP_STATIC_APPS=true

STATIC_APPS_DIRS=(
    "/var/www/html/site1"
    "/var/www/html/site2"
)
```

#### Nginx
```bash
BACKUP_NGINX=true
NGINX_CONFIG_DIR="/etc/nginx"
BACKUP_SSL_CERTS=true
SSL_CERTS_DIR="/etc/letsencrypt"
```

#### Scripts Customizados
```bash
BACKUP_CUSTOM_SCRIPTS=true
CUSTOM_SCRIPTS_DIRS="/opt/scripts /root/scripts"
```

#### S3 (Opcional)
```bash
S3_BACKUP=true
RCLONE_REMOTE="s3"        # Nome do remote no rclone
S3_BUCKET="meu-bucket"
S3_PATH="backups/vps"
S3_RETENTION_COUNT=10     # Manter últimos 10 backups no S3
```

### 2. Configurar Rclone (para S3)

```bash
# Configurar rclone
rclone config

# Siga as instruções para adicionar um remote S3
# Nome sugerido: "s3"
# Tipo: Amazon S3
# Provider: AWS
# Forneça Access Key e Secret Key
```

## 🚀 Uso

### Backup Completo

```bash
# Executar backup manualmente
sudo ./backup-vps.sh
```

### Backups Modulares (NOVO!)

Você pode configurar backups modulares usando a variável `BACKUP_MODE` no arquivo `backup.conf`:

#### Opções de BACKUP_MODE:

```bash
# No arquivo backup.conf

# Backup completo (tudo)
BACKUP_MODE="full"

# Apenas infraestrutura (sem banco e sem webapps do Tomcat)
BACKUP_MODE="infra"

# Apenas banco de dados
BACKUP_MODE="database"

# Apenas webapps do Tomcat
BACKUP_MODE="webapps"

# Deixe vazio para usar as configurações individuais (modo legado)
BACKUP_MODE=""
```

#### Exemplos de Uso:

**Backup de infraestrutura (durante janela de manutenção):**
```bash
# Edite backup.conf e defina:
BACKUP_MODE="infra"

# Execute o backup
sudo ./backup-vps.sh
# Resultado: Backup de Spring Boot, Tomcat (sem webapps), Node.js, Nginx, SSL, scripts
# NÃO inclui: Banco de dados e webapps do Tomcat
```

**Backup apenas do banco (backup diário rápido):**
```bash
# Edite backup.conf e defina:
BACKUP_MODE="database"

# Execute o backup
sudo ./backup-vps.sh
# Resultado: Backup apenas do MariaDB
```

**Backup apenas das webapps (após deploy):**
```bash
# Edite backup.conf e defina:
BACKUP_MODE="webapps"

# Execute o backup
sudo ./backup-vps.sh
# Resultado: Backup apenas do diretório webapps/ do Tomcat
```

**Estratégia recomendada para produção:**
```bash
# Crontab com múltiplos backups:

# Backup completo semanal (domingos às 2h)
0 2 * * 0 BACKUP_MODE=full /opt/backup-scripts/backup-vps.sh

# Backup de banco diário (todos os dias às 3h)
0 3 * * * BACKUP_MODE=database /opt/backup-scripts/backup-vps.sh

# Backup de infraestrutura quinzenal (1º e 15º dia do mês às 4h)
0 4 1,15 * * BACKUP_MODE=infra /opt/backup-scripts/backup-vps.sh
```

### Agendar Backup Diário (Cron)

```bash
# Editar crontab
sudo crontab -e

# Adicionar linha para backup às 2h da manhã todos os dias
0 2 * * * /opt/backup-scripts/backup-vps.sh >> /var/log/backup-vps.log 2>&1
```

### Gerar Apenas Inventário

```bash
# Gerar inventário do sistema
sudo ./generate-inventory.sh

# Ou especificar arquivo de saída
sudo ./generate-inventory.sh /tmp/meu-inventario.txt
```

### Restaurar Backup

```bash
# Restaurar de arquivo compactado
sudo ./restore-vps.sh /root/backups/20250130_120000.tar.gz

# Restaurar de diretório
sudo ./restore-vps.sh /root/backups/20250130_120000

# Restaurar de S3 (primeiro baixar com rclone)
rclone copy s3:meu-bucket/backups/vps/20250130_120000.tar.gz /tmp/
sudo ./restore-vps.sh /tmp/20250130_120000.tar.gz
```

#### Menu de Restore Interativo (NOVO!)

O script de restore agora oferece **12 opções** de restauração:

**Restauração Rápida:**
- [1] Tudo (restore completo)
- [2] Tudo EXCETO banco de dados
- [3] Infraestrutura (tudo exceto banco e webapps)

**Componentes Individuais:**
- [4] Apenas banco de dados
- [5] Apenas webapps do Tomcat
- [6] Apenas aplicações Spring Boot
- [7] Apenas Tomcat (sem webapps)
- [8] Apenas Node.js
- [9] Apenas apps estáticas
- [10] Apenas Nginx
- [11] Apenas certificados SSL
- [12] Apenas scripts customizados

**Exemplos de Uso:**

```bash
# Restaurar apenas banco de dados (após problema no DB)
sudo ./restore-vps.sh /root/backups/20250130_120000.tar.gz
# Escolha opção [4]

# Restaurar infraestrutura sem afetar banco e webapps
sudo ./restore-vps.sh /root/backups/20250130_120000.tar.gz
# Escolha opção [3]

# Restaurar apenas webapps após rollback de deploy
sudo ./restore-vps.sh /root/backups/20250130_120000.tar.gz
# Escolha opção [5]
```

## 📁 Estrutura de Backup

```
/root/backups/
└── 20250130_120000/  (ou .tar.gz)
    ├── backup.log
    ├── database/
    │   ├── mariabackup/  (se usar mariabackup)
    │   │   └── ...
    │   └── *.sql         (se usar mysqldump)
    ├── springboot/
    │   ├── api-produtos/
    │   │   ├── app.jar
    │   │   ├── application.properties
    │   │   └── api-produtos.service
    │   └── api-usuarios/
    │       └── ...
    ├── tomcat/
    │   ├── conf/
    │   ├── webapps/
    │   └── tomcat.service
    ├── nodejs/
    │   ├── app-websocket/
    │   │   ├── src/
    │   │   ├── package.json
    │   │   └── ...
    │   └── .pm2/  (configuração PM2)
    ├── static/
    │   ├── site1/
    │   └── site2/
    ├── nginx/
    │   ├── nginx/  (configurações)
    │   └── ssl/    (certificados)
    ├── system/
    │   ├── crontab-root.txt
    │   ├── systemd/
    │   ├── scripts/
    │   │   ├── opt/scripts/
    │   │   └── root/scripts/
    │   └── hosts
    └── inventory/
        ├── system-info.txt
        ├── databases.txt
        └── migration-commands.sh
```

## 💡 Exemplos Práticos

### Exemplo 1: Backup Básico com Upload para S3

```bash
# 1. Configurar backup.conf
BACKUP_ROOT="/root/backups"
COMPRESS_BACKUPS=true
S3_BACKUP=true
RCLONE_REMOTE="s3"
S3_BUCKET="backups-producao"
S3_PATH="vps-principal"

# 2. Executar
sudo ./backup-vps.sh

# Resultado:
# - Backup criado em /root/backups/20250130_120000.tar.gz
# - Enviado para s3://backups-producao/vps-principal/
```

### Exemplo 2: Backup Apenas de Banco de Dados

```bash
# 1. Editar backup.conf
BACKUP_SPRINGBOOT=false
BACKUP_TOMCAT=false
BACKUP_NODEJS=false
BACKUP_STATIC_APPS=false
BACKUP_NGINX=false

# 2. Executar
sudo ./backup-vps.sh
```

### Exemplo 3: Migração Completa para Novo Servidor

**No servidor antigo:**
```bash
# 1. Fazer backup completo
sudo ./backup-vps.sh

# 2. Copiar backup para novo servidor
scp /root/backups/20250130_120000.tar.gz user@novo-servidor:/tmp/
```

**No novo servidor:**
```bash
# 1. Instalar sistema base (verificar inventário)
cat /tmp/20250130_120000/inventory/migration-commands.sh

# 2. Executar comandos sugeridos
sudo bash /tmp/20250130_120000/inventory/migration-commands.sh

# 3. Restaurar backup
sudo ./restore-vps.sh /tmp/20250130_120000.tar.gz

# 4. Escolher opção [1] para restore completo

# 5. Verificar serviços
sudo systemctl status nginx
sudo systemctl status mariadb
sudo pm2 status
```

### Exemplo 4: Restore Seletivo (Apenas Nginx)

```bash
# Executar restore
sudo ./restore-vps.sh /root/backups/20250130_120000.tar.gz

# Escolher opção [7] - Apenas Nginx
# Seguir prompts interativos
```

### Exemplo 5: Configurar Backup Automático Diário com Notificação

```bash
# 1. Configurar email no backup.conf
SEND_EMAIL_NOTIFICATION=true
EMAIL_TO="admin@empresa.com"

# 2. Instalar mailutils
sudo apt install -y mailutils

# 3. Adicionar ao cron
sudo crontab -e

# Backup diário às 3h da manhã
0 3 * * * /opt/backup-scripts/backup-vps.sh >> /var/log/backup-vps.log 2>&1
```

## 🔍 Troubleshooting

### Problema: Erro "mariabackup command not found"

**Solução:**
```bash
sudo apt install -y mariadb-backup

# OU mudar para mysqldump no backup.conf
DB_BACKUP_METHOD="mysqldump"
```

### Problema: Backup muito grande

**Soluções:**
1. Desabilitar backup de logs:
```bash
BACKUP_TOMCAT_LOGS=false
BACKUP_NGINX_LOGS=false
BACKUP_SCRIPT_LOGS=false
```

2. Excluir bancos grandes desnecessários:
```bash
DB_EXCLUDE="information_schema performance_schema mysql sys banco_logs"
```

3. Usar mariabackup compactado:
```bash
DB_BACKUP_METHOD="mariabackup"
COMPRESS_BACKUPS=true
```

### Problema: Restore falha em banco de dados

**Verificar:**
1. MariaDB está rodando?
```bash
sudo systemctl status mariadb
```

2. Credenciais corretas no backup.conf?
```bash
mysql -u root -p
```

3. Espaço em disco suficiente?
```bash
df -h
```

### Problema: PM2 não restaura aplicações

**Solução:**
```bash
# Verificar usuário PM2
PM2_USER="root"  # ou seu usuário

# Restaurar manualmente
su - $PM2_USER
pm2 resurrect
pm2 list
```

### Problema: Nginx não inicia após restore

**Verificar:**
1. Testar configuração:
```bash
sudo nginx -t
```

2. Verificar certificados SSL:
```bash
ls -la /etc/letsencrypt/live/
```

3. Verificar portas:
```bash
sudo ss -tlnp | grep :80
sudo ss -tlnp | grep :443
```

### Problema: Upload S3 falha

**Verificar:**
1. Rclone configurado?
```bash
rclone listremotes
```

2. Testar acesso:
```bash
rclone ls s3:seu-bucket
```

3. Verificar credenciais:
```bash
rclone config show s3
```

## 📊 Monitoramento

### Ver Logs de Backup

```bash
# Log mais recente
cat /root/backups/*/backup.log | tail -100

# Buscar erros
grep -i error /root/backups/*/backup.log
```

### Listar Backups Existentes

```bash
# Locais
ls -lh /root/backups/

# No S3
rclone ls s3:seu-bucket/backups/vps/
```

### Verificar Tamanho dos Backups

```bash
du -sh /root/backups/*
```

## 🔐 Segurança

### Recomendações

1. **Proteger backup.conf** (contém senhas):
```bash
chmod 600 backup.conf
```

2. **Criptografar backups sensíveis**:
```bash
# Após backup
gpg --symmetric --cipher-algo AES256 backup.tar.gz
```

3. **Usar chaves SSH para remote backup**:
```bash
ssh-keygen -t rsa -b 4096
ssh-copy-id usuario@servidor-backup
```

4. **Rotacionar senhas** de banco de dados periodicamente

5. **Testar restore regularmente** (pelo menos mensalmente)

## 📝 Notas Adicionais

- Os scripts usam `set -euo pipefail` para parar em erros
- Logs detalhados são salvos em cada backup
- Restore é interativo com confirmações
- Backups compactados economizam ~70% de espaço
- mariabackup é ~3x mais rápido que mysqldump
- S3 é ideal para backup offsite
- Sempre teste o restore antes de confiar no backup!

## 🆘 Suporte

Para problemas ou dúvidas:
1. Verificar logs em `/root/backups/*/backup.log`
2. Executar `generate-inventory.sh` para diagnosticar sistema
3. Verificar permissões dos arquivos e diretórios
4. Conferir se todos os serviços estão rodando

## 📄 Licença

Scripts de uso livre para fins pessoais e comerciais.
