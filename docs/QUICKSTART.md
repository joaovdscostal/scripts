# 🚀 Guia Rápido de Início

## Instalação em 5 Minutos

### 1. Copiar Arquivos para o Servidor

```bash
# No seu servidor VPS
sudo mkdir -p /opt/backup-scripts
cd /opt/backup-scripts

# Copie os seguintes arquivos para este diretório:
# - backup.conf ou backup.conf.example
# - backup-vps.sh
# - restore-vps.sh
# - generate-inventory.sh
```

### 2. Dar Permissões

```bash
sudo chmod +x *.sh
```

### 3. Configurar

```bash
# Se usar o exemplo, copie primeiro
sudo cp backup.conf.example backup.conf

# Edite a configuração
sudo nano backup.conf
```

**Configurações MÍNIMAS necessárias:**

```bash
# Senha do banco de dados
DB_PASSWORD="sua_senha_aqui"

# Aplicações Spring Boot (se tiver)
SPRINGBOOT_APPS=(
    "nome-app:/caminho/app.jar:/caminho/service"
)

# Aplicações Node.js (se tiver)
NODEJS_APPS=(
    "nome-app:/caminho/aplicacao"
)

# Sites estáticos (se tiver)
STATIC_APPS_DIRS=(
    "/var/www/html/seu-site"
)

# Tomcat (se tiver)
TOMCAT_HOME="/opt/tomcat9"
```

### 4. Testar

```bash
# Gerar inventário primeiro
sudo ./generate-inventory.sh

# Fazer primeiro backup
sudo ./backup-vps.sh
```

### 5. Verificar

```bash
# Ver o backup criado
ls -lh /root/backups/

# Ver o log
cat /root/backups/*/backup.log
```

## Configuração S3 (Opcional mas Recomendado)

### 1. Instalar Rclone

```bash
curl https://rclone.org/install.sh | sudo bash
```

### 2. Configurar S3

```bash
rclone config

# Escolha: n (New remote)
# Nome: s3
# Tipo: 4 (Amazon S3)
# Provider: 1 (AWS)
# Forneça Access Key ID
# Forneça Secret Access Key
# Region: (sua região, ex: us-east-1)
# Pressione Enter para demais opções
# Confirme: y
```

### 3. Testar Conexão

```bash
# Criar bucket (se não existir)
rclone mkdir s3:seu-bucket-backups

# Listar buckets
rclone lsd s3:

# Testar upload
echo "teste" > /tmp/teste.txt
rclone copy /tmp/teste.txt s3:seu-bucket-backups/
```

### 4. Habilitar no backup.conf

```bash
sudo nano backup.conf

# Alterar:
S3_BACKUP=true
S3_BUCKET="seu-bucket-backups"
S3_PATH="vps"
```

## Agendar Backup Automático

```bash
# Editar crontab do root
sudo crontab -e

# Adicionar (backup diário às 2h da manhã)
0 2 * * * /opt/backup-scripts/backup-vps.sh >> /var/log/backup-vps.log 2>&1
```

## Cenários Comuns

### Cenário 1: Servidor Simples (Apenas Nginx + Arquivos)

```bash
# backup.conf
BACKUP_SPRINGBOOT=false
BACKUP_TOMCAT=false
BACKUP_NODEJS=false
BACKUP_NGINX=true
BACKUP_STATIC_APPS=true

STATIC_APPS_DIRS=(
    "/var/www/html"
)
```

### Cenário 2: API Spring Boot + Banco

```bash
# backup.conf
DB_PASSWORD="senha123"
BACKUP_SPRINGBOOT=true
BACKUP_TOMCAT=false
BACKUP_NODEJS=false

SPRINGBOOT_APPS=(
    "minha-api:/opt/apps/minha-api/app.jar:/etc/systemd/system/minha-api.service"
)
```

### Cenário 3: Full Stack (Node + Spring + Banco + Nginx)

```bash
# backup.conf
DB_PASSWORD="senha123"
BACKUP_SPRINGBOOT=true
BACKUP_NODEJS=true
BACKUP_NGINX=true

SPRINGBOOT_APPS=(
    "api-backend:/opt/apps/api/app.jar:/etc/systemd/system/api.service"
)

NODEJS_APPS=(
    "app-frontend:/opt/nodejs/frontend"
)
```

## Testar Restore

**IMPORTANTE:** Sempre teste o restore em ambiente de desenvolvimento primeiro!

```bash
# 1. Fazer backup
sudo ./backup-vps.sh

# 2. Simular restore (em servidor de testes)
sudo ./restore-vps.sh /root/backups/XXXXX.tar.gz

# 3. Escolher opção apropriada
# [1] = Tudo
# [2] = Apenas banco
# [9] = Personalizado
```

## Comandos Úteis

```bash
# Ver backups
ls -lh /root/backups/

# Ver últimos logs
tail -100 /root/backups/*/backup.log

# Buscar erros
grep -i error /root/backups/*/backup.log

# Ver tamanho total
du -sh /root/backups/

# Baixar do S3
rclone ls s3:seu-bucket/vps/
rclone copy s3:seu-bucket/vps/backup.tar.gz /tmp/

# Limpar backups antigos manualmente
find /root/backups/ -name "*.tar.gz" -mtime +30 -delete
```

## Troubleshooting Rápido

### Erro: "mariabackup not found"
```bash
sudo apt install mariadb-backup
# OU
# Mude no backup.conf: DB_BACKUP_METHOD="mysqldump"
```

### Erro: "Permission denied"
```bash
# Verificar permissões
ls -la backup-vps.sh
sudo chmod +x backup-vps.sh
```

### Erro: "No space left"
```bash
# Verificar espaço
df -h

# Limpar backups antigos
rm -f /root/backups/*.tar.gz
```

### Backup muito lento
```bash
# Desabilitar logs
BACKUP_TOMCAT_LOGS=false
BACKUP_NGINX_LOGS=false

# Usar mariabackup
DB_BACKUP_METHOD="mariabackup"
```

## Checklist Pré-Produção

- [ ] Testei o backup manualmente
- [ ] Testei o restore em servidor de desenvolvimento
- [ ] Configurei S3 para backup remoto
- [ ] Agendei backup automático no cron
- [ ] Testei que o cron está funcionando
- [ ] Documentei as senhas em local seguro
- [ ] Configurei alertas (email ou outro)
- [ ] Testei restore completo em servidor limpo

## Próximos Passos

1. ✅ Scripts instalados e configurados
2. ✅ Primeiro backup realizado
3. ⬜ Configurar S3
4. ⬜ Agendar backup automático
5. ⬜ Testar restore
6. ⬜ Documentar procedimentos específicos da sua infraestrutura

## Suporte

- Ver README.md para documentação completa
- Ver logs em /root/backups/*/backup.log
- Executar ./generate-inventory.sh para diagnóstico

---

**Lembre-se:** Um backup que não foi testado não é um backup! Teste o restore regularmente.
